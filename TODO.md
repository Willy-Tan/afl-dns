====
TODO
====

IMPORTANT :
- Use Crowbar instead of AflPersistent


For ocaml-dns :
- Current crashes/should-be-crashes pinpointed by afl-fuzz on Dns_packet.parse :
	- Check if somewhere there is a test on the cstruct validity (Cstruct failures)
	- Check if somewhere there is a test on alphanumeric/hyphens (some domain names 
	containing non-conform chars are going through)

- After having a nice set of testcases made from fuzzing the parser, fuzz :
	- The resolver
	- The server lookup

------------------------------------------------------------------------------------------------

For udns :
- DONE : Try to make afl-fuzz understand what is a crash and what isn't (monad type handling).
- DONE : Cleanup the crash folder (on_hex raising errors)
	-> Filtering done on the script 
- After having a nice set of testcases made from fuzzing the parser, fuzz :
	- The resolver
	- The server lookup


------------------------------------------------------------------------------------------------


- As afl creates input that doesn't raise crashes, add an erasing block for the /queue directory
  on the .sh scripts
