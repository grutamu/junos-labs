# junos-labs

ContainerLab topologies for hands-on Junos networking practice. Each lab is a self-contained `.clab.yml` file with addressing, roles, and protocol details documented in the file header.

**Prerequisites:** [ContainerLab](https://containerlab.dev/) and the `vrnetlab/juniper_vjunos-router:25.4R1.12` / `vrnetlab/juniper_vjunos-switch:25.4R1.12` images available to Docker.

---

## Labs

| Lab | Topic | File |
|-----|-------|------|
| 1 | OSPF Single Area | `lab01-ospf-single-area.clab.yml` |
| 2 | OSPF Multi-Area | `lab02-ospf-multi-area.clab.yml` |
| 3 | OSPF Advanced (virtual links, redistribution) | `lab03-ospf-advanced.clab.yml` |
| 4 | IS-IS | `lab04-isis.clab.yml` |
| 5 | BGP Foundation (eBGP + iBGP) | `lab05-bgp-foundation.clab.yml` |
| 6 | BGP Advanced (RR, communities, AS-path, BFD) | `lab06-bgp-advanced.clab.yml` |
| 7 | Routing Policy & Firewall Filters | `lab07-routing-policy.clab.yml` |
| 8 | Layer 2 Switching (VLANs, STP, LAG, IRB, VRRP) | `lab08-layer2-switching.clab.yml` |
| 9 | Class of Service | `lab09-cos.clab.yml` |

Labs 1–7 and 9 build on the same 4-router square topology (`R1—R2—R4—R3—R1`). Only the Junos configuration changes between them. Lab 8 uses a separate 4-switch topology.

---

## Spinning Up a Lab

```bash
sudo containerlab deploy -t lab01-ospf-single-area.clab.yml
```

Once deployed, SSH into any node using the pattern `clab-<lab-name>-<node>`:

```bash
# Router labs
ssh admin@clab-lab01-ospf-single-area-r1
ssh admin@clab-lab01-ospf-single-area-r2

# Switch labs (lab 8)
ssh admin@clab-lab08-layer2-switching-sw1
```

Check the status of running nodes:

```bash
sudo containerlab inspect
```

## Tearing Down a Lab

```bash
sudo containerlab destroy -t lab01-ospf-single-area.clab.yml
```

## Saving and Resuming Progress

By default, ContainerLab containers are ephemeral — any configuration applied during a lab session is lost on `destroy`. To preserve your work, save configs before tearing down:

```bash
# Save running configs from all nodes
sudo containerlab save -t lab01-ospf-single-area.clab.yml

# Then tear down
sudo containerlab destroy -t lab01-ospf-single-area.clab.yml
```

Saved configs are written to `clab-<lab-name>/<node>/config/` alongside the topology file and persist on disk after the lab is destroyed. To reload them on the next deploy, add a `startup-config` reference to each node in the topology file:

```yaml
nodes:
  r1:
    kind: juniper_vjunosrouter
    startup-config: clab-lab01-ospf-single-area/r1/config/junos.conf
  r2:
    kind: juniper_vjunosrouter
    startup-config: clab-lab01-ospf-single-area/r2/config/junos.conf
  # ...
```

> **Note:** `startup-config` support for vrnetlab-wrapped images can be inconsistent. Test a full save/destroy/redeploy cycle before relying on it. If configs don't apply automatically, the saved files can be pasted in manually after boot.

---

## Quick Reference

**Interface mapping** (all labs):

| ContainerLab | Junos |
|---|---|
| eth1 | ge-0/0/0 |
| eth2 | ge-0/0/1 |
| eth3 | ge-0/0/2 |
| eth4 | ge-0/0/3 |

**Standard addressing** (labs 1–7, 9):
- Loopbacks: `10.0.0.<router-num>/32`
- P2P links: `10.0.<R><R>.0/30` (e.g. R1↔R2 = `10.0.12.0/30`)
