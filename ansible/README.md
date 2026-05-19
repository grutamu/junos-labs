# Ansible — junos-labs host bootstrap & lab management

Two playbooks:

| Playbook | Purpose |
|----------|---------|
| `site.yml` | One-time host bootstrap — installs Docker, containerlab, vJunos images, sets sysctls/MTU/firewall |
| `labs.yml` | Day-to-day lab lifecycle — deploy, destroy, save, inspect, restart |

---

## site.yml — Host Bootstrap

### What it does

| Role | Purpose |
|------|---------|
| `common` | Base packages, kernel modules (`vxlan`, `br_netfilter`), sysctls, underlay NIC MTU via netplan |
| `docker` | Docker CE from the official repo, service enabled |
| `containerlab` | Pinned `containerlab` binary via the official installer |
| `vrnetlab_images` | `docker load` the `juniper_vjunos-{router,switch}` images onto each host |
| `firewall` | `ufw` enabled, SSH from `mgmt_cidr`, UDP/4789 from peer underlay IPs |

User/SSH setup is **not** performed — the playbook assumes you SSH as `root` (set in `inventory.yml`).

### Layout

```
ansible.cfg
inventory.yml          # lab-01 / lab-02 (+lab-03 placeholder)
group_vars/all.yml     # versions, image source, MTU, mgmt CIDR, lab configs
host_vars/lab-01.yml   # ansible_host, underlay_ip, underlay_iface
host_vars/lab-02.yml
site.yml
labs.yml
roles/
```

### Before running

1. **`inventory.yml`** — replace `10.10.0.x` with your real host IPs (or set `ansible_host` in `host_vars/`).
2. **`host_vars/<host>.yml`** — set `underlay_ip` (the address the *peer* host will use for VXLAN) and `underlay_iface` (the NIC carrying that IP).
3. **`group_vars/all.yml`** — set `mgmt_cidr` to your management network. Choose how vJunos images are distributed:
   - `peer` (default) — streams images from `vrnetlab_image_source_host` (default `lab-01`) to every other host via the Ansible controller. The source host must already have the images loaded (built manually from the Juniper-supplied qcow2).
   - `tarball` — load `*.tar` files from `vrnetlab_tarball_dir` on the controller.
   - `registry` — `docker pull` (only works if a registry hosts the images; official vJunos images are not public).
4. **SSH access** — `ssh root@<host>` must work without a password (key auth).

### Run

```bash
cd ansible
ansible-galaxy collection install -r requirements.yml
ansible -m ping lab_hosts           # smoke test
ansible-playbook site.yml --check   # dry run
ansible-playbook site.yml           # full bootstrap
ansible-playbook site.yml --limit lab-02   # single host
```

### Adding a host (e.g. lab-03)

1. Uncomment the `lab-03` block in `inventory.yml`, set its IP.
2. Add `host_vars/lab-03.yml` with `underlay_ip` and `underlay_iface`.
3. Re-run `ansible-playbook site.yml`. The `firewall` role recomputes peer VXLAN rules from inventory automatically.

---

## labs.yml — Lab Lifecycle Management

Deploys, tears down, and manages labs across the bootstrapped hosts.

### Usage

```bash
ansible-playbook labs.yml -e "lab=<name> op=<op>"
```

| `lab` | Description |
|-------|-------------|
| `routing-lab` | 4x vJunos-router, square topology — OSPF, IS-IS, BGP, Policy, CoS |
| `layer2-lab` | 4x vJunos-switch — VLANs, STP, LAG, IRB, VRRP |
| `multinode-routing-lab` | Same routing topology split across two hosts via VXLAN |
| `multinode-layer2-lab` | Same layer2 topology split across two hosts via VXLAN |
| `multinode-load-test` | 10-node dual-pentagon (r1–r5 / r6–r10), OSPF + BFD + iBGP full mesh — host capacity stress test |

| `op` | What it does |
|------|-------------|
| `deploy` | Destroys any existing state, syncs lab files, runs `containerlab deploy` (idempotent) |
| `destroy` | Runs `containerlab destroy --cleanup` |
| `restart` | Alias for `deploy` — destroy + re-sync + deploy |
| `save` | Runs `containerlab save` to write running node configs back to startup-config files |
| `inspect` | Shows running container state — no changes made |

After `deploy`, `restart`, and `inspect`, the playbook prints ready-to-use SSH commands for each node:

```
── lab-01  (ProxyJump: root@100.110.163.67) ──
clab-routing-lab-r1       ssh -J root@100.110.163.67 admin@172.20.20.2
clab-routing-lab-r2       ssh -J root@100.110.163.67 admin@172.20.20.3
```

### Examples

```bash
# Deploy the single-node routing lab on lab-01
ansible-playbook labs.yml -e "lab=routing-lab op=deploy"

# Deploy the multinode routing lab across lab-01 and lab-02
ansible-playbook labs.yml -e "lab=multinode-routing-lab op=deploy"

# Check what's running
ansible-playbook labs.yml -e "lab=multinode-routing-lab op=inspect"

# Save running Junos configs back to startup-config files
ansible-playbook labs.yml -e "lab=routing-lab op=save"

# Tear down
ansible-playbook labs.yml -e "lab=multinode-routing-lab op=destroy"

# Full restart (destroy + redeploy)
ansible-playbook labs.yml -e "lab=routing-lab op=restart"
```

### Adding a new lab to labs.yml

Add an entry to `lab_configs` in `group_vars/all.yml`:

```yaml
# Single-host lab (always runs on lab-01)
my-lab:
  host: lab-01
  topo: my-lab.clab.yml          # relative to singlenode/
  configs_subdir: my-lab         # relative to singlenode/configs/
  remote_dir: /opt/labs/my-lab

# Multinode lab
my-multinode-lab:
  hosts:
    lab-01: host1.clab.yml
    lab-02: host2.clab.yml
  remote_dir: /opt/labs/my-multinode-lab
```
