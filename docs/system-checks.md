# 시스템 관리 상태 확인

패키지·부팅·계정·튜닝·정기 작업·임시 파일의 설정을 바꾸기 전후에 무엇을 대조할지 정리합니다. 아래 명령은 현재 상태를 확인하는 출발점이며, 개별 실습의 완료 기록을 대신하지 않습니다.

| 영역 | 현재 상태 확인 | 변경 수단 또는 설정 위치 |
| --- | --- | --- |
| 패키지 | `rpm -q 패키지명`, `dnf history` | `dnf install`, `dnf remove` 등 변경 이력 |
| 부팅과 서비스 | `systemctl --failed`, `systemctl status 서비스명`, `journalctl -b` | 해당 Unit 및 관련 구성 파일 |
| 사용자·그룹 | `id 사용자명`, `getent passwd 사용자명`, `getent group 그룹명` | `useradd`·`usermod`·`groupmod`, `/etc/sudoers.d/` 등 |
| 튜닝 | `tuned-adm active`, `tuned-adm recommend` | 선택한 Tuned 프로파일과 설정 파일 |
| 작업 예약 | `crontab -l`, `systemctl list-timers` | 사용자 crontab, systemd Timer 등 |
| 임시 파일 | `systemctl status systemd-tmpfiles-clean.timer`, `systemctl cat systemd-tmpfiles-clean.timer` | `/etc/tmpfiles.d/`와 배포판 기본 설정 |

일부 명령은 패키지·서비스가 설치되지 않았거나 조회 권한이 부족하면 정보를 반환하지 못합니다. 변경은 테스트 VM에서 해당 설정의 원본을 확인하고 복구 방법을 준비한 뒤 진행합니다.

## 경로를 읽는 기준

`/etc`에는 시스템·서비스 설정이, `/var/log`에는 로그가, `/home`에는 일반 사용자의 홈 디렉터리가, `/run`에는 재부팅 후 유지되지 않는 런타임 데이터가 놓입니다. 저장소의 `backup.sh`는 `/home`을 읽고 `/backup`에 쓰며, `web-backup.sh`는 `/etc/httpd`·`/var/log`·`/var/www`를 입력으로 사용합니다. `/backup`과 `/root/bin`은 모든 Linux 시스템에 준비된 경로가 아니므로 스크립트 실행 경로와 실제 디렉터리 유무를 대조해야 합니다.

## 부팅과 서비스의 연결

부팅은 펌웨어 → 부트로더 → 커널·initramfs → systemd 순서로 이어집니다. 문제가 생긴 부팅을 조사할 때는 먼저 `systemctl --failed`와 `journalctl -b`로 현재 부팅의 실패한 Unit·로그를 찾아 관련 서비스를 좁힙니다. 부트로더 설정을 다시 만들거나 기본 부팅 대상을 바꾸는 작업은 다른 단계이므로 단순한 서비스 재시작 절차에 넣지 않습니다.

저장소의 [`bin/work.sh`](../bin/work.sh)는 로그를 남기고 무한 루프를 실행합니다. 저장소에는 이 스크립트를 등록한 systemd Unit이 없으므로 “서비스가 구성·검증되었다”는 근거가 아닙니다.

## 계정과 예약 작업의 확인 순서

사용자 또는 그룹을 바꾼 뒤에는 `id`, `getent`, 관련 파일 소유권을 확인합니다. `usermod -L` 같은 암호 잠금과 SSH 로그인 가능 여부는 같지 않을 수 있으므로, 로그인 제어를 다룰 때는 인증 방식과 셸·만료 설정도 구분합니다. 저장소에는 계정 변경 결과 로그가 없으므로 특정 사용자의 권한 변경 완료를 주장하지 않습니다.

`crontab`에는 다섯 시간 필드와 실행할 명령을 지정합니다. 저장소의 [`backup.sh`](../bin/backup.sh)는 `/home`과 `/backup` 경로에 의존합니다. 예약을 추가하기 전 해당 경로의 권한·용량, 실행 계정, 로그 보존 방식, 백업본의 복원 가능성을 확인해야 합니다. 예약 항목의 존재와 백업 성공은 다른 상태입니다.

crontab 항목의 형식은 다음과 같습니다. **문법 참고용이며 등록된 설정이 아닙니다.** 왼쪽 다섯 필드는 분·시·일·월·요일이고, 오른쪽은 실행 경로입니다. 저장소의 파일이 `/root/bin/backup.sh`에 배치되었다는 근거는 없으므로 경로를 실제 환경과 대조해야 합니다.

```cron
0 3 * * * /root/bin/backup.sh
```

사용자 crontab을 편집한다면 해당 사용자로 `crontab -l`을 먼저 확인하고, 적용 뒤에도 같은 명령으로 항목을 확인합니다. 백업이 실행된 시각의 로그와 복원 테스트는 별도로 확인합니다. `crontab -r`은 해당 사용자의 예약 항목 전체를 지우므로 점검용 명령으로 사용하지 않습니다.

## Tuned와 임시 파일

`tuned-adm active`로 활성 프로파일을 확인하고, 추천 프로파일이 있더라도 워크로드를 측정하지 않은 상태에서 성능 개선을 주장하지 않습니다. 프로파일 변경 전후에는 같은 부하 조건에서 비교할 방법을 먼저 정해야 합니다.

임시 파일 설정은 배포판의 기본 파일을 직접 덮어쓰는 방식보다 `/etc/tmpfiles.d/`에 별도 파일을 둘지 판단합니다. 규칙의 유형, 대상 경로, 권한, 정리 시점을 읽고 기존 데이터에 미치는 영향을 확인합니다. 저장소에는 별도 tmpfiles 규칙 파일이나 적용 기록이 없습니다.

tmpfiles 규칙 형식은 `Type Path Mode UID GID Age Argument`입니다. `D` 유형과 `1d` 경과 시간이 함께 지정되면 디렉터리 생성뿐 아니라 오래된 내용 정리까지 포함합니다. `D`는 `--remove`를 실행할 때 디렉터리 내용도 제거할 수 있으므로 대상에 보관할 데이터가 있는지 먼저 확인해야 합니다. 해당 버전에서 지원한다면 실습 VM의 `systemd-tmpfiles --cat-config`로 구성 파일 목록과 내용을 확인하고, 실제 정리 동작은 별도의 테스트 경로에서 검증합니다.

참고: [systemd-tmpfiles 명령 설명](https://www.freedesktop.org/software/systemd/man/systemd-tmpfiles.html), [tmpfiles.d 규칙 형식](https://www.freedesktop.org/software/systemd/man/tmpfiles.d.html).
