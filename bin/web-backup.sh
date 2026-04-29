#!/bin/bash

set -e

# 환경변수 정의
REMOTE_USER="backupuser"
REMOTE_HOST="server2"
REMOTE_REPO="/home/${REMOTE_USER}/borg"
ARCHIVE_NAME="$(hostname)-$(date +%Y-%m-%d_%H-%M-%S)"
BACKUP_PATHS="/etc/httpd /var/log /var/www"

# 원격 저장소 초기화 (최초 1회만 수행)
#ssh ${REMOTE_USER}@${REMOTE_HOST} "borg init --encryption=repokey ${REMOTE_REPO}"

# 백업 실행
borg create \
    --stats \
    --progress \
    --compression lz4 \
    ${REMOTE_USER}@${REMOTE_HOST}:${REMOTE_REPO}::${ARCHIVE_NAME} \
    ${BACKUP_PATHS}

# 백업본 목록 확인
borg list ${REMOTE_USER}@${REMOTE_HOST}:${REMOTE_REPO}

