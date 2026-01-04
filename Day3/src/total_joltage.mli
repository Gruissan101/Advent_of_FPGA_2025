open! Core
open! Hardcaml

module I : sig
  type 'a t =
    { clock : 'a
    ; clear : 'a
    ; start : 'a
    ; data_in : 'a list
    }
  [@@deriving hardcaml]
end

module O : sig
  type 'a t = 
    { result : 'a With_valid.t
    } 
  [@@deriving hardcaml]
end

val hierarchical : Scope.t -> Signal.t I.t -> Signal.t O.t
