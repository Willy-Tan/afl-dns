(*General test for fuzzing, raises every possible exception.*)
(*
let main () =
  let s = read_line () in
  let testcase =
    try Some (Cstruct.of_hex s)
    with
    | _ -> None (*Bad kind of test*)
  in
  match testcase with
  | None -> ()
  | Some cstr -> 
    Printf.printf "%s\n\n" (Dns.Dig.string_of_answers (Dns.Packet.parse cstr));;

let () = AflPersistent.run main;;



*)

(*TODO : Packet generator*)


(*Cstruct generator*)

let cstruct =
  Crowbar.map [Crowbar.bytes] (fun a ->
      try
        Cstruct.of_string a
      with
        _ -> Printf.printf "?\n"; print_endline a; Crowbar.bad_test ());;

(*Pretty-printer*)
let pp_packet ppf parsed = Crowbar.pp ppf "%s" (Dns.Dig.string_of_answers parsed);;


(*--Test on the domain name label specifically--*)

(*Test if a qname is valid*)
let name_is_valid qname =
  let qname_str = Dns.Name.to_string_list qname in
  (*Check is each char is standard : only uppercase,lowercase and hyphens*)
  let char_is_valid char = let code = Char.code char in
    match code with
    |upper when upper >= 65 && upper <= 90 -> true
    |lower when lower >= 97 && lower <= 122 -> true
    |45 (*hyphen*) -> true
    | _-> false
  in
  (*Apply the char check to label, no hyphen at the beginning, restricted length*)
  let label_is_valid label =
    Astring.String.for_all char_is_valid label
    && label.[0] <> '-'
    && String.length label <= 63
  in
  (*Apply the label check to every label, whole length should be less than 253*)
  let whole_length list =
    let rec aux list length = match list with
      |[] -> length
      |t::q -> aux q (length + String.length t)
    in aux list 0
  in     
  List.for_all label_is_valid qname_str
  && whole_length qname_str <=253
;;


(*Get qname from a DNS packet*)
let get_qname ?(index=0) Dns.Packet.{id; detail; questions; answers; authorities; additionals} =
  (List.nth questions index).q_name;;

(*Crowbar test*)
let qname_check packet =
  let qname = get_qname packet in
  Crowbar.check (name_is_valid qname);;
                                                
let qname_test () =
  Crowbar.add_test ~name:"Ocaml-dns parser" [cstruct] @@ (fun cstr ->
  let packet = Dns.Packet.parse cstr in
  (Printf.printf "%s\n\n %!" @@ Dns.Dig.string_of_answers packet;
  qname_check packet));;

let is_positive n = (n >= 0);;

let simple_test () =
  Crowbar.add_test ~name:"Int test" [Crowbar.uint8] @@ (fun int -> Printf.printf "%d\n" int; Crowbar.check (is_positive int));;

let () =
  simple_test ();;
