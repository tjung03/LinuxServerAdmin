#!/bin/bash
# 시작 파일에서 '|->'가 포함된 모든 줄을 삭제합니다. env_conf.sh가 추가하지 않은 줄도 지울 수 있으므로 원본을 백업하세요.
FILES="/etc/profile /etc/bashrc $HOME/.bash_profile $HOME/.bashrc $HOME/.bash_logout" 

for i in $FILES
do
	sed -i '/|->/d' $i
done

rm -f /etc/profile.d/test.sh >/dev/null
