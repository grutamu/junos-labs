# PE Lab

## Topology

```
  pc1 (host7)
    |
    | 192.168.17.0/24
    |
  [ r1 (PE1) 1.1.1.1 ] ——————— 192.168.12.0/24 ——————— [ r2 (PE2) 2.2.2.2 ]
                                2001:12:dead:beef::/64      |    |     |    |
                                              ge-0/0/1 ——————    |     |    |
                                           172.16.25.0/24        |     |  ge-0/0/3  ge-0/0/4
                                       2002:25:dead:beef::/64    |  172.16.23.0/24  172.16.24.0/24
                                              ge-0/0/2 ——————    |     |              |
                                           172.16.52.0/24        | [ r3 (CE1) ]  [ r4 (CE2) ]
                                       2002:52:dead:beef::/64    |  11.11.11.11   12.12.12.12
                                                                  |        \         /
                                                            [ r5 (P) ]  172.16.34.0/24
                                                             5.5.5.5
                                                                  |
                                                           10.56.56.0/24
                                                       2005:56:dead:beef::/64
                                                                  |
                                                            [ r6 6.6.6.6 ]
                                                                  |
                                                           192.168.68.0/24
                                                                  |
                                                            pc2 (host8)
```

**Host split:** r5, r6, pc2 on lab-01 (`host1.clab.yml`); r1, r2, r3, r4, pc1 on lab-02 (`host2.clab.yml`).

## Node Reference

| Node | Diagram Name | Role | Loopback | SSH |
|------|-------------|------|----------|-----|
| r1 | vMX1 | PE1 | 1.1.1.1 | `clab-pe-lab-r1` |
| r2 | vMX2 | PE2 | 2.2.2.2 | `clab-pe-lab-r2` |
| r3 | vMX11 | CE1 | 11.11.11.11 | `clab-pe-lab-r3` |
| r4 | vMX12 | CE2 | 12.12.12.12 | `clab-pe-lab-r4` |
| r5 | R5 | P | 5.5.5.5 | `clab-pe-lab-r5` |
| r6 | R6 | — | 6.6.6.6 | `clab-pe-lab-r6` |
| pc1 | host7 | Linux endpoint | — | — |
| pc2 | host8 | Linux endpoint | — | — |

## Interface / Addressing Reference

| Link | Node A | IP A | Node B | IP B |
|------|--------|------|--------|------|
| PE1–PE2 | r1 ge-0/0/0 | 192.168.12.1/24 | r2 ge-0/0/0 | 192.168.12.2/24 |
| PE1–host | r1 ge-0/0/1 | 192.168.17.1/24 | pc1 eth1 | 192.168.17.100/24 |
| PE2–P (1) | r2 ge-0/0/1 | 172.16.25.2/24 | r5 ge-0/0/0 | 172.16.25.5/24 |
| PE2–P (2) | r2 ge-0/0/2 | 172.16.52.2/24 | r5 ge-0/0/2 | 172.16.52.5/24 |
| PE2–CE1 | r2 ge-0/0/3 | 172.16.23.2/24 | r3 ge-0/0/0 | 172.16.23.3/24 |
| PE2–CE2 | r2 ge-0/0/4 | 172.16.24.2/24 | r4 ge-0/0/0 | 172.16.24.4/24 |
| CE1–CE2 | r3 ge-0/0/1 | 172.16.34.3/24 | r4 ge-0/0/1 | 172.16.34.4/24 |
| P–R6 | r5 ge-0/0/1 | 10.56.56.5/24 | r6 ge-0/0/0 | 10.56.56.6/24 |
| R6–host | r6 ge-0/0/1 | 192.168.68.6/24 | pc2 eth1 | 192.168.68.100/24 |

Dual-stack links: PE1–PE2 (`2001:12:dead:beef::/64`), PE2–P-1 (`2002:25:dead:beef::/64`), PE2–P-2 (`2002:52:dead:beef::/64`), P–R6 (`2005:56:dead:beef::/64`). All others are IPv4-only.

## Deploy

```bash
ansible-playbook ansible/labs.yml -e "lab=pe-lab op=deploy"
```

Or manually on each host:

```bash
# lab-01
sudo containerlab deploy -t multinode/pe-lab/host1.clab.yml

# lab-02
sudo containerlab deploy -t multinode/pe-lab/host2.clab.yml
```

## Prerequisites

- All interfaces up and reachable: `show interfaces terse` on each router
- Verify pc1 → r1: `ping 192.168.17.1` from pc1
- Verify pc2 → r6: `ping 192.168.68.6` from pc2

## Tasks

Startup configs provide interfaces, loopbacks, and router-IDs only. Configure all protocols from scratch.

### Task 1 — IGP reachability

Bring up an IGP (OSPF or IS-IS) across all six routers so every loopback is reachable from every other router.

**Verification**

- [ ] `ping 5.5.5.5 source 1.1.1.1` succeeds on r1
- [ ] `ping 1.1.1.1 source 6.6.6.6` succeeds on r6
- [ ] All loopbacks appear in the routing table on every router

### Task 2 — MPLS label distribution

Enable MPLS and LDP on all core-facing interfaces (PE1, PE2, P). Verify label-switched paths between PE loopbacks.

**Verification**

- [ ] `show mpls lsp` shows active LSPs on r1 and r2
- [ ] `traceroute mpls ldp 2.2.2.2` from r1 shows a label-switched path

### Task 3 — BGP between PEs

Configure iBGP between r1 and r2 using loopbacks as update-source. Add r5 or r6 as a route reflector if desired.

**Verification**

- [ ] `show bgp summary` shows established session on both PEs

### Task 4 — L3VPN

Configure a VRF on PE2 (r2) and attach the CE interfaces (ge-0/0/3, ge-0/0/4). Run eBGP between PE2 and each CE. Advertise CE loopbacks into the VPN and verify end-to-end reachability.

**Verification**

- [ ] `show route table <vrf>.inet.0` on r2 shows CE prefixes
- [ ] `ping 11.11.11.11 routing-instance <vrf>` from r2 succeeds
- [ ] pc1 can reach pc2 (once PE1 VRF is configured)

## pc1 / pc2 Tools

ping is available immediately. For curl: `apk add curl` (requires internet access on the host).
