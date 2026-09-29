# 시스템 관리 상태 확인

패키지·저장소·부팅·계정·로그·튜닝·정기 작업·임시 파일의 설정을 바꾸기 전후에 무엇을 대조할지 정리합니다. 아래 명령은 현재 상태를 확인하는 출발점이며, 개별 실습의 완료 기록을 대신하지 않습니다.

| 영역 | 현재 상태 확인 | 변경 수단 또는 설정 위치 |
| --- | --- | --- |
| 패키지·저장소 | `rpm -q 패키지명`, `dnf repolist --all`, `dnf history` | `/etc/yum.repos.d/*.repo`, `dnf config-manager`와 패키지 변경 이력 |
| 부팅과 서비스 | `systemctl --failed`, `systemctl status 서비스명`, `journalctl -b` | 해당 Unit 및 관련 구성 파일 |
| 사용자·그룹 | `id 사용자명`, `getent passwd 사용자명`, `getent group 그룹명` | `useradd`·`usermod`·`groupmod`, `/etc/sudoers.d/` 등 |
| 로그 보존 | `journalctl --list-boots`, `/var/log/journal` | `journald.conf`와 영구 저장 위치 |
| 튜닝 | `tuned-adm active`, `tuned-adm recommend` | 선택한 Tuned 프로파일과 설정 파일 |
| 작업 예약 | `crontab -l`, `systemctl list-timers` | 사용자 crontab, systemd Timer 등 |
| 임시 파일 | `systemctl status systemd-tmpfiles-clean.timer`, `systemctl cat systemd-tmpfiles-clean.timer` | `/etc/tmpfiles.d/`와 배포판 기본 설정 |

일부 명령은 패키지·서비스가 설치되지 않았거나 조회 권한이 부족하면 정보를 반환하지 못합니다. 변경은 테스트 VM에서 해당 설정의 원본을 확인하고 복구 방법을 준비한 뒤 진행합니다.

## 경로를 읽는 기준

`/etc`에는 시스템·서비스 설정이, `/var/log`에는 로그가, `/home`에는 일반 사용자의 홈 디렉터리가, `/run`에는 재부팅 후 유지되지 않는 런타임 데이터가 놓입니다. 저장소의 `backup.sh`는 `/home`을 읽고 `/backup`에 쓰며, `web-backup.sh`는 `/etc/httpd`·`/var/log`·`/var/www`를 입력으로 사용합니다. `/backup`과 `/root/bin`은 모든 Linux 시스템에 준비된 경로가 아니므로 스크립트 실행 경로와 실제 디렉터리 유무를 대조해야 합니다.

## 부팅과 서비스의 연결

부팅은 펌웨어 → 부트로더 → 커널·initramfs → systemd 순서로 이어집니다. 문제가 생긴 부팅을 조사할 때는 먼저 `systemctl --failed`와 `journalctl -b`로 현재 부팅의 실패한 Unit·로그를 찾아 관련 서비스를 좁힙니다. 부트로더 설정을 다시 만들거나 기본 부팅 대상을 바꾸는 작업은 다른 단계이므로 단순한 서비스 재시작 절차에 넣지 않습니다.

저장소의 [`bin/work.sh`](../bin/work.sh)는 로그를 남기고 무한 루프를 실행합니다. 저장소에는 이 스크립트를 등록한 systemd Unit이 없으므로 “서비스가 구성·검증되었다”는 근거가 아닙니다.

## DNF 저장소 확인

패키지 설치 문제를 조사할 때는 저장소가 **정의되어 있는 상태**, 활성화된 상태, 메타데이터를 실제로 읽을 수 있는 상태를 구분합니다.

```bash
dnf repolist --all
dnf repoinfo <저장소-ID>
dnf config-manager --dump <저장소-ID>
```

`<저장소-ID>`는 첫 명령에서 확인한 값으로 바꿉니다. 사용자 정의 저장소는 `/etc/yum.repos.d/*.repo`의 `baseurl` 또는 `mirrorlist`, `enabled`, `gpgcheck`, `gpgkey`를 확인합니다. `dnf config-manager --add-repo <저장소-URL>`은 RHEL 9 계열에서 저장소 파일을 추가하는 방법이지만, 플러그인 제공 여부와 신뢰할 수 있는 공식 URL·서명 키를 먼저 확인해야 합니다. 인증 토큰이나 자격 증명이 든 내부 URL을 문서·셸 기록·공개 저장소에 남기지 않습니다.

저장소를 추가한 뒤에는 `dnf repolist`, `dnf makecache --refresh`로 메타데이터 접근 여부를 확인합니다. `gpgcheck=0`으로 서명 검증을 끄거나 출처가 불명확한 저장소를 추가하는 것을 오류 해결의 기본 방법으로 사용하지 않습니다.

## 계정과 권한

사용자 또는 그룹을 바꾼 뒤에는 `id`, `getent`, 관련 파일 소유권을 확인합니다. `usermod -L` 같은 암호 잠금과 SSH 로그인 가능 여부는 같지 않을 수 있으므로, 로그인 제어를 다룰 때는 인증 방식과 셸·만료 설정도 구분합니다. 저장소에는 계정 변경 결과 로그가 없으므로 특정 사용자의 권한 변경 완료를 주장하지 않습니다.

새 계정의 기본 암호 만료 정책과 기존 계정의 현재 정책도 구분합니다. `/etc/login.defs`의 `PASS_MAX_DAYS` 같은 기본값 변경은 일반적으로 이후 생성되는 계정에 적용되므로, 기존 계정은 `chage -l <사용자명>`으로 현재 만료 정보를 확인하고 필요한 경우 계정별 정책을 별도로 변경합니다. 공용 암호나 명령줄에 노출되는 평문 암호를 실습 기본값으로 사용하지 않습니다.

관리 권한은 `NOPASSWD: ALL`을 기본값으로 두지 않고, 식별 가능한 개인 계정과 필요한 명령 범위로 제한합니다. sudoers 변경은 배포판 기본 파일을 직접 덮어쓰기보다 `/etc/sudoers.d/<구성명>`의 별도 파일을 검토하고, 적용 전에 `visudo -cf <후보파일>`로 문법을 확인합니다. 기존 관리 세션을 유지한 채 별도 세션에서 `sudo -l -U <사용자명>`과 허용된 작업을 확인해야 잠금 사고를 줄일 수 있습니다.

## systemd journal 영구 보존 확인

현재 부팅의 로그가 조회된다는 사실과 재부팅 뒤에도 로그가 남는 상태는 다릅니다. 먼저 설정과 저장 위치, 부팅별 로그 목록을 확인합니다.

```bash
systemd-analyze cat-config systemd/journald.conf
ls -ld /var/log/journal
journalctl --list-boots
```

`Storage=auto`에서는 `/var/log/journal`의 존재 여부에 따라 영구 저장 사용 여부가 달라질 수 있습니다. 영구 보존이 요구되는 시스템은 보존 기간·디스크 용량·접근 권한을 함께 정한 뒤 persistent 설정과 저장 디렉터리를 구성하고, runtime 로그를 옮길 필요가 있으면 `journalctl --flush`를 사용합니다. 적용 뒤 재부팅 전후의 `journalctl --list-boots`와 디스크 사용량을 확인하며, 저장 디렉터리를 만들었다는 사실만으로 보존 정책 전체가 검증된 것으로 보지 않습니다.

## 예약 작업 확인 순서

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

참고: [RHEL 9 DNF 저장소 관리](https://docs.redhat.com/en/documentation/red_hat_enterprise_linux/9/html/managing_software_with_the_dnf_tool/assembly_managing-custom-software-repositories_managing-software-with-the-dnf-tool), [systemd-journald 영구 로그](https://docs.redhat.com/en/documentation/red_hat_enterprise_linux/9/html/configuring_basic_system_settings/assembly_persistently-storing-system-logs-in-the-journal_configuring-basic-system-settings), [systemd-tmpfiles 명령 설명](https://www.freedesktop.org/software/systemd/man/systemd-tmpfiles.html), [tmpfiles.d 규칙 형식](https://www.freedesktop.org/software/systemd/man/tmpfiles.d.html).
