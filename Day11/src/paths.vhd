----------------------------------------------------------------------------------
-- Company: 
-- Engineer: Pierre Borderie
-- 
-- Create Date: 18/12/2025 10:45:03 AM
-- Design Name: paths
-- Module Name: paths - rtl
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
-- create a RAM for every possible device (AAA -> ZZZ) and populate it with its target machines
-- FSM then sorts through it to find total no. of paths.
----------------------------------------------------------------------------------


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use IEEE.math_real.all;

library xil_defaultlib;
use xil_defaultlib.AoC_25_Day11_pkg.all;

entity paths is
    generic ( 
      num_devices : integer := 17576;  -- assume worst case scenario that devices could be anywhere from "aaa" to "zzz" (26**3)
      max_ops     : integer := 22; --the max number of devices a single one can be connected to
      max_path_l  : integer := num_devices --Assume the maximum path we explore is the num of devices. Although it could be larger. This is quite a major limitation.
    );
    port ( 
      clk        : in  std_logic;
      device     : in  std_logic_vector(14 downto 0); --instead of using ASCII, to make things simpler (sort of..) we'll work in base 26 where 0 = null, 1 = aaa, ;26 = aaz 27 = aba etc
      dev_addr   : in  std_logic_vector (integer(((ceil(log2(real(max_ops)))))) - 1 downto 0);
      data       : in  std_logic_vector(14 downto 0); -- devices that are connected to device
      data_valid : in  std_logic;
      data_done  : in  std_logic;
      result     : out integer := 0;
      result_vld : out std_logic := '0'
    );
end paths;

architecture rtl of paths is
  
  component dev_ref_ram -- a RAM for each device to store what devices its connected to and a count of how many exist
    generic (depth : integer);
    port ( 
      clk             : in std_logic;
      address         : in integer range 0 to depth -1;
      data_in         : in std_logic_vector(14 downto 0);
      data_in_valid   : in std_logic;
      data_out        : out std_logic_vector(14 downto 0);
      pop_count       : out integer range 0 to depth
    );
  end component dev_ref_ram;
    
    -- RAM Mapping
    type adr_all is array (1 to num_devices) of integer range 0 to max_ops -1;
    signal ref_address : adr_all := (others => 0);
    type data_all is array (1 to num_devices) of std_logic_vector(14 downto 0);
    signal ref_data_in : data_all := (others => (others => '0'));
    signal ref_dv : std_logic_vector (1 to num_devices) := (others => '0');
    signal ref_data_out : data_all := (others => (others => '0'));
    type pop_all is array (1 to num_devices) of integer range 0 to max_ops;
    signal ref_pop_count : pop_all := (others => 0);
    
    -- FSM
    type states is (wr_data, check, add_curr_path, addr_sum_devs, fin);
    signal state : states := wr_data;
    
    -- Device Path Calc
    type path_type is array (0 to max_path_l) of std_logic_vector(14 downto 0);
    signal current_path : path_type := (others => (others => '0'));
    signal path_counter : integer range 0 to max_path_l := 0;
    signal pop_cache : pop_all := (others => 0);
    type device_val_type is array (1 to num_devices) of integer;
    signal device_val : device_val_type := (others => 0); --to store the 'value' of each device
    signal device_val_vld : std_logic_vector (1 to num_devices) := (others => '0'); -- is the value of the device valid
    signal sum_count : integer range max_ops downto 0;

begin
  
  -- Create a RAM for every possible device (aaa => zzz)
  ram_gen : for j in 1 to num_devices generate
    U_ram : dev_ref_ram
      generic map (
        depth =>  max_ops
      )
      port map (
        clk           => clk,
        address       => ref_address(j),
        data_in       => ref_data_in(j),
        data_in_valid => ref_dv(j),
        data_out      => ref_data_out(j),
        pop_count     => ref_pop_count(j)
      );
  end generate;

  fsm : process (clk)
  begin
    if rising_edge(clk) then
      -- FSM
      case state is
        when wr_data => 
          device_val(to_integer(unsigned(ram_loc("out")))) <= 1;
          device_val_vld(to_integer(unsigned(ram_loc("out")))) <= '1';
          if data_valid = '1' then
            ref_address(to_integer(unsigned(device))) <= to_integer(unsigned(dev_addr));
            ref_data_in(to_integer(unsigned(device))) <= data;
            ref_dv <= (others => '0');
            ref_dv(to_integer(unsigned(device))) <= '1';
          end if;
          
          -- Next State
          if data_done = '1' then
            pop_cache <= ref_pop_count;
            current_path(path_counter) <= ram_loc("you");
            ref_dv <= (others => '0');
            state <= check;
          end if;
        
        when check => 
          if pop_cache(to_integer(unsigned(current_path(path_counter)))) > 0 then
            -- get child device
            ref_address(to_integer(unsigned(current_path(path_counter)))) <= pop_cache(to_integer(unsigned(current_path(path_counter)))) - 1;
            path_counter <= path_counter + 1;
            state <= add_curr_path;
          else
            -- If the device we have reached has children then go sum them otherwise pop the stack
            if ref_pop_count(to_integer(unsigned(current_path(path_counter)))) /= 0 then
              state <= addr_sum_devs;
              sum_count <= ref_pop_count(to_integer(unsigned(current_path(path_counter)))) - 1; -- use this so we know how many devices we have to sum
              ref_address(to_integer(unsigned(current_path(path_counter)))) <= ref_pop_count(to_integer(unsigned(current_path(path_counter)))) - 1;
            else
              current_path(path_counter) <= (others => '0');
              device_val_vld(to_integer(unsigned(current_path(path_counter)))) <= '1';
              path_counter <= path_counter - 1;
              pop_cache(to_integer(unsigned(current_path(path_counter-1)))) <= pop_cache(to_integer(unsigned(current_path(path_counter-1)))) - 1;
            end if;
          end if;
        
        when add_curr_path => 
          current_path(path_counter) <= ref_data_out(to_integer(unsigned(current_path(path_counter-1))));
          
          -- Next State
          state <= check;
        
        when addr_sum_devs => 
          -- if we have already counted this then skip otherwise sum
          if ((sum_count > 0) and (device_val_vld(to_integer(unsigned(current_path(path_counter)))) = '0')) then
            device_val(to_integer(unsigned(current_path(path_counter)))) <= device_val(to_integer(unsigned(current_path(path_counter)))) + device_val(to_integer(unsigned((ref_data_out(to_integer(unsigned((current_path(path_counter)))))))));
            ref_address(to_integer(unsigned(current_path(path_counter)))) <= sum_count - 1;
            sum_count <= sum_count - 1;
          else
            if ((sum_count = 0) and (device_val_vld(to_integer(unsigned(current_path(path_counter)))) = '0')) then
              device_val(to_integer(unsigned(current_path(path_counter)))) <= device_val(to_integer(unsigned(current_path(path_counter)))) + device_val(to_integer(unsigned((ref_data_out(to_integer(unsigned((current_path(path_counter)))))))));
            end if;
            device_val_vld(to_integer(unsigned(current_path(path_counter)))) <= '1';
            current_path(path_counter) <= (others => '0');
            if path_counter > 0 then
              state <= check;
              path_counter <= path_counter - 1;
              if pop_cache(to_integer(unsigned(current_path(path_counter-1)))) > 0 then
                pop_cache(to_integer(unsigned(current_path(path_counter-1)))) <= pop_cache(to_integer(unsigned(current_path(path_counter-1)))) - 1;
              end if;
            else
              if pop_cache(to_integer(unsigned(current_path(0)))) = 0 then
                state <= fin; -- *** DONE!! *** 
              else
                pop_cache(to_integer(unsigned(current_path(path_counter-1)))) <= pop_cache(to_integer(unsigned(current_path(path_counter-1)))) - 1;
                state <= check;
              end if;
            end if;
          end if;
          
        when others => -- FIN
          result_vld <= '1';
          result <= device_val(to_integer(unsigned(ram_loc("you"))));
      end case;
    end if;
  end process fsm;


end rtl;
