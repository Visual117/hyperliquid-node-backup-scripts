#!/bin/bash

ARCHIVE_DIR="/data/hyperliquid-archives"
REPLICA_CMDS_DIR="/var/lib/hyperliquid/data/replica_cmds"
GROUP_SIZE=100000   # e.g. 100k blocks per archive; adjust if needed

# Find all eligible block files
blockfiles=$(find "$REPLICA_CMDS_DIR" -type f -regextype posix-extended -regex '.*/[0-9]{9}$')

# Map: block number => full path
declare -A filemap
for f in $blockfiles; do
    fname=$(basename "$f")
    filemap["$fname"]="$f"
done

# Sort block numbers, group by GROUP_SIZE
groups=()
for fname in "${!filemap[@]}"; do
    group=$(( fname / GROUP_SIZE ))
    groups+=($group)
done

# Sort and dedupe group list
readarray -t sorted_groups < <(printf "%s\n" "${groups[@]}" | sort -n | uniq)

# Loop to find the lowest eligible group to compress
for group in "${sorted_groups[@]}"; do
    batch_start=$(( group * GROUP_SIZE ))
    batch_end=$(( (group + 1) * GROUP_SIZE - 1 ))
    batch_name="group_${batch_start}_${batch_end}"

    archive="${ARCHIVE_DIR}/${batch_name}.tar.zst"
    marker_inprog="${ARCHIVE_DIR}/${batch_name}.inprogress"
    marker_done="${ARCHIVE_DIR}/${batch_name}.done"
    filelist="${ARCHIVE_DIR}/${batch_name}_filelist.txt"

    # Skip if already completed or in progress
    if [ -f "$marker_done" ] || [ -f "$marker_inprog" ] || [ -f "$archive" ]; then
        continue
    fi

    # Build filelist for this batch
    rm -f "$filelist"
    for fname in "${!filemap[@]}"; do
      if [[ "$fname" -ge "$batch_start" && "$fname" -le "$batch_end" ]]; then
        echo "${filemap[$fname]}" >> "$filelist"
      fi
    done

    count=$(wc -l < "$filelist")
    if [ "$count" -eq 0 ]; then
      rm -f "$filelist"
      continue
    fi

    # Only compress **one** group per run!
    touch "$marker_inprog"
    echo "Compressing $count deduped files in $batch_name..."
    tar -cf - --files-from="$filelist" | zstd -19 -T0 -o "$archive"
    tar_rc=$?
    if [ $tar_rc -ne 0 ]; then
      echo "[ERROR] Compression failed for $batch_name"
      rm -f "$marker_inprog" "$filelist"
      exit 1
    fi

    rm -f "$marker_inprog" "$filelist"
    touch "$marker_done"
    echo "Finished $batch_name"
    exit 0
done

echo "No eligible groups found for compression."
exit 0
