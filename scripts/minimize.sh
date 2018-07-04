#!/bin/bash

set -eu

#------------------------------------------------------------------------------------------


#Define variables

ODNS_PATH="forAFL/persistent_output/odns_output"
UDNS_PATH="forAFL/persistent_output/udns_output"

ODNS_EXE="_build/install/default/bin/ocamldns_persistent_test"
UDNS_EXE="_build/install/default/bin/udns_persistent_test"

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


#Copy queue files from fuzzers

for FUZZER in $ODNS_PATH/*; do
	if [ -d $FUZZER ]; then
		cp ${FUZZER}/queue/* $QUEUE_ALL
	fi
done

#Minimize with afl-cmin first

$AFL_CMIN -i $QUEUE_ALL -o $QUEUE_CMIN -- $ODNS_EXE

#Then minimize with a parallelized afl-tmin

$AFL_PTMIN 8 $QUEUE_CMIN $QUEUE_PTMIN $ODNS_EXE

#Copy back the files to the corresponding fuzzers after having removed them

for FUZZER in $ODNS_PATH/*; do
	if [ -d $FUZZER ]; then
		rm -rf ${FUZZER}/queue/*
		cp ${QUEUE_PTMIN}/* ${FUZZER}/queue
	fi
done

#Cleanup temporary folders

rm -rf $QUEUE_ALL/*
rm -rf $QUEUE_CMIN/*
rm -rf $QUEUE_PTMIN/*


#-----------------------------------------------------------------------------------------

#Now for udns

#Copy queue files from fuzzers

for FUZZER in $UDNS_PATH/*; do
	if [ -d $FUZZER ]; then
		cp ${FUZZER}/queue/* $QUEUE_ALL
	fi
done

#Minimize with afl-cmin first

$AFL_CMIN -i $QUEUE_ALL -o $QUEUE_CMIN -- $UDNS_EXE

#Then minimize with a parallelized afl-tmin

$AFL_PTMIN 8 $QUEUE_CMIN $QUEUE_PTMIN $UDNS_EXE

#Copy back the files to the corresponding fuzzers after having removed them

for FUZZER in $UDNS_PATH/*; do
	if [ -d $FUZZER ]; then
		rm -rf ${FUZZER}/queue/*
		cp ${QUEUE_PTMIN}/* ${FUZZER}/queue
	fi
done

#------------------------------------------------------------------------------------------


#Erase temporary folders

rm -rf $QUEUE_ALL
rm -rf $QUEUE_CMIN
rm -rf $QUEUE_PTMIN






