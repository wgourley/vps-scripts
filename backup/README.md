# Docker app backup to an encrypted remote

One script per app: dumps its databases from inside the containers, archives the config, uploads to an [rclone](https://rclone.org) remote, **verifies the upload**, and keeps 14 days.

## Why the extra checks

Backups fail quietly. A dump that errors still writes a small, valid `.gz`; an upload can "succeed" with a truncated file; and a site that moved can leave you backing up an empty folder for days. So this script:

- checks every dump ends with `Dump completed`
- downloads the uploaded archive again and compares it byte for byte
- pings [healthchecks.io](https://healthchecks.io) on success **and** on failure, and at start, so a run that hangs or never starts turns red too

## Setup

1. `rclone config`: create a remote for your storage, then a **crypt** remote on top of it (e.g. `backup-crypt:`). The provider only ever sees encrypted files.
2. Copy `backup-docker-app.sh` to `/usr/local/bin/backup-myapp.sh`, `chmod 700`, and fill in the settings block.
3. Create a check on healthchecks.io (period 1 day, grace 2 hours) and put its URL in `HC_URL`.
4. Run it once by hand, then add to cron, e.g. `/etc/cron.d/backup-myapp`:
   ```
   40 3 * * * root /usr/local/bin/backup-myapp.sh >> /var/log/backup-myapp.log 2>&1
   ```
5. **Test a restore.** A backup you have never restored is a hope, not a backup.

## Assumptions

- MariaDB/MySQL containers using the standard `MYSQL_USER` / `MYSQL_PASSWORD` / `MYSQL_DATABASE` environment variables.
- Docker Compose v2 (`docker compose`).
