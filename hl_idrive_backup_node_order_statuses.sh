#!/usr/bin/env bash
set -euo pipefail

ARCHIVE_DIR="/data/hyperliquid-archives/node_order_statuses"
LOG_FILE="/var/log/hl_idrive_backup_node_order_statuses.log"
SUCCESS_LOG="/var/log/hl_idrive_successful_backups.txt"
IDRIVE_CLI="/opt/IDriveForLinux/bin/idrive"

echo "===== $(date -u) BACKUP node_order_statuses START =====" | tee -a "$LOG_FILE"

find "$ARCHIVE_DIR" -maxdepth 1 -type f -name 'node_order_statuses_*.tar.zst' | sort | while read -r tarfile; do
  # Skip any archives already in the success log
  if grep -Fxq "$tarfile" "$SUCCESS_LOG"; then
    echo "[SKIP-DONE] $tarfile already backed up" | tee -a "$LOG_FILE"
    continue
  fi

  echo "[INFO] Backing up $tarfile" | tee -a "$LOG_FILE"
  if $IDRIVE_CLI --backup "$tarfile" --silent; then
    echo "[SUCCESS] $tarfile" | tee -a "$LOG_FILE"
    echo "$tarfile" >> "$SUCCESS_LOG"
  else
    echo "[ERROR] Backup failed for $tarfile" | tee -a "$LOG_FILE"
  fi
done

echo "===== $(date -u) BACKUP node_order_statuses END =====" | tee -a "$LOG_FILE"
