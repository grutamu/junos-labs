# Challenge Lab — Class of Service Design

No step-by-step commands. Design and implement the solution yourself.

## Deploy

```bash
cd ~/development/github/junos-labs
sudo containerlab deploy -t routing-lab.clab.yml
```

Interfaces and loopbacks are pre-configured. Configure OSPF first (or use the quick paste from Routing-Lab.md) to establish basic reachability, then implement CoS.

---

## Scenario

r1 is a branch office router. Its ge-0/0/0 interface connects to r2, which represents the WAN uplink to headquarters. You need to implement a complete CoS policy on this link to ensure critical traffic is prioritised and lower-priority traffic doesn't starve time-sensitive applications.

---

## Traffic Classification Requirements

The network carries four traffic types, identified by DSCP markings applied by upstream devices:

| Traffic Type | DSCP Name | DSCP Binary | Priority |
|-------------|-----------|-------------|----------|
| VoIP | EF | 101110 | Highest — must never be delayed |
| Video conferencing | AF41 | 100010 | High — needs guaranteed bandwidth |
| Business data | AF11 | 001010 | Medium |
| Best effort | BE | 000000 | Lowest |

---

## Requirements

### Forwarding Classes

Define four forwarding classes mapped to queues. Choose queue numbers that make sense for the traffic priorities involved. Queue 7 is conventionally reserved for network control (OSPF/BGP hellos) — factor this in.

---

### DSCP Classifier

Create a DSCP classifier that maps incoming DSCP values to the appropriate forwarding class and loss priority:

- EF → highest forwarding class, low loss priority
- AF41 → video forwarding class, low loss priority
- AF11 → business data forwarding class, low loss priority
- BE → best effort forwarding class, low loss priority
- Network control traffic (CS6 = 110000) → network control class, low loss priority

Apply the classifier **inbound** on r1's ge-0/0/0 interface.

---

### Schedulers and Scheduler Map

Design a scheduler for each forwarding class with the following bandwidth guarantees on the WAN link:

| Traffic Class | Minimum Bandwidth | Scheduling Behaviour |
|--------------|-------------------|---------------------|
| VoIP | 20% | Strict priority — served before all others |
| Video | 30% | Strict priority |
| Business data | 30% | Weighted fair queuing |
| Best effort | 20% | Weighted fair queuing |

> Note: Two strict-priority queues is valid but carries risk of starvation — think about whether to use `strict-high` for both or differentiate.

Build a scheduler map binding each scheduler to its forwarding class. Apply it to r1's **ge-0/0/0** interface.

---

### WRED Drop Profile

Configure a WRED drop profile on the business data queue to start dropping **high loss-priority** packets probabilistically before the queue fills:

- Begin dropping at 50% queue fill
- Drop probability should reach 100% at full queue
- Choose appropriate intermediate points

Attach the WRED profile to the business data scheduler for high loss-priority traffic.

---

### DSCP Rewrite

Ensure outgoing packets on ge-0/0/0 are marked with the correct DSCP values based on their forwarding class. At minimum, rewrite EF and BE forwarding classes. Apply the rewrite rule outbound on r1's ge-0/0/0.

---

## Success Criteria

When your implementation is complete, verify:

- [ ] `show class-of-service interface ge-0/0/0` — classifier and scheduler map applied on ge-0/0/0
- [ ] `show class-of-service classifier name <your-classifier>` — all DSCP mappings correct
- [ ] `show class-of-service forwarding-class` — four custom classes defined
- [ ] `show interfaces queue ge-0/0/0` — four queues visible with expected names
- [ ] `show class-of-service drop-profile <name>` — WRED profile defined with correct fill/drop points
- [ ] Generate test traffic: `ping 10.0.12.2 count 1000 rapid size 1400` — watch queue counters with `show interfaces queue ge-0/0/0`
- [ ] OSPF/BGP hellos should appear in the network control queue (queue 7), confirming classifier is working
