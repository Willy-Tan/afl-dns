#!/bin/bash

#This script creates log files containing what the parser reads from 
#the valid corpora made by afl-fuzz. 



#-----------------------------------------------------------------------


#Define variables 

set -u

#Executables

PERS_ODNS_TEST=./_build/install/default/bin/ocamldns_persistent_test
PERS_UDNS_TEST=./_build/install/default/bin/udns_persistent_test
CROW_TEST=./_build/install/default/bin/crowbar_test

#Persistent variables

PERS_ODNS_OUTPUT=forAFL/persistent_output/odns_output/*
PERS_UDNS_OUTPUT=forAFL/persistent_output/udns_output/*

PERS_VALID_ODNS_LOG=log/valid/persistent_valid_odns.txt
PERS_VALID_UDNS_LOG=log/valid/persistent_valid_udns.txt

PERS_HANGS_ODNS_LOG=log/hangs/persistent_hangs_odns.txt
PERS_HANGS_UDNS_LOG=log/hangs/persistent_hangs_udns.txt

PERS_CRASHES_ODNS_LOG=log/crashes/persistent_crashes_odns.txt
PERS_CRASHES_UDNS_LOG=log/crashes/persistent_crashes_udns.txt

#Crowbar variables

CROW_ODNS_OUTPUT=forAFL/crowbar_output/odns_output
CROW_UDNS_OUTPUT=forAFL/crowbar_output/udns_output

CROW_VALID_ODNS_LOG=log/valid/crowbar_valid_odns.txt
CROW_VALID_UDNS_LOG=log/valid/crowbar_valid_udns.txt

CROW_HANGS_ODNS_LOG=log/hangs/crowbar_hangs_odns.txt
CROW_HANGS_UDNS_LOG=log/hangs/crowbar_hangs_udns.txt

CROW_CRASHES_ODNS_LOG=log/crashes/crowbar_crashes_odns.txt
CROW_CRASHES_UDNS_LOG=log/crashes/crowbar_crashes_udns.txt

BUFFER=tmp.txt



#-----------------------------------------------------------------------

if [ ! -d log ]; then
    mkdir log
    mkdir log/valid
    mkdir log/crashes
    mkdir log/hangs
fi


#------------------------- PERSISTENT FILES ----------------------------

#-------------------------- ocaml-dns log ------------------------------

#------------------------------ VALID ----------------------------------

echo -e "This file contains what the parser reads from the ocaml-dns valid corpora made by afl-fuzz.\n\n\n" > $PERS_VALID_ODNS_LOG
echo -e "Printing valid input log for ocaml-dns..."
for d in $PERS_ODNS_OUTPUT; do
	echo -e "Going into $d..."
	QUEUE="${d}/queue"
	TOTAL="$(ls -1q "$QUEUE" | wc -l)"
	COUNTER=0
	for f in $QUEUE/*; do
		((COUNTER++))
		echo -ne "Processing valid files... (${COUNTER}/${TOTAL})\r"
		cat $f | $PERS_ODNS_TEST &> $BUFFER
		if [ -s $BUFFER ];then
			echo -e "Reading file :" $f >> $PERS_VALID_ODNS_LOG
			echo -e "Content : $(cat $f)" >> $PERS_VALID_ODNS_LOG
			cat $BUFFER >> $PERS_VALID_ODNS_LOG
			echo -e "\n" >> $PERS_VALID_ODNS_LOG
		fi	
	done
	echo ""
done
echo ""

#----------------------------- HANGS ----------------------------------

echo -e "This file contains what the parser reads from the ocaml-dns hangs corpora made by afl-fuzz.\n\n\n" > $PERS_HANGS_ODNS_LOG
echo -e "Printing hangs input log for ocaml-dns..."
for d in $PERS_ODNS_OUTPUT; do
	echo -e "Going into $d..."
	HANGS="${d}/hangs"
	TOTAL="$(ls -1q "$HANGS" | wc -l)"
	COUNTER=0
	for f in $HANGS/*; do
		((COUNTER++))
		echo -ne "Processing hanging files... (${COUNTER}/${TOTAL})\r"
		cat $f | $PERS_ODNS_TEST &> $BUFFER
		if [ -s $BUFFER ];then
			echo -e "Reading file :" $f >> $PERS_HANGS_ODNS_LOG
			echo -e "Content : $(cat $f)" >> $PERS_HANGS_ODNS_LOG
			cat $BUFFER >> $PERS_HANGS_ODNS_LOG
			echo -e "\n" >> $PERS_HANGS_ODNS_LOG
		fi	
	done
	echo ""
done
echo ""

#---------------------------- CRASHES ----------------------------------

echo -e "This file contains what the parser reads from the ocaml-dns crashes corpora made by afl-fuzz.\n\n\n" > $PERS_CRASHES_ODNS_LOG
echo -e "Printing crashes input log for ocaml-dns..."
for d in $PERS_ODNS_OUTPUT; do
	echo -e "Going into $d..."
	CRASHES="${d}/crashes"
	TOTAL="$(ls -1q "$CRASHES" | wc -l)"
	COUNTER=0
	for f in $CRASHES/*; do
		((COUNTER++))
		echo -ne "Processing crash files... (${COUNTER}/${TOTAL})\r"
		cat $f | $PERS_ODNS_TEST &> $BUFFER
		if [ -s $BUFFER ];then
			echo -e "Reading file :" $f >> $PERS_CRASHES_ODNS_LOG
			echo -e "Content : $(cat $f)" >> $PERS_CRASHES_ODNS_LOG
			cat $BUFFER >> $PERS_CRASHES_ODNS_LOG
			echo -e "\n" >> $PERS_CRASHES_ODNS_LOG
		fi	
	done
	echo ""
done
echo ""

#--------------------------- µDNS log ---------------------------------

#---------------------------- VALID -----------------------------------

echo -e "This file contains what the parser reads from the udns valid corpora made by afl-fuzz.\n\n\n" > $PERS_VALID_UDNS_LOG
echo -e "Printing valid input log for µDNS..."
for d in $PERS_UDNS_OUTPUT; do
	echo -e "Going into $d..."
	QUEUE="${d}/queue"
	TOTAL="$(ls -1q "$QUEUE" | wc -l)"
	COUNTER=0
	for f in $QUEUE/*; do
		((COUNTER++))
		echo -ne "Processing valid files... (${COUNTER}/${TOTAL})\r"
		cat $f | $PERS_UDNS_TEST &> $BUFFER
		if [ -s $BUFFER ];then
			echo -e "Reading file :" $f >> $PERS_VALID_UDNS_LOG
			echo -e "Content : $(cat $f)" >> $PERS_VALID_UDNS_LOG
			cat $BUFFER >> $PERS_VALID_UDNS_LOG
			echo -e "\n" >> $PERS_VALID_UDNS_LOG
		fi	
	done
	echo ""
done
echo ""

#----------------------------- HANGS ----------------------------------

echo -e "This file contains what the parser reads from the µDNS hangs corpora made by afl-fuzz.\n\n\n" > $PERS_HANGS_UDNS_LOG
echo -e "Printing hangs input log for ocaml-dns..."
for d in $PERS_UDNS_OUTPUT; do
	echo -e "Going into $d..."
	HANGS="${d}/hangs"
	TOTAL="$(ls -1q "$HANGS" | wc -l)"
	COUNTER=0
	for f in $HANGS/*; do
		((COUNTER++))
		echo -ne "Processing hanging files... (${COUNTER}/${TOTAL})\r"
		cat $f | $PERS_UDNS_TEST &> $BUFFER
		if [ -s $BUFFER ];then
			echo -e "Reading file :" $f >> $PERS_HANGS_UDNS_LOG
			echo -e "Content : $(cat $f)" >> $PERS_HANGS_UDNS_LOG
			cat $BUFFER >> $PERS_HANGS_UDNS_LOG
			echo -e "\n" >> $PERS_HANGS_UDNS_LOG
		fi	
	done
	echo ""
done
echo ""


#---------------------------- CRASHES ---------------------------------

echo -e "This file contains what the parser reads from the µDNS crashes corpora made by afl-fuzz.\n\n\n" > $PERS_CRASHES_UDNS_LOG
echo -e "Printing crashes input log for µDNS..."
for d in $PERS_UDNS_OUTPUT; do
	echo -e "Going into $d..."
	CRASHES="${d}/crashes"
	TOTAL="$(ls -1q "$CRASHES" | wc -l)"
	COUNTER=0
	for f in $CRASHES/*; do
		((COUNTER++))
		echo -ne "Processing crash files... (${COUNTER}/${TOTAL})\r"
		cat $f | $PERS_UDNS_TEST &> $BUFFER
		if [ -s $BUFFER ];then
			echo -e "Reading file :" $f >> $PERS_CRASHES_UDNS_LOG
			echo -e "Content : $(cat $f)" >> $PERS_CRASHES_UDNS_LOG
			cat $BUFFER >> $PERS_CRASHES_UDNS_LOG
			echo -e "\n" >> $PERS_CRASHES_UDNS_LOG
		fi	
	done
	echo ""
done


rm -f $BUFFER
