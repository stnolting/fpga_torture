-- #################################################################################################
-- # << FPGA Torture - FPGA Stress Test >>                                                         #
-- # ********************************************************************************************* #
-- # Simple, technology-agnostic and scalable design to utilize *ALL* logic resources of an FPGA   #
-- # (LUTs and FFs). Generates very high (chaotic) switching activity / dynamic power consumption  #
-- # to stress-test the FPGA power supply. Based on a modified "circular" Galois LFSR.             #
-- #                                                                                               #
-- # NUM_CELLS generic defines the number of LUT3+FF elements.                                     #
-- # Required LUTs: NUM_CELLS+2                                                                    #
-- # Required FFs:  NUM_CELLS+1                                                                    #
-- # ********************************************************************************************* #
-- # BSD 3-Clause License                                                                          #
-- #                                                                                               #
-- # Copyright (c) 2021, Stephan Nolting. All rights reserved.                                     #
-- #                                                                                               #
-- # Redistribution and use in source and binary forms, with or without modification, are          #
-- # permitted provided that the following conditions are met:                                     #
-- #                                                                                               #
-- # 1. Redistributions of source code must retain the above copyright notice, this list of        #
-- #    conditions and the following disclaimer.                                                   #
-- #                                                                                               #
-- # 2. Redistributions in binary form must reproduce the above copyright notice, this list of     #
-- #    conditions and the following disclaimer in the documentation and/or other materials        #
-- #    provided with the distribution.                                                            #
-- #                                                                                               #
-- # 3. Neither the name of the copyright holder nor the names of its contributors may be used to  #
-- #    endorse or promote products derived from this software without specific prior written      #
-- #    permission.                                                                                #
-- #                                                                                               #
-- # THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS   #
-- # OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF               #
-- # MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE    #
-- # COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,     #
-- # EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE #
-- # GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED    #
-- # AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING     #
-- # NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED  #
-- # OF THE POSSIBILITY OF SUCH DAMAGE.                                                            #
-- # ********************************************************************************************* #
-- # https://github.com/stnolting/fpga_torture                                 (c) Stephan Nolting #
-- #################################################################################################

library ieee;
use ieee.std_logic_1164.all;

entity fpga_torture is
  generic (
    NUM_CELLS : positive := 5278 -- number of LUT3+FF elements
  );
  port (
    clk_i  : in  std_ulogic; -- clock input
    rstn_i : in  std_ulogic; -- low-active async reset
    out_o  : out std_ulogic  -- dummy output (LED or unconnected FPGA pin)
  );
end fpga_torture;

architecture fpga_torture_rtl of fpga_torture is

  signal toggle_gen : std_ulogic := '0'; -- toggle generator to start chain
  signal chain      : std_ulogic_vector(NUM_CELLS-1 downto 0) := (others => '0'); -- the chain of torture

begin

  -- Toggle Chain (single element = LUT3 + FF) ----------------------------------------------
  -- -------------------------------------------------------------------------------------------
  torture_chain: process(clk_i, rstn_i)
  begin
    if (rstn_i = '0') then
      toggle_gen <= '0';
      chain      <= (others => '0');
    elsif rising_edge(clk_i) then
      toggle_gen <= not toggle_gen;
      for i in 0 to NUM_CELLS-1 loop
        case i is
          when 0      => chain(i) <= toggle_gen xor chain(NUM_CELLS-1) xor chain(NUM_CELLS-2); -- chain start 0
          when 1      => chain(i) <= chain(0)   xor toggle_gen         xor chain(NUM_CELLS-1); -- chain start 1
          when 2      => chain(i) <= chain(1)   xor chain(0)           xor toggle_gen; -- chain start 2
          when others => chain(i) <= chain(i-1) xor chain(i-2)         xor chain(i-3); -- inside chain
        end case;
      end loop;
    end if;
  end process torture_chain;

  -- dummy output --
  out_o <= chain(chain'left);

  -- intro --
  assert false report "FPGA_TORTURE using " & positive'image(NUM_CELLS) & " LUT3+FF cells." severity note;


end fpga_torture_rtl;
