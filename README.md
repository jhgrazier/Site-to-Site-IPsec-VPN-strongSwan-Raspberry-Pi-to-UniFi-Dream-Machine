# Site-to-Site IPsec VPN: strongSwan (Raspberry Pi) <-> UniFi Dream Machine

This guide documents a working site-to-site IPsec VPN using strongSwan on a Raspberry Pi and a UniFi Dream Machine (UDM).

---

## Topology

Local (UDM side):
- 192.168.32.0/24
- 10.10.1.0/24
- 10.20.30.0/24

Remote (Pi side):
- 192.168.40.0/24
- Raspberry Pi IP: 192.168.40.250

Public IP / FQDN:
- UDM WAN: x.x.x.x

---

## Packages

Install strongSwan on the Pi:

```
sudo apt update
sudo apt install -y strongswan strongswan-pki
```

Enable at boot:

```
sudo systemctl enable strongswan-starter
```

---

## Kernel Forwarding

Enable IPv4 forwarding:

```
sudo sysctl -w net.ipv4.ip_forward=1
echo "net.ipv4.ip_forward=1" | sudo tee /etc/sysctl.d/99-ipsec-forwarding.conf
sudo sysctl --system
```

---

## strongSwan Configuration

### /etc/ipsec.conf

```
config setup
    charondebug="ike 1, knl 1"

conn udm-site
    keyexchange=ikev2
    ike=aes256-sha256-modp2048
    esp=aes256-sha256
    authby=psk

    left=192.168.40.250
    leftid=@far-pi
    leftsubnet=192.168.40.0/24

    right=x.x.x.x
    rightid=@x.x.x.x
    rightsubnet=192.168.32.0/24,10.10.1.0/24,10.20.30.0/24

    dpddelay=30s
    dpdtimeout=120s
    dpdaction=restart

    auto=start
```

Important:
- Use straight quotes only.
- left and right IDs must match UDM configuration exactly.

---

### /etc/ipsec.secrets

```
@far-pi @home.grazierfamily.com : PSK "REPLACE_WITH_SHARED_KEY"
```

Quotes must be ASCII double quotes.

---

## UniFi Dream Machine Settings

Create a Site-to-Site VPN:
- VPN Type: Manual IPsec
- IKE Version: IKEv2
- Authentication: Pre-Shared Key
- IKE Proposal:
  - AES-256
  - SHA-256
  - DH Group 14
- ESP Proposal:
  - AES-256
  - SHA-256
  - PFS disabled or Group 14
- Local Networks:
  - 192.168.32.0/24
  - 10.10.1.0/24
  - 10.20.30.0/24
- Remote Networks:
  - 192.168.40.0/24
- Remote Gateway:
  - Pi public IP or dynamic DNS

Disable NAT-T only if both sides have public IPs. Otherwise keep enabled.

---

## Start and Verify

Restart strongSwan:

```
sudo systemctl restart strongswan-starter
```

Check status:

```
ipsec statusall
```

You should see:
- IKE_SA: ESTABLISHED
- CHILD_SA: INSTALLED
- Traffic counters increasing

---

## Routing and Firewall

The Pi acts as a router only.
- Do not SNAT VPN traffic.
- Forward policy must allow traffic.

Flush test rules if needed:

```
sudo iptables -F
sudo iptables -P FORWARD ACCEPT
```

---

## Testing

From Pi:
```
ping 192.168.32.10
```

From UDM LAN:
```
traceroute 192.168.40.88
```

Expected:
- Hop through Pi
- Replies from remote hosts

---

## Debugging

Live logs:

```
journalctl -u strongswan-starter -f
```

Common issues:
- AUTH_FAILED: PSK mismatch or ID mismatch
- NO_PROP: ESP or IKE proposal mismatch
- Traffic seen but no replies: routing or firewall on remote host

---

## Notes

- UDM may periodically renegotiate CHILD_SA.
- Multiple remote subnets work in a single tunnel.
- strongSwan starts automatically at boot.

---

## Status

Verified working:
- IKEv2
- NAT traversal
- Multi-subnet routing
- Bidirectional ICMP and TCP traffic
