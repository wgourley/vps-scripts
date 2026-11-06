#!/bin/bash
# Limit Docker-published ports to an allow-list of IPs.
# https://github.com/wgourley/vps-scripts
#
# Docker publishes ports with its own iptables rules, which run before UFW's,
# so "ufw deny 3000" does nothing for a container port. Docker leaves one hook
# for you: the DOCKER-USER chain. This script fills it.
#
# Traffic to a published port has already been DNAT-ed by the time it reaches
# DOCKER-USER, so the destination port is the container's, not the public one.
# --ctorigdstport matches the port the client originally asked for instead.

# ---- settings -----------------------------------------------------------
ALLOW_IPS="203.0.113.10"                 # space-separated IPs/CIDRs allowed in
PORTS="1935 2022 3000 21000:21100"       # published ports to restrict (ranges with :)
IFACE="eth0"                             # public interface
CHAIN="DOCKER-ALLOWLIST"
# --------------------------------------------------------------------------

set -e
iptables -N "$CHAIN" 2>/dev/null || true
iptables -F "$CHAIN"

for ip in $ALLOW_IPS; do
  iptables -A "$CHAIN" -s "$ip" -j RETURN
done

for p in $PORTS; do
  iptables -A "$CHAIN" -p tcp -m conntrack --ctstate NEW \
    --ctorigdstport "$p" --ctdir ORIGINAL -j REJECT --reject-with tcp-reset
done

# Hook it into DOCKER-USER once (idempotent).
iptables -C DOCKER-USER -i "$IFACE" -j "$CHAIN" 2>/dev/null || \
  iptables -I DOCKER-USER -i "$IFACE" -j "$CHAIN"

echo "$CHAIN: $(iptables -S "$CHAIN" | grep -c REJECT) port rules, allow-list: $ALLOW_IPS"
