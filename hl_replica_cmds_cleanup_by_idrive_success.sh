#!/bin/bash

REPLICA_CMDS_DIR="/var/lib/hyperliquid/data/replica_cmds"
LOG_FILE="/var/log/hl_replica_cmds_cleanup.log"
SUCCESS_LOG="/var/log/hl_idrive_successful_backups.txt"

echo "===== $(date) Replica Cmds Raw Cleanup Start =====" | tee -a "$LOG_FILE"

if [ ! -f "$SUCCESS_LOG" ]; then
    echo "[ERROR] Success log not found: $SUCCESS_LOG" | tee -a "$LOG_FILE"
    exit 1
fi

# Find block ranges from SUCCESS_LOG
cat "$SUCCESS_LOG" | while read tarfile; do
    fname=$(basename "$tarfile")
    if [[ "$fname" =~ group_([0-9]+)_([0-9]+)\.tar\.zst ]]; then
        start=${BASH_REMATCH[1]}
        end=${BASH_REMATCH[2]}
        echo "[INFO] Cleaning raw blocks in range $start - $end" | tee -a "$LOG_FILE"
        find "$REPLICA_CMDS_DIR" -type f -regextype posix-extended -regex ".*/[0-9]{9}$" | while read file; do
            block=$(basename "$file")
            if [[ "$block" -ge "$start" && "$block" -le "$end" ]]; then
                echo "[DELETE] $file" | tee -a "$LOG_FILE"
                rm -f "$file"
            fi
        done
    fi
done

echo "===== $(date) Replica Cmds Raw Cleanup End =====" | tee -a "$LOG_FILE"
