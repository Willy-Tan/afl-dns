(*Test cases for dns standards*)


let standard_detail = Dns.Packet.{
  qr = Query;
  opcode = Standard;
  aa = false;
  tc = false;
  rd = true;
  ra = false;
  rcode = NoError;
};;

let standard_name = ["www";"example";"com"];;


(*Subject to modifications*)
let make_query ?(id=1337) ?(name=standard_name) ?(qtype = Dns.Packet.Q_A) ?(qclass=Dns.Packet.Q_IN) () =
  let qname = Dns.Name.of_string_list name in 
  let question = Dns.Packet.{
      q_name = qname;
      q_type = qtype;
      q_class = qclass;
      q_unicast = Q_Normal;
    }
  in
  Dns.Packet.{
    id = id;
    detail = standard_detail;
    questions = [question];
    answers = [];
    authorities = [];
    additionals = [];
  };;

(*A-type query with a starting hyphen : "-www.northeastern.edu"*)
let starting_hyphen_A = make_query ~name:["-www";"northeastern";"edu"] ();;

(*A-type query with non-LDH characters : "é.test.com"*)
let nonalpha_char_A = make_query ~name:["é";"test";"com"] ();;

(*Query with a label of length > 63 : "www.abcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdefghijkl.edu"
Middle label length is 64*)
let long_label = make_query ~name:["www";"abcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdefghijkl";"edu"] ();;


(*Query with a total length > 255 : "abcdefghij.abcdefghij.abcdefghij.abcdefghij.abcdefghij.abcdefghij.abcdefghij.abcdefghij.abcdefghij.abcdefghij.abcdefghij.abcdefghij.abcdefghij.abcdefghij.abcdefghij.abcdefghij.abcdefghij.abcdefghij.abcdefghij.abcdefghij.abcdefghij.abcdefghij.abcdefghij.abcdefghij.abcdefghij.abcdefghij.abcdefghij.abcdefghij.abcdefghij.abcdefghij"
Total length is 329*)
let long_query = make_query ~name:[
    "abcdefghij"; 
    "abcdefghij";
    "abcdefghij";
    "abcdefghij";
    "abcdefghij";
    "abcdefghij";
    "abcdefghij";
    "abcdefghij";
    "abcdefghij";
    "abcdefghij"; (*10*)
    "abcdefghij";
    "abcdefghij";
    "abcdefghij";
    "abcdefghij";
    "abcdefghij";
    "abcdefghij";
    "abcdefghij";
    "abcdefghij";
    "abcdefghij";
    "abcdefghij"; (*20*)
    "abcdefghij";
    "abcdefghij";
    "abcdefghij";
    "abcdefghij";
    "abcdefghij";
    "abcdefghij";
    "abcdefghij";
    "abcdefghij";
    "abcdefghij";
    "abcdefghij"; (*30*)
  ] ();;


  
let () =
  (*=-=-= Label conformance =-=-=*)
  
  (*For host names, labels must start with a letter/digit and end with a letter/digit according to RFC1035, section 2.3.1*)

  (*Starting hyphen test : query is "-www.northeastern.edu"*)
  Printf.printf "Forbidding starting hyphens in A-type queries : ";
  (try
     let _ = Dns.Packet.parse (Dns.Packet.marshal starting_hyphen_A) in
     Printf.printf "FAIL\n";
  with
  |e -> Printf.printf "PASS\n");

  
  (*non-alphanumeric characters test : query is "é.test.com"*)
  Printf.printf "Forbidding non-alpha characters in A-type queries : ";
  (try
     let _ = Dns.Packet.parse (Dns.Packet.marshal nonalpha_char_A) in
     Printf.printf "FAIL\n";
   with
   |e -> Printf.printf "PASS\n");

  (*=-=-= Length conformance =-=-=*)

  (*Label length test : query is "www.abcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdefghijkl.edu"*)
  Printf.printf "Forbidding label of length greater than 63 : ";
  (try
     let _ = Dns.Packet.parse (Dns.Packet.marshal long_label) in
     Printf.printf "FAIL\n"
   with
   |e -> Printf.printf "PASS\n");

  
  (*Domain name length test : query is "abcdefghij.abcdefghij.abcdefghij.abcdefghij.abcdefghij.abcdefghij.abcdefghij.abcdefghij.abcdefghij.abcdefghij.abcdefghij.abcdefghij.abcdefghij.abcdefghij.abcdefghij.abcdefghij.abcdefghij.abcdefghij.abcdefghij.abcdefghij.abcdefghij.abcdefghij.abcdefghij.abcdefghij.abcdefghij.abcdefghij.abcdefghij.abcdefghij.abcdefghij.abcdefghij"*)
  Printf.printf "Forbidding domain name queries of length greater than 255 : ";
  (try
     let _ = Dns.Packet.parse (Dns.Packet.marshal long_query) in
     Printf.printf "FAIL\n"
   with
   |e -> Printf.printf "PASS\n");

  Printf.printf "udns test : ";
  (try
     match Dns_packet.decode (Dns.Packet.marshal starting_hyphen_A) with
     |Error e -> Fmt.failwith "Error %a\n" Dns_packet.pp_err e
     |Ok _ -> Printf.printf "FAIL\n"
   with
   |e ->
     (Printf.printf "Error : %s\n" @@ Printexc.to_string e;
     Printf.printf "PASS\n"))
  
;;
     
