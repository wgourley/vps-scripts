# Docker port allow-list

Docker bypasses UFW. A port published with `-p 3000:3000` is reachable from the whole internet, even after `ufw deny 3000`.

This restricts chosen published ports to an allow-list of IPs, using the `DOCKER-USER` chain Docker provides for exactly this.

## Install

```bash
cp docker-port-firewall.sh /usr/local/sbin/ && chmod 755 /usr/local/sbin/docker-port-firewall.sh
# edit ALLOW_IPS, PORTS and IFACE at the top
cp docker-port-firewall.service /etc/systemd/system/
systemctl daemon-reload && systemctl enable --now docker-port-firewall
```

Test from **outside** the allow-list (a phone on mobile data): the ports should refuse the connection.

## Notes

- **`--ctorigdstport`** is the important part. By the time traffic reaches `DOCKER-USER`, Docker has already rewritten the destination to the container's port. Matching on `--dport` silently matches the wrong port, and the rule looks right but does nothing.
- If your home IP is dynamic, you can lock yourself out of these ports when it changes. Keep SSH outside this list, and update `ALLOW_IPS` when needed.
- Ports that must stay public (80/443 behind a reverse proxy, a radio stream) simply aren't listed.
