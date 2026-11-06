#!/bin/sh
# Daily disk-space check -> healthchecks.io
# https://github.com/wgourley/vps-scripts
#
# Pings success while usage is under the limit, /fail above it. Because the
# check itself is monitored, it also goes red if this script stops running.

# ---- settings -----------------------------------------------------------
URL="https://hc-ping.com/your-check-uuid"
LIMIT=80          # percent
MOUNT="/"
# --------------------------------------------------------------------------

USE=$(df --output=pcent "$MOUNT" | tail -1 | tr -dc 0-9)
HOST=$(hostname)
if [ "$USE" -ge "$LIMIT" ]; then
  curl -fsS -m 10 --retry 3 --data-raw "Disk ${USE}% used on $HOST $MOUNT" "$URL/fail" >/dev/null
else
  curl -fsS -m 10 --retry 3 --data-raw "Disk ${USE}% used on $HOST $MOUNT" "$URL" >/dev/null
fi
