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

entity memctrl is
	generic (
		-- This should be overridden by the inferring hardware or testbench!
		INIT_COUNT  : unsigned(12 downto 0) := "1" & x"FFF"
	);
	port(
		-- Client interface
		mcClk_in    : in std_logic;
		mcRDV_out   : out std_logic;  -- Read Data Valid flag

		-- SDRAM interface
		ramRAS_out  : out std_logic;
		ramCAS_out  : out std_logic;
		ramWE_out   : out std_logic;
		ramAddr_out : out std_logic_vector(11 downto 0);
		ramData_io  : inout std_logic_vector(15 downto 0);
		ramBank_out : out std_logic_vector(1 downto 0);
		ramLDQM_out : out std_logic;
		ramUDQM_out : out std_logic
	);
end entity;

architecture behavioural of memctrl is
	type StateType is (
		-- Initialisation states
		S_INIT_WAIT,
		S_INIT_PRE,
		S_INIT_REF1,
		S_INIT_REF1_WAIT,
		S_INIT_REF2,
		S_INIT_REF2_WAIT,
		S_INIT_LMR,
		S_INIT_LMR_WAIT,

		-- Activate a row, do some writes
		S_WRITE_ACT,
		S_WRITE1,
		S_WRITE2,
		S_WRITE3,
		S_WRITE4,

		-- Do a read
		S_READ1,
		S_READ2,
		S_READ3,

		-- Loop forever
		S_IDLE
	);
	signal cmd         : std_logic_vector(2 downto 0);
	constant CMD_NOP   : std_logic_vector(2 downto 0) := "111";
	constant CMD_ACT   : std_logic_vector(2 downto 0) := "011";
	constant CMD_READ  : std_logic_vector(2 downto 0) := "101";
	constant CMD_WRITE : std_logic_vector(2 downto 0) := "100";
	constant CMD_PRE   : std_logic_vector(2 downto 0) := "010";
	constant CMD_REF   : std_logic_vector(2 downto 0) := "001";
	constant CMD_LMR   : std_logic_vector(2 downto 0) := "000";

	--                                                             Reserved
	--                                                            /      Write Burst Mode (0=Burst, 1=Single)
	--                                                           /      /     Reserved
	--                                                          /      /     /      Latency Mode (CL=2)
	--                                                         /      /     /      /       Burst Type (0=Sequential, 1=Interleaved)
	--                                                        /      /     /      /       /     Burst Length (1,2,4,8,X,X,X,Full)
	--                                                       /      /     /      /       /     /
	--                                                      /      /     /      /       /     /
	constant LMR_VALUE : std_logic_vector(11 downto 0) := "00" & "1" & "00" & "010" & "0" & "000";
	signal state       : StateType := S_INIT_WAIT;
	signal state_next  : StateType;
	signal count       : unsigned(12 downto 0) := INIT_COUNT;
	signal count_next  : unsigned(12 downto 0);

begin
	
	-- Infer registers for state & count
	process(mcClk_in)
	begin
		if ( rising_edge(mcClk_in) ) then
			state <= state_next;
			count <= count_next;
		end if;
	end process;

	-- Next state logic
	process(state, count)
	begin
		state_next  <= state;
		count_next  <= count - 1;
		cmd         <= CMD_NOP;
		ramBank_out <= (others => 'Z');
		ramAddr_out <= (others => 'Z');
		ramData_io  <= (others => 'Z');
		mcRDV_out   <= '0';
		case state is
			----------------------------------------------------------------------------------------
			-- The init sequence: 4800 NOPs, PRE all, 2xREF, & LMR
			----------------------------------------------------------------------------------------

			-- Issue NOPs until the count hits the threshold
			when S_INIT_WAIT =>
				if ( count = 0 ) then
					state_next <= S_INIT_PRE;
				end if;

			-- Issue a PRECHARGE command to all banks
			when S_INIT_PRE =>
				cmd <= CMD_PRE;
				ramAddr_out(10) <= '1';  -- A10=1: Precharge all banks
				state_next <= S_INIT_REF1;

			-- Issue a refresh command. Must wait 63ns (four clocks, conservatively)
			when S_INIT_REF1 =>
				cmd <= CMD_REF;
				count_next <= "0" & x"002";
				state_next <= S_INIT_REF1_WAIT;
			when S_INIT_REF1_WAIT =>  -- Three NOPs
				if ( count = 0 ) then
					state_next <= S_INIT_REF2;
				end if;

			-- Issue a refresh command. Must wait 63ns (four clocks, conservatively)
			when S_INIT_REF2 =>
				cmd <= CMD_REF;
				count_next <= "0" & x"002";
				state_next <= S_INIT_REF2_WAIT;
			when S_INIT_REF2_WAIT =>  -- Three NOPs
				if ( count = 0 ) then
					state_next <= S_INIT_LMR;
				end if;

			-- Issue a Load Mode Register command. Must wait tMRD (two clocks).
			when S_INIT_LMR =>
				cmd <= CMD_LMR;
				ramAddr_out <= LMR_VALUE;
				state_next <= S_INIT_LMR_WAIT;
			when S_INIT_LMR_WAIT =>
				state_next <= S_WRITE_ACT;

			----------------------------------------------------------------------------------------
			-- Now do some hard-coded writes
			----------------------------------------------------------------------------------------

			-- Do some writes
			when S_WRITE_ACT =>
				cmd <= CMD_ACT;
				ramBank_out <= "00";
				ramAddr_out <= x"000";
				state_next <= S_WRITE1;

			when S_WRITE1 =>
				cmd <= CMD_WRITE;
				ramData_io <= x"CAFE";
				ramAddr_out <= x"010";
				state_next <= S_WRITE2;

			when S_WRITE2 =>
				cmd <= CMD_WRITE;
				ramData_io <= x"BABE";
				ramAddr_out <= x"011";
				state_next <= S_WRITE3;

			when S_WRITE3 =>
				cmd <= CMD_WRITE;
				ramData_io <= x"DEAD";
				ramAddr_out <= x"012";
				state_next <= S_WRITE4;

			when S_WRITE4 =>
				cmd <= CMD_WRITE;
				ramData_io <= x"F00D";
				ramAddr_out <= x"013";
				state_next <= S_READ1;

			----------------------------------------------------------------------------------------
			-- Now do a hard-coded read
			----------------------------------------------------------------------------------------

			when S_READ1 =>
				cmd <= CMD_READ;
				ramAddr_out <= x"010";
				state_next <= S_READ2;

			when S_READ2 =>
				state_next <= S_READ3;

			when S_READ3 =>
				mcRDV_out <= '1';
				state_next <= S_IDLE;

			when others =>

		end case;
	end process;

	-- Breakout command signals
	ramRAS_out <= cmd(2);
	ramCAS_out <= cmd(1);
	ramWE_out  <= cmd(0);

	-- Don't mask anything
	ramLDQM_out <= '0';
	ramUDQM_out <= '0';

end architecture;
