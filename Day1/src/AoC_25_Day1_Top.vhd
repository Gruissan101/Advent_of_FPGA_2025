----------------------------------------------------------------------------------
-- Company: 
-- Engineer: Pierre Borderie
-- 
-- Create Date: 02/12/2025 01:52:49 PM
-- Design Name: AoC_25_Day1_Top
-- Module Name: AoC_25_Day1_Top - rtl
-- Project Name: AoC_25_Day1
-- Target Devices: 
-- Tool Versions: Vivado 2023.2
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.math_real.all;

library xil_defaultlib;
use xil_defaultlib.AoC_25_Day1_pkg.all;

entity AoC_25_Day1_Top is
  Generic(
    num_cmds      : integer := 4493;
    dial_max_num  : integer := 99;
    moves_max_num : integer :=  999
  );
 Port ( 
    cmds : in cmds_array ((num_cmds - 1) downto 0)((integer(ceil(log2(real(moves_max_num))))+1) downto 0);
    result : out integer := 0;
    part2_result : out integer := 0
 );
end AoC_25_Day1_Top;

architecture rtl of AoC_25_Day1_Top is
  
  component calc_engine is
  Generic (
    dial_max_num : integer := dial_max_num;
    moves_max_num : integer := moves_max_num
  );
  Port ( 
     start_val : IN  unsigned(integer(ceil(log2(real(dial_max_num)))) downto 0);
     move      : IN  unsigned((integer(ceil(log2(real(moves_max_num))))+1) downto 0); -- MSB indicates direction, 0=L 1=R
     result    : OUT unsigned(integer(ceil(log2(real(dial_max_num)))) downto 0);
     
     num_zeros : OUT integer
  );
  end component calc_engine;
  
  subtype val_type is unsigned(integer(ceil(log2(real(dial_max_num)))) downto 0);
  subtype move_type is unsigned((integer(ceil(log2(real(moves_max_num))))+1) downto 0);
  type results_type is array ((num_cmds - 1) downto 0) of val_type;
  type ex_zeros_type is array ((num_cmds - 1) downto 0) of integer;
  
  signal results : results_type;
  
  -- Part 2
  signal extra_zeros : ex_zeros_type;
  
begin
  
  U_1 : calc_engine
  generic map (
    dial_max_num => dial_max_num,
    moves_max_num => moves_max_num
  )
  port map (
    start_val => (to_unsigned(50, val_type'length)),
    move => cmds(0),
    result => results(0),
    num_zeros => extra_zeros(0)
  );
  
  gen_engines : for j in 1 to (num_cmds - 1) generate
    U_x : calc_engine
    generic map (
      dial_max_num => dial_max_num,
      moves_max_num => moves_max_num
    )
    port map (
      start_val => results(j-1),
      move => cmds(j),
      result => results(j),
      num_zeros => extra_zeros(j)
    );
  end generate gen_engines;
  
  counter : process(all)
    variable count : integer := 0;
    variable count2 : integer := 0;
    
    function is_zero (data : val_type) return boolean is
      variable zer_ho_ho_ho : boolean := TRUE;
    begin
      for j in 0 to data'length - 1 loop
        if data(j) = '1' then
          zer_ho_ho_ho := FALSE;
        end if;
      end loop;
        return zer_ho_ho_ho;
    end function is_zero;
    
  begin
    count := 0;
    count2 := 0;
    for k in 0 to results'length - 1 loop
      if is_zero(results(k)) then
        count := count + 1;
      end if;
    end loop;
    
    result <= count;
    
    for m in 0 to extra_zeros'length - 1 loop
        count2 := count2 + extra_zeros(m);
    end loop;
    
    part2_result <= count + count2;
    
    end process counter;
  
  
end rtl;
