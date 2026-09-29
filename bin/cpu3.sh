#!/bin/bash
# 이 스크립트는 CPU 부하 프로세스를 두 번 시작합니다. Ctrl-C의 killall은 같은 이름의 다른 cpu.sh도 종료할 수 있습니다.

echo "+------------------------------------------+"
echo "| Control-C will terminate cpu3.sh process.|"
echo "+------------------------------------------+"

trap 'killall cpu.sh ; exit 1' 2 3

./cpu.sh & 
sleep 10
./cpu.sh & 
sleep 10
