# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Repo Is

A collection of [ContainerLab](https://containerlab.dev/) topology files for hands-on Junos networking labs. Each `.clab.yml` file defines a virtual network using `vrnetlab`-wrapped Junos images. Labs are standalone and self-documented via header comments — all addressing, area assignments, BGP ASNs, and protocol roles are defined in the comments at the top of each file.

## Lab Management Commands

```bash
# Deploy a lab
sudo containerlab deploy -t lab01-ospf-single-area.clab.yml

# Destroy a lab (removes containers and links)
sudo containerlab destroy -t lab01-ospf-single-area.clab.yml

# List running labs and node status
sudo containerlab inspect

# SSH into a node (pattern: clab-<lab-name>-<node>)
ssh admin@clab-lab01-ospf-single-area-r1
```

## Architecture

### Topology Pattern

Labs 1–7 and lab 9 share the same physical 4-router **square topology** using `juniper_vjunosrouter`. Only the Junos configuration changes between labs — the `.clab.yml` wiring is identical:

```
R1 --- R2
|       |
R3 --- R4
```

Lab 8 uses `juniper_vjunosswitch` (QFX-based) for Layer 2 switching exercises.

### Interface Mapping

ContainerLab `eth` interfaces map to Junos `ge-0/0/x` interfaces:

| ContainerLab | Junos      |
|-------------|------------|
| eth1        | ge-0/0/0   |
| eth2        | ge-0/0/1   |
| eth3        | ge-0/0/2   |
| eth4        | ge-0/0/3   |

### Standard Addressing (Labs 1–7, 9)

- Loopbacks: `10.0.0.x/32` where x = router number
- P2P links: `10.0.XY.0/30` where XY = the two router numbers (e.g., R1-R2 = `10.0.12.0/30`)

### Lab Progression

Labs build on each other:
- **Lab 1**: OSPF single area — baseline config reused in later labs
- **Lab 2**: OSPF multi-area (same wiring, different area assignments)
- **Lab 3**: OSPF advanced (virtual links, redistribution)
- **Lab 4**: IS-IS (replace OSPF; same physical topology)
- **Lab 5**: BGP foundation — uses Lab 1 OSPF as underlay
- **Lab 6**: BGP advanced — route reflection, communities, AS-path filters, BFD
- **Lab 7**: Routing policy + firewall filters — layers on top of Labs 5/6
- **Lab 8**: Layer 2 switching — separate switch topology
- **Lab 9**: Class of Service — primary CoS link is R1–R2 (ge-0/0/0)

### Docker Image

All routers: `vrnetlab/juniper_vjunos-router:25.4R1.12`  
All switches: `vrnetlab/juniper_vjunos-switch:25.4R1.12`
