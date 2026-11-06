# vps-scripts

Small shell scripts from running a self-hosted Linux VPS: Docker, nginx, mail, radio and video. Each one is generic, with a settings block at the top.

| Folder | What it does |
|---|---|
| [`docker-firewall`](docker-firewall) | Restrict Docker-published ports to an IP allow-list (Docker bypasses UFW) |
| [`backup`](backup) | Nightly database + config backup to an encrypted rclone remote, verified by download, monitored |
| [`monitoring`](monitoring) | Daily disk-space check that also alerts if it stops running |
| [`patch-update`](patch-update) | Update a git-installed app without losing your edits to its files |

## The rule behind them

A check that runs, fails and tells nobody is worse than no check at all. So each script either proves it worked (a backup is downloaded again and compared) or reports to an external monitor that goes red when it fails **or** stops reporting.

## Use

Read a script before running it as root. Fill in its settings block, run it once by hand, then schedule it. Tested on Debian 12.

## Licence

MIT. See [LICENSE](LICENSE).
