#!/bin/bash

set -eu

#------------------------------------------------------------------------------------------


#Define variables

ODNS_PATH="forAFL/persistent_output/odns_output"
UDNS_PATH="forAFL/persistent_output/udns_output"
CROW_PATH="forAFL/crowbar_output"

ODNS_EXE="_build/install/default/bin/ocamldns_persistent_test"
UDNS_EXE="_build/install/default/bin/udns_persistent_test"
CROW_EXE="_build/install/default/bin/crowbar_test"

QUEUE_ALL="queue_all"
QUEUE_CMIN="queue_cmin"
QUEUE_PTMIN="queue_ptmin"

AFL_CMIN=afl-cmin
AFL_PTMIN="scripts/afl-ptmin.sh"



#------------------------------------------------------------------------------------------


#Create temporary directories to hold queue files

if [ ! -d $QUEUE_ALL ]; then
    mkdir $QUEUE_ALL
fi

if [ ! -d $QUEUE_CMIN ]; then
    mkdir $QUEUE_CMIN
fi

if [ ! -d $QUEUE_PTMIN ]; then
    mkdir $QUEUE_PTMIN
fi


#------------------------------------------------------------------------------------------


#Start with ocaml-dns

for FUZZER in $ODNS_PATH/*; do
    if [ -d $FUZZER ]; then
	#Copy queue files from fuzzers
	cp -v $FUZZER/queue/* $QUEUE_ALL
	
	#Minimize with afl-cmin first
	$AFL_CMIN -i $QUEUE_ALL -o $QUEUE_CMIN -- $ODNS_EXE
	
	#Then minimize with a parallelized afl-tmin
	$AFL_PTMIN 8 $QUEUE_CMIN $QUEUE_PTMIN $ODNS_EXE

	#Copy back the files to the corresponding fuzzers after having removed them
	rm $FUZZER/queue/*
	cp -v $QUEUE_PTMIN/* $FUZZER/queue
	
	#Cleanup folders
	rm $QUEUE_ALL/*
	rm $QUEUE_CMIN/*
	rm $QUEUE_PTMIN/*
	
    fi
done

#-----------------------------------------------------------------------------------------


#Now for udns

for FUZZER in $UDNS_PATH/*; do
    if [ -d $FUZZER ]; then
	#Copy queue files from fuzzers
	cp -v $FUZZER/queue/* $QUEUE_ALL
	
	#Minimize with afl-cmin first
	$AFL_CMIN -i $QUEUE_ALL -o $QUEUE_CMIN -- $UDNS_EXE
	
	#Then minimize with a parallelized afl-tmin
	$AFL_PTMIN 8 $QUEUE_CMIN $QUEUE_PTMIN $UDNS_EXE

	#Copy back the files to the corresponding fuzzers after having removed them
	rm $FUZZER/queue/*
	cp -v $QUEUE_PTMIN/* $FUZZER/queue
	
	#Cleanup folders
	rm $QUEUE_ALL/*
	rm $QUEUE_CMIN/*
	rm $QUEUE_PTMIN/*
    fi
done

#-----------------------------------------------------------------------------------------


#Finally, for Crowbar

for FUZZER in $CROW_PATH/*; do
    if [ -d $FUZZER ]; then
	#Copy queue files from fuzzers
	cp -v $FUZZER/queue/* $QUEUE_ALL
	
	#Minimize with afl-cmin first
	$AFL_CMIN -i $QUEUE_ALL -o $QUEUE_CMIN -- $UDNS_EXE
	
	#Then minimize with a parallelized afl-tmin
	$AFL_PTMIN 8 $QUEUE_CMIN $QUEUE_PTMIN $UDNS_EXE

	#Copy back the files to the corresponding fuzzers after having removed them
	rm $FUZZER/queue/*
	cp -v $QUEUE_PTMIN/* $FUZZER/queue
	
	#Cleanup folders
	rm $QUEUE_ALL/*
	rm $QUEUE_CMIN/*
	rm $QUEUE_PTMIN/*
    fi
done

#-----------------------------------------------------------------------------------------


#Erase folders

rm -rf $QUEUE_ALL
rm -rf $QUEUE_CMIN
rm -rf $QUEUE_PTMIN






