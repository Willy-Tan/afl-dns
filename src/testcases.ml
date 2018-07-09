(* ============ Packet crafting tools ============ *)

(** [prepend_zero hex desired_length] prepends '0' to [hex] until its length reaches [desired_length]. If the length of [hex] is greater than [desired_length], nothing will be done. *)
let prepend_zero string length =
  let rec aux acc n = match n with
    |k when k <=0 -> acc
    |k -> aux ("0"^acc) (k-1)
  in
  let strlen = String.length string in
  aux string (length-strlen);;


(** [int_to_hex ~nb_bytes n] converts the integer [n] to its hexadecimal representation as a string on [nb_bytes]. There should be a test to see if [nb_bytes] is too short to represent n.*)
let int_to_hex ?(nb_bytes=2) n =
  let hex = Printf.sprintf "%x" n in
  prepend_zero hex (2*nb_bytes) (*Each byte is on two chars*)
;;


(** [header ~id ~qr .. () ] returns a hex representation of the header as a string with the corresponding parameters. See RFC2929, Section 2 for a schema of a typical header*)
let header ?(id=42) ?(qr=0) ?(opcode=0) ?(aa=0) ?(tc=0) ?(rd=0) ?(ra=0) ?(z=0) ?(ad=0) ?(cd=0) ?(rcode=0) ?(qdcount=1) ?(ancount=0) ?(nscount=0) ?(arcount=0) () =
  let hex_id = int_to_hex id 
  and flags_and_codes = (*flags and codes need to be concatenated to be reprented in hex*)
    let int_rep =
      qr lsl 15 +
      opcode lsl 11 +
      aa lsl 10 +
      tc lsl 9 +
      rd lsl 8 +
      ra lsl 7 +
      z lsl 6 +
      ad lsl 5 +
      cd lsl 4 +
      rcode
    in int_to_hex ~nb_bytes:2 int_rep
  and hex_qdcount = int_to_hex qdcount
  and hex_ancount = int_to_hex ancount
  and hex_nscount = int_to_hex nscount
  and hex_arcount = int_to_hex arcount
  in
  hex_id^flags_and_codes^hex_qdcount^hex_ancount^hex_nscount^hex_arcount
  ;;


(** [default_name_as_hex] is the hex representation of foo.my.domain.*)
let default_name_as_hex = "03666f6f026d7906646f6d61696e00";;


(** [query ~qname ~qtype ~qclass ()] returns a query section with the corresponding qname, qtype and qclass. Qname will be represented as a valid hex because I didn't make a string parsing function out of laziness*)
let query ?(qname=default_name_as_hex) ?(qtype=1) ?(qclass=1) () =
  let hex_qtype = int_to_hex qtype
  and hex_qclass = int_to_hex qclass
  in
  qname^hex_qtype^hex_qclass;;


(** [const_ip] is the hex representation of the IPv4 address 127.0.0.1*)
let default_ip_as_hex = "7f000001";;


(** Returns a resource record with the corresponding parameters. Name will be represented as a hex because of the lack of a string parsing function; rdata will also be represented as a hex.*)
let resource_record ?(name=default_name_as_hex) ?(rrtype=1) ?(rrclass=1) ?(ttl=300) ?(rdlength=4) ?(rdata=default_ip_as_hex) () =
  let hex_rrtype = int_to_hex rrtype
  and hex_rrclass = int_to_hex rrclass
  and hex_ttl = int_to_hex ~nb_bytes:4 ttl
  and hex_rdlength = int_to_hex rdlength
  in
  name^hex_rrtype^hex_rrclass^hex_ttl^hex_rdlength;;


(** [concat_rr rr_list] returns the hex representation of the concatenated resource record list as a string. Returns an empty string if the list is empty.*)
let concat_rr rr_list =
  let rec aux acc rr_list = match rr_list with
    | [] -> acc
    | t::q -> aux (acc^t) q
  in
  aux "" rr_list;;


(** [answer rr_list] returns the hex representation of the answer section.*)
let answer ?(rr_list = [resource_record ()]) () =
  concat_rr rr_list;;


(** [authoritative rr_list] returns the hex representation of the authoritative section.*)
let authoritative ?(rr_list = []) () =
  concat_rr rr_list;;


(** [additional rr_list] returns the hex representation of the additional section.*)
let additional ?(rr_list = []) () =
  concat_rr rr_list;;


(** [packet header query answer authoritative additional] returns the {! cstruct} representation of the packet with the corresponding fields.*)
let packet ?(header = header ()) ?(query = query ()) ?(answer = answer ()) ?(authoritative = authoritative ()) ?(additional = additional ()) () =
  Cstruct.of_hex (header^query^answer^authoritative^additional);; 



(* =================================== Alcotest =================================== *)



(* ================================ uDNS testing ================================== *)



(*Auxilliary functions and variables*)

exception Stub;;

(** val default_name : string
    [default_name] is the name used if nothing is specified. 
    Conversions of [default_name] and [default_name_as_hex] specified above to same types (either as a hex [string] or as a [Dns_name.t]) should be equal.*)
let default_name = "foo.my.domain";;

(** val default_rdata : Dns_packet.rdata
    [default_data] is the rdata used if nothing is specified.
    Conversions of [default_rdata] of [default_rdata_as_hex] specified above to same types (either as a hex [string] or as a [Dns_packet.rdata] should be equal.*)
let default_rdata =
  let default_ip = Ipaddr.V4.of_string_exn "127.0.0.1" in
  Dns_packet.A default_ip;;


(** val make_rr : string -> int -> Dns_packet.rdata -> Dns_packet.rr
    [make_rr name ttl rdata] returns a Dns_packet.rr with the corresponding name, ttl and rdata. 
    The purpose of this function is to clarify the code.*)
let make_rr ?(name=default_name) ?(ttl=300) ?(rdata=default_rdata) () = Dns_packet.{
    name = Domain_name.of_string_exn name;
    ttl = Int32.of_int ttl;
    rdata = rdata;
  };;


(** val packet_equal : Dns_packet.t -> Dns_packet.t -> bool
    [packet_equal a b] tests if a and b are equal bitwise.*)
let packet_equal a b =
  let (a_header,a_v,_,_) = a
  and (b_header,b_v,_,_) = b
  in
  let (a_cstr,_) = Dns_packet.encode `Udp a_header a_v
  and (b_cstr,_) = Dns_packet.encode `Udp b_header b_v
  in Cstruct.equal a_cstr b_cstr;;


(** val p_packet : Dns_packet.t testable
    [p_packet] is a packet [testable] for Alcotest unit tests on packets*)
let p_packet = Alcotest.testable Dns_packet.pp packet_equal;;


(** val p_rr : Dns_packet.rr testable
    [p_rr] is a RR testable for Alcotest unit tests on resource records*) 
let p_rr = Alcotest.testable Dns_packet.pp_rr Dns_packet.rr_equal;;




exception DisallowedRRtype;;

(** val int_to_rr_typ_exn : int -> Dns_enum.rr_typ 
    [int_to_rr_typ_exn n] converts [n] to the corresponding RR type, and raises an error if the µDNS implementation doesn't allow that RRtype.
    It unwraps the option output of Dns_enum.int_to_rr_typ to properly raise an error.*)
let int_to_rr_typ_exn n = match Dns_enum.int_to_rr_typ n with
  |Some typ -> typ
  |None -> raise DisallowedRRtype;;

(** val decode_query_exn cstr : Cstruct.t -> Dns_packet.query 
    [decode_query_exn packet] returns the decoded query using the µDNS parsing function and raises an error when it's not a query or a monadic error.*)
let decode_query_exn cstr = match Dns_packet.decode cstr with
    |Ok ((_,`Query q,_,_), _) -> q
    |Ok (update,_) -> failwith "Not a query packet"
    |Error e -> Fmt.failwith "%a" Dns_packet.pp_err e;;



(*Tests*)

(** TTL rule compliance, RFC2181, Section 8. TTL is on a 32 bits field, but it should only use the 31 less significant bits with the MSB set to 0 : if the MSB is set to 1, then TTL should be considered as 0. However, as 0 TTLs should be handled carefully, raising an error may also be alright. 
This tests TTLs with the MSB set to 1 : passing this test means TTL with MSB set to 1 is either zero or raises an error.*)
let ttl_with_MSBset_test () =
  let expected_result = make_rr ~ttl:0 () in

  let parsed_packet = 
    (*Packet crafting*)
    let hdr = header ~ancount:1 ()
    and max_ttl_rr = resource_record ~ttl:4294967295 () in (* = 2^32-1 All bits set to 1*)
    let ans = answer ~rr_list:[max_ttl_rr] () in
    let pckt = packet ~header:hdr ~answer:ans () in

    (*Getting the parsed resource record*)
    try
      let content = decode_query_exn pckt in
      List.nth content.answer 0
    with
    |Failure str when str = "bad ttl 4294967295" -> expected_result 
  in
  Alcotest.check p_rr "Parsing TTL with MSB set raises TTL error or returns a TTL with 0 value" parsed_packet expected_result
;;

(** Name syntax compliance : any characters allowed, RFC2181, Section 11. Names can have any ASCII characters in the DNS server, hostname or service checking should not be done at this layer.*)
let syntax_test () =
  let expected_result = "\255(((é_ç" in

  let parsed_name =
    let non_ldh_name = "0a5c323535282828e95fe7" in
    let qry = query ~qname:non_ldh_name () in
    let pckt = packet ~query:qry () in
    try
      let content = decode_query_exn pckt in
      match content.question with
      |[q] -> Domain_name.to_string q.q_name
      | _ -> raise (Failure "Packet parsed incorrectly")
    with
    | e -> raise e 
  in
  Alcotest.check Alcotest.string "Non-LDH domain names are allowed" expected_result parsed_name 
;;
   

(** Unknown RR type number compliance, RFC3597. It is assumed that the [Raw] type in Dns_packet can also represent unknown types (could be changed to an explicit [Unknown] type). *)
let unknown_rrtype_test () =
  let expected_result =
    let expected_rdata = Dns_packet.Raw (int_to_rr_typ_exn 32771, Cstruct.create 16) in
    make_rr ~rdata:expected_rdata ()
      
  and parsed_packet =
    (*Packet crafting*)
    let hdr = header ~ancount:1 () 
    and unknown_rr = resource_record ~rrtype:32771 () in
    let ans = answer ~rr_list:[unknown_rr] () in
    let pckt = packet ~header:hdr ~answer:ans () in

    (*Parsing and getting the resource record in the rr list of the parsed packet answer field*)
    let content = decode_query_exn pckt in
    List.nth content.answer 0
  in
  Alcotest.check p_rr "parsing an RR with rrtype=32771 returns rdata = Raw (Unknown 32771,_)" parsed_packet expected_result
;;


(** Unknown RR class number compliance, RFC3597. There is no {! class} field in Dns_packet.query so it only checks if the result is parsed correctly. For now, I am using a stub exception because the function is failing : if it can produce a proper result, this will be changed to a simple equality test.*)
let unknown_rrclass_test () =
   
  (*Encapsulating the parsing test in a unit -> unit function because we check for exceptions and the result does not matter *)
  let rrclass_parsing () = 
    (*Packet crafting*)
    let hdr = header ~ancount:1 ()
    and unknown_rr = resource_record ~rrclass:2 () in
    let ans = answer ~rr_list:[unknown_rr] () in
    let pckt = packet ~header:hdr ~answer:ans () in

    (*Packet parsing, returning a unit for now*)
    let _ = decode_query_exn pckt in ()
  in
  Alcotest.check_raises "Unknown RR class does not raise exception" Stub rrclass_parsing;;

  



let udns_tests = [
  "TTL with MSB set test", `Quick, ttl_with_MSBset_test ;
  "Non-LDH allowance test", `Quick, syntax_test ;
  "unknown rrtype test",`Quick,unknown_rrtype_test ;
  "unknown rrclass test", `Quick, unknown_rrclass_test ;
];;

let tests = [
  "udns tests", udns_tests ;
]
;;


                                                   
let () =
  Alcotest.run "µDNS RFC compliance" tests
;;
