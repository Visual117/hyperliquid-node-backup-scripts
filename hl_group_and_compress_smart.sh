#!/bin/bash

REPLICA_CMDS_DIR="/var/lib/hyperliquid/data/replica_cmds"
ARCHIVE_DIR="/data/hyperliquid-archives"
LOG_FILE="/var/log/hl_group_and_compress_smart.log"
LOCKFILE="/tmp/hl_group_and_compress_smart.lock"

# --- Locking to prevent overlap ---
if [ -e "$LOCKFILE" ]; then
  echo "[ERROR] Compressor already running! Exiting." | tee -a "$LOG_FILE"
  exit 1
fi
touch "$LOCKFILE"
trap "rm -f '$LOCKFILE'" EXIT

echo "===== $(date) Smart Compressor Start =====" | tee -a "$LOG_FILE"

# 1. Find all unique block numbers (basename, 9 digits)
all_blocks=$(find "$REPLICA_CMDS_DIR" -type f -regextype posix-extended -regex '.*/[0-9]{9}$' -printf "%f\n" | sort -n | uniq)
if [[ -z "$all_blocks" ]]; then
  echo "[WARN] No block files found." | tee -a "$LOG_FILE"
  exit 0
fi

min_block=$(echo "$all_blocks" | head -1)
max_block=$(echo "$all_blocks" | tail -1)
min_group=$((min_block / 100000 * 100000))
max_group=$((max_block / 100000 * 100000))

compressed_any=false

for group_start in $(seq $min_group 100000 $((max_group - 100000))); do
  group_end=$((group_start + 99999))
  next_group_start=$((group_start + 100000))

  archive="$ARCHIVE_DIR/group_${group_start}_${group_end}.tar.zst"
  marker_done="$ARCHIVE_DIR/group_${group_start}_${group_end}.done"
  marker_inprog="$ARCHIVE_DIR/group_${group_start}_${group_end}.inprogress"

  # Only compress if .done/inprogress don't exist
  if [ -e "$marker_done" ] || [ -e "$marker_inprog" ]; then
    echo "[SKIP] $group_start-$group_end already compressed." | tee -a "$LOG_FILE"
    continue
  fi

  # Only compress if at least one file >= next_group_start exists!
  if ! echo "$all_blocks" | grep -q "^$next_group_start$"; then
    echo "[WAIT] $group_start-$group_end still open. Not compressing yet." | tee -a "$LOG_FILE"
    continue
  fi

  # Gather all files in this group range
  mapfile -t files < <(find "$REPLICA_CMDS_DIR" -type f -regextype posix-extended -regex ".*/[0-9]{9}$" -printf "%p\n" | awk -F/ -v s="$group_start" -v e="$group_end" '{b=substr($NF,1,9)+0; if(b>=s && b<=e) print $0}' | sort)
  if [ "${#files[@]}" -eq 0 ]; then
    echo "[WARN] No files to compress for $group_start-$group_end!" | tee -a "$LOG_FILE"
    continue
  fi

  # Compress the batch
  echo "[INFO] Compressing ${#files[@]} files: $group_start-$group_end ..." | tee -a "$LOG_FILE"
  touch "$marker_inprog"
  tar -cf - "${files[@]}" | zstd -19 -T0 -o "$archive"
  rc=$?
  rm -f "$marker_inprog"
  if [ $rc -ne 0 ]; then
    echo "[ERROR] Compression failed for $group_start-$group_end" | tee -a "$LOG_FILE"
    continue
  fi

  touch "$marker_done"
  echo "[DONE] Finished group_$group_start\_$group_end ($(date))" | tee -a "$LOG_FILE"
  compressed_any=true
done

if [ "$compressed_any" = false ]; then
  echo "[INFO] No eligible groups were compressed this run." | tee -a "$LOG_FILE"
fi

echo "===== $(date) Smart Compressor End =====" | tee -a "$LOG_FILE"
