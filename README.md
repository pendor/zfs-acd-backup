# zfs-acd-backup

Utilities for sending encrypted zfs filesystem backups to Amazon Cloud Drive.

Very very work-in-progress scripts for backing up ZFS filesystems to Amazon Cloud Drive.

## Backup Process:
* (Manual) Create ZFS snapshot
* zfs send output
* openssl compress & encrypt w/ user-provided AES key
* split into 1GB chunks
* streamed to Amazon Cloud Drive

## Restore Process:
* (Manual) Create empty ZFS to contain received filesystems
* list files from ACD matching desired zfs snapshot
* stream matching files sequentially into openssl to decrypt & decompress
* stream decompressed zfs data into zfs receive

