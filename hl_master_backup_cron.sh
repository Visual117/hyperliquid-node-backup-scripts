#!/bin/bash
set -e

LOCK="/tmp/hl_master_backup_cron.lock"

if [ -e "$LOCK" ]; then
  echo "Master cron already running, exiting." >> /var/log/hl_master_backup_cron.log
  exit 1
fi
trap 'rm -f $LOCK' EXIT   # <-- Fixed quote bug!
touch "$LOCK"

LOG="/var/log/hl_master_backup_cron.log"

echo "===== $(date) MASTER BACKUP PIPELINE START =====" | tee -a "$LOG"

echo "[STEP 1] Group and compress" | tee -a "$LOG"
/usr/local/bin/hl_group_and_compress_locked.sh 2>&1 | tee -a "$LOG"

echo "[STEP 2] Backup and log" | tee -a "$LOG"
/usr/local/bin/hl_idrive_backup_and_log.sh 2>&1 | tee -a "$LOG"

echo "[STEP 3] Archive cleanup" | tee -a "$LOG"
/usr/local/bin/hl_archive_cleanup.sh 2>&1 | tee -a "$LOG"

echo "[STEP 4] Replica_cmds cleanup" | tee -a "$LOG"
/usr/local/bin/hl_replica_cmds_cleanup_by_idrive_success.sh 2>&1 | tee -a "$LOG"

echo "===== $(date) MASTER BACKUP PIPELINE END =====" | tee -a "$LOG"
