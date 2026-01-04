----------------------------------------------------------------------------------
-- Company: 
-- Engineer: Pierre Borderie
-- 
-- Create Date: 18/12/2025 02:52:02 PM
-- Design Name: paths_tb
-- Module Name: paths_tb - sim
-- Project Name: AoC_25_Day11
-- Target Devices: Kria KV260
-- Tool Versions: Vivado 2023.2, QuestaSim 2023.2
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- writing a self checking TB for this in VHDL would be too time consuming
-- so I have just printed the result of the sim, which could then
-- be verified in software.
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.math_real.all;

library std;
use std.textio.all;

library xil_defaultlib;
use xil_defaultlib.AoC_25_Day11_pkg.all;

entity paths_tb is
  generic (
    file_path : string := "/home/pie/Documents/FPGA_Projs/AoC_25/25_AoC_Day11/AoC_25_day11/test_data.txt"
  );
--  Port ( );
end paths_tb;

architecture sim of paths_tb is
  component paths
    generic ( 
      num_devices : integer;
      max_ops     : integer;
      max_path_l  : integer
    );
    port ( 
      clk        : in std_logic;
      device     : in std_logic_vector(14 downto 0);
      dev_addr   : in std_logic_vector (integer(((ceil(log2(real(max_ops)))))) - 1 downto 0);
      data       : in std_logic_vector(14 downto 0);
      data_valid : in std_logic;
      data_done  : in  std_logic;
      result     : out integer;
      result_vld : out std_logic
    );
    end component paths;
  
  procedure print (arg : in string := "") is
  begin
    std.textio.write(std.textio.output, arg & LF);
  end procedure print;
  
  constant clk_period : time := 10 * 1 ns;
  signal run_tb : boolean := true;
  
  constant max_ops : integer := 22;
  constant num_devices : integer := 17576;
  
  signal tb_clk        : std_logic := '0';
  signal tb_device     : std_logic_vector(14 downto 0);
  signal tb_dev_addr   : std_logic_vector (integer(((ceil(log2(real(max_ops)))))) - 1 downto 0);
  signal tb_data       : std_logic_vector(14 downto 0);
  signal tb_dv         : std_logic;
  signal tb_datad      : std_logic;
  signal tb_result     : integer;
  signal tb_result_vld : std_logic;
  
  signal exp_result : integer := 0;
begin
  
  U_DUT : paths
  generic map (
    num_devices => num_devices,
    max_ops     => max_ops,
    max_path_l  => num_devices
  )
  port map (
    clk        => tb_clk,
    device     => tb_device,
    dev_addr   => tb_dev_addr,
    data       => tb_data,
    data_valid => tb_dv,
    data_done  => tb_datad,
    result     => tb_result,
    result_vld => tb_result_vld
  );

  tb_clk <= not(tb_clk) after clk_period/2 when run_tb else '0';
  
  main_stim : process
    file f : text;
    variable fsts : file_open_status;
    variable l : line;
    variable device : string(1 to 3);
    variable target : string (1 to 3);
    variable bin : character;
  begin
    
    file_open(fsts, f, file_path, read_mode);
    if fsts /= open_ok then
      print ("*** ERROR Could not open file please check path! ***");
      print ("Terminating TB...");
      run_tb <= false;
      wait;
    else
      print ("File opened successfully.");
    end if;
    
    tb_device <= (others => '0');
    tb_dev_addr <= (others => '0');
    tb_data <= (others => '0');
    tb_dv <= '0';
    tb_datad <= '0';
    
    wait until falling_edge(tb_clk);
    
    while not endfile(f) loop
      readline(f, l);
      read(l, device); 
      read(l, bin); -- :
      tb_device <= ram_loc(device);
      tb_dev_addr <= (others => '0');
      while l'length > 0 loop
        read(l, bin);
        read(l, target);
        tb_data <= ram_loc(target);
        tb_dv <= '1';
        wait for clk_period;
        tb_dev_addr <= std_logic_vector(to_unsigned((to_integer(unsigned(tb_dev_addr)) + 1), tb_dev_addr'length));
      end loop;
    end loop;
    
    tb_dv <= '0';
    wait for clk_period;
    tb_datad <= '1';
    
    wait until tb_result_vld = '1';
    wait for clk_period;
    print (LF & "Result is: " & to_string(tb_result));
    
    run_tb <= not(run_tb);
    wait;
  end process main_stim;

end sim;
