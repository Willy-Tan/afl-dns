# Fuzzing different dns implementations

## Introduction

This is a small attempt at fuzzing different dns implementations (ocaml-dns and udns).

For now, fuzzing is done on the packet parser to see what goes through and what doesn't.

Because it takes a long time for the fuzzer to go from a valid query packet to a valid
response packet, I have decided to launch two fuzzers.

In the long term, both should have some similar test cases in 
```./[DNS_implementation]_test/forAFL/*_output/queue```.

I don't know yet if it is coherent to do so.


## Scripts

To start the fuzzers, execute 
```./launch_afl.sh``` which launches two afl-fuzzers,
one on query packet types, one on response packet types.

Execute ```./pp_queue.sh``` to print in ```log/valid/valid_query.txt``` and ```log/valid/valid_response.txt```
what the parser reads from the valid corpora made by afl-fuzz.

Execute ```./pp_crashes.sh``` to print in ```log/crashes/crashes_query.txt``` and 
```log/crashes/crashes_response.txt``` what the parser raises as an error from the crashes corpora
made by afl-fuzz.

## Made by

* **TAN Willy**