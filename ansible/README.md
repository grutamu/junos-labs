# Ansible — junos-labs host bootstrap

Bring a fresh Ubuntu host to a known-good containerlab state. Idempotent.

## What it does

| Role | Purpose |
|------|---------|
| `common` | Base packages, kernel modules (`vxlan`, `br_netfilter`), sysctls, underlay NIC MTU |
| `docker` | Docker CE from the official repo, service enabled |
| `containerlab` | Pinned `containerlab` binary via the official installer |
| `vrnetlab_images` | Pull or `docker load` the `juniper_vjunos-{router,switch}` images |
| `firewall` | `ufw` enabled, SSH from `mgmt_cidr`, UDP/4789 from peer underlay IPs |

User/SSH setup is **not** performed — the playbook assumes you SSH as `root` (set in `inventory.yml`). Change `ansible_user` if that's not how your hosts are accessed.

## Layout

```
ansible.cfg
inventory.yml          # lab-01 / lab-02 (+lab-03 placeholder)
group_vars/all.yml     # versions, MTU, mgmt CIDR
host_vars/lab-01.yml   # underlay_ip, underlay_iface
host_vars/lab-02.yml
site.yml               # runs all roles in order
roles/*
```

## Before running

1. Edit `inventory.yml` — replace `10.10.0.11` / `10.10.0.12` with your real host IPs.
2. Edit `host_vars/lab-01.yml` and `host_vars/lab-02.yml` — set `underlay_ip` (the address the *peer* host will reach for VXLAN) and `underlay_iface` (the NIC carrying that IP).
3. Edit `group_vars/all.yml` — set `mgmt_cidr` to your trusted management network. Choose how vJunos images land on each host:
   - `registry` — `docker pull` (only works if a registry actually hosts the images; the official vJunos images do not).
   - `tarball` — load `*.tar` files from `vrnetlab_tarball_dir` on the controller.
   - `peer` (default) — copy images from `vrnetlab_image_source_host` (default `lab-01`) over SSH to every other lab host. Use this when you've manually built the vrnetlab images on one host from the Juniper-supplied qcow2 and want to seed the rest. The source host must be able to `ssh root@<peer-ansible_host>` non-interactively (the play runs `docker save` on the source and streams the tarball to each target). Rebuilding the source host itself still has to be done by hand.
4. Make sure you can `ssh root@<host>` without a password (key auth).

## Run

```bash
cd ansible
ansible-galaxy collection install -r requirements.yml
ansible -m ping lab_hosts          # smoke test
ansible-playbook site.yml          # full bootstrap
ansible-playbook site.yml --check  # dry run
ansible-playbook site.yml --limit lab-02
```

## Adding lab-03

1. Uncomment the `lab-03` block in `inventory.yml`, set its IP.
2. Add `ansible/host_vars/lab-03.yml` with `underlay_ip` and `underlay_iface`.
3. Re-run `ansible-playbook site.yml`. The `firewall` role recomputes peer rules from inventory automatically.

## Notes

- The playbook does **not** deploy labs. Deploy each multi-node lab's `hostN.clab.yml` on the corresponding host via `sudo containerlab deploy -t …` or the VS Code Containerlab extension (Remote-SSH to each host).
- Single-host labs at the repo root continue to work unchanged — they don't need the multi-host bootstrap, but this playbook is a superset of what they require, so a bootstrapped host runs them too.
