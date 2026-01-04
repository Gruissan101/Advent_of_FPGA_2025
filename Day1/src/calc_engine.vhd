----------------------------------------------------------------------------------
-- Engineer: Pierre Borderie
-- 
-- Create Date: 01/12/2025 12:01:00 PM
-- Design Name: calc_engine
-- Module Name: calc_engine - rtl
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

entity calc_engine is
  Generic (
    dial_max_num : integer := 99;
    moves_max_num : integer := 999
  );
  Port ( 
     start_val : IN  unsigned(integer(ceil(log2(real(dial_max_num)))) downto 0);
     move      : IN  unsigned((integer(ceil(log2(real(moves_max_num))))+1) downto 0); -- MSB indicates direction, 0=L 1=R
     result    : OUT unsigned(integer(ceil(log2(real(dial_max_num)))) downto 0);
     
     --For Part 2
     num_zeros : OUT integer
  );
end calc_engine;

architecture rtl of calc_engine is
  subtype val_range is unsigned(integer(ceil(log2(real(dial_max_num)))) downto 0);
  subtype move_range is unsigned((integer(ceil(log2(real(moves_max_num))))+1) downto 0);
  subtype real_move_range is unsigned ((move_range'length -2) downto 0);
  signal real_move : real_move_range;
  
  signal r_ln : unsigned(0 downto 0);
  constant max_ops : integer := integer(ceil(real(moves_max_num) / real((dial_max_num + 1))));
  constant max_ops_m1 : integer := max_ops -1;
  type array_moves is array (max_ops_m1 downto 0) of real_move_range;
  signal moves_actual : array_moves;

  alias translated_move is moves_actual(0);
  
  -- Part 2
  signal zero_count1, zero_count2 : integer;
  
  
begin
  
  r_ln <= move(move'length - 1 downto move'length -1);
  real_move <= move((move'length - 2) downto 0);
  
  num_zeros <= zero_count1 + zero_count2;

  main : process (all)
    variable temp : real_move_range;
    variable temp1 : real_move_range;
    variable count1 : integer := 0;
    
    function is_zero (data : val_range) return boolean is
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
    -- Left Turn
    if r_ln = "0" then
      if translated_move > start_val then
        temp := translated_move - start_val;
        result <= to_unsigned((dial_max_num+1 - to_integer(temp)), val_range'length);
        if (NOT(is_zero(result))) AND (NOT(is_zero(start_val))) then -- don't want to count a 0 twice
          count1 := 1;
        end if;
      else
        result <= to_unsigned((to_integer(start_val) - to_integer(translated_move)), val_range'length);
      end if;
    -- Right Turn
    else
      if (translated_move + start_val) > dial_max_num then
        temp := to_unsigned((dial_max_num - to_integer(start_val)), temp'length);
        result <= to_unsigned((to_integer(translated_move) - to_integer(temp) - 1), val_range'length);
        if (NOT(is_zero(result))) AND (NOT(is_zero(start_val))) then
          count1 := 1;
        end if;
      else
        temp1 := (start_val + translated_move);
        result <= temp1(integer(ceil(log2(real(dial_max_num)))) downto 0);
      end if;
    end if;
    zero_count1 <= count1;
  end process main;
  
  -- Process to take away max no. of full rotations, 
  -- each element in the array is populated with 
  -- the value of one full rotation less than the previous element
  -- 
  -- the size of the array is the max number of full rotations 
  -- away from a rotation that is < the largest number on the dial
  -- so moves_actual(0) represents where we actually need to end up
  calc_real_turns : process (all)
    variable count2 : integer := 0;
  begin
    for j in moves_actual'range loop 
      if j = moves_actual'left then --if first time in loop then check if inital move is greater than dial max num
        if real_move > to_unsigned((dial_max_num +1), real_move_range'length) then
          moves_actual(j) <= real_move - to_unsigned((dial_max_num + 1), real_move_range'length);
          count2 := 1;
        else
          moves_actual(j) <= real_move;
        end if;
      else
        if moves_actual(j+1) > to_unsigned((dial_max_num +1), real_move_range'length) then
          moves_actual(j) <= moves_actual(j+1) - to_unsigned((dial_max_num + 1), real_move_range'length);
          count2 := max_ops_m1 - j + 1;
        else
          moves_actual(j) <= moves_actual(j+1);
        end if;
      end if;
    end loop;

    zero_count2 <= count2;
  end process calc_real_turns;
  
end rtl;
