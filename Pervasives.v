(** Basic type and event definitions. *)
Require Import Coq.Lists.List.
Require Import Coq.Strings.String.
Require Import String.

Import ListNotations.
Open Local Scope string.

(** Events to log data. *)
Module Log.
  Module Output.
    Inductive t : Type :=
    | write : string -> t.
  End Output.
End Log.

(** Events to read files. *)
Module File.
  (** The name of a file. Only relative for now. *)
  Module Name.
    (** A file name is a path and a base name. *)
    Record t : Type := {
      path : list string;
      base : string }.

    (** Convert a file name to a single string. *)
    Definition to_string (file_name : t) : string :=
      List.fold_right (fun x y => (x ++ "/" ++ y) % string) (base file_name)
        (path file_name).

    Check eq_refl : to_string {|
      path := ["some"; "dir"];
      base := "file.txt" |} =
      "some/dir/file.txt".

    (** Test equality. *)
    Definition eqb (file_name1 file_name2 : t) : bool :=
      if List.list_eq_dec string_dec (path file_name1) (path file_name2) then
        String.eqb (base file_name1) (base file_name2)
      else
        false.

    (** Parse a string into a file name. *)
    Definition of_string (file_name : string) : option t :=
      let names : list string := String.split file_name "/" in
      match List.rev names with
      | base :: path => Some {|
        File.Name.path := List.rev path;
        File.Name.base := base |}
      | [] => None
      end.
  End Name.

  (** Incoming events. *)
  Module Input.
    Inductive t : Type :=
    | read : Name.t -> string -> t (** The file content had been read. *).
  End Input.

  (** Generated events. *)
  Module Output.
    Inductive t : Type :=
    | read : Name.t -> t (** Read all the content of a file. *).
  End Output.
End File.

Module TCPServerSocket.
  Module Id.
    Inductive t : Type :=
    | new : nat -> t.
  End Id.

  Module ConnectionId.
    Require Import Coq.Numbers.Natural.Peano.NPeano.

    Inductive t : Type :=
    | new : nat -> t.

    (** Test equality. *)
    Definition eqb (id1 id2 : t) : bool :=
      match (id1, id2) with
      | (new id1, new id2) => Nat.eqb id1 id2
      end.
  End ConnectionId.

  Module Input.
    Inductive t : Type :=
    | bound : Id.t -> t
    | accepted : ConnectionId.t -> t
    | read : ConnectionId.t -> string -> t.
  End Input.

  Module Output.
    Inductive t : Type :=
    | bind : nat -> t
    | write : ConnectionId.t -> string -> t
    | close_connection : ConnectionId.t -> t.
  End Output.
End TCPServerSocket.

Module Input.
  Inductive t : Type :=
  | file : File.Input.t -> t
  | socket : TCPServerSocket.Input.t -> t.
End Input.

Module Output.
  Inductive t : Type :=
  | log : Log.Output.t -> t
  | file : File.Output.t -> t
  | socket : TCPServerSocket.Output.t -> t.
End Output.