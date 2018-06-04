let rec truncate list length =
  let rec aux acc n list = match (n,list) with
    |(k,_) when (k >= length) -> acc
    |(_,[]) -> acc
    |(k,t::q) -> aux (acc@[t]) (k+1) q
  in aux [] 0 list;;

let prepend_zero string length =
  let rec aux acc n = match n with
    |0 -> acc
    |k -> aux ("0"^acc) (k-1)
  in
  let strlen = String.length string in
  aux string (length-strlen);;

  

(*One byte string generator in hexadecimal form.*)
let hex = Crowbar.map [Crowbar.range 255] @@ (fun a ->
    let str = Printf.sprintf "%x" a in
    prepend_zero str 2);;

let hex_range ?(min=0) n = Crowbar.map [Crowbar.range ~min:min n] @@ (fun a ->
    let str = Printf.sprintf "%x" a
    in let length = String.length str in
    match length with
    |k when k<0 || k>2 -> raise (Failure "Bad hex range")
    |_ -> prepend_zero str 2 
  );;

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
  aux (Crowbar.const "") list;;

(*[hex_times n] returns a string Crowbar.gen made of n byte generators*)
let hex_times n =
  let rec aux acc k = match k with
    |0 -> acc
    |k -> aux (hex_concat acc hex) (k-1)
  in
  aux (Crowbar.const "") n;;




(*---- Header generation ----*)

let counter = ref 0;;
let id = Crowbar.dynamic_bind (Crowbar.const !counter) @@ (fun a ->
    incr counter;
    Crowbar.const (prepend_zero (Printf.sprintf "%x" !counter) 4));;

let flags_and_codes =
  let qr = Crowbar.range 1
  and opcode = Crowbar.range 5
  and aa = Crowbar.range 1
  and tc = Crowbar.range 1
  and rd = Crowbar.range 1
  and ra = Crowbar.range 1
  and z = Crowbar.const 0
  and rcode = Crowbar.range 10 (*Additional rcodes may be implemented soon*)
  in
  Crowbar.map [qr;opcode;aa;tc;rd;ra;z;rcode] @@ (fun qr opcode aa tc rd ra z rcode -> 
      let bin_rep =
        qr lsl 15 +
        opcode lsl 11 +
        aa lsl 10 +
        tc lsl 9 +
        rd lsl 8 +
        ra lsl 7 +
        z lsl 4 +
        rcode
      in
      let hex_rep = Printf.sprintf "%x" bin_rep in
      prepend_zero hex_rep 4)
     ;;
    
(*
let qdcount = hex_times 2;;
let ancount = hex_times 2;;
let aacount = hex_times 2;;
let arcount = hex_times 2;;
*)

let qdcount = Crowbar.const "0001";;
let ancount = Crowbar.const "0000";;
let aacount = Crowbar.const "0000";;
let arcount = Crowbar.const "0000";;

let header = hex_concat_list [id;flags_and_codes;qdcount;ancount;aacount;arcount];;



(*---- Query generation ----*)



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



(*[valid_qname] returns a domain name generator with length restriction.
The number of labels is arbitrarily chosen to four.*)
let valid_qname = Crowbar.dynamic_bind (Crowbar.range 63) @@ fun length ->
       hex_concat_list [valid_label length;valid_label length;valid_label length;valid_label length;Crowbar.const "00"];;


(*[long_qname] returns a domain name as a string list without length restriction*)
let long_qname = Crowbar.map [Crowbar.list1 long_label] @@ (fun l ->
    String.concat "" (l@["00"]));;

let label_times n =
  let rec aux acc n = match n with
    |0 -> acc
    |n -> aux (hex_concat acc (valid_label 63)) (n-1)
  in aux (Crowbar.const "") n;;
  

let longer_qname =
  Crowbar.dynamic_bind (Crowbar.range 255) @@ (fun n ->
      hex_concat (label_times n) (Crowbar.const "00"));;

let const_qname = Crowbar.const "076578616d706c6503636f6d00";;

(*let qtype = hex_times 2;; (*More guidance may be needed*)*)
let qtype = Crowbar.const "0001";;
let qclass = hex_concat (Crowbar.const "00") (hex_range ~min:1 4);;

let valid_query = hex_concat_list [header;valid_qname; qtype; qclass];;
let long_query = hex_concat_list [header;long_qname; qtype; qclass];;
let longer_query = hex_concat_list [header;longer_qname;qtype;qclass];;
let const_query = hex_concat_list [header;const_qname;qtype;qclass];;




