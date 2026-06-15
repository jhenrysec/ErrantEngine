# ErrantEngine

**An offline ICS/SCADA movable-bridge cyber range for the Donovia Rail Network scenario.**

ErrantEngine teaches how a network command actually reaches — and breaks — the mechanical guts of a
movable railroad bridge. It pairs a dispatcher-scale rail HMI with a subsystem-level mechanical +
Modbus trainer, syncs their bridge state live, and ships guided attack/defense scenarios mapped to
MITRE ATT&CK for ICS. A terminal version of the trainer (**ErrantEngine**) is included for a
from-the-command-line walkthrough. Built for 17C (Cyber Operations Specialist) instruction in an
air-gapped lab.

The name cuts both ways: the railroad runs on tracks, and the point of the exercise is learning what
an operator can **track** — the anomalous coil write, the stall current with no motion, the lock that
reports released while it is physically engaged.

![License](https://img.shields.io/badge/license-MIT-blue)
![Offline](https://img.shields.io/badge/network-air--gapped%20%2F%20offline-00e676)
![Dependencies](https://img.shields.io/badge/dependencies-none-success)
![Stack](https://img.shields.io/badge/stack-vanilla%20HTML%2FJS%2FSVG%20%2B%20py3%20stdlib-131d2a)

> **Defensive training simulator.** ErrantEngine contains no live protocol stack, no real device I/O,
> and no exploit tooling. The browser apps model an idealized bridge controller in-page; the
> ErrantEngine console mutates an in-memory model only and has **no network capability** (no socket,
> no Modbus wire protocol, no target host). The "attack" scenarios exist to make the **detection and
> resilient-design** lessons concrete. Use in authorized training environments only.

---

## What's new in this release

- **ErrantEngine terminal trainer** (`errantengine-console.py`) — the trainer's bridge model and the
  V-series vector walkthroughs in a hacker-themed CLI. Sandbox only; installs onto PATH.
- **SS-24 SCALPEL scenario asset** — a strategic missile train on the Congaree corridor
  (Columbia-Orangeburg), rendered as a distinct military unit with civilian traffic cleared off its
  track. Opening the Congaree bridge halts it — the mission-impact lever.
- **Live two-way bridge sync** between the rail HMI and the trainer (same-origin, browser-local).
- **`deploy.sh` / `install-console.sh`** — one-command web deploy (web root + systemd) and console
  install.
- **Donovia** scenario naming throughout (DATE convention).

---

## Components

| File | Role |
|---|---|
| `index.html` | Launcher — links to both web apps. |
| `rail.html` | **Donovia Rail Network Control** — dispatcher HMI: trains, switches, signals, all 8 movable bridges, the SS-24 SCALPEL. |
| `trainer.html` | **Bridge Mechanical & SCADA Trainer** — Congaree (bascule) + Cooper (swing) at subsystem fidelity, Modbus map, network console, scenarios. |
| `errantengine-console.py` | **ErrantEngine** — terminal version of the trainer (sandbox, no network I/O). |
| `deploy.sh` | Deploy the web apps to a web root + install/enable a systemd unit. |
| `install-console.sh` | Install the ErrantEngine console onto PATH. |
| `Bridge_Usage.md` | Operator + adversary guide: compromise vectors V1-V8 with exploitability ratings. |
| `docs/BRIDGE-MECHANICAL-ANALYSIS.md` | Engineering + cyber reference (mechanics, sequences, failure modes, defense). |
| `docs/CONSOLE_USAGE.md` | ErrantEngine command + scenario reference. |
| `docs/INTEGRATION-README.md` | Cross-file sync mechanics + deployment. |
| `deploy/bridge.service` | Systemd unit reference. |

### Two views of one network

```
rail.html        (dispatcher / network scale)
   br1 Congaree  = BASCULE   -- SS-24 SCALPEL corridor (Columbia-Orangeburg)
   br2 Cooper    = SWING
        |  live sync (Congaree, Cooper)
        v
trainer.html     (maintainer + attacker + defender)   <->   errantengine-console.py (terminal)
   Congaree River Bridge (bascule)  -- every lock, brake, limit, register
   Cooper  River Bridge (swing)     -- end lifts, wedges, rail locks, pivot
```

---

## The Modbus map (the heart of the lesson)

Every mechanical subsystem maps to a Modbus point. Three classes, three lessons:

| Class | Examples | Writing it teaches |
|---|---|---|
| **Command coils** `0000x` | `OPEN_CMD`, `CLOSE_CMD`, `STOP_CMD` | Honored without auth, but interlock-checked -> **unauthorized but non-destructive** (T0855). |
| **Output coils** `001xx` | `MOTOR_RAISE`, `BRAKE_RELEASE`, `SPANLOCK_RELEASE`, `ENDLIFT_RETRACT` | Forcing bypasses the PLC -> **mechanical damage** (T0831). |
| **Input registers** `300xx` | `POS_ANGLE`, `MOTOR_CURRENT`, `SEATED_LS`, `LOCK_STATUS`, `SPAN_OCCUPIED` | Spoofing weaponizes the *safe* command path — the Stuxnet pattern (T0856 / T0832). |
| **Holding registers** `4000x` | `DRIVE_SPEED` | Parameter manipulation (T0836). |

---

## Scenarios

| # | Scenario | ATT&CK for ICS | Outcome |
|---|---|---|---|
| 1 | Reconnaissance / enumeration | T0846, T0888 | Full control surface revealed; zero auth |
| 2 | Unauthorized OPEN via command coil | T0855 | Opens safely but without authorization |
| 3 | Output forcing — drive against locks | T0831, T0821 | Stall current, no motion, rack/pinion stripped |
| 4 | Sensor spoofing — lie to the interlock | T0856, T0832 | "Safe" sequence drives into engaged locks |
| 5 | Swing bridge — rotate on the jacks | T0831 | End-lift machinery sheared |
| 6 | Defeat the limit — over-travel | T0856, T0879 | Span driven past travel into the end stops |
| 7 | Open under load — catastrophe | T0879, T0880 | Span moved with a train on it |

Run them from the in-app **Training Scenarios** panel (`trainer.html`) or with `scenario <n>` in
ErrantEngine. Full vector catalog + exploitability ratings: `Bridge_Usage.md`.

---

## Quick start

### Web apps (rail + trainer)

Static files served from a **single origin** (the live sync uses `localStorage` + `BroadcastChannel`,
which are origin-scoped).

```bash
sudo ./deploy.sh                 # -> /var/www/html, installs+starts a systemd unit on :8080
sudo ./deploy.sh --port 9090     # custom port
sudo ./deploy.sh --no-service    # copy files only
sudo ./deploy.sh --uninstall     # remove the service
./deploy.sh --help               # all options
```

Or by hand: `python3 -m http.server --bind 0.0.0.0 8080` from the repo root, then browse to
`http://<host>:8080/`. Open `rail.html` and `trainer.html` in separate tabs for the live
Congaree/Cooper sync.

> **Do not use `file://`** — Chromium treats file pages as opaque origins and won't share state.
> Serve over HTTP (any static server works offline).

### ErrantEngine terminal trainer

```bash
./install-console.sh             # -> /usr/local/bin (root) or ~/.local/bin (user)
errantengine-console             # launch
# or run in place:
python3 errantengine-console.py
```

Stdlib-only (Python 3.8+). Command + scenario reference: `docs/CONSOLE_USAGE.md`.

---

## Repository layout

```
ErrantEngine/
├── index.html                       # launcher
├── rail.html                        # Donovia Rail Network Control (dispatcher HMI, w/ SS-24 SCALPEL)
├── trainer.html                     # Bridge Mechanical & SCADA Trainer
├── errantengine-console.py          # ErrantEngine terminal trainer (sandbox — no network I/O)
├── deploy.sh                        # deploy web apps (web root + systemd)
├── install-console.sh               # install the ErrantEngine console onto PATH
├── README.md
├── Bridge_Usage.md                  # operator + adversary guide (compromise vectors)
├── LICENSE
├── deploy/
│   └── bridge.service               # systemd unit reference
└── docs/
    ├── BRIDGE-MECHANICAL-ANALYSIS.md
    ├── CONSOLE_USAGE.md             # ErrantEngine usage guide
    └── INTEGRATION-README.md        # cross-file sync + deployment
```

---

## How the sync works

The rail HMI and trainer share bridge open/close state two ways, both browser-local:

1. **`localStorage`** key `scrail_bridge_sync_v1` — the snapshot a freshly loaded tab reads on start.
2. **`BroadcastChannel('scrail_bridges')`** — instant push to other open tabs (with a `storage`-event
   fallback).

Only `open / opening / closed / closing` crosses the boundary, and only for the two modeled bridges
(Congaree, Cooper). Mechanical damage, forced coils, and spoofed sensors stay local to the trainer —
by design. (Teaching beat: an output-forcing attack that destroys the drive train doesn't change the
dispatcher's open/closed picture at all — which is why HMI-level monitoring misses field-level
attacks.) Origin-tagged messages and consistency guards prevent feedback loops. The ErrantEngine
console is standalone and does not sync. Details: `docs/INTEGRATION-README.md`.

---

## Suggested lab flow (~90 min)

1. **Brief** — `docs/BRIDGE-MECHANICAL-ANALYSIS.md` 1-4: bascule vs swing mechanics.
2. **Normal ops** — drive Congaree and Cooper open/close from the HMI; watch the trainer mirror each
   and name the subsystems actuating.
3. **The wire** — trainer console (or ErrantEngine) -> `scan`; inventory the three register classes.
4. **Attacks** — run scenarios 1->7; after each, state what was written, why the PLC did/didn't stop
   it, what broke, and what the dispatcher would have seen.
5. **The mission** — bring the SS-24 SCALPEL into the Congaree block, then open the bridge (HMI or
   trainer) and discuss mission-delay vs. mechanical denial vs. catastrophe.
6. **Defense** — `docs/BRIDGE-MECHANICAL-ANALYSIS.md` 6: map each attack to its detection signature
   and the independent (non-PLC) safety control that defeats it.

---

## Reset

Clear shared sync state from a browser console on either web app:

```js
localStorage.removeItem('scrail_bridge_sync_v1');
```

Then reload both tabs. The trainer's **Reset / Repair Selected Bridge** button (and ErrantEngine's
`repair`) clears local damage, forces, and spoofs without touching sync.

---

## Built with

Vanilla HTML, CSS, JavaScript, SVG (browser apps) and Python 3 stdlib (ErrantEngine). No frameworks,
no build tooling, no external assets. Designed to run in an isolated, air-gapped lab.

> Note: the README badges fetch from `img.shields.io` and render on github.com but not on an
> air-gapped mirror — swap them for static text if that matters.

## License

MIT — see [`LICENSE`](LICENSE). Educational use encouraged; attribution appreciated.
