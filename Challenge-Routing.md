# Challenge Lab — Enterprise Routing Design

No step-by-step commands. Design and implement the solution yourself.

## Deploy

```bash
cd ~/development/github/junos-labs
sudo containerlab deploy -t routing-lab.clab.yml
```

Interfaces and loopbacks are pre-configured. Everything else is up to you.

---

## Scenario

You are the network engineer for a small enterprise. You need to build out the routing infrastructure from scratch to meet the following requirements. The network uses the standard 4-router square topology (r1–r4).

---

## Requirements

### Topology Roles

| Router | Role |
|--------|------|
| r1 | Core router — AS 65001, OSPF ABR, BGP route reflector |
| r2 | Core router — AS 65001, OSPF internal, BGP RR client |
| r3 | Branch router — AS 65002, eBGP peer to r1 |
| r4 | Partner router — AS 65003, eBGP peer to r2 |

---

### IGP: OSPF Multi-Area

- r1–r2 link: Area 0 (backbone)
- r1–r3 link: Area 1
- r2–r4 link: Area 2
- r3–r4 link: not used for OSPF (r3 and r4 are in separate ASes)
- All loopbacks must be advertised as passive interfaces in their respective area
- Area 1 must be configured as a **stub area** — r3 should receive a default route from the ABR, not individual external prefixes
- Configure route summarization at r1: summarize Area 1 loopbacks (10.0.0.3/32) as 10.0.0.0/24 into Area 0
- MD5 authentication on all OSPF interfaces with key `ospf-secret`

---

### eBGP

- r1 peers eBGP with r3 (AS 65002) using direct interface IPs
- r2 peers eBGP with r4 (AS 65003) using direct interface IPs
- Each eBGP router advertises only its own loopback into BGP (no transit prefixes)
- Apply a routing policy on r1: tag all routes received from r3 with community `65001:100`
- Apply a routing policy on r2: routes tagged with `65001:100` received via iBGP should get local-preference 200

---

### iBGP with Route Reflection

- r1 is the route reflector; r2 is its only client
- iBGP sessions use loopback addresses (OSPF provides reachability)
- `next-hop-self` must be set on the iBGP group to ensure next-hops are reachable by the client

---

### Firewall Filter

- Apply a stateless firewall filter on r1's ge-0/0/0 interface (toward r2) in the **input** direction
- The filter must: explicitly permit OSPF, explicitly permit BGP (TCP 179), count all other traffic (do not drop it)

---

## Success Criteria

When your implementation is complete, verify:

- [ ] `show ospf neighbor` — all OSPF adjacencies Full
- [ ] `show ospf database area 1` — no Type 5 LSAs (stub area working)
- [ ] `show route 0.0.0.0/0` on r3 — default route learned from ABR
- [ ] `show ospf database area 0 summary` — 10.0.0.0/24 summary present (not individual /32)
- [ ] `show bgp summary` — all three sessions Established
- [ ] `show route protocol bgp` — all loopbacks reachable across all routers
- [ ] `show route 10.0.0.3 detail` on r2 — local-preference 200 (community policy working)
- [ ] `show route 10.0.0.3 detail` on r2 — next-hop is r1's loopback (next-hop-self working)
- [ ] `show firewall filter` on r1 — OSPF and BGP counters incrementing
