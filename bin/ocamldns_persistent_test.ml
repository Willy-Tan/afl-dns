(*General test for fuzzing, raises every possible exception.*)

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
    Printf.printf "%s\n\n" (Dns.Dig.string_of_answers (Dns.Packet.parse (Dns.Packet.marshal ((Dns.Packet.parse cstr)))));;

let () = AflPersistent.run main;;

