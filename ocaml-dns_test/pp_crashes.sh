#!/bin/bash

#This script creates log files containing what the parser returns from 
#the crashes corpora made by afl-fuzz. 


#Define variables

AFLTEST=./_build/install/default/bin/afltest

QUERY_FILES=./forAFL/query_output/crashes/*
RESPONSE_FILES=./forAFL/response_output/crashes/*

QUERY_LOG=./log/crashes/crashes_query.txt
RESPONSE_LOG=./log/crashes/crashes_response.txt

BUFFER=./tmp.txt

#Query log

echo -e "This file contains what the parser reads from the crashes query corpora made by afl-fuzz.\n\n\n" > $QUERY_LOG

for f in $QUERY_FILES
do
	
	cat $f | $AFLTEST &> $BUFFER
	if [ -s $BUFFER ]
	then
		echo -e "Reading file :" $f >> $QUERY_LOG
		echo -e "Content : $(cat $f)" >> $QUERY_LOG
		cat $BUFFER >> $QUERY_LOG
		echo -e "\n" >> $QUERY_LOG
	fi
done



#Response log

echo -e "This file contains what the parser reads from the crashes response corpora made by afl-fuzz.\n\n\n" > $RESPONSE_LOG

for f in $RESPONSE_FILES
do
	cat $f | $AFLTEST &> $BUFFER
	if [ -s $BUFFER ]
	then
		echo -e "Reading file :" $f >> $RESPONSE_LOG
		echo -e "Content : $(cat $f)\n" >> $RESPONSE_LOG
		cat $BUFFER >> $RESPONSE_LOG
		echo -e "\n" >> $RESPONSE_LOG
	fi
done

rm -f $BUFFER
