#!/bin/bash

IDRIVE_BIN_DIR="/opt/IDriveForLinux/bin"
ARCHIVE_DIR="/data/hyperliquid-archives"
BACKUP_SET_FILE="/opt/IDriveForLinux/idriveIt/user_profile/explorer/scalesjam@gmail.com/Backup/DefaultBackupSet/Backupset.txt"
LOGFILE="$HOME/hl_idrive_offload.log"

cd "$IDRIVE_BIN_DIR"

echo "===== $(date) IDrive Offload Start =====" >> "$LOGFILE"

# 1. Overwrite backup set to only include tar.zst files
find "$ARCHIVE_DIR" -maxdepth 1 -type f -name "*.tar.zst" > "$BACKUP_SET_FILE"

# 2. Start backup
./idrive --backup >> "$LOGFILE" 2>&1 &

# 3. Wait for backup to start and get the job id
sleep 10

# 4. Poll for backup completion
while true; do
    JOB_STATUS=$(./idrive --job-status)
    echo "$JOB_STATUS" >> "$LOGFILE"
    if echo "$JOB_STATUS" | grep -qi "No backup job(s) in progress"; then
        echo "IDrive backup job completed." >> "$LOGFILE"
        break
    fi
    sleep 30
done

echo "===== $(date) IDrive Offload End =====" >> "$LOGFILE"
