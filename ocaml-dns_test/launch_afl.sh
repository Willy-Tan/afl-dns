#!/bin/bash



#Define directory variables

QUERY_INP=./forAFL/query_input
QUERY_OUT=./forAFL/query_output

RESPONSE_INP=./forAFL/response_input
RESPONSE_OUT=./forAFL/response_output

AFLTEST=./_build/install/default/bin/afltest

ASK_QUERY="foo"
ASK_RESPONSE="bar"

#Test if some query output already exists


if [ -n "$(ls -A $QUERY_OUT)" ]
then
	while [ $ASK_QUERY != "Y" ] && [ $ASK_QUERY != "n" ]
	do
		read -p "Some data already exists in the query output folder, would you like to resume afl on it ? (Y/n) " ASK_QUERY
		if [ $ASK_QUERY != "Y" ] && [ $ASK_QUERY != "n" ]
		then
			printf "You didn't write Y or n...\n"
		fi
	done

	if [ $ASK_QUERY = "Y" ]
	then
		printf "Precedent query-type fuzzing will be resumed. \n\n"
	else
		printf "Old data will be erased. \n\n"
	fi
fi

#Test if some response output already exists

if [ -n "$(ls -A $RESPONSE_OUT)" ]
then
	while [ $ASK_RESPONSE != "Y" ] && [ $ASK_RESPONSE != "n" ]
	do
		read -p "Some data already exists in the response output folder, would you like to resume afl on it ? (Y/n) " ASK_RESPONSE
		if [ $ASK_RESPONSE != "Y" ] && [ $ASK_RESPONSE != "n" ]
		then
			printf "You didn't write Y or n...\n"
		fi
	done

	if [ $ASK_RESPONSE = "Y" ]
	then
		printf "Precedent RESPONSE-type fuzzing will be resumed. \n\n"
	else
		printf "Old data will be erased. \n\n"
	fi
fi


#Query-type fuzzing

if [ $ASK_QUERY == "foo" ] || [ $ASK_QUERY = "n" ]
then
	xterm -hold -title "Query-type fuzzing" -geometry 80x25+0+0 -fa monospace -fs 9 -e "afl-fuzz -i $QUERY_INP -o $QUERY_OUT $AFLTEST " &
else
	xterm -hold -title "Query-type fuzzing" -geometry 80x25+0+0 -fa monospace -fs 9 -e "afl-fuzz -i - -o $QUERY_OUT $AFLTEST " &
fi	

#Response-type fuzzing

if [ $ASK_RESPONSE == "bar" ] || [ $ASK_RESPONSE == "n" ]
then
	xterm -hold -title "Response-type fuzzing" -geometry 80x25+800+0 -fa monospace -fs 9 -e "afl-fuzz -i $RESPONSE_INP -o $RESPONSE_OUT $AFLTEST " &
else
	xterm -hold -title "Response-type fuzzing" -geometry 80x25+800+0 -fa monospace -fs 9 -e "afl-fuzz -i - -o $RESPONSE_OUT $AFLTEST " &
fi 
