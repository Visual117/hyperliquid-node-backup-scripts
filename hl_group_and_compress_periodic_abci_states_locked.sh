#!/usr/bin/env bash
LOCKDIR="/tmp/hl_group_and_compress_periodic_abci_states.lock"

# simple mkdir-as-lock
if ! mkdir "$LOCKDIR" 2>/dev/null; then
  echo "Another instance running, exiting."
  exit 1
fi
trap "rmdir '$LOCKDIR'" EXIT

/usr/local/bin/hl_group_and_compress_periodic_abci_states.sh
