# Troubleshooting Lab — OSPF

## Deploy

```bash
cd ~/development/github/junos-labs
sudo containerlab deploy -t troubleshoot-ospf.clab.yml

ssh admin@clab-troubleshoot-ospf-r1
ssh admin@clab-troubleshoot-ospf-r2
ssh admin@clab-troubleshoot-ospf-r3
ssh admin@clab-troubleshoot-ospf-r4
```

---

## Scenario

A junior engineer configured OSPF across all four routers before going on leave. They left a note saying "OSPF is set up and should be working" but the NOC is reporting that not all routers are reachable.

---

## Intended State

When working correctly, this network should have:

- All four routers running OSPF in a **single area (Area 0)**
- MD5 authentication with a shared key on all OSPF interfaces
- All loopbacks advertised as passive interfaces
- Full loopback reachability — every router should be able to ping every other router's loopback

---

## What You're Seeing

The network is currently broken. Some OSPF adjacencies are not forming, and some loopbacks are unreachable.

---

## Your Task

Find and fix **all** faults. The network is considered fixed when:

- [ ] `show ospf neighbor` — all expected adjacencies in **Full** state on all routers
- [ ] `show route protocol ospf` — all four loopbacks (`10.0.0.1–4/32`) visible on every router
- [ ] `ping 10.0.0.X source 10.0.0.Y` — all loopbacks reachable from all routers
- [ ] `show ospf interface detail` — authentication mode MD5 confirmed on all interfaces

---

## Useful Commands

```
show ospf neighbor
show ospf neighbor detail
show ospf interface
show ospf interface detail
show ospf database
show log messages | match OSPF
show log messages | match auth
show configuration protocols ospf
```

---

## Teardown

```bash
sudo containerlab destroy -t troubleshoot-ospf.clab.yml
```
