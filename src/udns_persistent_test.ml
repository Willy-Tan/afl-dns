(*General test for fuzzing, raises every possible exception.*)

let main () =
  let s = read_line () in
  let testcase =
    try Some (Cstruct.of_string s)
    with
    | e -> Printf.printf "%s\n" (Printexc.to_string e); None (*Bad kind of test*)
  in
  match testcase with
  | None -> ()
  | Some cstr ->
    (match Dns_packet.decode cstr with
     | Ok (parsed,_) -> Format.printf "%a\n\n" Dns_packet.pp parsed
     | Error e -> Fmt.failwith "%a" Dns_packet.pp_err e)

let () = AflPersistent.run main;;
