#!/bin/bash
# 아래 고정 VM 주소에 원격 종료 명령을 보냅니다. 대상을 확인한 뒤 실행하세요.

ssh 192.168.10.10 poweroff
sleep 3

ssh 192.168.10.30 poweroff
sleep 3

ssh 192.168.10.20 poweroff
