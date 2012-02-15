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
use ieee.std_logic_textio.all;
use std.textio.all;
use work.memctrl_pkg.all;
use work.hexutil.all;

entity memctrl_tb is
end memctrl_tb;

architecture behavioural of memctrl_tb is

	-- Memory controller signals
	signal mcRst       : std_logic;
	signal mcClk       : std_logic;
	signal mcRDV       : std_logic;

	-- SDRAM signals
	signal ramCmd      : std_logic_vector(2 downto 0);
	signal ramClk      : std_logic;
	signal ramRAS      : std_logic;
	signal ramCAS      : std_logic;
	signal ramWE       : std_logic;
	signal ramAddr     : std_logic_vector(11 downto 0);
	signal ramData_io  : std_logic_vector(15 downto 0);
	signal ramBank_out : std_logic_vector(1 downto 0);
	signal ramLDQM     : std_logic;
	signal ramUDQM     : std_logic;
	
begin

	-- Instantiate the memory controller for testing
	uut: memctrl
		generic map(
			INIT_COUNT => "0" & x"004"  -- Much longer in real hardware!
		)
		port map(
			mcRst_in        => mcRst,
			mcClk_in        => mcClk,
			mcRDV_out       => mcRDV,

			ramRAS_out      => ramRAS,
			ramCAS_out      => ramCAS,
			ramWE_out       => ramWE,
			ramAddr_out     => ramAddr,
			ramData_io      => ramData_io,
			ramBank_out     => ramBank_out,
			ramLDQM_out     => ramLDQM,
			ramUDQM_out     => ramUDQM
		);

	ramCmd <= ramRAS & ramCAS & ramWE;
	
	-- Drive the unit under test. Read stimulus from stimulus.txt and write results to results.txt
	--
	process
	begin
		mcClk <= '0';
		mcRst <= '1';
		ramData_io <= (others => 'Z');		

		ramClk <= '1';
		wait for 4 ns;
		mcClk <= '1';

		wait for 6 ns;
		ramClk <= '0';
		wait for 4 ns;
		mcRst <= '0';
		loop
			mcClk <= '0';
			wait for 6 ns;
			ramClk <= '1';
			wait for 4 ns;
			mcClk <= '1';
			-- Assert signals from line in stimulus file here
			wait for 6 ns;
			-- Sample outputs here
			ramClk <= '0';
			wait for 4 ns;
			-- Write to results file here
		end loop;
		wait;
	end process;

	-- Simulate the SDRAM returning data two clocks after a read command
	process
	begin
		loop
			ramData_io <= (others => 'Z');
			wait until ramRAS = '1' and ramCAS = '0' and ramWE = '1' and mcClk = '1';
			wait until mcClk = '0';
			wait until mcClk = '1';
			wait until mcClk = '0';
			wait until mcClk = '1';
			wait for 6 ns;
			ramData_io <= x"CAFE";
			wait until mcClk = '0';
			wait until mcClk = '1';
			wait for 3 ns;
		end loop;
	end process;
end architecture;
