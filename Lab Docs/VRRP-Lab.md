# VRRP Lab — JNCIS-ENT

**Type:** Guided — router interfaces are pre-configured; you configure VRRP from scratch.

## Topology

```
pc1 (192.168.1.100/24)
 |
sw1  ────────────────────────────────────
 |                                       |
r1 ge-0/0/0: 192.168.1.2/24         r2 ge-0/0/0: 192.168.1.3/24
(VRRP master, priority 200)         (VRRP backup, priority 100)
 |                                       |
 └─────── ge-0/0/1 ── ge-0/0/1 ─────────┘
          10.0.12.1/30   10.0.12.2/30  (uplink)

VRRP Group 1 — VIP: 192.168.1.1 (pc1's default gateway)
```

| Node | Interface | Address | Role |
|------|-----------|---------|------|
| pc1  | eth1      | 192.168.1.100/24 | Endpoint (gw: 192.168.1.1) |
| sw1  | ge-0/0/0–2 | — | Transparent L2 (VLAN 10) |
| r1   | ge-0/0/0  | 192.168.1.2/24 | VRRP master |
| r1   | ge-0/0/1  | 10.0.12.1/30   | Uplink |
| r2   | ge-0/0/0  | 192.168.1.3/24 | VRRP backup |
| r2   | ge-0/0/1  | 10.0.12.2/30   | Uplink |

## Deploy

```bash
sudo containerlab deploy -t vrrp-lab.clab.yml
```

## Access

```bash
ssh admin@clab-vrrp-lab-r1
ssh admin@clab-vrrp-lab-r2
ssh admin@clab-vrrp-lab-sw1
docker exec -it clab-vrrp-lab-pc1 sh
```

---

## Task 1 — Baseline Verification

Before configuring VRRP, verify the pre-loaded addressing is correct.

**On r1:**
```
show interfaces ge-0/0/0 brief
show interfaces ge-0/0/1 brief
ping 192.168.1.3           # r2 LAN IP
ping 10.0.12.2             # r2 uplink IP
```

**On pc1:**
```
# The VIP 192.168.1.1 does not respond yet — that's expected
ip addr show eth1
ping 192.168.1.2           # r1 LAN IP — should succeed
ping 192.168.1.3           # r2 LAN IP — should succeed
ping 192.168.1.1           # VIP — fails until VRRP is configured
```

---

## Task 2 — Configure VRRP

VRRP is configured under the interface address stanza on both routers. The router with the higher priority wins the master election.

### r1 — Master (priority 200)

```
configure

set interfaces ge-0/0/0 unit 0 family inet address 192.168.1.2/24 vrrp-group 1 virtual-address 192.168.1.1
set interfaces ge-0/0/0 unit 0 family inet address 192.168.1.2/24 vrrp-group 1 priority 200
set interfaces ge-0/0/0 unit 0 family inet address 192.168.1.2/24 vrrp-group 1 preempt

commit
```

### r2 — Backup (default priority 100)

```
configure

set interfaces ge-0/0/0 unit 0 family inet address 192.168.1.3/24 vrrp-group 1 virtual-address 192.168.1.1
set interfaces ge-0/0/0 unit 0 family inet address 192.168.1.3/24 vrrp-group 1 preempt

commit
```

> Priority defaults to 100 on r2 — no explicit set needed. Always configure `preempt` on both so the higher-priority router reclaims master after recovering.

---

## Task 3 — Verify VRRP State

**On r1 (expect master):**
```
show vrrp
show vrrp detail
```

Look for:
- `State: Master` on r1
- `State: Backup` on r2
- `Virtual IP: 192.168.1.1`
- `Priority: 200` on r1, `Priority: 100` on r2

**From pc1:**
```
ping 192.168.1.1    # VIP — should now succeed (r1 is answering)
```

**Check which router owns the VIP MAC:**
```
# On pc1
ip neigh show        # 192.168.1.1 should have the VRRP virtual MAC (00:00:5e:00:01:01)
```

The VRRP virtual MAC is always `00:00:5e:00:01:<group-id-hex>` — group 1 = `01`.

---

## Task 4 — Test Manual Failover

Simulate r1 failure by taking down its LAN interface. Watch r2 assume master.

**On r1:**
```
configure
set interfaces ge-0/0/0 disable
commit
```

**On r2 (within a few seconds):**
```
show vrrp
# Expect: State: Master
```

**From pc1:**
```
ping 192.168.1.1    # Should still succeed after r2 takes over
```

**Restore r1:**
```
# On r1
configure
delete interfaces ge-0/0/0 disable
commit
```

With `preempt` configured, r1 reclaims master once it recovers (watch the brief traffic interruption).

---

## Task 5 — Interface Tracking

Interface tracking lets VRRP automatically lower a router's priority when its uplink fails — triggering failover without manually shutting the LAN interface.

**Scenario:** If r1's uplink (`ge-0/0/1`) goes down, decrement r1's priority by 150. This drops it from 200 to 50, below r2's 100, so r2 wins master.

**On r1:**
```
configure

set interfaces ge-0/0/0 unit 0 family inet address 192.168.1.2/24 vrrp-group 1 track interface ge-0/0/1 priority-cost 150

commit
```

**Verify tracking config:**
```
show vrrp detail
# Look for: Track: ge-0/0/1  Cost: 150
```

**Test — bring down r1's uplink:**
```
configure
set interfaces ge-0/0/1 disable
commit
```

**On r2 (within a few seconds):**
```
show vrrp
# Expect: State: Master  (r1's effective priority dropped to 50)
```

**From pc1:**
```
ping 192.168.1.1    # Continues working via r2
```

**Restore uplink on r1:**
```
configure
delete interfaces ge-0/0/1 disable
commit
# r1 priority returns to 200, preempt kicks in, r1 reclaims master
```

---

## Verification Reference

| Command | What to Check |
|---------|---------------|
| `show vrrp` | State (Master/Backup), VIP, priority |
| `show vrrp detail` | Timers, tracking, advertisement intervals |
| `show vrrp statistics` | Advertisement counts, preemption events |
| `show interfaces ge-0/0/0 detail` | VRRP group summary under inet section |
| `monitor traffic interface ge-0/0/0` | Live VRRP advertisement packets (proto 112) |

## Key Concepts

- **Virtual IP (VIP):** The shared gateway address that clients point to. Owned by the master at any given time.
- **Virtual MAC:** `00:00:5e:00:01:<group-hex>` — static MAC that moves with the VIP so ARP caches don't need to flush.
- **Priority:** 1–254, higher wins. Default is 100. Owner of the VIP IP gets automatic priority 255.
- **Preempt:** Allows a recovered high-priority router to reclaim master. Without it, a backup stays master even after the original master returns.
- **Advertisement interval:** How often the master sends VRRP hellos (default 1 second). Backup declares master dead after 3× missed hellos.
- **Interface tracking:** Dynamically adjusts priority based on uplink state, enabling automatic failover on upstream failures.

## Destroy

```bash
sudo containerlab destroy -t vrrp-lab.clab.yml
```
