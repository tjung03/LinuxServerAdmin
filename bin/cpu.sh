#!/bin/bash

echo "+------------------------------------------+"
echo "| Control-C will terminate cpu.sh process. |"
echo "+------------------------------------------+"

START=0
END=1000000000000000000
while [ $START -le $END ]
do
        START=`expr $START + 1`
done
