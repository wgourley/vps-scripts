#!/bin/bash
# Nightly backup of a Docker app: databases + config + media, to an rclone
# remote (use an rclone "crypt" remote so the provider can't read it).
# https://github.com/wgourley/vps-scripts
#
# Verifies the upload by downloading it again and comparing, keeps KEEP days,
# and pings a healthchecks.io check: success -> green, any failure -> red,
# never runs -> red after the grace period.

set -uo pipefail
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

# ---- settings -----------------------------------------------------------
NAME="myapp"                                  # used in file names
COMPOSE_DIR="/srv/myapp"                      # where docker-compose.yml lives
DB_SERVICES="database"                        # compose services running MariaDB/MySQL
CONFIG_PATHS="srv/myapp/.env srv/myapp/docker-compose.override.yml etc/nginx/sites-enabled/myapp.conf"  # relative to /
MEDIA_DIR=""                                  # e.g. /srv/myapp/videos (synced, not archived); empty = skip
REMOTE="backup-crypt:myapp"                   # rclone remote:path for archives
MEDIA_REMOTE="backup-crypt:myapp-media"       # rclone remote:path for MEDIA_DIR
KEEP=14                                       # archives to keep, locally and remotely
WORK="/root/backup_staging"
HC_URL=""                                     # https://hc-ping.com/<uuid> (optional)
# --------------------------------------------------------------------------

ping_hc(){ [ -n "$HC_URL" ] && curl -fsS -m 10 --retry 3 --data-raw "$2" "$HC_URL$1" >/dev/null || true; }
fail(){ echo "$NAME: FAILED - $1"; ping_hc /fail "FAILED - $1"; exit 1; }

RCLONE=$(command -v rclone) || fail "rclone not installed"
D=$(date +%F); N="${NAME}_$D"; A="$WORK/$N"
mkdir -p "$A"; cd "$COMPOSE_DIR" || fail "no $COMPOSE_DIR"
ping_hc /start "starting"

# Databases: dump inside each container with its own credentials, then check
# the dump actually finished (a failed dump still produces a small .gz).
for svc in $DB_SERVICES; do
  docker compose exec -T "$svc" sh -c 'mariadb-dump -u"$MYSQL_USER" -p"$MYSQL_PASSWORD" --single-transaction --routines "$MYSQL_DATABASE"' </dev/null \
    | gzip > "$A/${svc}.sql.gz"
  zcat "$A/${svc}.sql.gz" | tail -1 | grep -q "Dump completed" || fail "$svc database dump"
done

# shellcheck disable=SC2086
tar czf "$A/config.tar.gz" --ignore-failed-read -C / $CONFIG_PATHS 2>/dev/null
tar czf "$WORK/$N.tar.gz" -C "$WORK" "$N" && rm -rf "$A"
SIZE=$(du -h "$WORK/$N.tar.gz" | cut -f1)

# Upload, then prove it: download it back and compare byte for byte.
$RCLONE copy "$WORK/$N.tar.gz" "$REMOTE/" || fail "upload"
$RCLONE cat "$REMOTE/$N.tar.gz" | cmp -s - "$WORK/$N.tar.gz" || fail "verify (downloaded copy differs)"

# Retention
ls -1t "$WORK"/"${NAME}"_*.tar.gz | tail -n +$((KEEP+1)) | xargs -r rm -f
$RCLONE lsf "$REMOTE/" | sort | head -n -"$KEEP" | while read -r f; do $RCLONE deletefile "$REMOTE/$f"; done

# Large media: sync rather than archive every night.
if [ -n "$MEDIA_DIR" ]; then
  $RCLONE sync "$MEDIA_DIR" "$MEDIA_REMOTE/" --exclude "cache/**" --exclude "*.lock" --exclude "*.log" || fail "media sync"
fi

MSG="$NAME: archive=$SIZE upload=OK verify=OK${MEDIA_DIR:+ media=synced}"
echo "$MSG"; ping_hc "" "$MSG"
