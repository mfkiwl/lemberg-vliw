----------------------------------------------------------------------------
-- This file is part of Lemberg.
-- Copyright (C) 2011 Wolfgang Puffitsch
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
----------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.core_pack.all;
use work.mem_pack.all;
use work.io_pack.all;
use work.pin_pack.all;

entity sc_io is
	
	port (
		clk, reset : in	   std_logic;
		cpu_out	   : in	   sc_out_type;
		cpu_in	   : out   sc_in_type;
		io_out     : out   io_pin_out_type;
		io_in      : in    io_pin_in_type);
		
end sc_io;

architecture rtl of sc_io is

	constant CLOCK_FREQ : integer := 70000000;

	constant BOOTROM_ADDR_WIDTH : integer := 8;	
	constant BOOTROM_SELECT : std_logic_vector(IO_ADDR_WIDTH-BOOTROM_ADDR_WIDTH-1 downto 0) := "0";
	signal bootrom_out : sc_out_type;
	signal bootrom_in : sc_in_type;
	
	constant UART_ADDR_WIDTH : integer := 1;
	constant UART_SELECT : std_logic_vector(IO_ADDR_WIDTH-UART_ADDR_WIDTH-1 downto 0) := "11111111";
	signal uart_out : sc_out_type;
	signal uart_in : sc_in_type;

	type mux_type is (BOOTROM_MUX, UART_MUX);
	signal cntmux_reg, cntmux_next : mux_type;
	signal datamux_reg, datamux_next : mux_type;
	
begin  -- rtl

	sc_uart: entity work.sc_uart
	generic map (
			addr_bits => UART_ADDR_WIDTH,
			clk_freq  => CLOCK_FREQ,
			baud_rate => 115200,
			txf_depth => 32,
			txf_thres => 16,
			rxf_depth => 32,
			rxf_thres => 16)
		port map (
			clk		=> clk,
			reset	=> reset,
			address => uart_out.address(UART_ADDR_WIDTH-1 downto 0),
			wr_data => uart_out.wr_data,
			rd		=> uart_out.rd,
			wr		=> uart_out.wr,
			rd_data => uart_in.rd_data,
			rdy_cnt => uart_in.rdy_cnt,
			txd		=> io_out.txd,
			rxd		=> io_in.rxd,
			ncts	=> '0',
			nrts	=> open);

	bootrom: entity work.bootrom
		generic map (
			addr_width => BOOTROM_ADDR_WIDTH)
		port map (
			clk		=> clk,
			address => bootrom_out.address(BOOTROM_ADDR_WIDTH-1 downto 0),
			rd		=> bootrom_out.rd,
			rd_data => bootrom_in.rd_data,
			rdy_cnt => bootrom_in.rdy_cnt);
	
	sync: process (clk, reset)
	begin  -- process sync
		if reset = '0' then  			-- asynchronous reset (active low)
			cntmux_reg <= BOOTROM_MUX;
			datamux_reg <= BOOTROM_MUX;
		elsif clk'event and clk = '1' then  -- rising clock edge
			cntmux_reg <= cntmux_next;
			datamux_reg <= datamux_next;
		end if;
	end process sync;

	async: process (cpu_out, bootrom_in, uart_in, cntmux_reg, datamux_reg)
	begin  -- process async

		uart_out <= cpu_out;
		uart_out.rd <= '0';
		uart_out.wr <= '0';

		bootrom_out <= cpu_out;
		bootrom_out.rd <= '0';
		bootrom_out.wr <= '0';

		cntmux_next <= cntmux_reg;
		datamux_next <= datamux_reg;
		
		if cpu_out.rd = '1' or cpu_out.wr = '1' then
			if cpu_out.address(IO_ADDR_WIDTH-1 downto BOOTROM_ADDR_WIDTH) = BOOTROM_SELECT then
				bootrom_out.rd <= cpu_out.rd;
				bootrom_out.wr <= cpu_out.wr;
				cntmux_next <= BOOTROM_MUX;
			end if;
			if cpu_out.address(IO_ADDR_WIDTH-1 downto UART_ADDR_WIDTH) = UART_SELECT then
				uart_out.rd <= cpu_out.rd;
				uart_out.wr <= cpu_out.wr;
				cntmux_next <= UART_MUX;
			end if;
		end if;

		case datamux_reg is
			when BOOTROM_MUX =>
				cpu_in.rd_data <= bootrom_in.rd_data;
			when UART_MUX =>
				cpu_in.rd_data <= uart_in.rd_data;
			when others => null;
		end case;

		-- simplify return of rdy_cnt; precondition: all entities assert rdy_cnt only when necessary
		cpu_in.rdy_cnt <= bootrom_in.rdy_cnt or uart_in.rdy_cnt;
		
		case cntmux_reg is
			when BOOTROM_MUX =>				
				if bootrom_in.rdy_cnt(1) = '0' then
					datamux_next <= cntmux_reg;
				end if;
				if bootrom_in.rdy_cnt = 0 then
					cpu_in.rd_data <= bootrom_in.rd_data;
				end if;
			when UART_MUX =>
				if uart_in.rdy_cnt(1) = '0' then
					datamux_next <= cntmux_reg;
				end if;
				if uart_in.rdy_cnt = 0 then
					cpu_in.rd_data <= uart_in.rd_data;
				end if;
			when others => null;
		end case;

	end process async;

end rtl;