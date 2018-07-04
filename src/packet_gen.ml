(*Useful tools for generation*)

let empty_gen = Crowbar.const "";;

let rec truncate list length =
  let rec aux acc n list = match (n,list) with
    |(k,_) when (k >= length) -> acc
    |(_,[]) -> acc
    |(k,t::q) -> aux (acc@[t]) (k+1) q
  in aux [] 0 list;;

let prepend_zero string length =
  let rec aux acc n = match n with
    |k when k <=0 -> acc
    |k -> aux ("0"^acc) (k-1)
  in
  let strlen = String.length string in
  aux string (length-strlen);;
  

(*One byte string generator in hexadecimal form.*)
let hex = Crowbar.map [Crowbar.range 255] @@ (fun a ->
    let str = Printf.sprintf "%x" a in
    prepend_zero str 2);;

let hex_range ?(min=0) ?(nb_bytes=1) n =
  (*if (min < 0) || ((min+n) > 2^(nb_bytes*8) then raise (Failure "Bad hex range");*) (*This check should be done if a proper power function exists *)
  Crowbar.map [Crowbar.range ~min:min n] @@ (fun a ->
      let str = Printf.sprintf "%x" a in
      prepend_zero str (2*nb_bytes)
  );;

let hex_const ?(nb_bytes=1) n =
  let str = Printf.sprintf "%x" n in (*It can lack some zeros*)
  Crowbar.const @@ prepend_zero str (2*nb_bytes);; 
  

     
(*[hex_concat bytes1 bytes2] returns a string Crowbar.gen made of two
concatenated string Crowbar.gen generators*)
let hex_concat a b = Crowbar.map [a;b] @@ (fun a b -> a^b);;

(*[hex_concat_list [gen1; gen2;...; genN] returns a string Crowbar.gen
made of the concatenated gen list *)
let hex_concat_list list =
  let rec aux acc list = match list with
    |[] -> acc
    |t::q -> aux (hex_concat acc t) q
  in
  aux empty_gen list;;

let gen_times gen n =
  let rec aux acc k = match k with
    |k when k <= 0 -> acc
    |k -> aux (hex_concat acc gen) (k-1)
  in
  aux empty_gen n;;


(*[hex_times n] returns a string Crowbar.gen made of n byte generators*)
let hex_times n = gen_times hex n;;


(*---- Header generation ----*)

let idcounter = ref 0;;
let id = Crowbar.map [empty_gen] @@ (fun _ ->
    incr idcounter;
    let str = Printf.sprintf "%x" !idcounter in
    prepend_zero str 4);;

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
    

let const_qdcount n = hex_const ~nb_bytes:2 n;;
let const_ancount n = hex_const ~nb_bytes:2 n;;
let const_aacount n = hex_const ~nb_bytes:2 n;;
let const_arcount n = hex_const ~nb_bytes:2 n;;

let make_header ?(id=id) ?(flags_and_codes=flags_and_codes ()) ?(qdcount=hex_times 2) ?(ancount=hex_times 2) ?(aacount=hex_times 2) ?(arcount=hex_times 2) () =
  hex_concat_list [id;flags_and_codes;qdcount;ancount;aacount;arcount];;


(*---- Name generation ----*)


(*[valid_label length] returns a string Crowbar.gen as hex, truncated to less than {! length} (RFC restricts length to be <=63)
Hex-wise, a label consists of a series of bytes of variable length, with the length as a prefix.
To prevent parsing errors, the last byte is non zero.*)
let valid_label length = Crowbar.map [Crowbar.list1 hex;hex_range ~min:1 255] @@ (fun list last ->
    let list = truncate list (length-1) in
    let shortlen = Printf.sprintf "%x" (List.length list + 1) in
    let length = prepend_zero shortlen 2 in
    String.concat "" (length::list@[last]));;

(*[long_label] returns a byte generator without length restriction.
To prevent parsing errors, the penultimate byte is non zero. *)
let long_label = Crowbar.map [Crowbar.list1 hex;hex_range ~min:1 255] @@ (fun list last ->
    let shortlen = Printf.sprintf "%x" (List.length list + 1) in
    let length = prepend_zero shortlen 2 in
    String.concat "" (length::list@[last]));;


let corrupted_label = hex_range ~min:64 128;;

let pointer_label = hex_concat (hex_range ~min:192 63) hex;;

let label_times length n =
  let rec aux acc n = match n with
    |0 -> acc
    |n -> aux (hex_concat acc (valid_label length)) (n-1)
  in aux (empty_gen) n;;


(*[valid_name] returns a domain name generator with length restriction.
The number of labels is arbitrarily chosen to four.*)
let valid_name = Crowbar.dynamic_bind (Crowbar.range 63) @@ fun length ->
       hex_concat_list [valid_label length;valid_label length;valid_label length;valid_label length;Crowbar.const "00"];;


(*[long_name] returns a domain name as a string list without length restriction*)
let long_name = Crowbar.map [Crowbar.list1 long_label] @@ (fun l ->
    String.concat "" (l@["00"]));;
  

let longer_name = hex_concat (label_times 1 2000) (Crowbar.const "00");;

let corrupted_name = Crowbar.map [Crowbar.list1 corrupted_label] @@ (fun l ->
    String.concat "" l);;


let pointer_name = Crowbar.map [Crowbar.list1 pointer_label] @@ fun l ->
  String.concat "" l;;


(*FOO.MY.DOMAIN*)
let const_name = Crowbar.const "03464f4f024d5906444f4d41494e00";;

let const_name = Crowbar.const "03666f6f026d7906646f6d61696e00";;

let valid_qtype = Crowbar.choose [
    hex_range ~nb_bytes:2 ~min:1 53;
    hex_range ~nb_bytes:2 ~min:55 7;
    hex_range ~nb_bytes:2 ~min:99 10;
    hex_range ~nb_bytes:2 ~min:249 10;
    hex_const 32768;
    hex_const 32769
  ]
;;

let qclass = hex_times 2;;
let valid_qclass = Crowbar.const "0001";;

let make_query ?(qtype=valid_qtype) ?(qclass=valid_qclass) ?(name=valid_name) () = hex_concat_list [name;qtype;qclass];;

let valid_query = make_query ~name:valid_name ();;
let long_query = make_query ~name:long_name ();;
let longer_query = make_query ~name:longer_name ();;
let corrupted_query = make_query ~name:corrupted_name ();;
let pointer_query = make_query ~name:pointer_name ();;
let const_query = make_query ~name:const_name ();;



(*RESOURCE RECORD GENERATION*)


let valid_rrtype = Crowbar.choose [
    hex_range ~nb_bytes:2 62;
    hex_range ~nb_bytes:2 ~min:99 10;
    hex_range ~nb_bytes:2 ~min:249 10;
    hex_const 32768;
    hex_const 32769
  ]
;;

let valid_rrclass = hex_const ~nb_bytes:2 1;;

let ttl = hex_const ~nb_bytes:4 65535 ;;

let const_rdlength_and_rdata =
  let const_rdlength = hex_const ~nb_bytes:2 4
  and const_rdata = Crowbar.const "7f000001" in
  hex_concat const_rdlength const_rdata;;

let valid_rdlength_and_rdata =
  let valid_rdlength = hex_const ~nb_bytes:2 4
  and valid_rdata = hex_times 4 in
  hex_concat valid_rdlength valid_rdata;;


let resource_record ?(rrtype=valid_rrtype) ?(rrclass=valid_rrclass) ?(rdlength_and_rdata=valid_rdlength_and_rdata) ?(name=valid_name) () = hex_concat_list [name; rrtype; rrclass; ttl; rdlength_and_rdata];;


(*PACKET GENERATION*)

let make_packet ?(header=make_header ()) ?(query=make_query ()) ?(answer=resource_record ()) ?(authority=resource_record ()) ?(additional=resource_record ()) () =
  hex_concat_list [header;query;answer;authority;additional];;

let query_packet =
  Crowbar.dynamic_bind (Crowbar.range 500) (fun n ->
      let f_and_c = flags_and_codes ~opcode:(Crowbar.const 0) ~rcode:(Crowbar.range 10) () in
      let hdr = make_header ~qdcount:(const_qdcount n) ~ancount:(const_ancount 0) ~aacount:(const_aacount 0) ~arcount:(const_arcount 0) ~flags_and_codes:f_and_c () in
      let qry = gen_times (make_query ~name:const_name ()) n in
      make_packet ~header:hdr ~query:qry ~answer:empty_gen ~authority:empty_gen ~additional:empty_gen ());;


let response_packet =
  let tuple_gen = Crowbar.map [Crowbar.range 500; Crowbar.range 500; Crowbar.range 500; Crowbar.range 500] (fun a b c d -> a,b,c,d) in
  Crowbar.dynamic_bind tuple_gen (fun (n1,n2,n3,n4) ->
      let f_and_c = flags_and_codes ~opcode:(Crowbar.const 0) ~rcode:(Crowbar.range 10) () in
      let hdr = make_header ~qdcount:(const_qdcount n1) ~ancount:(const_ancount n2) ~aacount:(const_aacount n3) ~arcount:(const_arcount n4) ~flags_and_codes:f_and_c () in
      let qry = gen_times (make_query ~name:const_name ()) n1
      and ans = gen_times (resource_record ~name:const_name ()) n2
      and aut = gen_times (resource_record ~name:const_name ()) n3
      and add = gen_times (resource_record ~name:const_name ()) n4
      in
      make_packet ~header:hdr ~query:qry ~answer:ans ~authority:aut ~additional:add ());;
