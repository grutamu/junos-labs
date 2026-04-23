# Troubleshooting Lab — BGP

## Deploy

```bash
cd ~/development/github/junos-labs
sudo containerlab deploy -t troubleshoot-bgp.clab.yml

ssh admin@clab-troubleshoot-bgp-r1
ssh admin@clab-troubleshoot-bgp-r2
ssh admin@clab-troubleshoot-bgp-r3
ssh admin@clab-troubleshoot-bgp-r4
```

---

## Scenario

OSPF is already running and confirmed working as the underlay. A BGP configuration was pushed to all four routers but the network team is seeing session failures and routes not propagating as expected.

---

## Intended State

When working correctly, this network should have:

- **eBGP** sessions:
  - r1 (AS 65001) ↔ r3 (AS 65002) via 10.0.13.x
  - r2 (AS 65001) ↔ r4 (AS 65003) via 10.0.24.x
- **iBGP** session between r1 and r2, sourced from loopback addresses
- All four loopbacks advertised into BGP and reachable end-to-end
- Routes from r3 visible on r2, and routes from r4 visible on r1 (via iBGP propagation)

---

## What You're Seeing

BGP sessions are not all established. Even where sessions do come up, routes may not be propagating correctly.

---

## Your Task

Find and fix **all** faults. The network is considered fixed when:

- [ ] `show bgp summary` — all three BGP sessions (r1-r2, r1-r3, r2-r4) **Established**
- [ ] `show route protocol bgp` — all four loopbacks visible on every router
- [ ] `ping 10.0.0.3 source 10.0.0.2` — r2 can reach r3's loopback
- [ ] `ping 10.0.0.4 source 10.0.0.1` — r1 can reach r4's loopback
- [ ] `show route 10.0.0.3 detail` on r2 — next-hop is reachable (not hidden)

---

## Useful Commands

```
show bgp summary
show bgp neighbor <ip> detail
show route protocol bgp
show route <prefix> detail
show route advertising-protocol bgp <ip>
show route receive-protocol bgp <ip>
show configuration protocols bgp
show log messages | match BGP
```

---

## Teardown

```bash
sudo containerlab destroy -t troubleshoot-bgp.clab.yml
```
