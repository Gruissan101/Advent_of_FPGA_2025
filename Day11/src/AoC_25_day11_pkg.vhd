----------------------------------------------------------------------------------
-- Company: 
-- Engineer: Pierre Borderie
-- 
-- Create Date: 18/12/2025 02:26:55 PM
-- Design Name: 
-- Module Name: AoC_25_Day11_pkg
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
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.math_real.all;

package AoC_25_Day11_pkg is
  
  function char_num (letter : character) return integer;
  function ram_loc (dev : string(1 to 3)) return std_logic_vector;
  
end package AoC_25_Day11_pkg;

package body AoC_25_Day11_pkg is
  function char_num (letter : character) return integer is
    variable result : integer range 1 to 26 := 1;
  begin
    case letter is  -- !!! do NOT use uppercase !!!
      when 'a' =>    result := 1;
      when 'b' =>    result := 2;
      when 'c' =>    result := 3;
      when 'd' =>    result := 4;
      when 'e' =>    result := 5;
      when 'f' =>    result := 6;
      when 'g' =>    result := 7;
      when 'h' =>    result := 8;
      when 'i' =>    result := 9;
      when 'j' =>    result := 10;
      when 'k' =>    result := 11;
      when 'l' =>    result := 12;
      when 'm' =>    result := 13;
      when 'n' =>    result := 14;
      when 'o' =>    result := 15;
      when 'p' =>    result := 16;
      when 'q' =>    result := 17;
      when 'r' =>    result := 18;
      when 's' =>    result := 19;
      when 't' =>    result := 20;
      when 'u' =>    result := 21;
      when 'v' =>    result := 22;
      when 'w' =>    result := 23;
      when 'x' =>    result := 24;
      when 'y' =>    result := 25;
      when others => result := 26;
    end case;
    return result;
  end function char_num;
  
  function ram_loc (dev : string(1 to 3)) return std_logic_vector is
    variable int_conv : integer range 1 to 17576;
    variable result : std_logic_vector(14 downto 0);
  begin
    int_conv := ((char_num(dev(1)) - 1) * (26 ** 2)) + ((char_num(dev(2)) - 1) * 26) + (char_num(dev(3)) - 1) + 1;
    -- Number=(L1−1)⋅26^2+(L2−1)⋅26^1+(L3−1)⋅26^0+1
    result := std_logic_vector(to_unsigned(int_conv, 15));
    return result;
  end function ram_loc;
  
end package body AoC_25_Day11_pkg;


