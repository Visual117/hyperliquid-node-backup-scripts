#!/bin/bash

ARCHIVE_DIR="/data/hyperliquid-archives"
LOG_FILE="/var/log/hl_idrive_backup_and_log.log"
SUCCESS_LOG="/var/log/hl_idrive_successful_backups.txt"
IDRIVE_CLI="/opt/IDriveForLinux/bin/idrive"

echo "===== $(date) iDrive BACKUP SCRIPT START =====" | tee -a "$LOG_FILE"

find "$ARCHIVE_DIR" -type f -name 'group_*.tar.zst' | sort | while read tarfile; do
    base="${tarfile%.tar.zst}"
    if [ -f "${base}.done" ] && [ ! -f "${base}.inprogress" ]; then
        echo "[INFO] Backing up: $tarfile" | tee -a "$LOG_FILE"
        $IDRIVE_CLI --backup "$tarfile" --silent
        RETCODE=$?
        if [ $RETCODE -eq 0 ]; then
            echo "[SUCCESS] $tarfile backed up and logged." | tee -a "$LOG_FILE"
            echo "$tarfile" >> "$SUCCESS_LOG"
            rm -f "${base}.done"
        else
            echo "[ERROR] Backup failed for $tarfile with code $RETCODE" | tee -a "$LOG_FILE"
        fi
    else
        echo "[SKIP] $tarfile (No .done or still .inprogress)" | tee -a "$LOG_FILE"
    fi
done

echo "===== $(date) iDrive BACKUP SCRIPT END =====" | tee -a "$LOG_FILE"
