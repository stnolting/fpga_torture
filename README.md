# FPGA Torture

This design allows to stress-test FPGA utilization by consuming **all** available
logic resources (LUTs + FFs). The design implements a modified Galois LFSR to generate
a lot of (chaotic) switching activity / dynamic power consumption to also stress-test
FPGA power supplies.

Most concepts for testing max utilization / power requirements use a simple shift register
where each FF (flip flop/register) toggles in every cycle. These kind of concepts are based entirely
on FFs but also provide a maximum switching activity (in the FFs). _FPGA_torture_ is also based on consuming
all available FFs but it also includes all available LUTs (look-up tables) to utilize **all** of the FPGA'shift
general purpose logic resources.

The VHDL code provides an technology-agnostic description, which do not use any
primitives, attributes or other device/platform-specific things. Tested on Lattice
(Radiant, SinplifyPro) and Intel (Quartus Prime) FPGAs.

**:warning: BEWARE! This setup might cause permanent damage of your FPGA/board if over-current
and over-temperature protection are insufficient!**


## How does it work?

The _FPGA_torture_ design is based on a register chain, which basically implements a "circular" modified Galois
LFSR (linear feedback shift register). The size of the chain is defined by the designs `NUM_CELLS` generic. Each cell
consists of a FF and a LUT. The LUT uses the input from the three previous FFs to compute the next value for the cell's FF:

`chain(i) = chain_(i-1) xor chain(i-2) xor chain(i-2)` (`chain(i)` is the FF at position `i` in the chain)

Technology view of the chain from Quartus Prime: computation of next value for register `chain[7]`
via one LUT by using the states of the previous three registers `chain[4]`, `chain[5]` and `chain[6]`.

![Chain detail](https://raw.githubusercontent.com/stnolting/fpga_torture/main/img/example_chain.png)

The beginning of the chain use an additional FF, which toggles every clock cycle, to "start" the chain.
Once initialized, the chain generates very high (but not max) chaotic switching activity
and dynamic power consumption. 

![Example waveform](https://raw.githubusercontent.com/stnolting/fpga_torture/main/img/example_wave.png)

:warning: For some `NUM_CELLS` values (e.g. 30) the chain will provide maximum switching activity (each FF toggling in every cycle).

### Top Entity

The top entity is [`rtl/fpga_torture.vhd`](https://github.com/stnolting/fpga_torture/blob/main/rtl/fpga_torture.vhd):

```vhdl
entity fpga_torture is
  generic (
    NUM_CELLS : natural := 5278 -- number of LUT3+FF elements
  );
  port (
    clk_i  : in  std_ulogic; -- clock input
    rstn_i : in  std_ulogic; -- low-active async reset
    out_o  : out std_ulogic  -- dummy output (LED or unconnected FPGA pin)
  );
end fpga_torture;
```

The reset signal `rstn_i` is optional if the target FPGA supports FF initialization via bitstream. In this case tie `rstn_i` to `1`.
The `out_o` output signal is required to prevent the synthesis tool from removing the whole design logic. Connect this to some uncritical
FPGA output pin like a LED or an unconnected FPGA pin.


### Simulation

The projects provides a simple testbench
([`sim/fpga_torture_tb.vhd`](https://github.com/stnolting/fpga_torture/blob/main/sim/fpga_torture_tb.vhd)), which
can be simulated by GHDL via the provides script ([`sim/ghdl.sh`](https://github.com/stnolting/fpga_torture/blob/main/sim/ghdl.sh):

```
fpga_torture/sim$ sh ghdl.sh
```

The simulation will run for 1ms using a 100MHz clock. The waveform data is stored to `sim/fpga_torture.vcd`
so it can be viewed using _gtkwave_:

```
fpga_torture/sim$ gtkwave fpga_torture.vcd`
```


## Hardware Utilization

The total size of the chain is defined by the `NUM_CELLS` generic. The design will require
`NUM_CELLS+1` FFs (registers) and `NUM_CELLS+2` LUT3s (look-up tables, 3-inputs each). Some
FPGAs/toolchains might also introduce some additional route-through LUTs.

Mapping example: Lattice `iCE40UP5K-UWG30ITR` FPGA, SinplifyPro, `NUM_CELLS` = **5278**

```
   Number of slice registers: 5279 out of  5280 (100%)
   Number of I/O registers:      0 out of    63 (0%)
   Number of LUT4s:           5280 out of  5280 (100%)
      Number of logic LUT4s:               5280
      Number of ripple logic:                 0 (0 LUT4s)
   Number of IO sites used:      3 out of    21 (14%)
   Number of Clocks:  1
      Net clk_i_c: 5279 loads, 5279 rising, 0 falling (Driver: Port clk_i)
   Number of LSRs:  1
      Net rstn_i_c_i: 5279 loads, 5279 SLICEs
```
