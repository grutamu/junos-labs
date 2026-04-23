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

## Junos CLI Reminders

```
configure
show | compare
commit check
commit
rollback 1 ; commit
run show ...
```
