#!/bin/bash
LOCKFILE="/tmp/hl_group_and_compress.lock"

# Check for existing lockfile
if [ -f "$LOCKFILE" ]; then
    echo "Another instance is already running (lockfile exists at $LOCKFILE). Exiting."
    exit 1
fi

# Create lockfile with PID
echo $$ > "$LOCKFILE"

# Trap to always remove lockfile when script exits (even if interrupted)
trap "rm -f '$LOCKFILE'" EXIT

# Call your real script
/usr/local/bin/hl_group_and_compress.sh

# Lockfile removed automatically by trap
