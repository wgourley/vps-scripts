# Disk-space check

Pings a [healthchecks.io](https://healthchecks.io) check once a day. It goes red when the disk passes the limit, **or** if the script stops running at all, so you hear about both.

```bash
cp check-disk-space.sh /usr/local/bin/ && chmod 755 /usr/local/bin/check-disk-space.sh
# set URL (period 1 day, grace 2 hours on healthchecks.io), LIMIT and MOUNT
echo "17 7 * * * root /usr/local/bin/check-disk-space.sh" > /etc/cron.d/check-disk-space
/usr/local/bin/check-disk-space.sh   # first ping: the check should turn green
```
   > **Cron ignores `/etc/cron.d` files that are group- or other-writable** (log: `INSECURE MODE`). If your umask is 002, run `chmod 644` on the file, or the job silently never runs.
