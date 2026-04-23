# junos-labs

ContainerLab topologies for hands-on Junos networking practice. Two topology files cover all JNCIS-ENT exam topics. Base configs (interfaces, loopbacks, hostnames) are pre-loaded via startup-config so you can focus on the protocol at hand.

**Prerequisites:** [ContainerLab](https://containerlab.dev/) and the `vrnetlab/juniper_vjunos-router:25.4R1.12` / `vrnetlab/juniper_vjunos-switch:25.4R1.12` images available to Docker.

---

## Labs

| Topology | Topics Covered | File |
|----------|---------------|------|
| Routing Lab | OSPF, IS-IS, BGP, Routing Policy, Firewall Filters, CoS | `routing-lab.clab.yml` |
| Layer 2 Lab | VLANs, STP, LACP, IRB, VRRP | `layer2-lab.clab.yml` |

Lab guides live in the Obsidian vault at `JNCIS-ENT/labs/`.

---

## Spinning Up a Lab

```bash
# Routing lab (OSPF, IS-IS, BGP, Policy, CoS)
sudo containerlab deploy -t routing-lab.clab.yml

# Layer 2 lab (VLANs, STP, LAG, IRB, VRRP)
sudo containerlab deploy -t layer2-lab.clab.yml
```

SSH into nodes using the pattern `clab-<lab-name>-<node>`:

```bash
# Routing lab nodes
ssh admin@clab-routing-lab-r1
ssh admin@clab-routing-lab-r2
ssh admin@clab-routing-lab-r3
ssh admin@clab-routing-lab-r4

# Layer 2 lab nodes
ssh admin@clab-layer2-lab-sw1
ssh admin@clab-layer2-lab-sw2
ssh admin@clab-layer2-lab-sw3
ssh admin@clab-layer2-lab-sw4
```

Check running nodes:

```bash
sudo containerlab inspect
```

---

## Tearing Down

```bash
sudo containerlab destroy -t routing-lab.clab.yml
sudo containerlab destroy -t layer2-lab.clab.yml
```

---

## Startup Configs

Base configs are in `configs/` and are applied at deploy time:

```
configs/
  routing/   r1.conf – r4.conf   interfaces + loopbacks + router-id
  layer2/    sw1.conf – sw4.conf  hostname + ssh only
```

> **Note:** `startup-config` support for vrnetlab-wrapped images can be inconsistent. If the config doesn't apply automatically after boot, paste the contents of the relevant `.conf` file into the router CLI manually:
> ```
> configure
> load merge terminal   # paste config, then Ctrl-D
> commit
> ```

---

## Saving and Resuming Progress

ContainerLab containers are ephemeral — config is lost on `destroy`. Save before tearing down:

```bash
sudo containerlab save -t routing-lab.clab.yml
sudo containerlab destroy -t routing-lab.clab.yml
```

Saved configs land in `clab-routing-lab/<node>/config/junos.conf`. To reload on next deploy, update the `startup-config` paths in the topology file to point at the saved files.

---

## Quick Reference

**Interface mapping** (all labs):

| ContainerLab | Junos |
|---|---|
| eth1 | ge-0/0/0 |
| eth2 | ge-0/0/1 |
| eth3 | ge-0/0/2 |
| eth4 | ge-0/0/3 |

**Standard addressing** (routing lab):
- Loopbacks: `10.0.0.<router-num>/32`
- P2P links: `10.0.<R><R>.0/30` (e.g. r1↔r2 = `10.0.12.0/30`)
