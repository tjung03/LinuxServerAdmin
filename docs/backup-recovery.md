# 백업본 생성과 복원 확인

`tar` 전체·증분 백업의 복원 예시와 `rsync`, Borg의 적용 조건을 저장소의 백업 스크립트에 연결합니다. 백업 파일이 만들어진 것과 복원한 파일이 원본과 일치하는 것은 별도로 확인해야 합니다.

## 사용자 디렉터리에서 `tar` 전체·증분 복원

다음은 개인 홈 디렉터리에 **새 실습 디렉터리**를 만들어 사용하는 예시입니다. 같은 셸에서 순서대로 실행합니다. `lab_dir` 생성이 실패하면 이후 명령을 실행하지 않습니다. 실제 `/home`이나 운영 데이터는 건드리지 않습니다.

```bash
lab_dir=$(mktemp -d "$HOME/linux-server-admin-backup.XXXXXX")
printf '실습 위치: %s\n' "$lab_dir"
mkdir "$lab_dir/source" "$lab_dir/archives" "$lab_dir/restore"
printf '첫 버전\n' > "$lab_dir/source/item.txt"
printf '삭제할 파일\n' > "$lab_dir/source/old.txt"

tar --listed-incremental="$lab_dir/archives/state.snar" \
  -czf "$lab_dir/archives/full.tar.gz" -C "$lab_dir/source" .
tar -tzf "$lab_dir/archives/full.tar.gz"
```

스냅샷 파일(`state.snar`)에는 다음 증분 백업을 만들 때 비교할 상태가 기록됩니다. 전체 백업 직후 변경하면 파일 타임스탬프가 겹쳐 변경 내용을 놓칠 수 있으므로 잠시 간격을 둔 뒤 원본을 변경합니다.

```bash
sleep 2
printf '두 번째 버전\n' > "$lab_dir/source/item.txt"
rm "$lab_dir/source/old.txt"
printf '새 파일\n' > "$lab_dir/source/new.txt"

tar --listed-incremental="$lab_dir/archives/state.snar" \
  -czf "$lab_dir/archives/incremental.tar.gz" -C "$lab_dir/source" .
tar -tzf "$lab_dir/archives/incremental.tar.gz"
```

복원은 **빈 `restore` 디렉터리**에서 전체 백업, 증분 백업 순서로 진행합니다. `-G`는 GNU tar 증분 아카이브를 추출할 때 사용합니다. 복원 확인 결과에 차이가 있다면 성공한 백업으로 취급하지 않습니다.

```bash
tar -xGzf "$lab_dir/archives/full.tar.gz" -C "$lab_dir/restore"
tar -xGzf "$lab_dir/archives/incremental.tar.gz" -C "$lab_dir/restore"
diff -r "$lab_dir/source" "$lab_dir/restore"
find "$lab_dir/restore" -type f -print
```

`diff -r`가 아무 차이도 출력하지 않고 종료 코드가 0이면 이 **임시 예제의 파일 내용과 경로**가 일치합니다. 운영 환경에서의 백업 성공이나 재해 복구가 검증되었다는 뜻은 아닙니다. 전체 백업을 다시 시작할 때는 새 스냅샷 상태가 필요하며, 증분 아카이브만 보관해서는 전체 상태를 복원할 수 없습니다.

## 저장소의 기존 스크립트

| 파일 | 코드에서 확인되는 동작 | 적용 전 확인할 것 |
| --- | --- | --- |
| [`bin/backup.sh`](../bin/backup.sh) | `/home`에서 `tar`로 `/backup/home_날짜.tar.gz`를 만들고 출력을 `/backup/backup.log`로 보냄 | `/backup` 존재·용량·권한, 로그 덮어쓰기, 파일 생성과 복원 점검. 스크립트에는 오류 검사나 보관 주기 관리가 없음 |
| [`bin/web-backup.sh`](../bin/web-backup.sh) | `backupuser@server2`의 Borg 저장소로 `/etc/httpd`, `/var/log`, `/var/www`를 보관하고 목록 조회 시도 | SSH 계정·저장소 초기화·Borg 버전·대상 경로·접근 권한. 저장소 초기화 명령은 주석 처리됨 |

`backup.sh`는 예약 작업에 사용할 수 있는 형태지만, 파일이 존재한다는 것만으로 crontab 등록이나 반복 실행을 확인할 수는 없습니다. `web-backup.sh`의 `repo::archive` 형식은 [Borg 1.x 공식 사용법](https://borgbackup.readthedocs.io/en/stable/usage/create.html)에 대응합니다. 설치된 버전의 `borg --version`과 명령 형식을 확인한 뒤 적용해야 하며, 저장소에는 실제 Borg 복원 기록이 없습니다.

`rsync --delete`는 대상에만 있는 파일을 제거할 수 있습니다. 양쪽 경로를 먼저 구분하고, 실제 변경 전에 `--dry-run --itemize-changes`로 대상에서 달라질 파일을 확인합니다. 원본 경로 뒤의 `/` 유무도 전송 결과의 디렉터리 구조를 바꿀 수 있습니다.

참고: [GNU tar 증분 백업](https://www.gnu.org/software/tar/manual/html_node/Incremental-Dumps.html).
