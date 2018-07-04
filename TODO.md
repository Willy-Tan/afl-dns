# TODO (NOT UP TO DATE)


## IMPORTANT :
- Use Crowbar and AflPersistent : DONE
- Make a better packet generator on Crowbar : DONE
- Make a binary packet generator instead of generating from internal structures : DONE
- Use UDP to send packets through OCaml : DONE
- Write a proper script for afl minimization : DONE
- Solve dependency errors in the code : DONE
- Make proper unit tests
- Complete rfc_compliance

## For ocaml-dns :
- Current crashes/should-be-crashes pinpointed by afl-fuzz on Dns_packet.parse :
	- Check if somewhere there is a test on the cstruct validity (Cstruct failures) : DONE (no bug, only bad packets)
	- Check for pointer errors : PARTIALLY DONE
	
- After having a nice set of testcases made from fuzzing the parser, fuzz :
	- The resolver
	- The server lookup

## For udns :
- Try to make afl-fuzz understand what is a crash and what isn't (monad type handling) : DONE
- Cleanup the crash folder (on_hex raising errors) : DONE
- Check for pointer errors
- Check for NOTIFY/UPDATE packets
 
- After having a nice set of testcases made from fuzzing the parser, fuzz :
	- The resolver
	- The server lookup
