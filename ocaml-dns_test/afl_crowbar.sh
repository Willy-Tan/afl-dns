#!/bin/bash



#Define directory variables

INP=./forAFL/query_input
OUT=./forAFL/crowbar_output

AFLTEST=./_build/install/default/bin/crowbar_test

ASK="foo"

#Test if some query output already exists


if [ -n "$(ls -A $OUT)" ]
then
	while [ $ASK != "Y" ] && [ $ASK != "n" ]
	do
		read -p "Some data already exists in the output folder, would you like to resume afl on it ? (Y/n) " ASK
		if [ $ASK != "Y" ] && [ $ASK != "n" ]
		then
			printf "You didn't write Y or n...\n"
		fi
	done

	if [ $ASK = "Y" ]
	then
		printf "Precedent query-type fuzzing will be resumed. \n\n"
	else
		printf "Old data will be erased. \n\n"
	fi
fi


#Query-type fuzzing

if [ $ASK == "foo" ] || [ $ASK = "n" ]
then
	xterm -hold -title "Query-type fuzzing" -geometry 80x25+0+0 -fa monospace -fs 13 -e "afl-fuzz -m 4000 -i $INP -o $OUT $AFLTEST @@" &
else
	xterm -hold -title "Query-type fuzzing" -geometry 80x25+0+0 -fa monospace -fs 13 -e "afl-fuzz -m 4000 -i - -o $OUT $AFLTEST @@" &
fi	