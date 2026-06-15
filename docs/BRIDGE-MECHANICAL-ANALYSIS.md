# Movable Bridge Mechanical Systems — Deep Analysis for ICS/SCADA Training

**Audience:** U.S. Army 17C Cyber Operations Specialists
**Context:** Offline ICS/SCADA training lab. Companion to the Bridge Mechanical & SCADA Trainer (`trainer.html`) and the Donovia Rail Network Control System (`debian9_index.html`).
**Purpose:** Give cyber operators the *physical* mental model they need to reason about what a network command actually does to a movable bridge — and what a malicious or out-of-sequence command breaks.

The original simulation modeled a bridge as a single number (`angle`, 0–100%) plus three flags (`horn`, `gates`, `lockPins`). That is enough to draw an icon but it hides the entire attack surface. Real movable bridges are choreographed assemblies of a dozen interlocked subsystems, and almost every one of them is a network-reachable point in a modern control system. This document analyzes the two types present in the rail network — **bascule** and **swing** — at the level of fidelity the trainer now simulates.

---

## 1. Why movable-bridge mechanics matter to a cyber operator

A movable bridge is a safety-critical cyber-physical system. The control logic exists to enforce one rule: **the bridge is either safe for rail traffic (seated, locked, load-bearing) or safe for marine traffic (fully open, clear) — and the transition between those two states happens in exactly one correct order.** Every interlock in the PLC exists to prevent an out-of-order transition.

For an operator, the important consequences are:

- **The HMI is not a security boundary.** Operator buttons issue *command* tags that the PLC validates against interlocks. But the field I/O — motor contactors, lock-bar solenoids, brake coils — sits below that logic. Anything that can write directly to those outputs (forced I/O, a compromised PLC, an unauthenticated Modbus/TCP master) bypasses every interlock the engineers wrote.
- **Sequence is everything.** The same coil energized at the wrong time is the difference between a normal opening and a sheared lock bar. The damage is mechanical and often unrecoverable in the field.
- **Sensors are trusted.** PLC interlock logic decides whether motion is safe by *reading position sensors and limit switches*. Spoof those inputs and the logic happily authorizes a destructive command. This is the movable-bridge version of the Stuxnet pattern: lie to the controller about the state of the process.

---

## 2. Bascule bridges (Congaree, Broad, Savannah, Santee in the Donovia network)

"Bascule" is French for *seesaw*. A bascule leaf rotates in a vertical plane about a horizontal axle — the **trunnion** — and is balanced by a **counterweight** on the short (tail) side. Think of a drawbridge that pivots rather than lifts.

### 2.1 Mechanical subsystems (toe-to-tail)

| Subsystem | Function | Failure if mis-commanded |
|---|---|---|
| **Trunnion** | The horizontal axle the leaf rotates on. Carries the entire dead load of leaf + counterweight. | Wear/galling under repeated slamming; bearing seizure. |
| **Counterweight** | Concrete + steel mass on the tail that balances the leaf so the motor only fights friction and wind, not the full deck weight. | If balance assumptions are violated (e.g., ice, modification) the drive is undersized → runaway or stall. |
| **Leaf / span** | The moving deck that carries the rails. | Over-rotation drives it into the counterweight pit; slamming fatigues the steel. |
| **Drive machinery** | Motor → brake → speed reducer → **pinion** → curved **rack** bolted to the leaf. (Some bascules use hydraulic cylinders instead.) | Energizing against an engaged lock strips the rack/pinion teeth — the classic, expensive failure. |
| **Machinery + motor brakes** | Two brakes: a motor brake (holds the motor shaft) and a machinery brake (holds the gear train). Spring-set, electrically released (fail-safe). | Releasing both with no drive on an imperfectly balanced leaf = uncontrolled motion. |
| **Span lock (toe lock)** | Sliding lock bars that pin the raised-toe end of the leaf to the rest pier when seated, so live load doesn't bounce the toe. | Driving the leaf with toe locks engaged shears the bars. |
| **Tail lock / center lock** | Secures the leaf at the centerline for two-leaf bascules; on single-leaf, a seating latch. | Same shear-failure mode. |
| **Live-load shoes / seating** | Hardened bearing surfaces that transfer train load into the pier when the leaf is seated. | Slamming the leaf onto the shoes spalls them; mis-seating concentrates load. |
| **Limit switches** | `SEATED` (fully closed), `NEAR-SEAT` (slow-down), `FULL-OPEN` (~70–82°). Define the legal travel envelope. | Defeating `FULL-OPEN` lets the leaf over-travel into the pit. |
| **Position encoder/resolver** | Continuous angle feedback for the drive controller. | Spoofed feedback makes the controller mis-decelerate → slam or over-travel. |
| **Warning gates / signals / horn** | Stop and warn rail (and any road) traffic before motion. | Suppressing them removes the human safety layer. |

### 2.2 Correct OPEN sequence

```
1. Sound warning horn
2. Set rail signals to STOP (protect the span)
3. Lower warning gates
4. Confirm span unoccupied (track circuit / axle counter clear)
5. Drive span-lock bars to RELEASED   ← verify with lock limit switches
6. Drive tail-lock to RELEASED         ← verify
7. Release machinery brake, then motor brake
8. Energize drive motor (RAISE), leaf rotates up about the trunnion
9. At NEAR-OPEN limit, decelerate
10. At FULL-OPEN limit, de-energize motor, set brakes
```

CLOSE is the mirror image: release brakes → drive LOWER → decelerate at near-seat → seat onto live-load shoes at creep speed → set brakes → drive locks ENGAGED → verify locks → raise gates → clear signals → silence horn.

### 2.3 How a network command breaks it

- **Drive against locks.** Force the motor contactor (RAISE) while the span-lock coil still reads ENGAGED. The leaf can't move; pinion torque has nowhere to go but the rack teeth and the lock bars. **Result: stripped rack/pinion and/or sheared lock bars — bridge inoperable.**
- **Brake release runaway.** Force both brake coils to RELEASED with no drive energized. A real leaf is never perfectly balanced (wind, ice, wear). **Result: the leaf drifts/accelerates uncontrolled; emergency only stopped by re-setting brakes — if the attacker holds them released, the leaf slams a stop.**
- **Limit defeat / over-travel.** Spoof the `FULL-OPEN` input to read *not reached*, keep driving. **Result: the leaf rotates past its envelope into the counterweight pit — structural damage.**
- **Seat-slam.** Command LOWER at full speed and spoof the `NEAR-SEAT` limit so the drive never decelerates. **Result: the leaf hits the live-load shoes at full speed — spalled seats, fatigue.**
- **Open under load.** Defeat the track-occupancy interlock and open with a train on the span. **Result: catastrophic.**

---

## 3. Swing bridges (Cooper, Wateree, Pee Dee, Edisto in the Donovia network)

A swing bridge rotates **horizontally** about a vertical axis on a central **pivot pier**. The span is (usually) symmetric — two arms balanced about the center — and rotates ~90° to lie parallel with the channel, opening two passages on either side of the pivot.

The defining mechanical wrinkle: when closed, a swing span must **lift its ends onto live-load bearings and lock the rails** so it behaves like a fixed bridge under a train. Before it can rotate, it must **set those ends back down and unlock** — or rotation will tear the end machinery apart. This extra "end lift / wedge" choreography is the swing bridge's signature attack surface.

### 3.1 Mechanical subsystems

| Subsystem | Function | Failure if mis-commanded |
|---|---|---|
| **Center pivot bearing** | Carries the full span weight while rotating. Either a **center bearing** (disc/roller) or **rim bearing** (rollers on a circular track). | Rotating with ends still jacked up forces the pivot to carry eccentric load → bearing damage. |
| **Pivot pier / drum** | The fixed structure under the pivot housing the rack. | — |
| **Rotating span (two arms)** | The deck that swings. Balanced about center. | Over-rotation past 90° drives the span into the end stops. |
| **Drive machinery** | Motor → brake → reducer → **pinion** engaging a circular **rack** on the drum. | Driving against engaged wedges/locks strips rack/pinion. |
| **End lifts / end wedges** | Jacks (screw or hydraulic) at each span end that **raise the span ends onto fixed live-load bearings** when closed, transferring train load to the abutments instead of the pivot. Must **retract before rotating.** | **Rotating while engaged shears the wedges/jacks** — the #1 swing-bridge failure. |
| **Center wedges** | Wedges at the pivot that lock the span vertically/laterally when centered. | Driving rotation against them = shear. |
| **Centering device / latch** | Confirms and holds the span exactly centered so wedges and miter rails align. | Driving wedges when not truly centered crushes misaligned seats. |
| **Rail (miter) locks** | Align and lock the running rails across the joint so wheels transition smoothly. | Rotating with rail locks engaged bends the miter rails → derail hazard. |
| **Machinery + motor brakes** | Hold the span against wind when stopped. Spring-set, electrically released. | Released with no drive in wind → the span weathervanes uncontrolled. |
| **Limit switches** | `CENTERED/CLOSED`, `FULL-OPEN (~90°)`, plus near-limits. | Defeating limits → over-rotation, mis-centering. |
| **Position encoder** | Continuous angle feedback. | Spoof → mis-decelerate, mis-center. |
| **Gates / signals / horn** | Warn and stop traffic. | Suppression removes human safety layer. |

### 3.2 Correct OPEN sequence

```
1. Sound horn
2. Rail signals to STOP
3. Lower gates
4. Confirm span unoccupied
5. Unlock rail (miter) locks          ← verify
6. Retract end lifts / end wedges      ← verify ends are down off live-load bearings
7. Retract center wedges               ← verify
8. Release centering latch
9. Release brakes
10. Energize drive (SWING), span rotates about center pivot
11. Decelerate at near-open
12. FULL-OPEN limit → de-energize, set brake
```

CLOSE: release brake → swing back → centering device captures center → verify CENTERED → drive center wedges → drive end lifts to raise ends onto live-load bearings → drive rail locks → verify all → gates up → signals clear → horn off. **Only after the ends are jacked and rails locked is the span safe for a train.**

### 3.3 How a network command breaks it

- **Swing on the jacks.** Force the drive (SWING) while `END_LIFTS = ENGAGED`. The rotating span tries to drag its jacked-up ends sideways. **Result: sheared end-lift screws/jacks and bent guides — span can no longer take live load — bridge unsafe even if it looks closed.**
- **Swing against rail locks.** Force SWING with miter rail locks engaged. **Result: bent miter rails; closed-state derail hazard.**
- **Drop ends under a train.** Retract end lifts (or unlock rails) with a train on the span. **Result: the span deflects on the pivot under load — derailment.**
- **Mis-centered wedging.** Spoof the `CENTERED` input, drive the center/end wedges when the span is a few degrees off. **Result: wedges crush misaligned seats; rails don't align → derail hazard.**
- **Over-rotation.** Defeat `FULL-OPEN`, keep driving past 90°. **Result: span hits end stops; rack/pinion and stops damaged.**
- **Weathervane.** Force brakes RELEASED with no drive. **Result: wind rotates the unpowered span uncontrollably.**

---

## 4. Bascule vs. swing — the cyber-relevant differences

| Dimension | Bascule | Swing |
|---|---|---|
| Motion | Vertical rotation about a horizontal trunnion | Horizontal rotation about a vertical pivot |
| Balance | Counterweight on tail; imbalance → vertical runaway | Balanced about center; imbalance → wind weathervane |
| Signature pre-motion step | Release **span/toe locks** | Retract **end lifts + wedges**, unlock **miter rails** |
| Most expensive mis-command | Drive against toe locks → stripped rack/pinion | Swing on engaged end lifts → sheared jacks |
| "Looks closed but isn't safe" failure | Mis-seated leaf, unspalled shoes | Ends not jacked / rails unlocked under load |
| Extra interlocks vs. simple model | Toe lock, tail lock, near-seat decel, seating shoes | End lifts, center wedges, centering latch, miter rail locks |

**Operator takeaway:** the swing bridge has a *deeper* command sequence (more discrete locking subsystems that must move in order), so it has a larger out-of-sequence attack surface. The bascule's danger is concentrated in raw drive torque vs. locks and gravity runaway.

---

## 5. The control-system mapping (what's on the wire)

Each mechanical subsystem above is wired to PLC I/O and is reachable as a Modbus data point in the trainer. The teaching map:

- **Coils (FC 01/05) — discrete commands & outputs.**
  - *Command coils* (request an action; the PLC validates against interlocks): `OPEN_CMD`, `CLOSE_CMD`, `STOP_CMD`.
  - *Direct output coils* (drive a field device; **bypass interlock logic when forced**): `MOTOR_RAISE`, `MOTOR_LOWER`/`SWING_CW`/`SWING_CCW`, `BRAKE_RELEASE`, `SPAN_LOCK_DRIVE`, `END_LIFT_DRIVE`, `WEDGE_DRIVE`, `RAIL_LOCK_DRIVE`, `HORN`, `GATE_LOWER`.
- **Holding registers (FC 03/06/16) — setpoints.** `CMD_ANGLE`, `DRIVE_SPEED`, `ACCEL_LIMIT`.
- **Input registers (FC 04) — sensors (read-only in normal operation, *spoofable* in a MITM/compromised-RTU scenario).** `POS_ANGLE`, `MOTOR_CURRENT`, `SEATED_LS`, `OPEN_LS`, `LOCK_STATUS`, `END_LIFT_STATUS`, `WEDGE_STATUS`, `SPAN_OCCUPIED`.

### 5.1 The two bypass classes (the heart of the lesson)

1. **Command-tag abuse (authorization failure).** Writing `OPEN_CMD` works because Modbus has no authentication. The PLC *still* runs its interlocks, so the bridge opens *safely* but *without authorization*. Lesson: you don't need to defeat safety to cause an unauthorized state change; you just need write access. (MITRE ATT&CK for ICS: **T0855 Unauthorized Command Message**.)
2. **Output forcing / sensor spoofing (integrity failure).** Forcing a direct output coil, or writing a false value into an input register the PLC trusts, *defeats* the interlocks. This is where mechanical damage happens. Lesson: interlocks are only as trustworthy as the I/O and feedback they're built on. (ATT&CK for ICS: **T0831 Manipulation of Control**, **T0836 Modify Parameter**, **T0856 Spoof Reporting Message**, **T0832 Manipulation of View**.)

---

## 6. Detection & defense (the blue-team half)

For each attack the trainer lets students run, there is an observable. Teach the operators to see them:

| Attack | Observable signature | Defensive control |
|---|---|---|
| Unauthorized `OPEN_CMD` | Command with no corresponding operator action / outside maintenance window; source IP not the HMI | Command-source allow-listing; HMI-to-PLC mutual auth; operations logging & alerting |
| Output forcing | PLC reports forced I/O; output state disagrees with command logic | Force-detection alarms; periodic "no forces" audits; integrity monitoring on PLC |
| Drive-against-lock | `MOTOR_CURRENT` spike with `POS_ANGLE` not changing; lock status ≠ commanded | Motor-current/stall monitoring; position-vs-command deviation alarms |
| Limit defeat / over-travel | `POS_ANGLE` exceeds envelope; limit input frozen while position moves | Cross-check encoder vs. discrete limit switches; hard-wired (non-PLC) over-travel cutouts |
| Sensor spoofing | Input register value physically inconsistent (e.g., `LOCK=RELEASED` while `MOTOR_CURRENT` shows bind) | Redundant/diverse sensing; plausibility checks; signed sensor channels where available |
| Open-under-load | `SPAN_OCCUPIED` true during motion command | Hard-wired track-circuit interlock independent of the PLC (Safety Instrumented System) |

The recurring blue-team thesis: **safety-critical interlocks should not live solely in a network-reachable PLC.** Hard-wired, independent safety systems (over-travel cutouts, track-circuit lockouts) are what stand between a Modbus write and a sheared jack.

---

## 7. How this maps into the simulations

The trainer implements every subsystem in the tables above as a discrete state machine with a damage model, plus the Modbus map in §5. The two bridges modeled — **Congaree River Bridge (bascule)** and **Cooper River Bridge (swing)** — mirror entries in `debian9_index.html`, so the high-level rail HMI and the deep mechanical/SCADA view describe the same assets at two levels of fidelity:

- `debian9_index.html` = the **operator/dispatcher** view (network-wide situational awareness).
- `trainer.html` = the **maintainer + attacker + defender** view (one bridge, every subsystem, every register).

Run order for a class: read this document → drive each bridge through a *correct* sequence in the trainer to build the physical model → run the attack scenarios → study the detection signatures → return to `debian9_index.html` to see the same events at the dispatcher scale.
