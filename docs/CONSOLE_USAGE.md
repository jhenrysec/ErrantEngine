# CONSOLE_USAGE.md — ErrantEngine Terminal Trainer

`errantengine-console.py` is a terminal version of the Bridge Mechanical & SCADA Trainer. It models
the Congaree (bascule) and Cooper (swing) bridges and lets students walk the V-series attack/defense
vectors from `Bridge_Usage.md` from a command line.

> **Sandbox only.** The console has **no network capability** — no socket, no Modbus wire protocol,
> and no "target host." Every `write`, `force`, and `spoof` mutates an in-memory Python object and
> nothing else. It cannot connect to, scan, or affect any real or remote device. It is the same
> sandboxed model as `trainer.html`, in a terminal.

---

## Install & run

Stdlib only — Python 3.8+. No dependencies.

```bash
# from inside ErrantEngine/
./install-console.sh          # -> /usr/local/bin (root) or ~/.local/bin (user)
errantengine-console           # launch

# or run it in place without installing:
python3 errantengine-console.py
```

Options: `./install-console.sh --prefix DIR`, `--uninstall`, `--help`.
Run with `--no-color` if your terminal doesn't handle ANSI.

---

## The prompt

```
attacker@kali:congaree[closed]$
```

The prompt shows the **target bridge** and its **state** (`closed` / `OPENING` / `OPEN` / `CLOSING`
/ a percentage / `FAULTED`). Switch targets with `target cooper`.

After any command that causes motion, the simulation fast-forwards to a settled state (or until it
jams), printing the event timeline as it goes — so you see the mechanical consequence immediately.

---

## Command reference

| Command | Effect |
|---|---|
| `help` | command list |
| `scan` | dump the Modbus point map + live values for the target |
| `status` | telemetry + damage for the target bridge |
| `target <congaree\|cooper>` | switch target bridge |
| `read <addr>` | read one point (e.g. `read 30001`) |
| `write coil <addr> <0\|1>` | **cmd-class (0000x) → PLC-validated**; **out-class (001xx) → FORCE (bypass PLC)** |
| `write hreg <addr> <val>` | set a holding register (e.g. `write hreg 40002 60`) |
| `spoof <ireg-addr> <val>` | inject a false sensor value (e.g. `spoof 30005 1`) |
| `clearspoof [addr\|all]` | stop spoofing |
| `unforce [addr\|all]` | release forced output coil(s) |
| `forces` | list active forces + spoofs |
| `open` / `close` / `stop` | operator command via the PLC |
| `occupancy <on\|off>` | place/remove a train on the span |
| `plc <on\|off>` | PLC interlock enforcement (off = command coils act as direct drives) |
| `repair` | reset the target bridge to nominal |
| `scenarios` | list the V-series vectors |
| `scenario <n>` | run vector *n* on the sandbox |
| `tick <sec>` | advance the simulation by N seconds (for partial/stuck states) |
| `quit` | exit |

### The three register classes (the whole lesson)
- **Command coils** `0000x` — honored but interlock-checked → unauthorized but non-destructive.
- **Output coils** `001xx` — forcing them bypasses the PLC → mechanical damage.
- **Input registers** `300xx` — the truth the PLC trusts; spoof them to weaponize the *safe* path.

---

## Built-in vectors (`scenarios`)

Each maps to the matching vector in `Bridge_Usage.md` and prints its steps + the lesson.

| # | Vector | ATT&CK for ICS |
|---|---|---|
| 1 | Reconnaissance — enumerate the field device | T0846 / T0888 |
| 2 | Unauthorized OPEN via command coil | T0855 |
| 3 | Output forcing — drive against the locks | T0831 / T0821 |
| 4 | Sensor spoofing — lie to the interlock | T0856 / T0832 |
| 5 | Swing bridge — rotate on the jacks | T0831 |
| 6 | Defeat the limit — over-travel the span | T0856 / T0879 |
| 7 | Open under load — catastrophe | T0879 / T0880 |

```
attacker@kali:congaree[closed]$ scenario 4
```

---

## Worked examples

**Correct operation (baseline).**
```
target congaree
open          # runs the full safe sequence; status -> OPEN, no damage
close         # reverses it; locks re-engage, rail CLEAR
```

**V3 — output forcing (mechanical damage).**
```
repair
write coil 00101 1     # force MOTOR_RAISE against engaged locks
status                 # rack/pinion STRIPPED; stall current, no motion
```

**V4 — sensor spoofing (safe path turned destructive).**
```
repair
spoof 30005 1          # span lock reports released while physically engaged
spoof 30006 1
write coil 00001 1     # the "safe" OPEN drives the motor into engaged locks
```

**V7 — open under load.**
```
repair
occupancy on
spoof 30008 0          # occupancy interlock lied to
write coil 00001 1     # span moved while occupied
```

Use `repair` between runs, or `target cooper` to work the swing bridge's deeper interlock chain.

---

## Instructor notes

- **Run order:** `open`/`close` baseline → `scan` → V1 → V2 (authorization) → V3/V4 (integrity) →
  V5–V6 (type-specific / limit defeat) → V7 (catastrophe). For each action, require the student to
  name the **ATT&CK technique**, the **detection signature**, and the **independent control** that
  defeats it (see `Bridge_Usage.md` §6 and `docs/BRIDGE-MECHANICAL-ANALYSIS.md` §6).
- **Compare paths:** run V2 (command coil, no damage) immediately before V3 (forced output, damage)
  to make the authorization-vs-integrity distinction concrete.
- **PLC toggle:** `plc off` then `open` shows what a bypassed/mis-programmed controller looks like —
  command coils behave like forced outputs.
- **Reset:** `repair` clears damage, forces, and spoofs on the target bridge.

---

## Relationship to the rest of the lab

The console is a standalone teaching aid; it does **not** sync with `rail.html` / `trainer.html`
(those mirror each other in the browser via same-origin storage). Use the console for a focused,
offline, terminal walk-through of the mechanics and vectors; use the browser apps for the
dispatcher-vs-field view and the live Congaree/Cooper sync. Engineering and defensive detail lives in
`docs/BRIDGE-MECHANICAL-ANALYSIS.md`; the full vector catalog and exploitability ratings are in
`Bridge_Usage.md`.
