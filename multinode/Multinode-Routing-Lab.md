# Multinode Routing Lab

Same square topology as the single-host routing lab, split across two containerlab hosts. Everything you'd configure on the single-host version applies — the VXLAN underlay is invisible to Junos.

## Topology

```
            host1                |               host2
                                 |
        r1 ───────────── r2      |
         │                │      |
         │      VXLAN 113 │ VXLAN 124
         │                │      |
        r3 ───────────── r4      |
                                 |
```

| Link | Type | Subnet |
|------|------|--------|
| r1 ge-0/0/0 — r2 ge-0/0/0 | host1 local veth | 10.0.12.0/30 |
| r1 ge-0/0/1 — r3 ge-0/0/0 | cross-host VXLAN (VNI 113) | 10.0.13.0/30 |
| r2 ge-0/0/1 — r4 ge-0/0/0 | cross-host VXLAN (VNI 124) | 10.0.24.0/30 |
| r3 ge-0/0/1 — r4 ge-0/0/1 | host2 local veth | 10.0.34.0/30 |

Loopbacks: `10.0.0.x/32` (x = router number).

## Deploy

```bash
# on host1
sudo containerlab deploy -t multinode/multinode-routing-lab/host1.clab.yml

# on host2
sudo containerlab deploy -t multinode/multinode-routing-lab/host2.clab.yml
```

SSH from the corresponding host: `ssh admin@clab-multinode-routing-lab-r1`.

## Suggested exercises

Identical to the single-host [Routing-Lab](../Lab%20Docs/Routing-Lab.md) — OSPF single/multi-area, IS-IS, iBGP/eBGP, policy. Cross-host links behave like any other P2P link.

**Things to look for that single-host labs can't show:**

1. Bring an underlay interface down (`ip link set <underlay_iface> down` on host1) — both VXLAN links to host2 drop. Watch OSPF reconvergence prefer the surviving path (r1 → r2 → r4 → r3).
2. Tweak underlay MTU (`/etc/sysctl.d/99-clab.conf`) and verify Junos PMTU discovery and OSPF MTU mismatch behavior.
3. Add ~50ms latency on the underlay with `tc qdisc add dev <underlay_iface> root netem delay 50ms` and observe BGP keepalive/hold timer effects across hosts.

## Verify VXLAN plumbing

```bash
# on either host
ip -d link show type vxlan
tcpdump -i <underlay_iface> udp port 4789 -n
```

Inside Junos, `show interfaces ge-0/0/x extensive` should report the link up and report the inner MTU (default 1500). If you raised `underlay_mtu` to 9000, you can raise the family inet MTU in Junos too and verify with `ping size 8000 do-not-fragment`.

## Tear down

```bash
sudo containerlab destroy -t multinode/multinode-routing-lab/host1.clab.yml   # host1
sudo containerlab destroy -t multinode/multinode-routing-lab/host2.clab.yml   # host2
```
