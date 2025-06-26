#!/bin/bash

LOCKFILE="/tmp/$(basename "$0").lock"
exec 200>"$LOCKFILE"
flock -n 200 || { echo "Script is already running. Exiting."; exit 1; }

set -euo pipefail

DATA_DIR="/var/lib/hyperliquid/data/replica_cmds"
ARCHIVE_DIR="/data/hyperliquid-archives"
BATCH_SIZE=100000

for archive in "$ARCHIVE_DIR"/group_*_*.tar.zst; do
    marker_done="${archive%.tar.zst}.done"
    [ -f "$marker_done" ] || continue

    bname=$(basename "$archive")
    batch_start=$(echo "$bname" | awk -F'[_\.]' '{print $2}')
    batch_end=$(echo "$bname" | awk -F'[_\.]' '{print $3}')

    find "$DATA_DIR" -type f -regextype posix-extended -regex ".*/[0-9]{9}$" | \
      while read -r file; do
        fnum=$(basename "$file")
        if [[ "$fnum" -ge "$batch_start" && "$fnum" -le "$batch_end" ]]; then
          echo "Deleting raw $file (archived in $bname)"
          rm -f "$file"
        fi
      done
done
