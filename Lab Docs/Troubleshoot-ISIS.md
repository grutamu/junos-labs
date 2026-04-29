# Troubleshooting Lab — IS-IS

## Deploy

```bash
cd ~/development/github/junos-labs
sudo containerlab deploy -t troubleshoot-isis.clab.yml

ssh admin@clab-troubleshoot-isis-r1
ssh admin@clab-troubleshoot-isis-r2
ssh admin@clab-troubleshoot-isis-r3
ssh admin@clab-troubleshoot-isis-r4
```

---

## Scenario

IS-IS was configured by a contractor who has since left. The network hasn't been tested end-to-end and you've been asked to verify and fix it.

---

## Intended State

When working correctly, this network should have:

- **r1**: L1/L2 router in area 49.0001
- **r2**: L2-only router in area 49.0001
- **r3**: L1-only router in area 49.0002
- **r4**: L1-only router in area 49.0002
- r1 and r2 form an **L2 adjacency**
- r1 and r3 form an **L1 adjacency**
- r3 and r4 form an **L1 adjacency**
- r2 and r4 form an **L2 adjacency**
- All L2 routes (including loopbacks from area 49.0001) are **leaked into area 49.0002** so r3 and r4 can reach all loopbacks

---

## What You're Seeing

Some IS-IS adjacencies are not forming. Routers in area 49.0002 cannot reach loopbacks in area 49.0001.

---

## Your Task

Find and fix **all** faults. The network is considered fixed when:

- [ ] `show isis adjacency` — all four expected adjacencies Up at the correct level on all routers
- [ ] `show isis database` — LSPs from all four routers visible
- [ ] `show route protocol isis` on r3 — routes from area 49.0001 visible (leaked)
- [ ] `ping 10.0.0.2 source 10.0.0.3` — r3 can reach r2's loopback
- [ ] `ping 10.0.0.1 source 10.0.0.4` — r4 can reach r1's loopback

---

## Useful Commands

```
show isis adjacency
show isis adjacency detail
show isis interface
show isis interface detail
show isis database
show isis database detail
show route protocol isis
show configuration protocols isis
show configuration interfaces lo0
show configuration interfaces ge-0/0/0
show configuration interfaces ge-0/0/1
show policy <policy-name>
show log messages | match ISIS
```

---

## Reminder: NET Address Format

```
49.AAAA.SSSS.SSSS.SSSS.00
    ^^^^  ^^^^^^^^^^^^^^^^
    Area    System ID (6 bytes)

10.0.0.1 → 0100.0000.0001
10.0.0.3 → 0100.0000.0003
```

---

## Teardown

```bash
sudo containerlab destroy -t troubleshoot-isis.clab.yml
```
