# Multinode Layer 2 Lab

Campus L2 topology spread across two containerlab hosts. LAG stays inside host1 (so LACP isn't tested over VXLAN); access switches sit on host2 and connect back via VXLAN trunks.

## Topology

```
                  host1                          |             host2
                                                 |
            sw1 ═══(ae0: eth1+eth2)═══ sw2       |
             │                          │        |
       VXLAN 213                  VXLAN 224      |
       VXLAN 214 ─────────────────────────┐      |
             │                          │ │      |
            sw3 ────(eth4 / eth4)──── sw4         |
                                                 |
```

| Link | Type | Purpose |
|------|------|---------|
| sw1 eth1 — sw2 eth1 | host1 veth | LAG ae0 member 1 |
| sw1 eth2 — sw2 eth2 | host1 veth | LAG ae0 member 2 |
| sw1 eth3 — sw3 eth1 | VXLAN 213 | Trunk VLANs 10/20/30 |
| sw1 eth4 — sw4 eth1 | VXLAN 214 | Trunk to sw4 (VRRP uplink) |
| sw2 eth3 — sw4 eth2 | VXLAN 224 | Redundant uplink |
| sw3 eth4 — sw4 eth4 | host2 veth | Host-local trunk between access switches |

VLANs: 10, 20, 30. IRB: `irb.10 = 192.168.10.1/24` (sw1 master), `irb.20 = 192.168.20.1/24`. VRRP group 10 VIP `192.168.10.254`, sw1 priority 200, sw4 priority 100.

## Deploy

```bash
# on host1
sudo containerlab deploy -t multinode/multinode-layer2-lab/host1.clab.yml

# on host2
sudo containerlab deploy -t multinode/multinode-layer2-lab/host2.clab.yml
```

## Notes for L2 protocols over VXLAN

- **LACP**: Kept inside host1 (ae0 between sw1 and sw2). Running LACP across VXLAN stitched links works but adds underlay sensitivity; keeping it local makes the exercise about LACP, not the tunnel.
- **STP/RSTP**: BPDUs are L2 frames inside the VXLAN payload, so RSTP works end-to-end. Watch root bridge election still pin to sw1; sw3/sw4 see their root ports across VXLAN.
- **VRRP**: Hellos cross VXLAN to elect sw4 as backup. Bring host1 down → sw4 should transition to master in seconds. (Tune `advertise-interval` to test convergence.)
- **IRB**: VLAN-tagged frames are encapsulated transparently. IRB ARP works across hosts as long as both ends of the trunk allow the VLAN.

## Suggested exercises

Same as the single-host [Layer2-Lab](../Lab%20Docs/Layer2-Lab.md), plus:

1. Tear down the host1↔host2 VXLAN trunks one at a time and watch RSTP unblock the redundant uplink.
2. Pause the host2 Docker containers (`docker pause clab-multinode-layer2-lab-sw4`) and watch VRRP master transition on sw1.
3. Inject loss on the underlay (`tc qdisc add dev <underlay_iface> root netem loss 5%`) and observe LACP being unaffected (it's local) while RSTP/VRRP get noisier across VXLAN.

## Tear down

```bash
sudo containerlab destroy -t multinode/multinode-layer2-lab/host1.clab.yml   # host1
sudo containerlab destroy -t multinode/multinode-layer2-lab/host2.clab.yml   # host2
```
