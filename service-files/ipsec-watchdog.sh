#!/usr/bin/env bash
set -euo pipefail

CONN="udm-site"
S="$(ipsec statusall 2>/dev/null || true)"

# Must have both IKE and CHILD up
if ! grep -qE "^ *${CONN}\\[[0-9]+\\]: ESTABLISHED" <<<"$S" || \
   ! grep -qE "^ *${CONN}\\{[0-9]+\\}: +INSTALLED, +TUNNEL" <<<"$S"; then
  logger -t ipsec-watchdog "Tunnel not healthy, restarting strongswan-starter"
  systemctl restart strongswan-starter
fi
