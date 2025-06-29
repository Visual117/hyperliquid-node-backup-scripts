#!/usr/bin/env bash
LOCKFILE="/tmp/hl_group_and_compress_node_order_statuses.lock"
if ! mkdir "$LOCKFILE" 2>/dev/null; then
  echo "Another instance running, exiting."
  exit 1
fi
trap "rmdir '$LOCKFILE'" EXIT

/usr/local/bin/hl_group_and_compress_node_order_statuses.sh
