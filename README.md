# Fuzzing different dns implementations in OCaml

This is a small attempt at fuzzing different dns implementations (ocaml-dns and udns). The goal is to reveal potential bugs in each implementation, and check if their behaviour is conform or not with the actual standards.

There are two ways to fuzz both implementations : 
 - a less guided fuzzing with AflPersistent, which starts with a valid DNS input and mutates this input by switching bits or bytes, by adding or erasing some fields (see http://lcamtuf.coredump.cx/afl/ for more details)
 - a more guided fuzzing with Crowbar, which uses the initial input as a seed for guided Random Number Generators which can be specified in the code itself (see https://github.com/stedolan/crowbar for more details)

Both techniques are used to test parsing functions and the server examples in each implementation.

The fuzz tests are written specifically for ocaml-dns and µDNS : the code is not suited for other implementations, although dumb fuzzing can still be done, using the ```send_only``` function defined in ```crowbar_test.ml```.

## Installation

You need ```afl-fuzz```, ```afl-tmin```, ```afl-cmin``` installed to use all the features of AflPersistent and Crowbar. Compile with the command ```dune build```.

## How to use

The Crowbar fuzzing implementation in this project is using the address ```127.0.0.1``` on port ```53```. Make sure the fuzzed server is listening to this port.

To start fuzzing, you need to have afl-fuzz and tmux installed. Then, execute ```scripts/afl_persistent.sh``` to fuzz ocaml-dns and udns with afl-persistent, or execute ```scripts/afl_crowbar.sh``` to fuzz ocaml-dns and udns with Crowbar.

/!\ There is an option to resume past fuzzing attempts if it was stopped, but you should minimize the former outputs for better performances. Most often, there are many redundant outputs, or outputs that have bits not influencing the execution path. To minimize the outputs, execute ```scripts/minimize.sh```. Beware, because minimization takes a lot of time !

Save the logs with ```scripts/log.sh```. It will print logs in the ```log``` folder.

Launch unit tests with ```_build/install/default/bin/testcases```. It will output test results in ```_build/_tests```.


## Known issues 

The scripts are written for computers with eight cores or more. Scripts may not work for computers with less than eight cores. Fuzzing may still be done without parallelization with the following commands :
- create the folders ```forAFL/persistent_output```, ```forAFL/persistent_output/odns_output```, ```forAFL/persistent_output/udns_output```, ```forAFL/crowbar_output``` if they don't exist
- fuzzing ocaml-dns with AflPersistent : ```afl-fuzz -i forAFL/input/ -o forAFL/persistent_output/odns_output/ _build/install/default/bin/ocamldns_persistent_test```
- fuzzing µDNS with AflPersistent : ```afl-fuzz -i forAFL/input/ -o forAFL/persistent_output/udns_output/ _build/install/default/bin/udns_persistent_test```
- fuzzing with Crowbar (fuzzed implementation depends of the current crowbar_test.ml file) : `afl-fuzz -i forAFL/input/ -o forAFL/crowbar_output/ _build/install/default/bin/crowbar_test @@`


