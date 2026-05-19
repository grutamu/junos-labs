# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Repo Is

Hands-on Junos JNCIS-ENT lab suite. Contains ContainerLab topology files, base startup configs, and all lab guides (Markdown) in one place. Three lab types:

- **Guided** (`Routing-Lab.md`, `Layer2-Lab.md`) — base interfaces pre-configured, build protocols from scratch
- **Troubleshooting** (`Troubleshoot-*.md`) — broken configs pre-loaded, find and fix all faults
- **Challenge** (`Challenge-*.md`) — requirements and success criteria only, no commands

## Lab Management Commands

```bash
# Deploy
sudo containerlab deploy -t singlenode/routing-lab.clab.yml
sudo containerlab deploy -t singlenode/layer2-lab.clab.yml

# Destroy
sudo containerlab destroy -t singlenode/routing-lab.clab.yml
sudo containerlab destroy -t singlenode/layer2-lab.clab.yml

# List running labs
sudo containerlab inspect

# SSH into a node (pattern: clab-<lab-name>-<node>)
ssh admin@clab-routing-lab-r1
ssh admin@clab-layer2-lab-sw1
```

## Architecture

### Topology Files

| File | Nodes | Covers |
|------|-------|--------|
| `singlenode/routing-lab.clab.yml` | r1–r4 (vJunos-router) | OSPF, IS-IS, BGP, Policy, CoS |
| `singlenode/layer2-lab.clab.yml` | sw1–sw4 (vJunos-switch) | VLANs, STP, LAG, IRB, VRRP |

### Startup Configs

```
singlenode/configs/
  routing/   r1.conf – r4.conf   interfaces + loopbacks + router-id (no protocols)
  layer2/    sw1.conf – sw4.conf  hostname + ssh only
```

Configs are in JunOS curly-brace format (same as `show configuration` output). If startup-config doesn't apply automatically (vrnetlab inconsistency), paste via `configure; load merge terminal`.

### Interface Mapping

ContainerLab `eth` interfaces map to Junos `ge-0/0/x` interfaces:

| ContainerLab | Junos |
|---|---|
| eth1 | ge-0/0/0 |
| eth2 | ge-0/0/1 |
| eth3 | ge-0/0/2 |
| eth4 | ge-0/0/3 |

### Standard Addressing (routing lab)

- Loopbacks: `10.0.0.x/32` where x = router number
- P2P links: `10.0.XY.0/30` where XY = the two router numbers (e.g., r1-r2 = `10.0.12.0/30`)

### Routing Lab Topology

```
r1 --- r2
|       |
r3 --- r4
```

r1: ge-0/0/0→r2, ge-0/0/1→r3  
r2: ge-0/0/0→r1, ge-0/0/1→r4  
r3: ge-0/0/0→r1, ge-0/0/1→r4  
r4: ge-0/0/0→r2, ge-0/0/1→r3

### Layer 2 Lab Topology

```
sw1 (root)
├── ae0 (LAG: eth1+eth2) → sw2
├── eth3 (ge-0/0/2) → sw3
└── eth4 (ge-0/0/3) → sw4 (VRRP backup)
sw2 eth3 (ge-0/0/2) → sw4 (redundant uplink)
```

### Docker Images

All routers: `vrnetlab/juniper_vjunos-router:25.4R1.12`  
All switches: `vrnetlab/juniper_vjunos-switch:25.4R1.12`

For full authoring conventions (resource limits, naming, YAML format, templates, validation checklist), see `docs/lab-authoring.md`.

### Multi-Node Labs

Separate, additive lab track under `multinode/`. Each multi-node lab has **one topology file per host** (e.g. `multinode/multinode-routing-lab/host1.clab.yml` and `host2.clab.yml`), wired together via `type: vxlan-stitch` links sharing a VNI on both sides. Single-host labs live under `singlenode/` and continue to run standalone.

| Lab | Nodes | Description |
|-----|-------|-------------|
| `multinode-routing-lab` | r1–r2 (host1), r3–r4 (host2) | OSPF, IS-IS, BGP across hosts |
| `multinode-layer2-lab` | sw1–sw2 (host1), sw3–sw4 (host2) | VLANs, LAG, RSTP, VRRP across hosts |
| `multinode-load-test` | r1–r5 (host1), r6–r10 (host2) | OSPF + BFD + iBGP full mesh — host capacity stress test |

```bash
# Deploy each half on its host (manual)
sudo containerlab deploy -t multinode/multinode-routing-lab/host1.clab.yml   # host1
sudo containerlab deploy -t multinode/multinode-routing-lab/host2.clab.yml   # host2

# Or deploy both halves via Ansible
ansible-playbook ansible/labs.yml -e "lab=multinode-routing-lab op=deploy"
ansible-playbook ansible/labs.yml -e "lab=multinode-load-test op=deploy"
```

Host bootstrap (Docker, containerlab, vJunos images, VXLAN sysctls/MTU/firewall) lives under `ansible/` and is invoked with `ansible-playbook ansible/site.yml`. Lab lifecycle (deploy/destroy/inspect/save) uses `ansible/labs.yml -e "lab=<name> op=<op>"`. Canonical VNI map: `multinode/vni-allocation.md`.
