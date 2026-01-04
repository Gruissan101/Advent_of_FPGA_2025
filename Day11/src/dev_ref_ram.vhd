----------------------------------------------------------------------------------
-- Company: 
-- Engineer: Pierre Borderie
-- 
-- Create Date: 12/18/2025 11:09:15 AM
-- Design Name: dev_ref_ram
-- Module Name: dev_ref_ram - rtl
-- Project Name: AoC_25_Day11
-- Target Devices: Kria KV260
-- Tool Versions: Vivado 2023.2
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- RAM to store what devices are connected to it, asynchronously outputs value and population count
----------------------------------------------------------------------------------


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity dev_ref_ram is
    generic (
      depth : integer
    );
    port ( 
      clk             : in std_logic;
      address         : in integer range 0 to depth -1;
      data_in         : in std_logic_vector(14 downto 0);
      data_in_valid   : in std_logic;
      data_out        : out std_logic_vector(14 downto 0);
      pop_count       : out integer range 0 to depth
    );
end dev_ref_ram;

architecture rtl of dev_ref_ram is
  type ram_def is array (0 to depth - 1) of std_logic_vector(14 downto 0);
  signal ram : ram_def := (others => (others => '0'));
begin
  -- Always read data
  data_out <= ram(address);
  -- RAM
  ram_proc : process(clk)
  begin
    if rising_edge(clk) then
      -- Write data
      if data_in_valid = '1' then
        ram(address) <= data_in;
      end if;
    end if;
  end process ram_proc;
  
  -- Async check how many devices are connected to this one
  count : process(all)
    variable i : integer range 0 to depth;
  begin
    -- if rising_edge(clk) then
      i := 0;
      for j in 0 to depth - 1 loop
        if ram(j) /= "000" & x"000" then
          i := i + 1;
        end if;
      end loop;
      pop_count <= i;
    -- end if;
  end process count;
  
end rtl;
