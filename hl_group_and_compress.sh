#!/bin/bash
# /usr/local/bin/hl_group_and_compress.sh
set -euo pipefail

ARCHIVE_DIR="/data/hyperliquid-archives"
REPLICA_CMDS_DIR="/var/lib/hyperliquid/data/replica_cmds"
LOG_FILE="/var/log/hl_group_and_compress.log"
batch_size=100000

# Find all block files (by block number), sort numerically
block_files=($(find "$REPLICA_CMDS_DIR" -type f -regextype posix-extended -regex '.*/[0-9]{9}$' | sort))

if [ "${#block_files[@]}" -eq 0 ]; then
    echo "No block files found in $REPLICA_CMDS_DIR." | tee -a "$LOG_FILE"
    exit 0
fi

# Get min and max block numbers
first_block=$(basename "${block_files[0]}")
last_block=$(basename "${block_files[-1]}")

min_group=$(( (first_block / batch_size) * batch_size ))
max_group=$(( (last_block / batch_size) * batch_size ))

for batch_start in $(seq $min_group $batch_size $max_group); do
    batch_end=$((batch_start + batch_size - 1))
    batch_name="group_${batch_start}_${batch_end}"
    archive="${ARCHIVE_DIR}/${batch_name}.tar.zst"
    marker_inprog="${ARCHIVE_DIR}/${batch_name}.inprogress"
    marker_done="${ARCHIVE_DIR}/${batch_name}.done"

    # Only compress if there is no .done/.inprogress/archive
    if [ -f "$marker_done" ] || [ -f "$marker_inprog" ] || [ -f "$archive" ]; then
        continue
    fi

    # Gather block files for this group
    filelist=$(mktemp)
    count=0
    for f in "${block_files[@]}"; do
        block=$(basename "$f")
        if [ "$block" -ge "$batch_start" ] && [ "$block" -le "$batch_end" ]; then
            echo "$f" >> "$filelist"
            count=$((count+1))
        fi
    done

    if [ $count -eq 0 ]; then
        rm -f "$filelist"
        continue
    fi

    touch "$marker_inprog"
    echo "[INFO] Compressing $count deduped files in $batch_name..." | tee -a "$LOG_FILE"
    tar -cf - --files-from="$filelist" | zstd -19 -T0 -o "$archive"
    tar_rc=$?
    if [ $tar_rc -ne 0 ]; then
        echo "[ERROR] Compression failed for $batch_name" | tee -a "$LOG_FILE"
        rm -f "$marker_inprog" "$filelist"
        exit 1
    fi

    rm -f "$marker_inprog" "$filelist"
    touch "$marker_done"
    echo "Finished $batch_name" | tee -a "$LOG_FILE"
    exit 0   # Only one batch per run!
done

echo "No eligible groups found for compression." | tee -a "$LOG_FILE"
exit 0
