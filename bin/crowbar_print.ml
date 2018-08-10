let odns_packet_readonly ~packet =
  Crowbar.add_test ~name:"odns packet readonly" [packet] (fun bin ->
      let cstr = Cstruct.of_hex bin in
      let pkt = Dns.Packet.parse cstr in
      Printf.printf "%s\n\n" @@ Dns.Dig.string_of_answers pkt);;

let udns_packet_readonly ~packet = 
  Crowbar.add_test ~name:"udns packet readonly" [packet] (fun bin ->
      let cstr = Cstruct.of_hex bin in
      let pkt = match Dns_packet.decode cstr with
        |Ok (p,_) -> p
        |Error e -> Format.printf "%a\n\n%!" Dns_packet.pp_err e;Crowbar.bad_test () in
        Format.printf "Packet :\n\n%a\n\n%!" Dns_packet.pp pkt);;

let () =
  udns_packet_readonly ~packet:Packet_gen.response_packet
;;
