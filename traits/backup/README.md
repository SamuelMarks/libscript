# Unified Backup, Object Storage Sync & CoW Snapshot Trait (`traits/backup/`)

## Overview

`traits/backup/` orchestrates physical (`hooks/backup`) and logical (`hooks/backup_tenant`)
application snapshots, Copy-on-Write (CoW) ZFS and Btrfs filesystem snapshots
(`cow_snapshot.{sh,cmd}`), and multi-backend PaaS object storage shipping (`ship.{sh,cmd}`)
supporting `s3://`, `gs://`, `azure://`, `rclone://`, `restic://`, and `borg://`.
