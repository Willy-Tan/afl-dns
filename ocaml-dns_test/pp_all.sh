#!/bin/bash

#This script creates log files containing what the parser reads from 
#the valid corpora made by afl-fuzz. 


#--- Define variables ---

#Executables

PERS_TEST=./_build/install/default/bin/persistent_test
CROW_TEST=./_build/install/default/bin/crowbar_test


#Valid files 

#Persistent testing
PERS_VALID_QUERY_FILES=./forAFL/persistent_output/query_output/queue/*
PERS_VALID_RESPONSE_FILES=./forAFL/persistent_output/response_output/queue/*

PERS_VALID_QUERY_LOG=./log/valid/persistent_valid_query.txt
PERS_VALID_RESPONSE_LOG=./log/valid/persistent_valid_response.txt

#Crowbar testing
CROW_VALID_QUERY_FILES=./forAFL/crowbar_output/query_output/queue/*
CROW_VALID_RESPONSE_FILES=./forAFL/crowbar_output/response_output/queue/*

CROW_VALID_QUERY_LOG=./log/valid/crowbar_valid_query.txt
CROW_VALID_RESPONSE_LOG=./log/valid/crowbar_valid_response.txt


#Crashes files

#Persistent testing
PERS_CRASHES_QUERY_FILES=./forAFL/persistent_output/query_output/crashes/*
PERS_CRASHES_RESPONSE_FILES=./forAFL/persistent_output/response_output/crashes/*

PERS_CRASHES_QUERY_LOG=./log/crashes/persistent_crashes_query.txt
PERS_CRASHES_RESPONSE_LOG=./log/crashes/persistent_crashes_response.txt

#Crowbar testing
CROW_CRASHES_QUERY_FILES=./forAFL/crowbar_output/query_output/crashes/*
CROW_CRASHES_RESPONSE_FILES=./forAFL/crowbar_output/response_output/crashes/*

CROW_CRASHES_QUERY_LOG=./log/crashes/crowbar_crashes_query.txt
CROW_CRASHES_RESPONSE_LOG=./log/crashes/crowbar_crashes_response.txt

BUFFER=./tmp.txt


# --- VALID FILES ---

# PERSISTENT FILES 

#Query log

echo -e "This file contains what the parser reads from the valid query corpora made by afl-fuzz.\n\n\n" > $PERS_VALID_QUERY_LOG

for f in $PERS_VALID_QUERY_FILES
do
	
	cat $f | $PERS_TEST &> $BUFFER
	if [ -s $BUFFER ]
	then
		echo -e "Reading file :" $f >> $PERS_VALID_QUERY_LOG
		echo -e "Content : $(cat $f)" >> $PERS_VALID_QUERY_LOG
		cat $BUFFER >> $PERS_VALID_QUERY_LOG
		echo -e "\n" >> $PERS_VALID_QUERY_LOG
	fi
done


#Response log

echo -e "This file contains what the parser reads from the valid response corpora made by afl-fuzz.\n\n\n" > $PERS_VALID_RESPONSE_LOG

for f in $PERS_VALID_RESPONSE_FILES
do
	cat $f | $PERS_TEST &> $BUFFER
	if [ -s $BUFFER ]
	then
		echo -e "Reading file :" $f >> $PERS_VALID_RESPONSE_LOG
		echo -e "Content : $(cat $f)\n" >> $PERS_VALID_RESPONSE_LOG
		cat $BUFFER >> $PERS_VALID_RESPONSE_LOG
		echo -e "\n" >> $PERS_VALID_RESPONSE_LOG
	fi
done

# CROWBAR FILES

# #Query log 

# echo -e "This file contains what the parser reads from the valid query corpora made by afl-fuzz.\n\n\n" > $CROW_VALID_QUERY_LOG

# for f in $CROW_VALID_QUERY_FILES
# do
	
# 	cat $f | $CROW_TEST &> $BUFFER
# 	if [ -s $BUFFER ]
# 	then
# 		echo -e "Reading file :" $f >> $CROW_VALID_QUERY_LOG
# 		echo -e "Content : $(cat $f)" >> $CROW_VALID_QUERY_LOG
# 		cat $BUFFER >> $CROW_VALID_QUERY_LOG
# 		echo -e "\n" >> $CROW_VALID_QUERY_LOG
# 	fi
# done


# #Response log

# echo -e "This file contains what the parser reads from the valid response corpora made by afl-fuzz.\n\n\n" > $CROW_VALID_RESPONSE_LOG

# for f in $CROW_VALID_RESPONSE_FILES
# do
# 	cat $f | $CROW_TEST &> $BUFFER
# 	if [ -s $BUFFER ]
# 	then
# 		echo -e "Reading file :" $f >> $CROW_VALID_RESPONSE_LOG
# 		echo -e "Content : $(cat $f)\n" >> $CROW_VALID_RESPONSE_LOG
# 		cat $BUFFER >> $CROW_VALID_RESPONSE_LOG
# 		echo -e "\n" >> $CROW_VALID_RESPONSE_LOG
# 	fi
#done

# -------------------------------------------------------------------------------------------------------------------------------


# --- CRASHES FILES ---

#Query log

echo -e "This file contains what the parser reads from the valid query corpora made by afl-fuzz.\n\n\n" > $PERS_CRASHES_QUERY_LOG

for f in $PERS_CRASHES_QUERY_FILES
do
	
	cat $f | $PERS_TEST &> $BUFFER
	if [ -s $BUFFER ]
	then
		echo -e "Reading file :" $f >> $PERS_CRASHES_QUERY_LOG
		echo -e "Content : $(cat $f)" >> $PERS_CRASHES_QUERY_LOG
		cat $BUFFER >> $PERS_CRASHES_QUERY_LOG
		echo -e "\n" >> $PERS_CRASHES_QUERY_LOG
	fi
done


#Response log

echo -e "This file contains what the parser reads from the CRASHES response corpora made by afl-fuzz.\n\n\n" > $PERS_CRASHES_RESPONSE_LOG

for f in $PERS_CRASHES_RESPONSE_FILES
do
	cat $f | $PERS_TEST &> $BUFFER
	if [ -s $BUFFER ]
	then
		echo -e "Reading file :" $f >> $PERS_CRASHES_RESPONSE_LOG
		echo -e "Content : $(cat $f)\n" >> $PERS_CRASHES_RESPONSE_LOG
		cat $BUFFER >> $PERS_CRASHES_RESPONSE_LOG
		echo -e "\n" >> $PERS_CRASHES_RESPONSE_LOG
	fi
done


# CROWBAR FILES

# #Query log 

# echo -e "This file contains what the parser reads from the crashes query corpora made by afl-fuzz.\n\n\n" > $CROW_CRASHES_QUERY_LOG

# for f in $CROW_CRASHES_QUERY_FILES
# do
	
# 	cat $f | $CROW_TEST &> $BUFFER
# 	if [ -s $BUFFER ]
# 	then
# 		echo -e "Reading file :" $f >> $CROW_CRASHES_QUERY_LOG
# 		echo -e "Content : $(cat $f)" >> $CROW_CRASHES_QUERY_LOG
# 		cat $BUFFER >> $CROW_CRASHES_QUERY_LOG
# 		echo -e "\n" >> $CROW_CRASHES_QUERY_LOG
# 	fi
# done


# #Response log

# echo -e "This file contains what the parser reads from the crashes response corpora made by afl-fuzz.\n\n\n" > $CROW_CRASHES_RESPONSE_LOG

# for f in $CROW_CRASHES_RESPONSE_FILES
# do
# 	cat $f | $CROW_TEST &> $BUFFER
# 	if [ -s $BUFFER ]
# 	then
# 		echo -e "Reading file :" $f >> $CROW_CRASHES_RESPONSE_LOG
# 		echo -e "Content : $(cat $f)\n" >> $CROW_CRASHES_RESPONSE_LOG
# 		cat $BUFFER >> $CROW_CRASHES_RESPONSE_LOG
# 		echo -e "\n" >> $CROW_CRASHES_RESPONSE_LOG
# 	fi
# done

rm -f $BUFFER