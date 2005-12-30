(************************************************************************)
(*  v      *   The Coq Proof Assistant  /  The Coq Development Team     *)
(* <O___,, * CNRS-Ecole Polytechnique-INRIA Futurs-Universite Paris Sud *)
(*   \VV/  **************************************************************)
(*    //   *      This file is distributed under the terms of the       *)
(*         *       GNU Lesser General Public License Version 2.1        *)
(************************************************************************)

(* $Id$ *)

(* This file defines the printer for natural numbers in [nat] *)

(*i*)
open Pcoq
open Pp
open Util
open Names
open Coqlib
open Rawterm
open Libnames
open Bigint
open Coqlib
open Notation
open Pp
open Util
open Names
(*i*)

(**********************************************************************)
(* Parsing via scopes *)
(* For example, (nat_of_string "3") is <<(S (S (S O)))>> *)

let nat_of_int dloc n =
  if is_pos_or_zero n then begin
      if less_than (of_string "5000") n & Options.is_verbose () then begin
	warning ("You may experience stack overflow and segmentation fault\
                  \nwhile parsing numbers in nat greater than 5000");
	flush_all ()
      end;
      let ref_O = RRef (dloc, glob_O) in
      let ref_S = RRef (dloc, glob_S) in
      let rec mk_nat acc n =
	if n <> zero then 
	  mk_nat (RApp (dloc,ref_S, [acc])) (sub_1 n)
	else 
	  acc
      in 
      mk_nat ref_O n
    end
  else
      user_err_loc (dloc, "nat_of_int",
        str "Cannot interpret a negative number as a number of type nat")

let pat_nat_of_int dloc n name =
  if is_pos_or_zero n then
      let rec mk_nat n name =
	if n <> zero then 
	  PatCstr (dloc,path_of_S,[mk_nat (sub_1 n) Anonymous],name)
	else 
	  PatCstr (dloc,path_of_O,[],name)
      in 
      mk_nat n name
  else
      user_err_loc (dloc, "pat_nat_of_int",
        str "Unable to interpret a negative number in type nat")

(************************************************************************)
(* Printing via scopes *)

exception Non_closed_number

let rec int_of_nat = function
  | RApp (_,RRef (_,s),[a]) when s = glob_S -> add_1 (int_of_nat a)
  | RRef (_,z) when z = glob_O -> zero
  | _ -> raise Non_closed_number
	  
let uninterp_nat p =
  try 
    Some (int_of_nat p)
  with
    Non_closed_number -> None

let rec int_of_nat_pattern = function
  | PatCstr (_,s,[a],_) when ConstructRef s = glob_S ->
      add_1 (int_of_nat_pattern a)
  | PatCstr (_,z,[],_) when ConstructRef z = glob_O -> zero
  | _ -> raise Non_closed_number
	  
let uninterp_nat_pattern p =
  try 
    Some (int_of_nat_pattern p)
  with
    Non_closed_number -> None

(************************************************************************)
(* Declare the primitive parsers and printers *)

let _ =
  Notation.declare_numeral_interpreter "nat_scope"
    (glob_nat,["Coq";"Init";"Datatypes"])
    (nat_of_int,Some pat_nat_of_int)
    ([RRef (dummy_loc,glob_S); RRef (dummy_loc,glob_O)], 
     uninterp_nat, Some uninterp_nat_pattern)
