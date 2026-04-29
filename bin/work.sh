#!/bin/bash

# 로그 생성
echo "System test service" | logger -t Testsystemd
# 테스트용 데몬 실행
while true
do
	echo "Running systemd"
	sleep 30
done
