# Multi-Node Labs

Labs that span two containerlab hosts on the same L2 segment, with cross-host links stitched via VXLAN. Single-host labs at the repo root are unaffected — these are separate, additional labs.

## Prerequisites

Both hosts must be bootstrapped via `../ansible/` (Docker, containerlab, vJunos images, VXLAN sysctls/MTU/firewall). See [ansible/README.md](../ansible/README.md).

## Labs

| Lab | Host1 nodes | Host2 nodes | Topics | Guide |
|-----|-------------|-------------|--------|-------|
| `multinode-routing-lab` | r1, r2 | r3, r4 | OSPF / IS-IS / BGP across hosts | [Multinode-Routing-Lab.md](Multinode-Routing-Lab.md) |
| `multinode-layer2-lab` | sw1, sw2 | sw3, sw4 | VLAN trunks + LAG + RSTP + VRRP across hosts | [Multinode-Layer2-Lab.md](Multinode-Layer2-Lab.md) |
| `multinode-load-test` | r1–r5 | r6–r10 | 10-node capacity stress test — OSPF area 0 + BFD + iBGP full mesh (45 sessions) | *(no separate guide)* |

VNI assignments per link: [vni-allocation.md](vni-allocation.md).

## Before deploying

Each `hostN.clab.yml` carries a `remote:` IP for every VXLAN-stitched link. These must match the `underlay_ip` values in `ansible/host_vars/<host>.yml`. The `vni` and `udp-port: 4789` must match on both sides of every link. If you change hosts, update the `remote:` fields in both topology files.

## Deploy

Run each host's half on that host. Order doesn't matter — VXLAN comes up as soon as both sides exist.

```bash
# on host1 (adjust lab name as needed)
sudo containerlab deploy -t multinode/multinode-routing-lab/host1.clab.yml
sudo containerlab deploy -t multinode/multinode-load-test/host1.clab.yml

# on host2
sudo containerlab deploy -t multinode/multinode-routing-lab/host2.clab.yml
sudo containerlab deploy -t multinode/multinode-load-test/host2.clab.yml
```

Or via Ansible (runs deploy on both hosts in one command):

```bash
cd ansible
ansible-playbook labs.yml -e "lab=multinode-routing-lab op=deploy"
ansible-playbook labs.yml -e "lab=multinode-load-test op=deploy"
```

Or via the VS Code Containerlab extension over Remote-SSH to each host.

## Destroy

```bash
# manual
sudo containerlab destroy -t multinode/multinode-routing-lab/hostN.clab.yml

# via Ansible
ansible-playbook labs.yml -e "lab=multinode-routing-lab op=destroy"
```

This also removes the VXLAN interfaces.

## SSH into nodes

```bash
# multinode-routing-lab
ssh admin@clab-multinode-routing-lab-r1     # from host1
ssh admin@clab-multinode-routing-lab-r3     # from host2

# multinode-load-test
ssh admin@clab-multinode-load-test-r1       # from host1 (r1–r5)
ssh admin@clab-multinode-load-test-r6       # from host2 (r6–r10)
```

Lab name is identical on both hosts — that is intentional. Each host owns its half of the node namespace.

## Troubleshooting

- `ip -d link show type vxlan` on each host — confirms VXLAN endpoints exist with the right VNI/remote.
- `tcpdump -i <underlay_iface> udp port 4789` — shows encapsulated traffic crossing.
- `nc -uvz <peer-host-ip> 4789` — sanity-check UDP path through any firewall.
- Wrong VNI or mismatched `remote:` → silent black hole. Diff the two `hostN.clab.yml` files; every cross-host link must have matching `vni` on both sides and each `remote:` pointing at the *other* host's underlay IP.
- MTU drops on big packets → bump `underlay_mtu` in `ansible/group_vars/all.yml` and re-run the playbook, or fragment inside the lab.
