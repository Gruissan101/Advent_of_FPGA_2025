open! Core
open! Hardcaml
open! Hardcaml_waveterm
open! Hardcaml_test_harness
module Total_joltage = Aoc_25_day3.Total_joltage
module Harness = Cyclesim_harness.Make (Total_joltage.I) (Total_joltage.O)

(*let waves_config =
  Waves_config.to_directory "/your/dir/here/"
  |> Waves_config.as_wavefile_format ~format:Hardcamlwaveform
;;
*)
let num_bits = 16
(* Replace path below with your test input file from the AoC website*)
let test_path = "/home/pie/Documents/FPGA_Projs/AoC_25/AoC_25_Day3_hardcaml/test/test_vectors.txt"

let tb (sim : Harness.Sim.t) =
  let inputs = Cyclesim.inputs sim in
  let outputs = Cyclesim.outputs sim in
  let cycle ?n () = Cyclesim.cycle ?n sim in (* cycle optionally n number of cycles*)
  let test_vect_convert bank num_bits = List.map bank ~f:(fun x -> Bits.of_int_trunc ~width:num_bits x) in (* convert OCaml int list to list of bit vectors*)
  let banks = In_channel.read_lines test_path |> Array.of_list in
  let num_lines = Array.length banks in


  (* Main Stim *)
  inputs.clear := Bits.vdd;
  cycle ();
  inputs.clear := Bits.gnd;
  cycle ();

  for i = 0 to num_lines - 1 do
    let bank = String.to_list banks.(i) |> List.map ~f:(fun c -> Char.to_int c - Char.to_int '0') in
    let converted = test_vect_convert bank num_bits |> List.rev in (* reverse the list or function below will pair in wrong direction*)
    List.iter2_exn inputs.data_in converted ~f:(fun r v -> r := v); (* assign each element of the bit list to the data_in list*)
    cycle ();
    inputs.start := Bits.vdd;
    cycle ();
    inputs.start := Bits.gnd;
    while not (Bits.to_bool !(outputs.result.valid)) do (*wait until FSM done*)
      cycle ();
    done;
  done;

  cycle ~n:25 (); (* add some extra clock cycles after DUT is done*)
  let tb_result = Bits.to_unsigned_int !(outputs.result.value) in
  print_s [%message "Result: " (tb_result : int)];
;;

let%expect_test "test1" = 
  let display_rules =
    Display_rule. [ port_name_is "start" ~wave_format:Bit
                  ; port_name_is "clear" ~wave_format:Bit
                  ; port_name_is "clock" ~wave_format:Bit
                  ; port_name_is "result_valid" ~wave_format:Bit
                  ; port_name_is "result_value" ~wave_format:Unsigned_int
                  (* Below for debug if needed*)
                  (*; port_name_is "data_in0" ~wave_format:Unsigned_int
                  ; port_name_is "data_in1" ~wave_format:Unsigned_int
                  ; port_name_is "data_in2" ~wave_format:Unsigned_int
                  ; port_name_is "data_in3" ~wave_format:Unsigned_int
                  ; port_name_is "data_in4" ~wave_format:Unsigned_int
                  ; port_name_is "data_in5" ~wave_format:Unsigned_int
                  ; port_name_is "data_in6" ~wave_format:Unsigned_int
                  ; port_name_is "data_in7" ~wave_format:Unsigned_int
                  ; port_name_is "data_in98" ~wave_format:Unsigned_int
                  ; port_name_is "data_in99" ~wave_format:Unsigned_int *)
                  ]
  in
    Harness.run_advanced
      ~create:Total_joltage.hierarchical
      ~trace: `All_named
      ~print_waves_after_test:(fun waves ->
        Waveform.print
          ~display_rules
          ~start_cycle:34600 (* I ran out of time to properly investigate the CycleSim waveform capabilities, so just had to try and test different runs to get this number*)
          ~signals_width:30
          ~display_width:160
          ~wave_width:1
          waves)
      tb;
  [%expect {|
    ("Result: " (tb_result 17144))
    ┌Signals─────────────────────┐┌Waves───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
    │start                       ││                                                                                                                                │
    │                            ││────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────│
    │clear                       ││                                                                                                                                │
    │                            ││────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────│
    │clock                       ││┌─┐ ┌─┐ ┌─┐ ┌─┐ ┌─┐ ┌─┐ ┌─┐ ┌─┐ ┌─┐ ┌─┐ ┌─┐ ┌─┐ ┌─┐ ┌─┐ ┌─┐ ┌─┐ ┌─┐ ┌─┐ ┌─┐ ┌─┐ ┌─┐ ┌─┐ ┌─┐ ┌─┐ ┌─┐ ┌─┐ ┌─┐ ┌─┐ ┌─┐ ┌─┐ ┌─┐ ┌─┐ │
    │                            ││  └─┘ └─┘ └─┘ └─┘ └─┘ └─┘ └─┘ └─┘ └─┘ └─┘ └─┘ └─┘ └─┘ └─┘ └─┘ └─┘ └─┘ └─┘ └─┘ └─┘ └─┘ └─┘ └─┘ └─┘ └─┘ └─┘ └─┘ └─┘ └─┘ └─┘ └─┘ └─│
    │result_valid                ││                                                            ┌───┐                                                               │
    │                            ││────────────────────────────────────────────────────────────┘   └───────────────────────────────────────────────────────────────│
    │                            ││────────────────────────────────────────────────────────────────┬───────────────────────────────────────────────────────────────│
    │result_value                ││ 17045                                                          │17144                                                          │
    │                            ││────────────────────────────────────────────────────────────────┴───────────────────────────────────────────────────────────────│
    └────────────────────────────┘└────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘
    |}]
;;
