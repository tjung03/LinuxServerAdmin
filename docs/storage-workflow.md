# 저장장치 구성과 확인

장치 인식·파티션·파일시스템·마운트·LVM·RAID·Swap 작업의 관계를 정리합니다. 아래의 확인 명령은 현재 상태를 읽습니다. 변경 작업은 실습 VM에서 대상과 기존 데이터를 확인한 뒤 각 단계별로 진행합니다.

## 1. 대상 장치와 현재 상태 식별

```bash
lsblk -o NAME,SIZE,TYPE,FSTYPE,UUID,MOUNTPOINTS
findmnt
df -hT
```

`lsblk`는 커널이 인식한 장치·파티션과 파일시스템·마운트 위치를, `findmnt`는 현재 마운트를, `df`는 마운트된 파일시스템의 사용량을 보여줍니다. 디스크 이름은 실습 VM의 구성에 따라 달라집니다. `/dev/sdb`나 `/dev/nvme0n2` 같은 이름을 현재 VM의 빈 디스크로 가정하지 않습니다. 새로 연결한 장치라면 연결 전후의 `lsblk` 결과를 비교하고 시스템 디스크·사용 중인 볼륨·Swap 영역과 겹치지 않는지 확인합니다.

## 2. 저장 계층을 구성할 때의 연결

| 단계 | 관련 도구·파일 | 다음 단계로 넘길 정보 |
| --- | --- | --- |
| 파티션 | `fdisk`, `gdisk`, `parted`, `partprobe` | 대상 장치와 생성된 파티션의 이름·크기 |
| LVM(선택) | `pvcreate` → `vgcreate` → `lvcreate` | LV 장치 경로와 할당 용량 |
| RAID(선택) | `mdadm` | 어레이 장치와 동기화 상태 |
| 파일시스템 | `mkfs.xfs` 또는 `mkfs.ext4`, `blkid` | 파일시스템 유형과 UUID |
| 마운트 | `mount`, `/etc/fstab`, `findmnt` | 실제 마운트 지점과 영구 설정 |

LVM의 PV는 전용 디스크 또는 파티션으로 만들 수 있습니다. RAID 장치를 사용한다면 파일시스템을 만들 대상은 원본 멤버 디스크가 아니라 구성된 장치인지 확인해야 합니다. 구성에 따라 단계가 생략되므로 위 표 전체를 한 디스크에 순서대로 실행하는 방법으로 읽지 않습니다.

**변경 전 확인:** 선택한 디스크의 장치 경로, 크기, 기존 서명(`blkid`), 현재 마운트·Swap·LVM·RAID 사용 여부를 기록합니다. `parted mklabel`, `mkfs`, `pvcreate`, `mdadm --create`는 기존 데이터를 잃게 할 수 있습니다. 문서에 보이는 장치 경로를 그대로 복사해 실행하지 않습니다.

### LVM 구성 순서 예시

다음 표는 **별도로 준비한 빈 PV 장치 한 개**에 `vg_lab`의 `lv_data`를 만드는 경우의 기록용 템플릿입니다. `[확인한_PV_장치]`는 실제 경로가 아니며, 표의 명령은 자동 실행용 스크립트가 아닙니다. 파티션을 PV로 쓴다면 파티션을 먼저 생성하고 커널이 새 장치를 인식했는지 확인합니다. 실습 대상이 시스템 디스크나 기존 PV라면 진행하지 않습니다.

| 순서 | 변경·확인 예시 | 확인할 결과 |
| --- | --- | --- |
| 대상 확인 | `lsblk -f`, `blkid`, `pvs` | 선택한 PV 장치에 사용 중인 파일시스템·볼륨이 없는지 |
| PV와 VG | `pvcreate [확인한_PV_장치]` → `vgcreate vg_lab [확인한_PV_장치]` | `pvs`, `vgs`에서 장치와 VG 용량 대조 |
| LV | `lvcreate -L 1G -n lv_data vg_lab` | `lvs`에서 LV 경로·크기 대조. VG 여유 공간이 1GiB보다 큰지 먼저 확인 |
| 파일시스템 | `mkfs.xfs /dev/vg_lab/lv_data` | `blkid /dev/vg_lab/lv_data`에서 `TYPE`·UUID 확인 |
| 마운트 | 빈 마운트 지점을 만든 뒤 `mount /dev/vg_lab/lv_data /mnt/data` | `findmnt /mnt/data`, `df -hT /mnt/data`로 장치·유형·용량 확인 |

위 예시는 RAID와 Swap을 포함하지 않습니다. RAID라면 먼저 **서로 다른 빈 멤버 장치**를 확인한 뒤 `mdadm --create`로 어레이를 만들고 `/proc/mdstat`, `mdadm --detail [어레이]`에서 구성과 동기화 상태를 확인합니다. 그 어레이에 파일시스템을 직접 만들거나 PV로 쓰는 것은 서로 다른 구성입니다. Swap이라면 별도 파일·파티션·LV를 준비해 `mkswap` 후 `swapon`하고 `swapon --show`로 활성화를 확인합니다. 파일을 쓸 경우 권한·파일시스템 제약도 확인합니다. 어느 방식도 실제 장치 목록과 용량이 정해지기 전에는 실행하지 않습니다.

**변경 후 확인:** 필요한 구성 명령을 적용한 실습 VM에서 다음 중 해당 항목을 사용해 결과를 대조합니다.

```bash
lsblk -f
blkid
pvs
vgs
lvs
cat /proc/mdstat
```

`pvs`, `vgs`, `lvs`는 LVM을 사용하는 VM에서, `/proc/mdstat`는 소프트웨어 RAID를 구성한 VM에서 의미가 있습니다. 생성 명령이 성공 메시지를 냈더라도 이 출력으로 실제 대상과 상태를 다시 확인합니다. 파티션 유형 표시는 파티션 도구와 디스크 레이블에 따라 다르며, 해당 유형 표시만으로 PV의 생성 여부를 판단할 수 없습니다.

## 3. 파일시스템과 마운트 연결

XFS·ext4 파일시스템과 수동 마운트, `/etc/fstab`의 영구 마운트는 각각 확인할 내용이 다릅니다. `blkid`로 확인한 실제 UUID와 파일시스템 유형을 사용합니다. 다음은 필드 형식을 보여주는 **미적용 예시**입니다.

```fstab
UUID=<실제-UUID>  /mnt/data  xfs  defaults  0  0
```

마운트 지점은 미리 마련하고 그 위치에 기존 파일이 있는지 확인합니다. `/etc/fstab` 변경 전에는 원본을 보관하고, 파일을 편집한 뒤 `findmnt --verify --verbose`로 구성 오류를 살펴봅니다. `mount -a`는 실제 마운트 상태를 바꾸므로 실습 VM에서만 적용하며, 마지막으로 `findmnt /mnt/data`와 `df -hT /mnt/data`에서 기대한 장치·유형·용량을 대조합니다. 설정 파일에 예시 UUID를 그대로 쓰지 않습니다.

## 4. 장애 점검과 용량 확인

```bash
df -hT
du -sh /var/log
findmnt
free -h
swapon --show
```

`df`는 마운트된 파일시스템 단위, `du`는 지정한 경로의 사용량을 보여줍니다. 둘이 다르다면 마운트 위치, 열린 삭제 파일, 예약 공간 등 원인을 따로 조사합니다. `swapon --show`는 활성 Swap을 보여주며, Swap 구성 파일이 존재한다는 사실만으로 활성화되었다고 판단하지 않습니다.

파일시스템 점검·복구는 사용 중인 볼륨에서 임의로 실행하지 않습니다. `fsck`와 `xfs_repair`는 대상 파일시스템 유형과 마운트 여부에 따라 절차가 다릅니다. 특히 XFS 파일시스템의 크기 축소는 지원되지 않으므로 LV 크기를 줄이기 전에 파일시스템 특성을 확인해야 합니다.

참고: [Red Hat Enterprise Linux 9 파일시스템 관리](https://docs.redhat.com/en/documentation/red_hat_enterprise_linux/9/htmlsingle/managing_file_systems/index), [스토리지 장치 관리](https://docs.redhat.com/en/documentation/red_hat_enterprise_linux/9/html/managing_storage_devices/index), [LVM 물리 볼륨 관리](https://docs.redhat.com/en/documentation/red_hat_enterprise_linux/9/html/configuring_and_managing_logical_volumes/managing-lvm-physical-volumes_configuring-and-managing-logical-volumes).
