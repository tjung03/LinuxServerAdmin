#!/bin/bash

echo "+------------------------------------------+"
echo "| Control-C will terminate cpu3.sh process.|"
echo "+------------------------------------------+"

trap 'killall cpu.sh ; exit 1' 2 3

./cpu.sh & 
sleep 10
./cpu.sh & 
sleep 10
