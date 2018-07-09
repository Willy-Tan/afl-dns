#!/bin/bash

set -eu

#Define directory variables

INP=forAFL/input
OUT=forAFL/crowbar_output

EXE=_build/install/default/bin/crowbar_test

ASK="foo"


#Create folders if they don't exist

if [ ! -d $OUT ]; then
    mkdir $OUT
    mkdir $OUT/fuzzer01
fi

if [ ! -d $OUT/fuzzer01 ]; then
    mkdir $OUT/fuzzer01
fi



#Check for existing data

if [ -n "$(ls -A $OUT/fuzzer01)" ]; then
    while [ $ASK != "Y" ] && [ $ASK != "n" ]; do
	read -p "Some data already exists in the odns output folder, would you like to resume afl on it ? (Y/n) " ASK
	if [ $ASK != "Y" ] && [ $ASK != "n" ]; then
	    printf "You didn't write Y or n...\n"
	fi
    done

    if [ $ASK = "Y" ]; then
	printf "Precedent ocaml-dns fuzzing will be resumed. \n\n"
    else
	printf "Old data will be erased. \n\n"
	rm -rf $OUT/fuzzer0*/*
    fi
fi

#flags

if [ $ASK == "foo" ] || [ $ASK == "n" ]; then 
    FLAGS="-i $INP -o $OUT"
else 
    FLAGS="-i- -o $OUT"
fi	

#tmux display 


tmux new -s persistent_fuzzing -d 													
tmux bind-key -n C-c send-keys C-c Enter "tmux kill-session -t persistent_fuzzing" Enter

#split into two windows
tmux new-window -t persistent_fuzzing

#ocaml-dns splitting 
tmux split-window -v -t persistent_fuzzing:0.0
tmux split-window -h -t persistent_fuzzing:0.0
tmux split-window -h -t persistent_fuzzing:0.1

#udns splitting
tmux split-window -v -t persistent_fuzzing:1.0
tmux split-window -h -t persistent_fuzzing:1.0
tmux split-window -h -t persistent_fuzzing:1.1

#send fuzz commands to tmux 
tmux send-keys -t persistent_fuzzing:0.0 "afl-fuzz $FLAGS -M fuzzer01 $EXE @@" C-m
tmux send-keys -t persistent_fuzzing:0.1 "afl-fuzz $FLAGS -S fuzzer02 $EXE @@" C-m
tmux send-keys -t persistent_fuzzing:0.2 "afl-fuzz $FLAGS -S fuzzer03 $EXE @@" C-m
tmux send-keys -t persistent_fuzzing:0.3 "afl-fuzz $FLAGS -S fuzzer04 $EXE @@" C-m
tmux send-keys -t persistent_fuzzing:1.0 "afl-fuzz $FLAGS -S fuzzer05 $EXE @@" C-m
tmux send-keys -t persistent_fuzzing:1.1 "afl-fuzz $FLAGS -S fuzzer06 $EXE @@" C-m
tmux send-keys -t persistent_fuzzing:1.2 "afl-fuzz $FLAGS -S fuzzer07 $EXE @@" C-m
tmux send-keys -t persistent_fuzzing:1.3 "afl-fuzz $FLAGS -S fuzzer08 $EXE @@" C-m

#attach back the session
tmux attach -t persistent_fuzzing
