#!/bin/bash

if [ $# -ne 1 ] ; then
  echo "Usage: $0 [server|client]"
  echo "  (server side) ./net_load.sh server"
  echo "  (client side) ./net_load.sh client"
  exit 1
fi
MODE=$1                     # server 또는 client

# 필요한 패키지 설치
dnf -q -y install epel-release
dnf -q -y install iperf3 gnuplot

# 변수 설정
SERVER_IP="192.168.10.10"   # 서버 IP
DURATION=60                 # 테스트 시간 (초)
PARALLEL=5                  # 병렬 연결 수
LOG_DIR="/root/bin/logs"
PLOT_DIR="/root/bin/plots"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
LOG_FILE="$LOG_DIR/iperf3_$TIMESTAMP.json"
PLOT_FILE="$PLOT_DIR/iperf3_$TIMESTAMP.png"

rm -rf "$LOG_DIR" "$PLOT_DIR"
mkdir -p "$LOG_DIR" "$PLOT_DIR"

if [[ "$MODE" == "server" ]]; then
    echo "[+] iperf3 서버 실행 중..."
    iperf3 -s

elif [[ "$MODE" == "client" ]]; then
    echo "[+] iperf3 클라이언트 실행 중..."
    echo "  - 서버: $SERVER_IP"
    echo "  - 지속 시간: $DURATION 초"
    echo "  - 병렬 연결 수: $PARALLEL"
    echo "  - 로그 파일: $LOG_FILE"

    iperf3 -c $SERVER_IP -t $DURATION -P $PARALLEL --json > "$LOG_FILE"

    echo "[+] 로그 저장 완료: $LOG_FILE"

    # JSON에서 초별 Mbps 추출
    jq -r '.intervals[] | .sum.bits_per_second / 1000000' "$LOG_FILE" > "$LOG_FILE.dat"

    # 그래프 생성
    gnuplot -persist <<EOF
set terminal png size 800,600
set output "$PLOT_FILE"
set title "iperf3 Network Throughput"
set xlabel "Interval (seconds)"
set ylabel "Throughput (Mbps)"
plot "$LOG_FILE.dat" using 0:1 with lines title "Throughput"
EOF

    echo "[+] 그래프 저장 완료: $PLOT_FILE"
    echo "[+] 그래프 파일을 열어 보세요: $PLOT_FILE"
else
    echo "[-] 알수 없는 에러"
    exit 2
fi

