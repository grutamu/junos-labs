# VNI Allocation

One VNI per cross-host link. Both `hostN.clab.yml` files of the lab must use the same VNI for the same logical link. UDP port is always **4789** (`dst-port: 4789`).

Namespaces:

| Range | Lab |
|-------|-----|
| 100–199 | `multinode-routing-lab` |
| 200–299 | `multinode-layer2-lab` |
| 300–399 | reserved for future multi-node labs |

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

## Adding a host3

Pick the lab's range and assign the next unused VNI per cross-host link. Keep this table updated.
