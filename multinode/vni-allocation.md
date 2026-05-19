# VNI Allocation

One VNI per cross-host link. Both `hostN.clab.yml` files of the lab must use the same VNI for the same logical link. UDP port is always **4789** (`dst-port: 4789`).

Namespaces:

| Range | Lab |
|-------|-----|
| 100–199 | `multinode-routing-lab` |
| 200–299 | `multinode-layer2-lab` |
| 300–399 | `multinode-load-test` |

## multinode-routing-lab

| VNI | Link | Subnet |
|-----|------|--------|
| 113 | r1 (host1) ↔ r3 (host2) — `r1:eth2` / `r3:eth1` | 10.0.13.0/30 |
| 124 | r2 (host1) ↔ r4 (host2) — `r2:eth2` / `r4:eth1` | 10.0.24.0/30 |

Local (veth, no VNI): `r1:eth1 — r2:eth1` (10.0.12.0/30), `r3:eth2 — r4:eth2` (10.0.34.0/30).

## multinode-layer2-lab

| VNI | Link |
|-----|------|
| 213 | sw1 (host1) ↔ sw3 (host2) — `sw1:eth3` / `sw3:eth1` (trunk VLANs 10/20/30) |
| 214 | sw1 (host1) ↔ sw4 (host2) — `sw1:eth4` / `sw4:eth1` (VRRP uplink) |
| 224 | sw2 (host1) ↔ sw4 (host2) — `sw2:eth3` / `sw4:eth2` (redundant uplink) |

Local (veth, no VNI): `sw1:eth1 — sw2:eth1` (ae0 member 1), `sw1:eth2 — sw2:eth2` (ae0 member 2), `sw3:eth4 — sw4:eth4`.

## multinode-load-test

10-node dual-pentagon (r1–r5 on host1, r6–r10 on host2). Each spoke connects the matching router on the opposite host.

| VNI | Link | Subnet |
|-----|------|--------|
| 300 | r1 (host1) ↔ r6 (host2) — `r1:eth3` / `r6:eth3` | 10.1.6.0/30 |
| 301 | r2 (host1) ↔ r7 (host2) — `r2:eth3` / `r7:eth3` | 10.2.7.0/30 |
| 302 | r3 (host1) ↔ r8 (host2) — `r3:eth3` / `r8:eth3` | 10.3.8.0/30 |
| 303 | r4 (host1) ↔ r9 (host2) — `r4:eth3` / `r9:eth3` | 10.4.9.0/30 |
| 304 | r5 (host1) ↔ r10 (host2) — `r5:eth3` / `r10:eth3` | 10.5.10.0/30 |

Local (veth, no VNI) host1: `r1:eth1—r2:eth1` (10.1.2.0/30), `r2:eth2—r3:eth1` (10.2.3.0/30), `r3:eth2—r4:eth1` (10.3.4.0/30), `r4:eth2—r5:eth1` (10.4.5.0/30), `r5:eth2—r1:eth2` (10.1.5.0/30).
Local (veth, no VNI) host2: `r6:eth1—r7:eth1` (10.6.7.0/30), `r7:eth2—r8:eth1` (10.7.8.0/30), `r8:eth2—r9:eth1` (10.8.9.0/30), `r9:eth2—r10:eth1` (10.9.10.0/30), `r10:eth2—r6:eth2` (10.6.10.0/30).

## Adding a host3

Pick the lab's range and assign the next unused VNI per cross-host link. Keep this table updated.
