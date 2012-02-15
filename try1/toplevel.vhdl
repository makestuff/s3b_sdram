--
-- Copyright (C) 2012 Chris McClelland
--
-- This program is free software: you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation, either version 3 of the License, or
-- (at your option) any later version.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program.  If not, see <http://www.gnu.org/licenses/>.
--
library ieee;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.memctrl_pkg.all;

entity toplevel is
	port(
		-- Reset & 48MHz clock
		reset_in    : in std_logic;
		ifclk_in    : in std_logic;

		-- SDRAM interface
		ramClk_out  : out std_logic;
		ramRAS_out  : out std_logic;
		ramCAS_out  : out std_logic;
		ramWE_out   : out std_logic;
		ramAddr_out : out std_logic_vector(11 downto 0);
		ramData_io  : inout std_logic_vector(15 downto 0);
		ramBank_out : out std_logic_vector(1 downto 0);
		ramLDQM_out : out std_logic;
		ramUDQM_out : out std_logic;

		-- Onboard peripherals
		sseg_out    : out std_logic_vector(7 downto 0);
		anode_out   : out std_logic_vector(3 downto 0)
	);
end entity;
 
architecture behavioural of toplevel is

	signal ssData      : std_logic_vector(15 downto 0);
	signal ssData_next : std_logic_vector(15 downto 0);
	signal mcRDV       : std_logic;

begin

	-- Infer the memory controller
	--
	u1: memctrl
		generic map(
			INIT_COUNT => "1" & x"2C0"  -- 100uS @ 48MHz
		)
		port map(
			mcRst_in    => reset_in,
			mcClk_in    => ifclk_in,

			mcRDV_out   => mcRDV,  -- Read Data Valid

			ramRAS_out  => ramRAS_out,
			ramCAS_out  => ramCAS_out,
			ramWE_out   => ramWE_out,
			ramAddr_out => ramAddr_out,
			ramData_io  => ramData_io,
			ramBank_out => ramBank_out,
			ramLDQM_out => ramLDQM_out,
			ramUDQM_out => ramUDQM_out
		);

	-- Infer a 16-bit register for ssData.
	--
	process(ifclk_in, reset_in)
	begin
		if ( reset_in = '1' ) then
			ssData <= (others => '0');
		elsif ( ifclk_in'event and ifclk_in = '1' ) then
			ssData <= ssData_next;
		end if;
	end process;

	-- Register the data bus when memctrl asserts RDV.
	--
	ssData_next <=
		ramData_io when mcRDV = '1'
		else ssData;

	-- Drive the SDRAM clock from the 48MHz IFCLK. This should really be driven by a PLL.
	--
	ramClk_out <= ifclk_in;
	
	-- Display the current value registered in ssSata.
	--
	sevenSeg : entity work.sevenseg
		port map(
			clk    => ifclk_in,
			data   => ssData,
			segs   => sseg_out(6 downto 0),
			anodes => anode_out
		);
	sseg_out(7) <= '1';  -- Decimal point off

end architecture;
