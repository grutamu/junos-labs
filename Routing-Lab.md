# Routing Lab

Covers OSPF, IS-IS, BGP, Routing Policy, Firewall Filters, and Class of Service on a single 4-router topology. Interfaces and loopbacks are pre-configured — jump straight to the protocol you're studying.

---

## Deploy

```bash
cd ~/development/github/junos-labs
sudo containerlab deploy -t routing-lab.clab.yml
```

SSH into nodes:
```bash
ssh admin@clab-routing-lab-r1
ssh admin@clab-routing-lab-r2
ssh admin@clab-routing-lab-r3
ssh admin@clab-routing-lab-r4
```

> If startup-config didn't apply (vrnetlab can be inconsistent), paste `configs/routing/rN.conf` manually:
> ```
> configure
> load merge terminal   # paste contents, then Ctrl-D
> commit
> ```

### Topology

```
        lo0: 10.0.0.1/32             lo0: 10.0.0.2/32
        r1 ----[10.0.12.0/30]---- r2
        |                           |
  [10.0.13.0/30]            [10.0.24.0/30]
        |                           |
        r3 ----[10.0.34.0/30]---- r4
        lo0: 10.0.0.3/32             lo0: 10.0.0.4/32
```

| Link  | Interface (left)       | Interface (right)      |
|-------|------------------------|------------------------|
| r1–r2 | r1 ge-0/0/0 10.0.12.1/30 | r2 ge-0/0/0 10.0.12.2/30 |
| r1–r3 | r1 ge-0/0/1 10.0.13.1/30 | r3 ge-0/0/0 10.0.13.2/30 |
| r2–r4 | r2 ge-0/0/1 10.0.24.1/30 | r4 ge-0/0/0 10.0.24.2/30 |
| r3–r4 | r3 ge-0/0/1 10.0.34.1/30 | r4 ge-0/0/1 10.0.34.2/30 |

### Junos CLI Reminders
```
configure                 # enter config mode
show | compare            # diff before committing
commit check              # validate
commit                    # apply
rollback 1 ; commit       # undo last commit
run show ...              # op command from config mode
```

---

---

# Section 1 — OSPF

## 1a — Single Area

**Objective:** Adjacency formation, LSDB inspection, MD5 auth, metric manipulation.

### Task 1 — Enable OSPF Area 0
Enable OSPF on all routers. Add loopbacks as **passive** so they are advertised but don't form adjacencies.

**All routers:**
```
set protocols ospf area 0.0.0.0 interface ge-0/0/0.0
set protocols ospf area 0.0.0.0 interface ge-0/0/1.0
set protocols ospf area 0.0.0.0 interface lo0.0 passive
commit
```

```
show ospf neighbor          # expect Full state on all links
show ospf database          # Router + Network LSAs
show ospf interface
```

### Task 2 — MD5 Authentication
Apply matching key on both ends of each link.

```
set protocols ospf area 0.0.0.0 interface ge-0/0/0.0 authentication md5 1 key "juniper123"
set protocols ospf area 0.0.0.0 interface ge-0/0/1.0 authentication md5 1 key "juniper123"
commit
```

```
show ospf neighbor
show ospf interface detail    # authentication mode: md5
```

### Task 3 — Verify Full Reachability
```
show route protocol ospf
ping 10.0.0.4 source 10.0.0.1 count 5
```

### Task 4 — Metric Manipulation
Force r1→r2 traffic to take the long path: r1 → r3 → r4 → r2.

**On r1:**
```
set protocols ospf area 0.0.0.0 interface ge-0/0/0.0 metric 1000
commit
```

```
show route 10.0.0.2 detail
traceroute 10.0.0.2 source 10.0.0.1
show ospf route 10.0.0.2     # next-hop via r3 (10.0.13.2)
```

**Key Concepts:**
- Hello/Dead timers must match on both ends
- DR/BDR elected on broadcast links; highest priority (then RID) wins
- LSA Type 1 = Router LSA (every router), Type 2 = Network LSA (DR on broadcast)
- Passive interface: advertised but no hellos sent

**Checklist:**
- [ ] `show ospf neighbor` — all neighbors Full
- [ ] `show ospf database` — Router + Network LSAs for all routers
- [ ] `show route protocol ospf` — all 4 loopbacks visible
- [ ] `show ospf interface detail` — auth mode md5
- [ ] `traceroute` confirms path change after metric manipulation

---

## 1b — Multi-Area

**Objective:** Configure areas, ABR role, Type 3 LSAs, route summarization, stub and NSSA areas.

**Prerequisite:** Single-area OSPF from 1a must be running.

### Area Layout

```
        Area 0 (Backbone)
        r1 ----[10.0.12.0/30]---- r2
        |                           |
  [Area 1]                    [Area 0]
        |                           |
        r3 ----[10.0.34.0/30]---- r4
        (Area 1)                   (Area 1)
```

| Router | Interface | Area |
|--------|-----------|------|
| r1 | ge-0/0/0 (→r2) | 0 |
| r1 | ge-0/0/1 (→r3) | 1 |
| r1 | lo0 | 0 |
| r2 | ge-0/0/0 (→r1) | 0 |
| r2 | ge-0/0/1 (→r4) | 0 |
| r2 | lo0 | 0 |
| r3 | ge-0/0/0 (→r1) | 1 |
| r3 | ge-0/0/1 (→r4) | 1 |
| r3 | lo0 | 1 |
| r4 | ge-0/0/0 (→r2) | 0 |
| r4 | ge-0/0/1 (→r3) | 1 |
| r4 | lo0 | 1 |

r1 and r4 are **ABRs**.

### Task 1 — Reconfigure Areas

**On r1 (ABR):**
```
delete protocols ospf area 0.0.0.0 interface ge-0/0/1.0
set protocols ospf area 0.0.0.1 interface ge-0/0/1.0
commit
```

**On r3 (Area 1 only):**
```
delete protocols ospf area 0.0.0.0
set protocols ospf area 0.0.0.1 interface ge-0/0/0.0
set protocols ospf area 0.0.0.1 interface ge-0/0/1.0
set protocols ospf area 0.0.0.1 interface lo0.0 passive
commit
```

**On r4 (ABR):**
```
delete protocols ospf area 0.0.0.0 interface ge-0/0/1.0
set protocols ospf area 0.0.0.1 interface ge-0/0/1.0
commit
```

```
show ospf neighbor
show ospf database               # separate per-area LSDBs
show ospf database area 1        # only Area 1 LSAs
show ospf database summary       # Type 3 LSAs from ABRs
```

### Task 2 — Route Summarization at ABR
Add a stub loopback on r3 to simulate an external subnet, then summarize at the ABR.

**On r3:**
```
set interfaces lo0 unit 0 family inet address 172.16.3.1/24
commit
```

**On r1 (ABR — summarize into Area 0):**
```
set protocols ospf area 0.0.0.1 area-range 172.16.0.0/16
commit
```

```
show ospf database summary       # one Type 3 for 172.16.0.0/16 (not /24)
show route 172.16.0.0/16         # on r2
```

### Task 3 — Stub Area
Block Type 5 (external) LSAs from Area 1; ABR injects a default instead.

**On r1, r3, r4 (all Area 1 routers must agree):**
```
set protocols ospf area 0.0.0.1 stub default-metric 10
commit
```

```
show ospf database area 1            # no Type 5 LSAs
show ospf database area 1 summary    # 0.0.0.0/0 default from ABR
show route 0.0.0.0/0                 # on r3, OSPF-learned default
```

### Task 4 — NSSA
Allow external redistribution from Area 1 via Type 7 LSAs.

**On r1, r3, r4:**
```
delete protocols ospf area 0.0.0.1 stub
set protocols ospf area 0.0.0.1 nssa
commit
```

**On r4 (add static + redistribute):**
```
set routing-options static route 10.99.0.0/24 discard
set policy-options policy-statement redistribute-static term 1 from protocol static
set policy-options policy-statement redistribute-static term 1 then accept
set protocols ospf export redistribute-static
commit
```

```
show ospf database area 1 nssa      # Type 7 on r3/r4
show ospf database area 0 external  # Type 5 on r2 (translated by r1)
show route 10.99.0.0/24             # on r2
```

**Key Concepts:**
- ABR = interfaces in multiple areas; generates Type 3 LSAs
- Type 3 = Summary LSA (inter-area prefix); Type 5 = AS External (ASBR); Type 7 = NSSA External
- Stub area: blocks Type 5, ABR injects default. All area routers must agree.
- NSSA: permits Type 7 redistribution; translated to Type 5 at ABR

**Checklist:**
- [ ] `show ospf neighbor` — adjacencies Full
- [ ] `show ospf database summary` — Type 3 LSAs from ABRs
- [ ] `show ospf database area 1` — no Type 5 in stub/NSSA
- [ ] `show ospf database area 1 nssa` — Type 7 after Task 4
- [ ] `show route 10.99.0.0/24` on r2 — confirms NSSA propagation

---

## 1c — Advanced (Virtual Links, Redistribution)

**Objective:** Virtual link for disconnected backbone, external redistribution, E1/E2 metrics, export filtering.

**Prerequisite:** Multi-area OSPF from 1b must be running.

### Task 1 — Virtual Link (Disconnected Backbone)
Simulate r2 losing its direct Area 0 connection. Reconnect via a virtual link through Area 1 as the transit area.

**Step 1 — Remove r1–r2 from Area 0:**
```
# On r1 and r2:
delete protocols ospf area 0.0.0.0 interface ge-0/0/0.0
commit
```

**Step 2 — Move r1–r2 link to Area 1:**
```
# On r1:
set protocols ospf area 0.0.0.1 interface ge-0/0/0.0
# On r2:
set protocols ospf area 0.0.0.1 interface ge-0/0/0.0
commit
```

**Step 3 — Configure virtual link between r1 and r2 (transit area = 1):**
```
# On r1:
set protocols ospf area 0.0.0.1 virtual-link neighbor-id 10.0.0.2 transit-area 0.0.0.1
# On r2:
set protocols ospf area 0.0.0.1 virtual-link neighbor-id 10.0.0.1 transit-area 0.0.0.1
commit
```

```
show ospf virtual-link            # should show Up
show ospf neighbor                # VL neighbor visible
show route 10.0.0.1               # r2 can reach r1 via VL
```

### Task 2 — External Redistribution (ASBR)
On r4, redistribute a static route as a Type 5 External LSA.

**On r4:**
```
set routing-options static route 192.168.100.0/24 discard
set policy-options policy-statement static-to-ospf term 1 from protocol static
set policy-options policy-statement static-to-ospf term 1 then accept
set protocols ospf export static-to-ospf
commit
```

```
show ospf database external       # Type 5 on r1, r2, r3
show route 192.168.100.0/24 detail
```

### Task 3 — E1 vs E2 Metric Types

Change to Type 1 (accumulates internal cost):
```
# On r4:
set policy-options policy-statement static-to-ospf term 1 then external type 1
set policy-options policy-statement static-to-ospf term 1 then metric 10
commit
```

Compare the metric for 192.168.100.0/24 on r1 vs r3 — with E1 they differ; with E2 (default) they are the same.

### Task 4 — Filter Redistribution
Only export specific prefixes; block the rest.

**On r4:**
```
set routing-options static route 192.168.200.0/24 discard
set policy-options prefix-list allowed-statics 192.168.100.0/24
set policy-options policy-statement static-to-ospf term 1 from prefix-list allowed-statics
set policy-options policy-statement static-to-ospf term 2 then reject
commit
```

```
show ospf database external       # only 192.168.100.0/24
show route 192.168.200.0/24       # NOT in OSPF on other routers
```

**Key Concepts:**
- Virtual link extends Area 0 through a transit area; not a permanent fix
- ASBR generates Type 5 LSAs; redistributes routes from outside OSPF
- E2 (default): fixed external metric regardless of internal path cost
- E1: cumulative internal + external cost; more accurate for path selection
- Always add a final `then reject` to export policies to prevent unintended redistribution

**Checklist:**
- [ ] `show ospf virtual-link` — VL neighbor Full
- [ ] `show ospf database external` — Type 5 for 192.168.100.0/24
- [ ] `show route 192.168.100.0/24 detail` — metric type E1/E2 visible
- [ ] After Task 4: only allowed prefix in Type 5 database

---

---

# Transition: OSPF → IS-IS

Run on **all 4 routers:**
```
delete protocols ospf
commit
```

Verify interfaces still have correct IPs:
```
show interfaces terse
```

---

---

# Section 2 — IS-IS

**Objective:** NET addressing, L1/L2 roles, adjacencies, route leaking, authentication, DIS election.

### Area Layout

```
        Area 49.0001                    Area 49.0001
        r1 ----[10.0.12.0/30]---- r2
        |                           |
  [10.0.13.0/30]            [10.0.24.0/30]
        |                           |
        r3 ----[10.0.34.0/30]---- r4
        Area 49.0002                    Area 49.0002
```

| Router | NET Address | Area | Level |
|--------|-------------|------|-------|
| r1 | 49.0001.0100.0000.0001.00 | 49.0001 | L1/L2 |
| r2 | 49.0001.0100.0000.0002.00 | 49.0001 | L2 only |
| r3 | 49.0002.0100.0000.0003.00 | 49.0002 | L1 only |
| r4 | 49.0002.0100.0000.0004.00 | 49.0002 | L1 only |

> NET format: `AFI.Area.SystemID.SEL` — AFI is always `49`, SEL is always `00`.
> SystemID for 10.0.0.1 → `0100.0000.0001`

### Task 1 — Enable IS-IS

IS-IS requires `family iso` on interfaces in addition to `family inet`.

**On r1 (L1/L2 — area boundary):**
```
set interfaces ge-0/0/0 unit 0 family iso
set interfaces ge-0/0/1 unit 0 family iso
set interfaces lo0 unit 0 family iso address 49.0001.0100.0000.0001.00

set protocols isis interface ge-0/0/0.0 level 1 disable
set protocols isis interface ge-0/0/1.0
set protocols isis interface lo0.0 passive
commit
```

**On r2 (L2 only):**
```
set interfaces ge-0/0/0 unit 0 family iso
set interfaces ge-0/0/1 unit 0 family iso
set interfaces lo0 unit 0 family iso address 49.0001.0100.0000.0002.00

set protocols isis interface ge-0/0/0.0 level 1 disable
set protocols isis interface ge-0/0/1.0 level 1 disable
set protocols isis interface lo0.0 passive
commit
```

**On r3 (L1 only — Area 49.0002):**
```
set interfaces ge-0/0/0 unit 0 family iso
set interfaces ge-0/0/1 unit 0 family iso
set interfaces lo0 unit 0 family iso address 49.0002.0100.0000.0003.00

set protocols isis interface ge-0/0/0.0 level 2 disable
set protocols isis interface ge-0/0/1.0 level 2 disable
set protocols isis interface lo0.0 passive
commit
```

**On r4 (L1 only — Area 49.0002):**
```
set interfaces ge-0/0/0 unit 0 family iso
set interfaces ge-0/0/1 unit 0 family iso
set interfaces lo0 unit 0 family iso address 49.0002.0100.0000.0004.00

set protocols isis interface ge-0/0/0.0 level 2 disable
set protocols isis interface ge-0/0/1.0 level 2 disable
set protocols isis interface lo0.0 passive
commit
```

### Task 2 — Verify Adjacencies
```
show isis adjacency          # r1: L1 adj with r3, L2 adj with r2
show isis database           # LSPs per level
show isis database detail    # IP reachability TLVs
show route protocol isis
```

Expected: r3 and r4 (L1 only) will NOT see routes from Area 49.0001 without route leaking.

```
ping 10.0.0.2 source 10.0.0.3   # likely fails without leaking
```

### Task 3 — Route Leaking (L2 → L1)
On r1 (the L1/L2 router), leak L2 routes into L1 so r3/r4 can see Area 49.0001.

**On r1:**
```
set policy-options policy-statement leak-l2-to-l1 term 1 from protocol isis
set policy-options policy-statement leak-l2-to-l1 term 1 from level 2
set policy-options policy-statement leak-l2-to-l1 term 1 then accept
set protocols isis export leak-l2-to-l1
commit
```

```
show route protocol isis         # on r3 — now sees 10.0.0.1/32 and 10.0.0.2/32
ping 10.0.0.2 source 10.0.0.3
```

### Task 4 — IS-IS Authentication
Apply HMAC-MD5 on interfaces. Must match on both ends.

```
set protocols isis interface ge-0/0/0.0 level 2 authentication-key "juniper123" authentication-type md5
set protocols isis interface ge-0/0/1.0 level 1 authentication-key "juniper123" authentication-type md5
commit
```

```
show isis adjacency
show log messages | match auth
```

### Task 5 — DIS Election
On broadcast links, IS-IS elects a DIS (no backup, unlike OSPF DR/BDR).

```
show isis interface detail    # shows current DIS and priority
```

Set r1 as DIS on ge-0/0/0:
```
set protocols isis interface ge-0/0/0.0 level 2 priority 127   # default 64
commit
```

**IS-IS vs OSPF:**

| Feature | OSPF | IS-IS |
|---------|------|-------|
| Area boundary | Router (ABR) | Link |
| Database units | LSAs | LSPs |
| Hello uses | IP (protocol 89) | L2 frames (not IP) |
| Backbone | Area 0 | L2 routers |
| Default to L1 | ABR injects Type 3 0/0 | L1/L2 sets ATT bit |

**Checklist:**
- [ ] `show isis adjacency` — all expected adjacencies Up at correct level
- [ ] `show isis database` — LSPs from all routers at each level
- [ ] `show route protocol isis` — leaked routes visible on r3
- [ ] `ping 10.0.0.2 source 10.0.0.3` — succeeds after leaking
- [ ] `show isis interface detail` — auth mode and DIS visible

---

---

# Transition: IS-IS → BGP

### Step 1 — Remove IS-IS (all 4 routers)
```
delete protocols isis
delete interfaces ge-0/0/0 unit 0 family iso
delete interfaces ge-0/0/1 unit 0 family iso
delete interfaces lo0 unit 0 family iso
commit
```

### Step 2 — Restore OSPF underlay (paste on all 4 routers)
BGP iBGP sessions use loopbacks — OSPF provides reachability between them.

```
set protocols ospf area 0.0.0.0 interface ge-0/0/0.0
set protocols ospf area 0.0.0.0 interface ge-0/0/1.0
set protocols ospf area 0.0.0.0 interface lo0.0 passive
commit
```

Verify:
```
show ospf neighbor
show route 10.0.0.2        # on r1 — via OSPF
```

---

---

# Section 3 — BGP

## 3a — Foundation (eBGP + iBGP)

**Objective:** eBGP and iBGP sessions, BGP table vs routing table, next-hop self, Local Preference, MED.

### AS Assignments

```
AS 65002        AS 65001 (r1 + r2)        AS 65003
  r3 --[eBGP]-- r1 ===[iBGP]=== r2 --[eBGP]-- r4
```

| Router | AS | Role |
|--------|----|------|
| r1 | 65001 | eBGP to r3, iBGP to r2 |
| r2 | 65001 | eBGP to r4, iBGP to r1 |
| r3 | 65002 | eBGP to r1 |
| r4 | 65003 | eBGP to r2 |

### Task 1 — eBGP Sessions (direct interface IPs)

**On r1:**
```
set protocols bgp local-as 65001
set protocols bgp group EBGP type external
set protocols bgp group EBGP peer-as 65002
set protocols bgp group EBGP neighbor 10.0.13.2 description "r3"
commit
```

**On r3:**
```
set protocols bgp local-as 65002
set protocols bgp group EBGP type external
set protocols bgp group EBGP peer-as 65001
set protocols bgp group EBGP neighbor 10.0.13.1 description "r1"
commit
```

Mirror for r2 ↔ r4 (using 10.0.24.x, peer-as 65003).

```
show bgp summary               # Established state
show bgp neighbor 10.0.13.2 detail
```

### Task 2 — iBGP Session (loopback addresses)

**On r1:**
```
set protocols bgp group IBGP type internal
set protocols bgp group IBGP local-address 10.0.0.1
set protocols bgp group IBGP neighbor 10.0.0.2 description "r2"
commit
```

**On r2:**
```
set protocols bgp group IBGP type internal
set protocols bgp group IBGP local-address 10.0.0.2
set protocols bgp group IBGP neighbor 10.0.0.1 description "r1"
commit
```

```
show bgp summary    # 3 sessions: r1-r2 iBGP, r1-r3 eBGP, r2-r4 eBGP
```

### Task 3 — Advertise Loopbacks into BGP

**On r1 (repeat for r2, r3, r4 with their own loopback):**
```
set policy-options policy-statement advertise-loopback term 1 from protocol direct
set policy-options policy-statement advertise-loopback term 1 from route-filter 10.0.0.1/32 exact
set policy-options policy-statement advertise-loopback term 1 then accept
set policy-options policy-statement advertise-loopback term 2 then reject
set protocols bgp group EBGP export advertise-loopback
commit
```

```
show route protocol bgp
show route advertising-protocol bgp 10.0.13.2
show route receive-protocol bgp 10.0.13.2
```

### Task 4 — Fix iBGP Next-Hop Issue

**Problem:** r1 forwards routes from r3 to r2 via iBGP with the original next-hop (10.0.13.2), which r2 cannot reach.

```
show route 10.0.0.3 detail    # on r2 — next-hop likely hidden
```

**Fix on r1:**
```
set protocols bgp group IBGP neighbor 10.0.0.2 next-hop-self
commit
```

```
show route 10.0.0.3 detail    # on r2 — next-hop now 10.0.0.1 (reachable via OSPF)
ping 10.0.0.3 source 10.0.0.2
```

### Task 5 — Local Preference
Highest LP wins within the AS (iBGP only). Make r1 prefer paths from r3.

**On r1:**
```
set policy-options policy-statement set-local-pref term 1 from neighbor 10.0.13.2
set policy-options policy-statement set-local-pref term 1 then local-preference 200
set protocols bgp group EBGP import set-local-pref
commit
```

```
show route 10.0.0.4 detail    # on r2 — local-pref 200 via r1 path
```

### Task 6 — MED
MED influences ingress path — lower MED is preferred. Set on r3 to influence how r1 enters r3's AS.

**On r3:**
```
set policy-options policy-statement set-med term 1 then metric 50
set protocols bgp group EBGP export set-med
commit
```

```
show route receive-protocol bgp 10.0.13.2 detail   # on r1 — MED 50 visible
```

**BGP Best-Path Order (Junos):**
1. Highest Local Preference
2. Shortest AS Path
3. Lowest Origin (IGP < EGP < Incomplete)
4. Lowest MED (same AS only)
5. eBGP over iBGP
6. Lowest IGP metric to next-hop
7. Lowest BGP Router ID (tie-breaker)

**Checklist:**
- [ ] `show bgp summary` — all sessions Established
- [ ] `show route protocol bgp` — all loopbacks reachable
- [ ] `show route 10.0.0.3 detail` on r2 — next-hop is r1 loopback
- [ ] `show route 10.0.0.4 detail` on r2 — local-pref 200
- [ ] `ping 10.0.0.4 source 10.0.0.3` — end-to-end across ASes

---

## 3b — Advanced BGP (Route Reflection, Communities, BFD)

**Objective:** Scale iBGP with route reflection, community tagging, AS-path filtering, BFD.

**Prerequisite:** BGP sessions from 3a must be running.

### Task 1 — Route Reflection
R1 becomes the Route Reflector; r2 is its client.

**On r1 (RR):**
```
delete protocols bgp group IBGP neighbor 10.0.0.2
set protocols bgp group IBGP-RR type internal
set protocols bgp group IBGP-RR local-address 10.0.0.1
set protocols bgp group IBGP-RR cluster 1.1.1.1
set protocols bgp group IBGP-RR neighbor 10.0.0.2 description "r2 RR-Client"
commit
```

**On r2 (client — points to RR, no special config):**
```
delete protocols bgp group IBGP neighbor 10.0.0.1
set protocols bgp group IBGP type internal
set protocols bgp group IBGP local-address 10.0.0.2
set protocols bgp group IBGP neighbor 10.0.0.1 description "r1 Route Reflector"
commit
```

```
show bgp summary
show route receive-protocol bgp 10.0.0.1 detail   # on r2 — look for ORIGINATOR_ID and CLUSTER_LIST
```

### Task 2 — Community Tagging on Ingress
Tag all routes received from r3 with community 65001:100 on r1.

**On r1:**
```
set policy-options community FROM-R3 members 65001:100
set policy-options policy-statement tag-r3-routes term 1 from neighbor 10.0.13.2
set policy-options policy-statement tag-r3-routes term 1 then community add FROM-R3
set policy-options policy-statement tag-r3-routes term 1 then accept
set protocols bgp group EBGP import tag-r3-routes
commit
```

```
show route receive-protocol bgp 10.0.13.2 detail   # on r1 — community 65001:100
show route 10.0.0.3 detail                          # on r2 — community visible in reflected route
```

### Task 3 — Act on Community in Policy
On r2, raise local-pref for routes tagged with 65001:100.

**On r2:**
```
set policy-options community FROM-R3 members 65001:100
set policy-options policy-statement prefer-r3 term 1 from community FROM-R3
set policy-options policy-statement prefer-r3 term 1 then local-preference 200
set policy-options policy-statement prefer-r3 term 1 then accept
set protocols bgp group IBGP import prefer-r3
commit
```

### Task 4 — AS-Path Regex Filtering
Block routes that transited AS 65003.

**On r2:**
```
set policy-options as-path THROUGH-65003 ".* 65003 .*"
set policy-options policy-statement block-65003 term 1 from as-path THROUGH-65003
set policy-options policy-statement block-65003 term 1 then reject
set policy-options policy-statement block-65003 term 2 then accept
set protocols bgp group IBGP import block-65003
commit
```

```
show route 10.0.0.4      # should NOT be in r2's routing table
```

Common AS-path regex:
- `"^$"` — locally originated
- `"^65002$"` — originated directly by AS 65002
- `".* 65003"` — transiting 65003
- `"^65002 .*"` — first AS is 65002

### Task 5 — Prefix-List Filtering on eBGP
Limit what r1 advertises to r3 to only its own loopback.

**On r1:**
```
set policy-options prefix-list my-prefixes 10.0.0.1/32
set policy-options policy-statement advertise-mine-only term 1 from prefix-list my-prefixes
set policy-options policy-statement advertise-mine-only term 1 then accept
set policy-options policy-statement advertise-mine-only term 2 then reject
set protocols bgp group EBGP export advertise-mine-only
commit
```

```
show route advertising-protocol bgp 10.0.13.2    # only 10.0.0.1/32
```

### Task 6 — BFD for Fast Failure Detection
BGP hold timer is 90s by default. BFD can detect failures in <1s.

**On r1 and r3:**
```
set protocols bgp group EBGP neighbor 10.0.13.2 bfd-liveness-detection minimum-interval 300
set protocols bgp group EBGP neighbor 10.0.13.2 bfd-liveness-detection multiplier 3
commit
```

```
show bfd session
show bgp neighbor 10.0.13.2 detail | match BFD
```

### Task 7 — Graceful Restart
Allow forwarding to continue during BGP session restart.

**All routers:**
```
set protocols bgp graceful-restart
commit
```

**Checklist:**
- [ ] `show bgp summary` — all sessions Established
- [ ] `show route receive-protocol bgp 10.0.0.1 detail` on r2 — ORIGINATOR_ID + CLUSTER_LIST
- [ ] `show route detail` — community 65001:100 on r3 routes
- [ ] `show route 10.0.0.4` on r2 — absent after AS-path filter
- [ ] `show bfd session` — BFD Up

---

## 3c — Routing Policy & Firewall Filters

**Objective:** Multi-term policies, policy chaining, prefix-list reuse, stateless firewall filters, policers.

**Prerequisite:** OSPF + BGP running from 3a/3b.

### Junos Policy Framework

```
Import policy: runs when receiving routes → into routing table
Export policy: runs when advertising routes → to peers

Term evaluation: first match wins
Default: BGP import = accept; BGP export = reject
Always add explicit final term to control behavior.
```

### Task 1 — Multi-Term Import Policy

**On r1:**
```
set policy-options prefix-list preferred-nets 10.0.0.0/8 upto /32
set policy-options community PARTNER members 65002:200

set policy-options policy-statement complex-import term 1 from prefix-list preferred-nets
set policy-options policy-statement complex-import term 1 from community PARTNER
set policy-options policy-statement complex-import term 1 then local-preference 200
set policy-options policy-statement complex-import term 1 then accept

set policy-options policy-statement complex-import term 2 from prefix-list preferred-nets
set policy-options policy-statement complex-import term 2 then local-preference 150
set policy-options policy-statement complex-import term 2 then accept

set policy-options policy-statement complex-import term default then reject

set protocols bgp group EBGP import complex-import
commit
```

```
show route receive-protocol bgp 10.0.13.2 detail   # local-pref varies by term
show policy complex-import
```

### Task 2 — Policy Chaining
Chain two policies: first tags community, second acts on it. Use `next policy` to pass control between policies without accepting/rejecting.

**On r1:**
```
set policy-options policy-statement tag-community term 1 from neighbor 10.0.13.2
set policy-options policy-statement tag-community term 1 then community add PARTNER
set policy-options policy-statement tag-community term 1 then next policy

set policy-options policy-statement set-lp term 1 from community PARTNER
set policy-options policy-statement set-lp term 1 then local-preference 180
set policy-options policy-statement set-lp term 1 then accept
set policy-options policy-statement set-lp term 2 then accept

set protocols bgp group EBGP import [tag-community set-lp]
commit
```

### Task 3 — Stateless Firewall Filter (Input)
Apply on r1 ge-0/0/0 (toward r2): permit OSPF, permit BGP, count/log the rest.

**On r1:**
```
set firewall family inet filter TRANSIT-FILTER term ALLOW-OSPF from protocol ospf
set firewall family inet filter TRANSIT-FILTER term ALLOW-OSPF then accept

set firewall family inet filter TRANSIT-FILTER term ALLOW-BGP from protocol tcp
set firewall family inet filter TRANSIT-FILTER term ALLOW-BGP from destination-port bgp
set firewall family inet filter TRANSIT-FILTER term ALLOW-BGP then accept

set firewall family inet filter TRANSIT-FILTER term COUNT-REST then count TRANSIT-OTHER
set firewall family inet filter TRANSIT-FILTER term COUNT-REST then log
set firewall family inet filter TRANSIT-FILTER term COUNT-REST then accept

set interfaces ge-0/0/0 unit 0 family inet filter input TRANSIT-FILTER
commit
```

```
show firewall filter TRANSIT-FILTER    # per-term counters
show interfaces ge-0/0/0 detail | match filter
```

### Task 4 — Output Firewall Filter
Block RFC1918 destinations on egress from r1 ge-0/0/1 (toward r3).

**On r1:**
```
set firewall family inet filter EGRESS-FILTER term BLOCK-RFC1918 from destination-address 10.0.0.0/8
set firewall family inet filter EGRESS-FILTER term BLOCK-RFC1918 from destination-address 172.16.0.0/12
set firewall family inet filter EGRESS-FILTER term BLOCK-RFC1918 from destination-address 192.168.0.0/16
set firewall family inet filter EGRESS-FILTER term BLOCK-RFC1918 then discard
set firewall family inet filter EGRESS-FILTER term ALLOW-REST then accept

set interfaces ge-0/0/1 unit 0 family inet filter output EGRESS-FILTER
commit
```

### Task 5 — Policer (Rate Limiting)
Rate-limit ICMP to 1 Mbps on TRANSIT-FILTER. Insert this term before COUNT-REST.

**On r1:**
```
set firewall policer ICMP-LIMIT if-exceeding bandwidth-limit 1m
set firewall policer ICMP-LIMIT if-exceeding burst-size-limit 10k
set firewall policer ICMP-LIMIT then discard

set firewall family inet filter TRANSIT-FILTER term RATE-LIMIT-ICMP from protocol icmp
set firewall family inet filter TRANSIT-FILTER term RATE-LIMIT-ICMP then policer ICMP-LIMIT
set firewall family inet filter TRANSIT-FILTER term RATE-LIMIT-ICMP then count ICMP-POLICED
set firewall family inet filter TRANSIT-FILTER term RATE-LIMIT-ICMP then accept
commit
```

```
show firewall filter TRANSIT-FILTER    # ICMP-POLICED counter
show firewall policer
```

**Policy Cheat Sheet:**

| Match (from) | Example |
|---|---|
| Protocol | `from protocol bgp` |
| Route filter | `from route-filter 10.0.0.0/8 orlonger` |
| Prefix list | `from prefix-list my-list` |
| Community | `from community MY-COMM` |
| AS path | `from as-path MY-ASPATH` |
| Neighbor | `from neighbor 10.0.13.2` |

| Action (then) | Effect |
|---|---|
| `accept` / `reject` | Stop evaluation |
| `next term` | Next term in this policy |
| `next policy` | Next policy in chain |
| `local-preference 200` | Set LOCAL_PREF |
| `metric 100` | Set MED |
| `community add X` | Add community |
| `as-path-prepend "65001"` | Prepend AS path |

| Route Filter | Meaning |
|---|---|
| `exact` | Exact match |
| `longer` | Longer prefixes only |
| `orlonger` | Exact or longer |
| `upto /28` | Exact to /28 |
| `prefix-length-range /24-/28` | Range |

**Checklist:**
- [ ] `show route receive-protocol bgp` — local-pref set per policy term
- [ ] `show route advertising-protocol bgp` — communities attached
- [ ] `show firewall filter TRANSIT-FILTER` — counters incrementing
- [ ] `show firewall policer` — policer active on ICMP
- [ ] OSPF and BGP adjacencies still up after filters applied

---

---

# Transition: BGP → CoS

Remove BGP to clean up; keep OSPF for basic reachability.

**All routers:**
```
delete protocols bgp
delete policy-options
delete firewall
commit
```

---

---

# Section 4 — Class of Service

**Objective:** Full CoS pipeline: forwarding classes, DSCP classifier, schedulers, WRED, rewrite rules.

CoS is applied on the r1–r2 link (ge-0/0/0 on both sides).

### CoS Pipeline
```
Incoming packet
      ↓
[Classifier] reads DSCP → assigns Forwarding Class + Loss Priority
      ↓
[Forwarding] routing decision
      ↓
[Scheduler] egress queuing per Forwarding Class
      ↓
[WRED] probabilistic drop based on Loss Priority
      ↓
Outgoing packet (optional DSCP rewrite)
```

### Task 1 — Define Forwarding Classes

**On r1 (and optionally all routers):**
```
set class-of-service forwarding-classes class BEST-EFFORT queue-num 0
set class-of-service forwarding-classes class ASSURED-FORWARDING queue-num 1
set class-of-service forwarding-classes class EXPEDITED-FORWARDING queue-num 5
set class-of-service forwarding-classes class NETWORK-CONTROL queue-num 7
commit
```

### Task 2 — DSCP Classifier

| DSCP Name | Binary | Decimal | Use |
|-----------|--------|---------|-----|
| BE | 000000 | 0 | Best effort |
| AF11 | 001010 | 10 | Low-priority data |
| AF13 | 001110 | 14 | High-drop data |
| EF | 101110 | 46 | Voice/real-time |
| CS6 | 110000 | 48 | Network control |

**On r1:**
```
set class-of-service classifiers dscp MY-DSCP-CLASSIFIER forwarding-class BEST-EFFORT loss-priority low code-points 000000
set class-of-service classifiers dscp MY-DSCP-CLASSIFIER forwarding-class ASSURED-FORWARDING loss-priority low code-points 001010
set class-of-service classifiers dscp MY-DSCP-CLASSIFIER forwarding-class ASSURED-FORWARDING loss-priority high code-points 001110
set class-of-service classifiers dscp MY-DSCP-CLASSIFIER forwarding-class EXPEDITED-FORWARDING loss-priority low code-points 101110
set class-of-service classifiers dscp MY-DSCP-CLASSIFIER forwarding-class NETWORK-CONTROL loss-priority low code-points 110000

set class-of-service interfaces ge-0/0/0 unit 0 classifiers dscp MY-DSCP-CLASSIFIER
commit
```

### Task 3 — Schedulers

**On r1:**
```
set class-of-service schedulers SC-BE transmit-rate percent 30
set class-of-service schedulers SC-BE buffer-size percent 30
set class-of-service schedulers SC-BE priority low

set class-of-service schedulers SC-AF transmit-rate percent 40
set class-of-service schedulers SC-AF buffer-size percent 40
set class-of-service schedulers SC-AF priority low

set class-of-service schedulers SC-EF transmit-rate percent 20
set class-of-service schedulers SC-EF buffer-size percent 10
set class-of-service schedulers SC-EF priority strict-high

set class-of-service schedulers SC-NC transmit-rate percent 10
set class-of-service schedulers SC-NC buffer-size percent 5
set class-of-service schedulers SC-NC priority strict-high
commit
```

> `strict-high` = always served before lower queues; risk of starvation.
> `low` = weighted fair queuing by transmit-rate percentage.

### Task 4 — Scheduler Map

**On r1:**
```
set class-of-service scheduler-maps MY-MAP forwarding-class BEST-EFFORT scheduler SC-BE
set class-of-service scheduler-maps MY-MAP forwarding-class ASSURED-FORWARDING scheduler SC-AF
set class-of-service scheduler-maps MY-MAP forwarding-class EXPEDITED-FORWARDING scheduler SC-EF
set class-of-service scheduler-maps MY-MAP forwarding-class NETWORK-CONTROL scheduler SC-NC

set class-of-service interfaces ge-0/0/0 scheduler-map MY-MAP
commit
```

```
show class-of-service interface ge-0/0/0
show interfaces queue ge-0/0/0         # per-queue counters
```

### Task 5 — WRED Drop Profile
Start dropping AF high-loss-priority packets before queue is full.

**On r1:**
```
set class-of-service drop-profiles WRED-AF fill-level 50 drop-probability 5
set class-of-service drop-profiles WRED-AF fill-level 80 drop-probability 40
set class-of-service drop-profiles WRED-AF fill-level 100 drop-probability 100

set class-of-service schedulers SC-AF drop-profile-map loss-priority high protocol any drop-profile WRED-AF
commit
```

### Task 6 — DSCP Rewrite (Egress Marking)

**On r1:**
```
set class-of-service rewrite-rules dscp MY-DSCP-REWRITE forwarding-class EXPEDITED-FORWARDING loss-priority low code-point 101110
set class-of-service rewrite-rules dscp MY-DSCP-REWRITE forwarding-class BEST-EFFORT loss-priority low code-point 000000

set class-of-service interfaces ge-0/0/0 unit 0 rewrite-rules dscp MY-DSCP-REWRITE
commit
```

### Task 7 — Verify Under Load
```
ping 10.0.12.2 count 1000 rapid size 1400
show interfaces queue ge-0/0/0
```

Look for: `Queued`, `Transmitted`, `Dropped`, `RED packets` per queue.

**CoS Scheduler Priorities:**

| Priority | Behavior |
|----------|----------|
| `strict-high` | Always first; can starve others |
| `high` | After strict-high |
| `medium-high` / `medium-low` | WFQ weighted |
| `low` | WFQ lowest weight |

**Checklist:**
- [ ] `show class-of-service interface ge-0/0/0` — classifier and scheduler map applied
- [ ] `show interfaces queue ge-0/0/0` — 4 queues with expected names
- [ ] OSPF/BGP traffic in NC queue (queue 7)
- [ ] WRED drop counters increment under congestion
- [ ] EF queue (queue 5) drains faster than BE under load

---

## Teardown

```bash
sudo containerlab destroy -t routing-lab.clab.yml
```

Save progress first if needed:
```bash
sudo containerlab save -t routing-lab.clab.yml
```
