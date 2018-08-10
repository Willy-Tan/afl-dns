(*Useful tools for crowbar generation*)

(**[empty_gen] is the zero-length string generator.*)
let empty_gen = Crowbar.const "";;

(**[truncate list length] keeps every element until the nth element. It is useful for valid label generation.*)
let truncate list length =
  let rec aux acc n list = match (n,list) with
    |(k,_) when (k >= length) -> acc
    |(_,[]) -> acc
    |(k,t::q) -> aux (acc@[t]) (k+1) q
  in aux [] 0 list;;


(**[prepend_zero string length] appends zeros at the beginning of the string until it is of length [length]. If [string] length is longer than [length], nothing is done.*)
let prepend_zero string length =
  let rec aux acc n = match n with
    |k when k <=0 -> acc
    |k -> aux ("0"^acc) (k-1)
  in
  let strlen = String.length string in
  aux string (length-strlen);;
  

(**[hex] returns a string crowbar generator which produces one byte in hex format.*)
let hex = Crowbar.map [Crowbar.range 255] @@ (fun a ->
    let str = Printf.sprintf "%x" a in
    prepend_zero str 2);;

(**[hex_range min nb range] returns a string crowbar generator which produces [nb] bytes in hex format, ranging from [min] to [min+range]. 
Currently, there is no check for when min+n is a number greater than the possible number on [nb] bytes. If a power function is efficient enough to take a minimal amount of time, this check should be done, but for now it causes a great loss in performance with a naive recursive function.*)
let hex_range ?(min=0) ?(nb_bytes=1) n =
  if (min < 0) (*|| ((min+n) > 2^(nb_bytes*8)*) then raise (Failure "Bad hex range");
  Crowbar.map [Crowbar.range ~min:min n] @@ (fun a ->
      let str = Printf.sprintf "%x" a in
      prepend_zero str (2*nb_bytes)
  );;

(**[hex_const nb n] returns a string crowbar generator which generates the number [n] on [nb] bytes.*)
let hex_const ?(nb_bytes=1) n =
  let str = Printf.sprintf "%x" n in (*It can lack some zeros*)
  Crowbar.const @@ prepend_zero str (2*nb_bytes);; 
  

     
(**[hex_concat bytes1 bytes2] returns a string crowbar generator made of two concatenated string crowbar generators*)
let hex_concat a b = Crowbar.map [a;b] @@ (fun a b -> a^b);;


(**[hex_concat_list [gen1; gen2;...; genN]] returns a string crowbar generator made of the concatenated gen list *)
let hex_concat_list list =
  let rec aux acc list = match list with
    |[] -> acc
    |t::q -> aux (hex_concat acc t) q
  in
  aux empty_gen list;;

(**[gen_times gen n] returns a string crowbar generator made of the [gen] replicated [n] times.*)
let gen_times gen n =
  let rec aux acc k = match k with
    |k when k <= 0 -> acc
    |k -> aux (hex_concat acc gen) (k-1)
  in
  aux empty_gen n;;


(**[hex_times n] returns a string crowbar generator made of [n] byte generators.*)
let hex_times n = gen_times hex n;;


(*---- Header generation ----*)


(** [id] returns a string crowbar generator of value equal to the number of packets generated. Reference incrementation is wrapped in Crowbar.map so that it is called each time it is generated.*)
let idcounter = ref 0;;
let id = Crowbar.map [empty_gen] @@ (fun _ ->
    incr idcounter;
    let str = Printf.sprintf "%x" !idcounter in
    prepend_zero str 4);;


(**[flags and codes qr opcode .. rcode] returns a string crowbar generator for the flags and codes parts using the generators for each field.*)
let flags_and_codes ?(qr=Crowbar.range 1) ?(opcode=Crowbar.range 15) ?(aa=Crowbar.range 1) ?(tc=Crowbar.range 1) ?(rd=Crowbar.range 1) ?(ra=Crowbar.range 1) ?(z=Crowbar.range 1) ?(ad=Crowbar.range 1) ?(cd=Crowbar.range 1) ?(rcode=Crowbar.range 15) () =
  Crowbar.map [qr;opcode;aa;tc;rd;ra;z;ad;cd;rcode] @@ (fun qr opcode aa tc rd ra z ad cd rcode -> 
      let bin_rep = 
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
      in
      let hex_rep = Printf.sprintf "%x" bin_rep in
      prepend_zero hex_rep 4)
     ;;
    
(**[const_qdcount n] (respectively [const_ancount], [const_aacount] and [const_arcount]) returns a string crowbar generator for the qdcount (respectively the other counts) field for the header as a constant. Those are defined for code clarity.*)
let const_qdcount n = hex_const ~nb_bytes:2 n;;
let const_ancount n = hex_const ~nb_bytes:2 n;;
let const_aacount n = hex_const ~nb_bytes:2 n;;
let const_arcount n = hex_const ~nb_bytes:2 n;;


(**[make_header id flags_and_codes qdcount .. arcount] returns a string crowbar generator made of each generator for the header part.*)
let make_header ?(id=id) ?(flags_and_codes=flags_and_codes ()) ?(qdcount=hex_times 2) ?(ancount=hex_times 2) ?(aacount=hex_times 2) ?(arcount=hex_times 2) () =
  hex_concat_list [id;flags_and_codes;qdcount;ancount;aacount;arcount];;




(*---- Question generation ----*)


(**[valid_label length] returns a string crowbar generator as hex, truncated to less than [length] (RFC restricts length to be <=63)
Hex-wise, a label consists of a series of bytes of variable length, with the length as a prefix.
To prevent parsing errors, the last byte is non zero.*)
let valid_label length = Crowbar.map [Crowbar.list1 hex;hex_range ~min:1 255] @@ (fun list last ->
    let list = truncate list (length-1) in
    let shortlen = Printf.sprintf "%x" (List.length list + 1) in
    let length = prepend_zero shortlen 2 in
    String.concat "" (length::list@[last]));;


(**[long_label] returns a label generator without length restriction.
To prevent parsing errors, the penultimate byte is non zero. *)
let long_label = Crowbar.map [Crowbar.list1 hex;hex_range ~min:1 255] @@ (fun list last ->
    let shortlen = Printf.sprintf "%x" (List.length list + 1) in
    let length = prepend_zero shortlen 2 in
    String.concat "" (length::list@[last]));;


(**[corrupted_label] returns a label generator which length makes its first two bits to be either 01 or 10, which is not allowed by the standards.*)
let corrupted_label = hex_range ~min:64 128;;


(**[pointer_label] returns a label generator which length makes its first two bits to be 11, sign of a pointer.*)
let pointer_label = hex_concat (hex_range ~min:192 63) hex;;


(**[label_times length n] is a strng crowbar generator which produces [n] labels of maximal length [length].*)
let label_times length n =
  let rec aux acc n = match n with
    |0 -> acc
    |n -> aux (hex_concat acc (valid_label length)) (n-1)
  in aux (empty_gen) n;;


(**[valid_name] returns a domain name generator with length restriction.
The number of labels is arbitrarily chosen to four.*)
let valid_name = Crowbar.dynamic_bind (Crowbar.range 63) @@ fun length ->
       hex_concat_list [valid_label length;valid_label length;valid_label length;valid_label length;Crowbar.const "00"];;


(**[long_name] returns a domain name as a string list without length restriction*)
let long_name = Crowbar.map [Crowbar.list1 long_label] @@ (fun l ->
    String.concat "" (l@["00"]));;
  

(**[longer_name] returns a domain name generator made of 2000 labels of length 1.*)
let longer_name = hex_concat (label_times 1 2000) (Crowbar.const "00");;


(**[corrupted_name] returns a domain name generator made of corrupted labels (starting with the two bits equal to either 01 or 10).*)
let corrupted_name = Crowbar.map [Crowbar.list1 corrupted_label] @@ (fun l ->
    String.concat "" l);;

(**[pointer_name] returns a domain name generator made of pointer labels.*)
let pointer_name = Crowbar.map [Crowbar.list1 pointer_label] @@ fun l ->
  String.concat "" l;;


(**[const_name] returns the domain name constant generator which produces [foo.my.domain].*)
let const_name = Crowbar.const "03666f6f026d7906646f6d61696e00";;


(**[qtype] returns a crowbar string generator which returns the qtype field.*)
let qtype = hex_times 2;;


(**[valid_qtype] returns a crowbar string generator which returns a qtype defined in the RFC standards.*)
let valid_qtype = Crowbar.choose [
    hex_range ~nb_bytes:2 ~min:1 53;
    hex_range ~nb_bytes:2 ~min:55 7;
    hex_range ~nb_bytes:2 ~min:99 10;
    hex_range ~nb_bytes:2 ~min:249 10;
    hex_const 32768;
    hex_const 32769
  ]
;;

(**[qclass] returns a crowbar string generator for the qclass field.*)
let qclass = hex_times 2;;


(**[valid_qclass] returns a crowbar string generator equal to the IN qclass.*)
let valid_qclass = Crowbar.const "0001";;

(**[make query qtype qclass name ()] returns a crowbar string generator for the query field.*)
let make_query ?(qtype=valid_qtype) ?(qclass=valid_qclass) ?(name=valid_name) () = hex_concat_list [name;qtype;qclass];;

let valid_query = make_query ~name:valid_name ();;
let long_query = make_query ~name:long_name ();;
let longer_query = make_query ~name:longer_name ();;
let corrupted_query = make_query ~name:corrupted_name ();;
let pointer_query = make_query ~name:pointer_name ();;
let const_query = make_query ~name:const_name ();;



(*------ Resource record generation ------*)


(**[rrtype] returns a crowbar string generator for the rrtype field.*)
let rrtype = hex_times 2;;


(**[valid_rrtype] returns a crowbar string generator which returns a rrtype defined in the RFC standards.*)
let valid_rrtype = Crowbar.choose [
    hex_range ~nb_bytes:2 62;
    hex_range ~nb_bytes:2 ~min:99 10;
    hex_range ~nb_bytes:2 ~min:249 10;
    hex_const 32768;
    hex_const 32769
  ]
;;


(**[valid_rrclass] returns a crowbar string generator equal to the IN class.*)
let valid_rrclass = hex_const ~nb_bytes:2 1;;


(**[ttl] returns a crowbar string generator for the TTL field.*)
let ttl = hex_times 4;;


(**[valid_ttl] returns a crowbar string generator equal to 65535.*)
let valid_ttl = hex_const ~nb_bytes:4 65535 ;;


(**[rdlength] returns a crowbar string generator for the rdlength, ranging from 0 to 65535.*)
let rdlength = Crowbar.dynamic_bind (Crowbar.range 4) (fun n -> hex_times n) ;;


(**[valid_rdlength] returns a crowbar string generator for the rdlength equal to 4.*)
let valid_rdlength = hex_const ~nb_bytes:2 4;;


(**[rdata] returns a crowbar string generator for the rdata which number of bytes ranges from 0 to 65535. *)
let rdata = Crowbar.dynamic_bind (Crowbar.range 65535) (fun n -> hex_times n);;


(**[valid_rdata] returns a crowbar string generator for the rdata, on four bytes.*)

let valid_rdata = hex_times 4;;

(**[resource_record rrtype rrclass rdlength rdata] returns a crowbar string generator for the resource record field.*)
let resource_record ?(rrtype=valid_rrtype) ?(rrclass=valid_rrclass) ?(rdlength=valid_rdlength) ?(rdata=valid_rdata) ?(name=valid_name) () = hex_concat_list [name; rrtype; rrclass; valid_ttl; rdlength; rdata];;



(*------ Packet generation ------*)




(**[make_packet header query answer authority additional] returns a crowbar string generator which produces a DNS packet.*)
let make_packet ?(header=make_header ()) ?(query=make_query ()) ?(answer=resource_record ()) ?(authority=resource_record ()) ?(additional=resource_record ()) () =
  hex_concat_list [header;query;answer;authority;additional];;


(**[query_packet] returns a packet with questions only. This is only an example of a generated packet and can be modified. Current flags and codes are chosen so that afl-fuzz doesn't take too much time on obviously bad packets.*)
let query_packet =
  Crowbar.dynamic_bind (Crowbar.range 600) (fun n ->
      let f_and_c = flags_and_codes ~opcode:(Crowbar.const 0) ~rcode:(Crowbar.const 0) ~aa:(Crowbar.const 0) ~tc:(Crowbar.const 0) ~rd:(Crowbar.const 0) ~ra:(Crowbar.const 0) ~z:(Crowbar.const 0) ~ad:(Crowbar.const 0) ~cd:(Crowbar.const 0) () in
      let hdr = make_header ~qdcount:(const_qdcount n) ~ancount:(const_ancount 0) ~aacount:(const_aacount 0) ~arcount:(const_arcount 0) ~flags_and_codes:f_and_c () in
      let qry = gen_times (make_query ~name:const_name ~qtype:(hex_const ~nb_bytes:2 1) ()) n in
      make_packet ~header:hdr ~query:qry ~answer:empty_gen ~authority:empty_gen ~additional:empty_gen ());;



(**[response_packet] returns a complete DNS packet. This is only an example of a generated packet and can be modified. Current flags and codes are chosen so that afl-fuzz doesn't take too much time on obviously bad packets.*)
let response_packet =
  let opcode = Crowbar.choose [
      Crowbar.const 0;
      Crowbar.const 4;
      Crowbar.const 5;
    ]
    and rcode = Crowbar.range 10
  and id = Crowbar.const "0001"
  in
  let tuple_gen = Crowbar.map [Crowbar.range 50; Crowbar.range 50; Crowbar.range 50; Crowbar.range 50] (fun a b c d -> a,b,c,d) in
  Crowbar.dynamic_bind tuple_gen (fun (n1,n2,n3,n4) ->
      let f_and_c = flags_and_codes ~opcode:opcode ~rcode:rcode () in
      let hdr = make_header ~id:id ~qdcount:(const_qdcount n1) ~ancount:(const_ancount n2) ~aacount:(const_aacount n3) ~arcount:(const_arcount n4) ~flags_and_codes:f_and_c () in
      let qry = gen_times (make_query ~name:const_name ()) n1
      and ans = gen_times (resource_record ~name:const_name ()) n2
      and aut = gen_times (resource_record ~name:const_name ()) n3
      and add = gen_times (resource_record ~name:const_name ()) n4
      in
      make_packet ~header:hdr ~query:qry ~answer:ans ~authority:aut ~additional:add ());;
