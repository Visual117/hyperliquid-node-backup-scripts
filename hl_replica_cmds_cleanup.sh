#!/bin/bash
# hl_replica_cmds_cleanup.sh
# Remove replica_cmds block folders that are no longer referenced by any .tar.zst filelist (i.e., already offloaded)

# ======= CONFIG =======
REPLICA_CMDS_DIR="/var/lib/hyperliquid/data/replica_cmds"
ARCHIVES_DIR="/data/hyperliquid-archives"
DRY_RUN=true      # Set to false to actually delete
LOG_FILE="$HOME/hl_replica_cmds_cleanup.log"

echo "===== $(date) Replica Cmds Orphan Cleanup Start =====" | tee -a "$LOG_FILE"

# 1. Gather all block numbers that are still referenced in any _filelist.txt
find "$ARCHIVES_DIR" -type f -name '*_filelist.txt' -exec cat {} + | grep -Eo '[0-9]{9}' | sort -u > "$HOME/active_blocks.txt"

# 2. Find all block folders in replica_cmds
find "$REPLICA_CMDS_DIR" -regextype posix-extended -type d -regex '.*/[0-9]{9}$' > "$HOME/all_replica_cmds_dirs.txt"

# 3. Extract block numbers from the replica_cmds paths
awk -F'/' '{print $NF}' "$HOME/all_replica_cmds_dirs.txt" | sort -u > "$HOME/replica_block_numbers.txt"

# 4. Figure out which blocks are NOT needed anymore (i.e., not present in any _filelist.txt)
grep -Fvx -f "$HOME/active_blocks.txt" "$HOME/replica_block_numbers.txt" > "$HOME/delete_blocks.txt"

# 5. Map those blocks back to their full replica_cmds folder paths
grep -Ff "$HOME/delete_blocks.txt" "$HOME/all_replica_cmds_dirs.txt" > "$HOME/delete_dirs.txt"

# 6. DRY RUN or ACTUAL DELETE
if [ "$DRY_RUN" = true ]; then
    echo "[DRY RUN] The following folders would be deleted:" | tee -a "$LOG_FILE"
    cat "$HOME/delete_dirs.txt" | tee -a "$LOG_FILE"
else
    echo "[DELETING] The following folders will be removed:" | tee -a "$LOG_FILE"
    cat "$HOME/delete_dirs.txt" | tee -a "$LOG_FILE"
    cat "$HOME/delete_dirs.txt" | xargs -I {} rm -rf {}
    echo "[DONE] Deleted." | tee -a "$LOG_FILE"
fi

echo "===== $(date) Replica Cmds Orphan Cleanup End =====" | tee -a "$LOG_FILE"
