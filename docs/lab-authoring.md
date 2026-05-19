# Lab Authoring Guide

Reference for anyone creating a new lab — human or LLM. Covers everything from hardware capacity to topology YAML format to the validation checklist. The companion file `CLAUDE.md` covers day-to-day repo usage; this file covers how to author new content.

---

## Available Images

Versions are pinned in `ansible/group_vars/all.yml`. Update that file when bumping a version — it controls what Ansible installs on the lab hosts.

| Role | Docker Image | ContainerLab Kind |
|------|-------------|-------------------|
| Router | `vrnetlab/juniper_vjunos-router:25.4R1.12` | `juniper_vjunosrouter` |
| Switch | `vrnetlab/juniper_vjunos-switch:25.4R1.12` | `juniper_vjunosswitch` |
| Linux endpoint | `alpine:latest` | `linux` |

---

## Node Resource Requirements

Both `vjunos-router` and `vjunos-switch` require **4 vCPU and 5 GB RAM** per instance. Linux (`alpine`) nodes are negligible.

### Capacity Formula

```
max_nodes = min( floor(host_vcpu / 4), floor(host_ram_gb / 5) )
```

### Host Capacity Table

Run `docs/update-capacity.sh` to regenerate this table after adding or modifying lab hosts.

| Host | Ansible Host | vCPU | RAM (GB) | Max vJunos Nodes |
|------|-------------|------|----------|-----------------|
| lab-01 | 100.110.163.67 | 12 | 30 | 5 |
| lab-02 | 100.122.128.16 | 16 | 30 | 5 |

> To update: run `bash docs/update-capacity.sh` and replace the rows above with the output.

**Design rule**: A single-host lab should run at most **4 nodes**. A multinode lab should run at most **2 nodes per host**. Stay below the calculated max to leave headroom for the host OS.

---

## Design Guidelines

- **Prefer square/ring topologies.** Four nodes in a square (r1–r2–r4–r3–r1) gives full-mesh reachability with four links and is the reference for all existing routing labs.
- **Node count**: ≤4 nodes for single-host labs; ≤2 nodes per host for multinode labs.
- **No subnet overlap.** Check all existing labs before assigning P2P subnets, loopbacks, or VLANs. Use the standard addressing scheme unless the lab topic specifically requires a different range.
- **Startup configs are minimal.** Interfaces, loopbacks, router-id, hostname, SSH — nothing else. The student configures protocols. Exception: troubleshooting labs ship broken configs.
- **One topology, one guide.** Each `.clab.yml` file should have a corresponding lab guide (`.md`). Challenge labs reuse existing topologies.
- **Pin the image version.** Never use a floating tag like `latest` for vJunos nodes; it produces non-reproducible labs.

---

## File and Naming Conventions

### Single-host labs

```
singlenode/
  <type>-<topic>.clab.yml          # topology
  configs/<subdir>/                # one .conf per node
  Lab Docs/<LabName>.md            # lab guide
```

Types: `routing`, `layer2`, `vrrp`, `tunnel`, `troubleshoot`, `challenge` (challenge labs reuse topology files).

### Multinode labs

```
multinode/
  <lab-name>/
    host1.clab.yml
    host2.clab.yml
    configs/                       # one .conf per node
  <LabName>.md                     # lab guide
```

### Naming rules

| Item | Pattern | Example |
|------|---------|---------|
| Topology file | `<type>-<topic>.clab.yml` | `troubleshoot-bgp.clab.yml` |
| ContainerLab `name:` field | matches filename without extension | `troubleshoot-bgp` |
| Node names | `r<N>` for routers, `sw<N>` for switches, `pc<N>` for Linux endpoints | `r1`, `sw2`, `pc1` |
| SSH hostname | `clab-<lab-name>-<node>` | `clab-troubleshoot-bgp-r1` |
| Config subdir | matches topology base name | `configs/troubleshoot-bgp/` |

---

## Addressing Conventions

### Routing labs

| Type | Scheme | Example |
|------|--------|---------|
| Loopback | `10.0.0.<N>/32` where N = router number | r3 → `10.0.0.3/32` |
| P2P link | `10.0.<XY>.0/30` where XY = both router numbers | r1↔r2 → `10.0.12.0/30` |
| P2P endpoint .1 | lower-numbered router | r1 → `10.0.12.1/30` |
| P2P endpoint .2 | higher-numbered router | r2 → `10.0.12.2/30` |

Standard P2P map for 4-node square:

| Link | Subnet | r1 end | r2 end |
|------|--------|--------|--------|
| r1 ↔ r2 | 10.0.12.0/30 | .1 | .2 |
| r1 ↔ r3 | 10.0.13.0/30 | .1 | .2 |
| r2 ↔ r4 | 10.0.24.0/30 | .1 | .2 |
| r3 ↔ r4 | 10.0.34.0/30 | .1 | .2 |

### Layer 2 labs

| Type | Range | Notes |
|------|-------|-------|
| VLANs | 10, 20, 30 | increment by 10 for new VLANs |
| IRB gateways | `192.168.<vlan/10>.1/24` | e.g., VLAN 10 → `192.168.1.1/24` |
| VRRP virtual IP | `192.168.<vlan/10>.254` | always .254 for the VIP |

### Linux endpoints

Use `192.168.<segment>.100/24` with gateway `192.168.<segment>.1` to keep endpoints clearly separate from switch IRBs.

---

## Interface Mapping

ContainerLab `eth` numbers map to Junos `ge-0/0/x`:

| ContainerLab | Junos |
|---|---|
| eth1 | ge-0/0/0 |
| eth2 | ge-0/0/1 |
| eth3 | ge-0/0/2 |
| eth4 | ge-0/0/3 |

eth0 is the management interface managed by ContainerLab; never reference it in configs.

---

## ContainerLab Topology YAML Format

Annotated skeleton for a 4-node routing lab:

```yaml
# <One-line description of what this topology covers>
# Interface mapping: eth1=ge-0/0/0, eth2=ge-0/0/1
#
# Addressing:
#   <paste the loopback and P2P table here>
#
# Lab guide: <relative path to the .md guide>

name: <lab-name>          # must match filename without .clab.yml

topology:
  kinds:
    juniper_vjunosrouter:
      image: vrnetlab/juniper_vjunos-router:25.4R1.12
    # juniper_vjunosswitch:
    #   image: vrnetlab/juniper_vjunos-switch:25.4R1.12

  nodes:
    r1:
      kind: juniper_vjunosrouter
      startup-config: configs/<subdir>/r1.conf
    r2:
      kind: juniper_vjunosrouter
      startup-config: configs/<subdir>/r2.conf
    r3:
      kind: juniper_vjunosrouter
      startup-config: configs/<subdir>/r3.conf
    r4:
      kind: juniper_vjunosrouter
      startup-config: configs/<subdir>/r4.conf

  links:
    - endpoints: ["r1:eth1", "r2:eth1"]  # ge-0/0/0 — ge-0/0/0  10.0.12.0/30
    - endpoints: ["r1:eth2", "r3:eth1"]  # ge-0/0/1 — ge-0/0/0  10.0.13.0/30
    - endpoints: ["r2:eth2", "r4:eth1"]  # ge-0/0/1 — ge-0/0/0  10.0.24.0/30
    - endpoints: ["r3:eth2", "r4:eth2"]  # ge-0/0/1 — ge-0/0/1  10.0.34.0/30
```

Rules:
- Always include endpoint comments showing the Junos interface names and subnet.
- List the kinds block at the top, even if only one kind is used.
- `startup-config` paths are relative to the directory where `containerlab deploy` is run.

---

## Startup Config Format

All configs use JunOS curly-brace format — the same output as `show configuration`. If a startup-config fails to apply automatically (a known vrnetlab inconsistency), paste it manually with `configure; load merge terminal`.

### Guided lab config (minimal)

```
system {
    host-name r1;
    services {
        ssh;
    }
}
interfaces {
    ge-0/0/0 {
        unit 0 {
            family inet {
                address 10.0.12.1/30;
            }
        }
    }
    ge-0/0/1 {
        unit 0 {
            family inet {
                address 10.0.13.1/30;
            }
        }
    }
    lo0 {
        unit 0 {
            family inet {
                address 10.0.0.1/32;
            }
        }
    }
}
routing-options {
    router-id 10.0.0.1;
}
```

**Do not include**: routing protocols, routing policy, BGP, IS-IS, OSPF, CoS, firewall filters. Those are the student's work.

### Troubleshooting lab config

Include a fully working base config plus intentionally broken protocol configuration. Document what is broken in the lab guide — not in the config itself.

### Challenge lab config

Use the guided lab format (interfaces + loopbacks only). The lab guide provides requirements; the student builds everything.

### Layer 2 switch config (minimal)

```
system {
    host-name sw1;
    services {
        ssh;
    }
}
```

Interface and VLAN config is left to the student.

---

## Multinode / VXLAN Rules

### Topology split

Each multinode lab has exactly two topology files:
- `multinode/<lab-name>/host1.clab.yml` — nodes assigned to lab-01
- `multinode/<lab-name>/host2.clab.yml` — nodes assigned to lab-02

Both files use the **same `name:`** field (ContainerLab treats them as one logical lab).

### VXLAN-stitch link format

```yaml
links:
  # Local veth (same host)
  - endpoints: ["r1:eth1", "r2:eth1"]  # 10.0.12.0/30

  # Cross-host link to r3 on host2 (VNI 113)
  - type: vxlan-stitch
    endpoint:
      node: r1
      interface: eth2
    remote: <host2-underlay-ip>   # from host_vars/<host>.yml
    vni: 113
    udp-port: 4789                # always 4789, not containerlab's default 14789
```

The matching entry on host2's topology file must use the same `vni:` value and point `remote:` back at host1's underlay IP.

### VXLAN rules

| Setting | Value | Why |
|---------|-------|-----|
| `udp-port` | `4789` | Linux/RFC default; matches the kernel's VXLAN implementation |
| Underlay MTU | `1600` | Leaves headroom for 50-byte VXLAN/UDP/IP overhead over 1500-byte inner frames |
| VNI scope | one VNI per cross-host link | Reusing VNIs between links causes bridging loops |

### VNI allocation

VNIs are tracked in `multinode/vni-allocation.md`. Always register a new VNI there before deploying.

| Range | Reserved for |
|-------|-------------|
| 100–199 | `multinode-routing-lab` |
| 200–299 | `multinode-layer2-lab` |
| 300–399 | future labs (claim the next free range) |

---

## Ansible Registration

After creating a topology file, register the lab in `ansible/group_vars/all.yml` under `lab_configs` so it can be managed with `labs.yml`.

### Single-host lab entry

```yaml
lab_configs:
  my-new-lab:
    host: lab-01                        # which lab host runs this lab
    topo: my-new-lab.clab.yml           # path relative to the lab's remote_dir
    configs_subdir: my-new-lab          # subdir under singlenode/configs/
    remote_dir: /opt/labs/my-new-lab    # working directory on the host
```

### Multinode lab entry

```yaml
lab_configs:
  my-multinode-lab:
    hosts:
      lab-01: host1.clab.yml
      lab-02: host2.clab.yml
    remote_dir: /opt/labs/my-multinode-lab
```

Run `ansible-playbook ansible/labs.yml -e "lab=my-new-lab action=deploy"` to test the registration.

---

## Linux Endpoint Usage

Add Alpine Linux nodes when a lab needs a simulated client or traffic source — for example, testing VRRP failover or verifying VLAN reachability from an endpoint.

### When to use

- VRRP labs — a PC behind the switch to verify gateway failover
- IRB verification — a client pinging across VLANs
- Traffic shaping (CoS) — `iperf3` source/sink
- Latency/loss simulation — `tc netem` on uplinks

### Topology YAML entry

```yaml
topology:
  kinds:
    linux:
      image: alpine:latest

  nodes:
    pc1:
      kind: linux
      exec:
        - ip addr add 192.168.1.100/24 dev eth1
        - ip route add default via 192.168.1.1
```

Use `exec:` for one-time setup commands (IP config, routes). For more complex initialization, place a shell script in the configs directory and reference it via `binds:`.

### Available tools in Alpine

`ping`, `traceroute`, `iperf3` (install with `apk add iperf3`), `tc` (from `iproute2`), `curl`, `wget`.

---

## Lab Type Skeletons

### Guided lab

**Topology YAML** (`singlenode/routing-<topic>.clab.yml`): use the 4-node routing skeleton above.

**Startup configs** (`singlenode/configs/routing-<topic>/rN.conf`): interfaces + loopbacks + router-id only.

**Lab guide** (`singlenode/Lab Docs/<Topic>-Lab.md`) structure:

```markdown
# <Topic> Lab

## Topology
<diagram>

## Prerequisites
<what must already be working>

## Task 1 — <first objective>
### Background
### Configuration
### Verification
- [ ] <expected output>

## Task 2 — ...
```

---

### Troubleshooting lab

**Topology YAML** (`singlenode/troubleshoot-<topic>.clab.yml`): same format as guided; configs reference `configs/troubleshoot/<topic>/`.

**Startup configs**: full broken configuration. Each config should have 2–4 distinct faults. Faults should cover different failure modes (e.g., wrong interface, wrong area ID, missing policy).

**Lab guide** (`singlenode/Lab Docs/Troubleshoot-<Topic>.md`) structure:

```markdown
# Troubleshoot <Topic>

## Topology
<diagram>

## Your Task
All faults are pre-loaded. Find and fix every problem. No hints.

## Success Criteria
- [ ] <verifiable outcome 1>
- [ ] <verifiable outcome 2>
```

Do not list the faults in the guide. Keep an internal answer key in a comment block or a separate `answers/` directory if needed.

---

### Challenge lab

Challenge labs reuse existing topology files — create only a lab guide.

**Lab guide** (`singlenode/Lab Docs/Challenge-<Topic>.md`) structure:

```markdown
# Challenge: <Topic>

## Topology
<reference the topology file>

## Requirements
1. <specific, testable requirement>
2. ...

## Success Criteria
- [ ] <show command and expected output>
```

No commands, no step-by-step guidance, no hints.

---

## Validation Checklist

Run through this before considering a lab complete.

- [ ] **Topology YAML is valid** — `sudo containerlab validate -t <topo>.clab.yml` returns no errors
- [ ] **All config files exist** — every node referenced in the topology has a matching `.conf` file at the declared path
- [ ] **No subnet overlap** — loopbacks, P2P subnets, and VLAN ranges don't collide with any existing lab
- [ ] **VNI registered** (multinode only) — new VNIs are added to `multinode/vni-allocation.md`
- [ ] **Ansible registration** — lab entry exists in `ansible/group_vars/all.yml` under `lab_configs`
- [ ] **Lab guide created** — `.md` file exists and is linked in `README.md`
- [ ] **Host capacity check** — node count ≤ `min(floor(vcpu/4), floor(ram/5))` for the target host; run `docs/update-capacity.sh` if unsure
- [ ] **Test deploy** — `sudo containerlab deploy -t <topo>.clab.yml` completes without errors
- [ ] **SSH reachable** — `ssh admin@clab-<lab-name>-r1` connects successfully
- [ ] **Configs applied** — `show interfaces terse` on each node shows correct IPs (for guided/troubleshoot labs)

---

## Updating This Document

### After adding or modifying lab hosts

1. Add/update the host entry in `ansible/inventory.yml` and `ansible/host_vars/<host>.yml`.
2. Run `bash docs/update-capacity.sh` and paste the output table into the Host Capacity Table section above.

### Adding a new VNI range

Add a row to the namespace table in `multinode/vni-allocation.md` and document it here under the VNI allocation table.

### Bumping image versions

Update `ansible/group_vars/all.yml` (`vjunos_router_image`, `vjunos_switch_image`), then update the Available Images table at the top of this file to match.
