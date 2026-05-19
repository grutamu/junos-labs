# JNCIS-ENT Labs

Three lab types: guided labs for learning, troubleshooting labs to test diagnostic skills, and challenge labs to test design and implementation from requirements alone.

---

## Guided Labs

Build knowledge progressively — interfaces pre-configured, protocols are up to you.

| Guide | Topics | Topology |
|-------|--------|----------|
| [Routing-Lab.md](Routing-Lab.md) | OSPF → IS-IS → BGP → Policy → CoS | `routing-lab.clab.yml` |
| [Layer2-Lab.md](Layer2-Lab.md) | VLANs → LACP → RSTP → IRB → VRRP | `layer2-lab.clab.yml` |

---

## Troubleshooting Labs

Broken configs are pre-loaded. Find and fix all faults — no hints given.

| Lab | Faults In | Topology |
|-----|-----------|----------|
| [Troubleshoot-OSPF.md](Troubleshoot-OSPF.md) | OSPF adjacency and loopback config | `troubleshoot-ospf.clab.yml` |
| [Troubleshoot-ISIS.md](Troubleshoot-ISIS.md) | IS-IS adjacency and route leaking | `troubleshoot-isis.clab.yml` |
| [Troubleshoot-BGP.md](Troubleshoot-BGP.md) | BGP sessions and route propagation | `troubleshoot-bgp.clab.yml` |
| [Troubleshoot-Layer2.md](Troubleshoot-Layer2.md) | LACP, STP, VLAN, IRB | `troubleshoot-l2.clab.yml` |

---

## Challenge Labs

Requirements only — no commands, no step-by-step guidance.

| Lab | Topics | Topology |
|-----|--------|----------|
| [Challenge-Routing.md](Challenge-Routing.md) | OSPF multi-area, iBGP RR, eBGP, communities, firewall filter | `routing-lab.clab.yml` |
| [Challenge-Layer2.md](Challenge-Layer2.md) | Full campus: LACP, RSTP, IRB, VRRP | `layer2-lab.clab.yml` |
| [Challenge-CoS.md](Challenge-CoS.md) | CoS pipeline design from requirements | `routing-lab.clab.yml` |

---

## Quick Start

```bash
cd ~/development/github/junos-labs

# Guided
sudo containerlab deploy -t routing-lab.clab.yml
sudo containerlab deploy -t layer2-lab.clab.yml

# Troubleshooting
sudo containerlab deploy -t troubleshoot-ospf.clab.yml
sudo containerlab deploy -t troubleshoot-isis.clab.yml
sudo containerlab deploy -t troubleshoot-bgp.clab.yml
sudo containerlab deploy -t troubleshoot-l2.clab.yml
```

SSH pattern: `ssh admin@clab-<lab-name>-<node>` (e.g. `clab-troubleshoot-ospf-r1`)

---

## Interface Mapping

| ContainerLab | Junos |
|---|---|
| eth1 | ge-0/0/0 |
| eth2 | ge-0/0/1 |
| eth3 | ge-0/0/2 |
| eth4 | ge-0/0/3 |

---

## Multi-node Labs

A separate set of labs designed to run **split across two containerlab hosts** on the same L2 segment, using VXLAN-stitched links. Single-host labs above are unchanged.

| Lab | Topics | Topology |
|-----|--------|----------|
| [Multinode-Routing-Lab.md](multinode/Multinode-Routing-Lab.md) | OSPF / IS-IS / BGP across hosts | `multinode/multinode-routing-lab/host{1,2}.clab.yml` |
| [Multinode-Layer2-Lab.md](multinode/Multinode-Layer2-Lab.md) | VLAN trunks + RSTP + VRRP across hosts | `multinode/multinode-layer2-lab/host{1,2}.clab.yml` |

Bring hosts to a known-good state with the [Ansible playbook](ansible/README.md); see [multinode/README.md](multinode/README.md) for deploy mechanics and [multinode/vni-allocation.md](multinode/vni-allocation.md) for the canonical VNI map.

---

## Authoring a New Lab

See [docs/lab-authoring.md](docs/lab-authoring.md) for the full authoring guide: available images, host capacity limits, naming and addressing conventions, topology YAML format, startup config rules, multinode/VXLAN rules, Ansible registration, lab type skeletons, and a validation checklist.

---

## Junos CLI Reminders

```
configure
show | compare
commit check
commit
rollback 1 ; commit
run show ...
```
