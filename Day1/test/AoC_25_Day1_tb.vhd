----------------------------------------------------------------------------------
-- Company: 
-- Engineer: Pierre Borderie
-- 
-- Create Date: 02/12/2025 04:21:53 PM
-- Design Name: 
-- Module Name: AoC_25_Day1_tb - sim
-- Project Name: AoC_25_Day1
-- Target Devices: Kria KV260
-- Tool Versions: Vivado 2023.2, QuestaSim 2023.2 
-- (to use Vivado simulator change the -maxdeltaid switch to 100,000
-- or it will fail. Vivado will take ~ 5-10 mins to run sim due to
-- large no. of delta cycles)
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

library std;
use std.textio.all;

library xil_defaultlib;
use xil_defaultlib.AoC_25_Day1_pkg.all;

entity AoC_25_Day1_tb is
  Generic ( file_path : string := "/home/pie/Documents/FPGA_Projs/AoC_25/25_AoC_Day1/AoC_25_Day1/top_level_instructions.txt");
--  Port ( );
end AoC_25_Day1_tb;

architecture sim of AoC_25_Day1_tb is
  
  PROCEDURE print (arg : in string := "") is
  begin
    std.textio.write(std.textio.output, arg & LF);
  end procedure print;
  
  component AoC_25_Day1_Top is
    Generic(
      num_cmds      : integer;
      dial_max_num  : integer;
      moves_max_num : integer
    );
    Port ( 
      cmds : in cmds_array;
      result : out integer;
      
      part2_result : out integer
    );
  end component AoC_25_Day1_Top;
  
  signal tb_result : integer;
  signal tb_result_2 : integer;
  constant num_cmds : integer := 4493;
  constant moves_max_num : integer := 999;
  constant dial_max_num_const : integer := 99;
  signal tb_cmds : cmds_array ((num_cmds - 1) downto 0)((integer(ceil(log2(real(moves_max_num)))) + 1) downto 0);
  
begin
  
  U_DUT : AoC_25_Day1_Top
  generic map (
    num_cmds =>  num_cmds,
    dial_max_num =>  dial_max_num_const,
    moves_max_num =>  moves_max_num
  )
  port map (
    cmds   =>  tb_cmds,
    result =>  tb_result,
    
    part2_result => tb_result_2
  );
  
  -- Read the test vectors from file to give to DUT and calc expected
  stim : process
    file instructions_f : text;
    variable fstatus : file_open_status;
    variable tline : line;
    variable dir : character;
    variable instr_moves : integer;
    variable i : integer := 0;
    
    variable test_condition : boolean;
    variable all_tests_passed : boolean := true;
    
    -- For calc exp results
    variable dial_pos : integer := 50;
    variable exp_result_1, exp_result_2 : integer;
  begin
    file_open(fstatus, instructions_f, file_path, read_mode);
    print (" ");
    if fstatus /= open_ok then
      print ("*** ERROR Could not open file please check path! ***");
      print ("Terminating TB...");
      wait;
    else
      print ("File opened successfully.");
    end if;
    
    while not endfile(instructions_f) loop
      readline(instructions_f, tline);
      
      -- ignore empty lines or comments
      if tline.all'length = 0 or tline.all(1) = '#' then
       next;
      end if;
      
      read(tline, dir);
      read(tline, instr_moves);
      wait for 0 ns;
      
      -- Set the direction bit at MSB
      if dir = 'l' or dir = 'L' then
        tb_cmds(i)((tb_cmds(i)'length) - 1 downto (tb_cmds(i)'length) -1) <= "0";
      else
        tb_cmds(i)((tb_cmds(i)'length) - 1 downto (tb_cmds(i)'length) -1) <= "1";
      end if;
      
      tb_cmds(i)(tb_cmds(i)'length - 2 downto 0) <= to_unsigned(instr_moves, ((tb_cmds(i)'length) - 1));
      
      wait for 0 ns;
      i := i + 1;
      wait for 0 ns;
    end loop;
    
      dial_pos := 50;
      exp_result_1 := 0;
      exp_result_2 := 0;
    -- Calculate the expected results here
    for i in 0 to tb_cmds'length - 1 loop
      for j in 0 to to_integer(tb_cmds(i)(tb_cmds(i)'length - 2 downto 0)) - 1 loop -- loop num times equal to size of move
        if tb_cmds(i)(tb_cmds(i)'length - 1 downto tb_cmds(i)'length - 1) = "0" then --left turn
          if dial_pos = 0 then
            dial_pos := 99;
          elsif dial_pos = 1 then
            exp_result_2 := exp_result_2 + 1;
            dial_pos := dial_pos - 1;
          else
            dial_pos := dial_pos - 1;
          end if;
        else --right turn
          if dial_pos = 99 then
            dial_pos := 0;
            exp_result_2 := exp_result_2 + 1;
          else
            dial_pos := dial_pos + 1;
          end if;
        end if;
      end loop;
      if dial_pos = 0 then
        exp_result_1 := exp_result_1 + 1;
      end if;
      end loop;
    
    wait for 1 ns;
    
    -- Assertions
    test_condition := tb_result = exp_result_1;
    assert test_condition
    report "Part 1 incorrect! " & LF & 
           "Expected: " & to_string(exp_result_1) & LF &
           "Received: " & to_string(tb_result) & LF
    severity error;
    if not(test_condition) then
      all_tests_passed := false;
    end if;
    
    test_condition := tb_result_2 = exp_result_2;
    assert test_condition
    report "Part 2 incorrect! " & LF & 
           "Expected: " & to_string(exp_result_2) & LF &
           "Received: " & to_string(tb_result_2) & LF
    severity error;
    if not(test_condition) then
      all_tests_passed := false;
    end if;
    
    if all_tests_passed then
      print ("All tests passed!");
    else
      print ("One or more tests failed!");
    end if;
    
    wait;
  end process stim;
  
end sim;