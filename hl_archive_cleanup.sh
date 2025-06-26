#!/bin/bash

ARCHIVE_DIR="/data/hyperliquid-archives"
LOG_FILE="/var/log/hl_archive_cleanup.log"
SUCCESS_LOG="/var/log/hl_idrive_successful_backups.txt"

echo "===== $(date) ARCHIVE CLEANUP START =====" | tee -a "$LOG_FILE"

if [ ! -f "$SUCCESS_LOG" ]; then
    echo "[ERROR] Success log not found: $SUCCESS_LOG" | tee -a "$LOG_FILE"
    exit 1
fi

cat "$SUCCESS_LOG" | while read tarfile; do
    base="${tarfile%.tar.zst}"
    # Only remove if .tar.zst exists and neither .done nor .inprogress is present
    if [ -f "$tarfile" ] && [ ! -f "${base}.done" ] && [ ! -f "${base}.inprogress" ]; then
        echo "[INFO] Deleting $tarfile" | tee -a "$LOG_FILE"
        rm -f "$tarfile"
        for EXT in .filelist.txt .inprogress; do
            file="${base}${EXT}"
            if [ -f "$file" ]; then
                echo "[INFO] Deleting $file" | tee -a "$LOG_FILE"
                rm -f "$file"
            fi
        done
    else
        echo "[SKIP] $tarfile (not ready for cleanup)" | tee -a "$LOG_FILE"
    fi
done

echo "===== $(date) ARCHIVE CLEANUP END =====" | tee -a "$LOG_FILE"
