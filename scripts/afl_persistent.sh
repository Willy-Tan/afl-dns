#!/bin/bash

set -eu

#Define directory variables

INP=forAFL/input
OUT=forAFL/persistent_output
ODNS_OUT=forAFL/persistent_output/odns_output
UDNS_OUT=forAFL/persistent_output/udns_output

ODNS_EXE=_build/install/default/bin/ocamldns_persistent_test
UDNS_EXE=_build/install/default/bin/udns_persistent_test

ASK_ODNS="foo"
ASK_UDNS="bar"


#Create folders if they don't exist

if [ ! -d $OUT ]; then
    mkdir $OUT
    mkdir $ODNS_OUT
    mkdir $UDNS_OUT
fi

if [ ! -d $ODNS_OUT ]; then
    mkdir $ODNS_OUT
fi

if [ ! -d $UDNS_OUT ]; then
    mkdir $UDNS_OUT
fi



#Check for existing data

if [ -n "$(ls -A $ODNS_OUT/odns01)" ]; then
    while [ $ASK_ODNS != "Y" ] && [ $ASK_ODNS != "n" ]; do
	read -p "Some data already exists in the odns output folder, would you like to resume afl on it ? (Y/n) " ASK_ODNS
	if [ $ASK_ODNS != "Y" ] && [ $ASK_ODNS != "n" ]; then
	    printf "You didn't write Y or n...\n"
	fi
    done

    if [ $ASK_ODNS = "Y" ]; then
	printf "Precedent ocaml-dns fuzzing will be resumed. \n\n"
    else
	printf "Old data will be erased. \n\n"
    fi
fi

#Test if some udns output already exists

if [ -n "$(ls -A $UDNS_OUT/udns01)" ]; then
    while [ $ASK_UDNS != "Y" ] && [ $ASK_UDNS != "n" ]; do
	read -p "Some data already exists in the udns output folder, would you like to resume afl on it ? (Y/n) " ASK_UDNS
	if [ $ASK_UDNS != "Y" ] && [ $ASK_UDNS != "n" ]; then
	    printf "You didn't write Y or n...\n"
	fi
    done

    if [ $ASK_UDNS = "Y" ]; then
	printf "Precedent udns fuzzing will be resumed. \n\n"
    else
	printf "Old data will be erased. \n\n"
    fi
fi


#ocaml-dns flags

if [ $ASK_ODNS == "foo" ] || [ $ASK_ODNS = "n" ]; then 
    ODNS_INP_FLAG="-i $INP"
else 
    ODNS_INP_FLAG="-i-"
fi	

ODNS_MASTER_FLAGS="$ODNS_INP_FLAG -o $ODNS_OUT"
ODNS_SLAVE_FLAGS="-i $INP -o $ODNS_OUT"

#udns flags

if [ $ASK_UDNS == "bar" ] || [ $ASK_UDNS == "n" ]; then
    UDNS_INP_FLAG="-i $INP"
else
    UDNS_INP_FLAG="-i-"
fi 

UDNS_MASTER_FLAGS="$UDNS_INP_FLAG -o $UDNS_OUT"
UDNS_SLAVE_FLAGS="-i $INP -o $UDNS_OUT"

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

#send ocaml-dns fuzz commands
tmux send-keys -t persistent_fuzzing:0.0 "afl-fuzz $ODNS_MASTER_FLAGS -M odns01 $ODNS_EXE" C-m
tmux send-keys -t persistent_fuzzing:0.1 "afl-fuzz $ODNS_SLAVE_FLAGS -S odns02 $ODNS_EXE" C-m
tmux send-keys -t persistent_fuzzing:0.2 "afl-fuzz $ODNS_SLAVE_FLAGS -S odns03 $ODNS_EXE" C-m
tmux send-keys -t persistent_fuzzing:0.3 "afl-fuzz $ODNS_SLAVE_FLAGS -S odns04 $ODNS_EXE" C-m

#send udns fuzz commands
tmux send-keys -t persistent_fuzzing:1.0 "afl-fuzz $UDNS_MASTER_FLAGS -M udns01 $UDNS_EXE" C-m
tmux send-keys -t persistent_fuzzing:1.1 "afl-fuzz $UDNS_SLAVE_FLAGS -S udns02 $UDNS_EXE" C-m
tmux send-keys -t persistent_fuzzing:1.2 "afl-fuzz $UDNS_SLAVE_FLAGS -S udns03 $UDNS_EXE" C-m
tmux send-keys -t persistent_fuzzing:1.3 "afl-fuzz $UDNS_SLAVE_FLAGS -S udns04 $UDNS_EXE" C-m

#attach back the session
tmux attach -t persistent_fuzzing
