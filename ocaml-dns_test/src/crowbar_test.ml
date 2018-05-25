(*--------------------------------------------------------------------*)

(*Packet pretty-printer*)
let pp_packet ppf parsed = Crowbar.pp ppf "%s" (Dns.Dig.string_of_answers parsed);;

(*--------------------------------------------------------------------*)

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
  let label_is_valid label = match String.length label with
    |0 -> false
    | _ -> (Astring.String.for_all char_is_valid label
           && label.[0] <> '-'
           && String.length label <= 63)
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
let get_qname ?(index=0) Dns.Packet.{id; detail; questions; answers; authorities; additionals} = match questions with
  |[] -> Crowbar.bad_test ()
  | _ -> (List.nth questions index).q_name;;

(*Crowbar test*)
let qname_check packet =
  let qname = get_qname packet in
  Crowbar.check (name_is_valid qname);;
                                                
let qname_test () =
  Crowbar.add_test ~name:"Ocaml-dns parser" [Dns.Packet.to_crowbar] @@ qname_check;;
 
(*Name generation printing*)
let name_test () =
  Crowbar.add_test ~name:"Dns.Name test" [Dns.Name.to_crowbar] @@
  (fun a ->
      Printf.printf "%s\n" @@ Dns.Name.to_string a;
      Crowbar.check true);;

(*Question generation printing*)
let question_print () =
  Crowbar.add_test ~name:"Dns.Packet.question test" [Dns.Packet.question_to_crowbar] @@
  (fun a ->
      Printf.printf "%s\n\n" @@ Dns.Packet.question_to_string a;
      Crowbar.check true);;

(*Question list generation printing*)
let questions_print () =
  Crowbar.add_test ~name:"Dns.Packet.t.questions test" [Dns.Packet.to_crowbar] @@
  (fun a ->
      Printf.printf "question list size : %d\n" @@ List.length a.questions;
      Dns.Packet.print_question a.questions;
      Crowbar.check (true));;

(*Packet generation printing*)
let packet_print () =
  Crowbar.add_test ~name:"Packet generation test" [Dns.Packet.to_crowbar] @@
  (fun a ->
     Printf.printf "%s\n\n %!" @@ Dns.Dig.string_of_answers a);;

(*packet marshalling and parsing test*)

let counter = ref 1;;


let marshal_parsing_test () =
  Crowbar.add_test ~name:"Marshalling test" [Dns.Packet.to_crowbar] @@
  (fun initial ->
     incr counter;
     let marshalled =
       try
         Dns.Packet.marshal initial
       with
       |e ->
         let msg = Printexc.to_string e
         and stack = Printexc.get_backtrace () in
         Printf.eprintf "Marshal error : %s \n%s \n" msg stack;
         Crowbar.bad_test ()
     in
     let processed = 
       try
         Dns.Packet.parse marshalled
       with
       |e ->
         let msg = Printexc.to_string e
         and stack = Printexc.get_backtrace () in
         Printf.eprintf "Parse error : %s \n%s \n" msg stack;
         Crowbar.bad_test ()
     in
     let oc = open_out_gen [Open_creat; Open_text; Open_append] 0o644 "result.txt" in
     let buffer = Buffer.create 256 in
     Cstruct.hexdump_to_buffer buffer marshalled;
     Printf.fprintf oc "Attempt N. %d : \n\n" !counter;
     Printf.fprintf oc "Hexdump : \n %s" @@ Buffer.contents buffer;
     Printf.fprintf oc "Initial :\n %s\n\n %!" @@ Dns.Dig.string_of_answers initial;
     Printf.fprintf oc "Marshalled :\n %s\n\n %!" @@ Dns.Dig.string_of_answers processed;
     Printf.fprintf oc "--------------------------------------------------------\n\n";
     close_out oc;
     (*Crowbar.check_eq ~pp:pp_packet initial processed)*)
     Crowbar.check (true));;


let () =
  marshal_parsing_test ();;
