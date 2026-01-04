open! Core
open! Hardcaml
open! Aoc_25_day3


let generate_total_joltage_rtl () =
  let module C = Circuit.With_interface (Total_joltage.I) (Total_joltage.O) in
  let scope = Scope.create ~auto_label_hierarchical_ports:true () in
  let circuit = C.create_exn ~name:"total_joltage_top" (Total_joltage.hierarchical scope) in
  let rtl_circuits =
    (* Rtl.create ~database:(Scope.circuit_database scope) Verilog [ circuit ] *)
    Rtl.create ~database:(Scope.circuit_database scope) Vhdl [ circuit ]
  in
  let rtl = Rtl.full_hierarchy rtl_circuits |> Rope.to_string in
  print_endline rtl
;;

let total_joltage_rtl_command =
  Command.basic
    ~summary:""
    [%map_open.Command
      let () = return () in
      fun () -> generate_total_joltage_rtl ()]
;;

let () =
  Command_unix.run
    (Command.group ~summary:"" [ "total-joltage", total_joltage_rtl_command ])
;;