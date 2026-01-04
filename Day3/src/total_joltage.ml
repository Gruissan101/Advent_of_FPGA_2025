open! Core
open! Hardcaml
open! Signal

let num_bits = 16
let bats = 100

module I = struct
  type 'a t =
    { clock : 'a
    ; clear : 'a (* need to include clear or FSM won't initialise to Idle*)
    ; start : 'a
    ; data_in : 'a list [@bits num_bits] [@length bats]
    }
  [@@deriving hardcaml]
end

module O = struct
  type 'a t =
    { 
      result : 'a With_valid.t [@bits num_bits]
    }
  [@@deriving hardcaml ~rtlmangle:"_"] (* rtlmangle replaces $ with _ which we need
                                          to generate VHDL at the end and use the With_valid.t construct*)
end

module States = struct
  type t =
    | Idle
    | Highest
    | Second
    | Mult
    | Add
    | Repeat
  [@@deriving sexp_of, compare ~localize, enumerate]
end

let create scope ({ clock; clear; start; data_in } : _ I.t) : _ O.t
  =
  let spec = Reg_spec.create ~clock ~clear () in
  let open Always in
  let sm =
    State_machine.create (module States) spec
  in
  (* let%hw = reserve signal name *)
  let%hw_var count = Variable.reg spec ~width:num_bits in
  let%hw_var hnum = Variable.reg spec ~width:num_bits in
  let%hw_var hpos = Variable.reg spec ~width:num_bits in
  let%hw_var lnum = Variable.reg spec ~width:num_bits in
  let%hw_var running_total = Variable.reg spec ~width:num_bits in
  let total = Variable.reg spec ~width:num_bits in
  let totalv = Variable.wire ~default:gnd () in (* This ends up being a cycle early because its wire but I couldnt get it working as a reg*)
  let countmux = mux count.value data_in in (* This was confusing coming from VHDL as you can just directly index rather than manually having to write a funciton*)
  compile
    [ sm.switch
        [ ( Idle
          , [ when_
                start
                [ count <--. bats - 1
                ; hnum <--. 0
                ; hpos <--. 0
                ; lnum <--. 0
                ; running_total <--. 0
                ; totalv <-- gnd
                ; sm.set_next Highest
                ]
            ] )
        ; ( Highest
          , [ 
              when_
                (countmux >: hnum.value)
                [
                  hnum <-- countmux
                ; hpos <-- count.value                
                ]
            ; if_
                (count.value ==:. 1) (* 1 because the the last number can't be the first digit*)
                [ 
                  if_
                    (countmux >: hnum.value)
                      [count <-- count.value -:. 1]
                      [count <-- hpos.value -:. 1]
                ; sm.set_next Second
                ]
                [count <-- count.value -:. 1]
            ] )
        ; ( Second
          , [ 
              when_
                (countmux >: lnum.value)
                [lnum <-- countmux]
            ; if_
                (count.value ==:. 0)
                [
                 sm.set_next Mult 
                ]
                [count <-- count.value -:. 1]
            ] )
        ; ( Mult
          , [
              if_
                (count.value <:. 10)
                [
                  count <-- count.value +:. 1
                ; running_total <-- running_total.value +: hnum.value
                ]
                [
                  sm.set_next Add
                ; count <--. bats
                ]
            ] )
        ; ( Add
          , [
              running_total <-- running_total.value +: lnum.value
            ; sm.set_next Repeat
            ] )
        ; ( Repeat
          , [
              total <-- total.value +: running_total.value
            ; totalv <-- vdd
            ; if_
                (start ==:. 1 )
                [
                  sm.set_next Highest
                ; hnum <--. 0
                ; lnum <--. 0
                ; running_total <--. 0
                ]
                [sm.set_next Idle]
            ] )
        ]
    ];
  { result = { value = total.value; valid = totalv.value } }
;;

(* Maintain hierarchy *)
let hierarchical scope =
  let module Scoped = Hierarchy.In_scope (I) (O) in
  Scoped.hierarchical ~scope ~name:"total_joltage" create
;;