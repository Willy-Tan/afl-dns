open Packet_gen;;
open Lwt.Infix;;
(*--------------------------------------------------------------------*)

(*Packet pretty-printer*)
let pp_packet ppf parsed = Crowbar.pp ppf "%s" (Dns.Dig.string_of_answers parsed);;

(*There is no way actually to print the result of a generator simply : this function helps testing generators*)
(*[gen_print printfn gen] prints 5000 values of {! gen} to stdout with {! printfn} as a string converter*)
let gen_print printfn gen = Crowbar.add_test ~name:"Generator printer" [gen] @@ fun a ->
  Printf.printf "Gen : %s\n%!" (printfn a);;

let gen_pp pp gen = Crowbar.add_test ~name:"Generator pretty printer" [gen] @@ fun a ->
  Format.printf "Gen : %a\n\n%!" pp a;;

let log_warn s = Printf.eprintf "WARN: %s\n%!" s

(*--------------------------------------------------------------------*)

(*packet marshalling and parsing test*)

let counter = ref 1;;

let odns_packet_test packet =
  Crowbar.add_test ~name:"Packet generation" [packet] @@ (fun packet ->
      try
        let cstr = Cstruct.of_hex packet in
        let packet = Dns.Packet.parse cstr in
        Printf.printf "%s\n\n" @@ Dns.Dig.string_of_answers packet
      with
      | e -> Printf.printf "%s\n%s\n" (Printexc.to_string e) (Printexc.get_backtrace ()))
     ;;

let udns_packet_test packet =
  Crowbar.add_test ~name:"Udns packet generation" [packet] @@ (fun packet ->
      let cstr =
      try
        Cstruct.of_hex packet
      with
      | e -> Printf.printf "%s\n%s\n%!" (Printexc.to_string e) (Printexc.get_backtrace ());raise e
      in
      let packet = Dns_packet.decode cstr in
      match packet with
      | Ok (p,_) -> Format.printf "%a\n\n%!" Dns_packet.pp p; Crowbar.check true
      | Error e -> Format.printf "%a\n\n%!" Dns_packet.pp_err e;
                    Crowbar.check true)
     ;;

(*Copied thoroughly from Dns_Resolver_unix.ml from ocaml-dns*)
let sockaddr addr port =
  Lwt_unix.(ADDR_INET (Ipaddr_unix.to_inet_addr addr, port));;
    
let outfd addr port =
  let fd = Lwt_unix.(socket PF_INET SOCK_DGRAM 17) in
  Lwt_unix.(bind fd (sockaddr addr port)) >>= fun () ->
  Lwt.return fd;;

let currentfd () = outfd Ipaddr.(V4 V4.any) 0;;

let closefd fd = Lwt.catch (fun () -> Lwt_unix.close fd) (fun e -> log_warn (Printf.sprintf "%s\n%!" (Printexc.to_string e)); Lwt.return_unit);;

let dest = sockaddr (Ipaddr.of_string_exn "127.0.0.1") 53;;


let send_packet cstr ofd =
  (Cstruct.(Lwt_bytes.sendto ofd cstr.buffer cstr.off cstr.len [] dest)
   >>= fun _ -> Lwt.return_unit);;


let send_only ?(packet=query_packet) () = 
  Crowbar.add_test ~name:"Packet send" [packet] @@ (fun packet ->
      let cstr = Cstruct.of_hex packet in
      Lwt_main.run (currentfd () >>= fun ofd -> send_packet cstr ofd));;

let odns_parse buf =
  let recv_id = Bytes.create 2 in
  Cstruct.blit_to_bytes buf 0 recv_id 0 2;
  (*if (Bytes.equal id recv_id) then
    None
    else*)
    Some (Dns.Packet.parse buf);;

let udns_parse buf =
  let recv_id = Bytes.create 2 in
  Cstruct.blit_to_bytes buf 0 recv_id 0 2;
  (*if (Bytes.equal id recv_id) then
    None
    else*)
  match Dns_packet.decode buf with
  |Error e -> Fmt.failwith "%a" Dns_packet.pp_err e
  |Ok (pkt,_) -> Some pkt
;;


let rec receive parse ofd =
  let buf = Cstruct.create 4096 in
  Cstruct.(Lwt_bytes.recvfrom ofd buf.buffer buf.off buf.len [])
  >>= fun (len, _) ->
  let buf = Cstruct.sub buf 0 len in
  match parse buf with
  | None -> receive parse ofd
  | Some r -> closefd ofd >>= fun _ -> Lwt.return r;;


let odns_send_and_receive ?(packet=query_packet) () =
  Crowbar.add_test ~name:"odns send and receive" [packet] @@ (fun packet ->
      (*Create packet and get ID*)
      let cstr = Cstruct.of_hex packet in
      let id = Bytes.create 2 in
      Cstruct.blit_to_bytes cstr 0 id 0 2;
      let recv_pkt = 
        Lwt_main.run (currentfd () >>= (fun ofd -> send_packet cstr ofd >>=
                                         fun _ -> receive odns_parse ofd)) in
      Printf.printf "============================================================\n\n%!";
      Printf.printf "Packet :\n\n%s\n\n%!"@@ Dns.Dig.string_of_answers (Dns.Packet.parse cstr);
      Printf.printf "Answer:\n\n%s\n\n%!" @@ Dns.Dig.string_of_answers recv_pkt;
      Crowbar.check true)

let udns_send_and_receive ?(packet=query_packet) () =
  Crowbar.add_test ~name:"udns send and receive" [packet] @@ (fun packet ->
      (*Create packet and get ID*)
      let cstr = Cstruct.of_hex packet in
      (*let id = Bytes.create 4 in
      Cstruct.blit_to_bytes cstr 0 id 0 4;
      Printf.printf "cstr length = %d\n" cstr.Cstruct.len;
        Printf.printf "id = %s\n\n%!" @@ Bytes.to_string id;*)
      let send_pkt = match Dns_packet.decode cstr with
      |Ok (p,_) -> p
      |Error e -> Format.printf "%a\n\n%!" Dns_packet.pp_err e;Crowbar.bad_test () in
      Printf.printf "============================================================\n\n%!";
        Format.printf "Packet :\n\n%a\n\n%!" Dns_packet.pp send_pkt;
      let recv_pkt =
        Lwt_main.run (currentfd () >>= (fun ofd -> send_packet cstr ofd >>=
                                         fun _ -> receive udns_parse ofd)) in
      Format.printf "Answer:\n\n%a\n\n%!" Dns_packet.pp recv_pkt);;


let () =
  udns_send_and_receive ~packet:response_packet ();;
