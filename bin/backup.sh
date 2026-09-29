#!/bin/bash
# /home을 /backup에 보관하고 /backup/backup.log를 덮어씁니다. 대상 용량과 권한을 확인한 뒤 실행하세요.

cd /home
tar cvzf /backup/home_$(date +%m%d_%H%M%S).tar.gz . > /backup/backup.log 2>&1

