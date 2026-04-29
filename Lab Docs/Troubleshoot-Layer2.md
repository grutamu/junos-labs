# Troubleshooting Lab — Layer 2 Switching

## Deploy

```bash
cd ~/development/github/junos-labs
sudo containerlab deploy -t troubleshoot-l2.clab.yml

ssh admin@clab-troubleshoot-l2-sw1
ssh admin@clab-troubleshoot-l2-sw2
ssh admin@clab-troubleshoot-l2-sw3
ssh admin@clab-troubleshoot-l2-sw4
```

---

## Scenario

A campus switching network was configured and handed off. Multiple complaints have come in: the LAG between core switches isn't bundling, the wrong switch is the STP root, and the inter-VLAN routing isn't working as expected. Also, VLAN 30 hosts on sw3 cannot reach other VLANs.

---

## Intended State

When working correctly, this network should have:

- **LAG (ae0)** between sw1 and sw2 with LACP — both physical member links active and bundled
- **sw1 as the RSTP root bridge** (lowest priority) for all VLANs
- **VLANs 10, 20, 30** present on all switches
- All trunk links carrying all three VLANs (10, 20, 30) — including sw1–sw3
- **IRB on sw1**: irb.10 = 192.168.10.1/24 bound to VLAN 10; irb.20 = 192.168.20.1/24 bound to VLAN 20
- **VRRP** on sw1 (Master, priority 200) and sw4 (Backup, priority 100) for VLAN 10 VIP 192.168.10.254

---

## What You're Seeing

- `show lacp interfaces ae0` — member links not Active/Up
- `show spanning-tree bridge` — unexpected root bridge
- VLAN 30 traffic not traversing sw1–sw3 trunk
- `ping 192.168.10.1` from sw1 fails or IRB not routing between VLANs as expected

---

## Your Task

Find and fix **all** faults. The network is considered fixed when:

- [ ] `show lacp interfaces ae0` — both member links **Active** on sw1 and sw2
- [ ] `show spanning-tree bridge` — **sw1 is root** (bridge priority 4096)
- [ ] `show vlans` — VLAN 30 members include sw1–sw3 trunk port on **both** sw1 and sw3
- [ ] `show interfaces irb terse` — irb.10 and irb.20 **up** with correct IPs
- [ ] `show vrrp` — sw1 **Master**, sw4 Backup

---

## Useful Commands

```
show lacp interfaces ae0
show lacp statistics interfaces ae0
show interfaces ae0 detail
show spanning-tree bridge
show spanning-tree interface
show vlans
show ethernet-switching interface
show interfaces irb terse
show vrrp
show vrrp detail
show configuration interfaces ae0
show configuration protocols rstp
show configuration vlans
```

---

## Teardown

```bash
sudo containerlab destroy -t troubleshoot-l2.clab.yml
```
