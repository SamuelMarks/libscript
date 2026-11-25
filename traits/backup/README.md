# Plane A Backup, CoW Snapshot & Restore Trait (`traits/backup/`)

## Overview

`traits/backup/` coordinates consistent stateful backups and point-in-time recovery across `T1`
datastores (`postgres`, `mariadb`, `mysql`, `mongodb`, `redis`, `valkey`, `etcd`), Copy-on-Write
filesystems (`ZFS` and `Btrfs`), and remote encrypted object stores (`S3`, `GCS`, `Azure Blob`,
`Restic`, `Borg`, `Rclone`).

## Scripts

- **`orchestrate.{sh,cmd}`**: Invokes component `hooks/backup.{sh,cmd}` (or
  `hooks/backup_tenant.*`), captures filesystem snapshots, and ships verified archives.
- **`cow_snapshot.{sh,cmd}`**: Creates, lists, and rolls back atomic `zfs snapshot` and
  `btrfs subvolume snapshot` checkpoints via `engine/common/cow_snapshot.{sh,cmd}`.
- **`ship.{sh,cmd}`**: Uploads encrypted, checksummed backup bundles to S3, GCS, Azure, Restic,
  Borg, or Rclone targets with retention pruning.
- **`restore.{sh,cmd}`**: Fetches backup archives or rolls back CoW snapshots and executes component
  `hooks/restore.{sh,cmd}` with post-restore health verification.

## Usage

```sh
./libscript.sh trait apply backup
./traits/backup/orchestrate.sh /var/backups/postgres postgres
./traits/backup/ship.sh /var/backups/postgres s3://my-backups/pg
./traits/backup/restore.sh postgres /var/backups/postgres
```
