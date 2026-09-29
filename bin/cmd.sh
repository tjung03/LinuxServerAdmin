#!/bin/bash
# 특정 VM 주소에 전달받은 명령을 실행합니다. 대상과 명령을 확인한 뒤 사용하세요.

echo "---- main.example.com ----"
ssh 192.168.10.10 $*
echo

echo "---- server1.example.com ----"
ssh 192.168.10.20 $*
echo

echo "---- server2.example.com ----"
ssh 192.168.10.30 $*
echo
