# Advent_of_FPGA_2025
My attempt at Jane Street's Advent of FPGA challenge.

Tool Versions:\
  Vivado 2023.2\
  QuestaSim 2023.3

## Running the designs
For Days 1 & 11, I created Vivado projects and added the VHDL files in the usual manner.\
Ensure they are set to VHDL 2008.\
I used QuestaSim to run the testbenches, use run -all and they will stop automatically.\
Day 1 can be run in the Vivado simulator with the -maxdeltaid switch set to 100,000.\
Day 11 takes around 25 mins to launch in the Vivado simulator so this is discouraged.\
To use QuestaSim from Vivado, the vendor libraries must be precompiled (despite not using any IP), then point Vivado at the location of the compiled libraries.

Ensure the generics in the VHDL TBs are changed to the absolute path of the text file containing the test input obtained from the AdventOfCode site.\
(In Questasim you can use the -G switch to do this without modifying the file)\
For Day 3 in Hardcaml, edit "test_path" in test_total_joltage.ml to the correct path.

## Design Info & Notes
### Day 1 Parts 1 & 2 - VHDL:
In the spirit of "upping the ante", I have completed this entirely in combinational logic. Obviosuly not a very practical solution but I thought it would be a fun way to approach it.\
All modules have generics to make them paramaterisable.\
It consits of multiple instantiations of a "calc_engine" module, which calculates the result of each move instruction by removing the max number of full turns, then calculating the final location.\
The top level module instantiates 1 instance of the calc_engine for each instruction.\
For part 2, I then added logic in the calc_engine to say how many times it crosses 0.\
The TB is self-checking.

### Day 11 Part 1 - VHDL:
For this problem, the logic explores each device and calculates how many of the connected devices have a path to the "out" device. The result is stored so that it doesn't have to explore each possible path entirely.\
The path exploration is done in a sort of stack with a count so that the FSM can keep track of where it is.\
To store the info about each device, a RAM is instantiated for each possible device, "aaa" : "zzz". Unfortunately, this means that there are large numbers of unused RAM. Each RAM asynchronously outputs a population count (to indicate how many devices that one is connected to).\
The devices are encoded in a +1 offset base-26. (So that 0 is null)\
I didn't have enough time to make a self-checking TB, so it outputs the result which could then be verified in software.

### Day 3 Part 1 - Hardcaml
Having used VHDL exclusively (with some exposure to Verilog), this was quite a daunting challenge. However the ample resources provided (thank you!) allowed me to complete part 1 in Hardcaml.\
My solution consists of a simple FSM that first finds the highest valid number in the bank, after which the second highest one is located.\
To prevent using any DSP, the tens digit is added up in successive clock cycles to multiply it by 10 with the final digit then added.\
A running total is kept and the valid is pulsed after each bank has been processed.\
The testbench takes the test file obtained from the AoC site and sends it to the DUT until all banks have been sent.\
Afterwards an expect test is used to verify functionality with both the integer result and the waveforms.\
The generate.exe is set to use VHDL since I was curious as to what it would output. This meant I had to use the rtlmangle preprocessor to prevent illegal port names.\
(My working repository I used for Day 3 is located here: https://github.com/Gruissan101/AoC_25_Day3_hardcaml)\
