(*Inspired by what Hannes did*)

let main () =
  (*Get input from file*)
  let s = read_line () in
  let testcase =
    try Some (Cstruct.of_hex s)
    with
    | _ -> None
  in
  match testcase with
  |None -> ()
  |Some cstr ->
    match Dns_packet.decode cstr with
    | Ok (packet, n) -> Format.printf "%a\n\n" Dns_packet.pp packet
    | Error e -> Fmt.failwith "%a" Dns_packet.pp_err e

;;


let () = AflPersistent.run main;;
