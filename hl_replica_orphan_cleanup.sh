#!/bin/bash

REPLICA_CMDS_DIR="/var/lib/hyperliquid/data/replica_cmds"
ARCHIVE_DIR="/data/hyperliquid-archives"
LOG_FILE="$HOME/hl_replica_orphan_cleanup.log"
DRY_RUN=true   # Set to false to actually delete

rm -f /tmp/all_still_needed_blocks.txt /tmp/all_replica_blocks.txt /tmp/blocks_safe_to_delete.txt

echo "[INFO] Scanning all filelists in $ARCHIVE_DIR..."
# This extracts all block numbers listed INSIDE each filelist
find "$ARCHIVE_DIR" -type f -name '*_filelist.txt' -exec cat {} + | grep -Eo '[0-9]{9}' | sort -u > /tmp/all_still_needed_blocks.txt

echo "[INFO] Scanning replica_cmds folders..."
# This finds all folders named with a 9-digit number
find "$REPLICA_CMDS_DIR" -regextype posix-extended -type d -regex '.*/[0-9]{9}$' | sort > /tmp/all_replica_blocks.txt

# Now extract just the block number from the path
awk -F'/' '{print $NF}' /tmp/all_replica_blocks.txt | sort -u > /tmp/_all_replica_blocks_short.txt

# 3. Find replica_cmds blocks not needed anymore (orphans)
grep -Fvx -f /tmp/all_still_needed_blocks.txt /tmp/_all_replica_blocks_short.txt > /tmp/orphan_block_numbers.txt

# Now, rematch the full paths from the original all_replica_blocks.txt
grep -Ff /tmp/orphan_block_numbers.txt /tmp/all_replica_blocks.txt > /tmp/blocks_safe_to_delete.txt

echo "===== $(date) Replica Cmds Orphan Cleanup Start =====" >> "$LOG_FILE"
echo "[INFO] Listing orphaned replica_cmds block folders:"
cat /tmp/blocks_safe_to_delete.txt | tee -a "$LOG_FILE"

while read -r blockpath; do
    if [ "$DRY_RUN" = true ]; then
        echo "[DRY RUN] Would delete: $blockpath" | tee -a "$LOG_FILE"
    else
        echo "[DELETING] $blockpath" | tee -a "$LOG_FILE"
        rm -rf "$blockpath"
    fi
done < /tmp/blocks_safe_to_delete.txt

echo "===== $(date) Replica Cmds Orphan Cleanup End =====" >> "$LOG_FILE"
