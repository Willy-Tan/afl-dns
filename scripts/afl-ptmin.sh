#!/bin/bash

#This script has been inspired by https://foxglovesecurity.com/2016/03/15/fuzzing-workflows-a-fuzz-job-from-start-to-finish/

cores=$1
inputdir=$2
outputdir=$3
pids=""
total=`ls $inputdir | wc -l`
EXE=$4
ASK=""

for k in `seq 1 $cores $total`
do
  for i in `seq 0 $(expr $cores - 1)`
  do
    file=`ls -Sr $inputdir | sed $(expr $i + $k)"q;d"`
    echo $file
    afl-tmin -i $inputdir/$file -o $outputdir/$file -- $EXE &
  done

  wait
done