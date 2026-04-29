#!/bin/bash

# 필요한 패키지 설치
dnf -q -y install epel-release
dnf -q -y install fio

echo "디스크 부하 테스트 시작 (fio 기반)..."

# 다음 스크립트는 /tmp/testfile(3G)에 4KB 블록 단위 랜덤 쓰기를 4개의 쓰레드로 60초가 수행한다.
fio --name=disk_load_test \
    --directory=/tmp \
    --filename=testfile \
    --size=3G \
    --time_based \
    --runtime=60 \
    --ioengine=libaio \
    --direct=1 \
    --rw=randwrite \
    --bs=4k \
	    --numjobs=4 \
    --group_reporting

echo "테스트 파일 삭제 중..."
rm -f /tmp/testfile

echo "테스트 종료"
