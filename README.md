# SCADA Bridge Lab — Integrated Rail HMI + Mechanical Trainer

Two programs, one host, **live two-way bridge sync**. Open or close a bridge in either app and
the other follows.

## Files

| File | Role |
|---|---|
| `debian9_index.html` | Donovia Rail Network Control System — the dispatcher HMI (now sync-enabled). |
| `trainer.html` | Deep mechanical + Modbus attack trainer (now sync-enabled). |
| `BRIDGE-MECHANICAL-ANALYSIS.md` | Engineering + cyber reference. |
| `INTEGRATION-README.md` | This file. |

## What's synced

The trainer models two of the rail network's eight bridges in full mechanical detail:

```
debian9_index.html              trainer.html
  br1  Congaree River  (bascule) ⇄  Congaree River Bridge (bascule)
  br2  Cooper   River  (swing)   ⇄  Cooper   River Bridge (swing)
```

When either of those two bridges opens or closes in one app, the other app mirrors the same
open/close state. The other six rail bridges are dispatcher-only (the trainer has no model for
them) and are not mirrored.

- Open/close **Congaree** or **Cooper** in the rail HMI → the trainer drives the same bridge
  through its mechanical sequence to match.
- Open/close (or attack into an open/closed state) in the trainer → the rail HMI's map and
  control panel update to match.
- A freshly opened tab reads the **current** state on load, so you can launch the two apps in
  any order and they start consistent.

State that crosses the boundary is intentionally limited to **open / opening / closed / closing**.
Mechanical damage, forced coils, and spoofed sensors stay local to the trainer — those are the
teaching surface, not something the dispatcher view models.

## How it works (for the instructor)

Both pages share state two ways, both fully offline:

1. **`localStorage`** key `scrail_bridge_sync_v1` holds the latest open/close snapshot per bridge.
   This is the source of truth a newly-loaded page reads.
2. **`BroadcastChannel('scrail_bridges')`** pushes each change to other open tabs instantly; a
   `storage`-event fallback covers browsers/usages where BroadcastChannel isn't available.

Each change is tagged with a random per-page origin id, and receivers ignore their own messages
and any update already consistent with local state — so there is no feedback loop between the two
apps.

## Deployment — important

`localStorage` and `BroadcastChannel` are scoped to a browser **origin**. For the two files to
share state they must be served from the **same origin**:

- **Recommended (matches your offline Apache setup):** drop both files in the same web root and
  open them as
  `http://<lab-host>/debian9_index.html` and `http://<lab-host>/trainer.html`.
  Same scheme + host + port = same origin → sync works.
- **Two tabs/windows, same host.** Put the rail HMI in one tab and the trainer in another (or
  side-by-side windows). They sync live.
- **Avoid `file://`.** Chromium treats `file://` pages as opaque origins and will not share
  `localStorage`/`BroadcastChannel` reliably between two different files. Serve them over the lab's
  web server instead (Apache/nginx/`python3 -m http.server` all work offline).

No build step, no database, no network egress — the sync is entirely browser-local.

## Quick verification

1. Serve both files from your lab host and open each in its own tab.
2. In `debian9_index.html`, click **Congaree River Bridge** on the map → **Open Bridge**.
3. Switch to `trainer.html`: Congaree runs its bascule open sequence and ends OPEN.
4. In the trainer, **Close Bridge** → switch back to the rail HMI: br1 Congaree shows CLOSED, track clear.

## Suggested lab flow (≈90 min)

1. **Brief (15m).** `BRIDGE-MECHANICAL-ANALYSIS.md` §1–§4: bascule vs swing mechanics.
2. **Normal ops (15m).** Drive Congaree and Cooper open/close from the rail HMI; watch the trainer
   mirror each one and narrate the subsystems actuating. Establishes "what right looks like" and
   shows the two views are the same assets at two zoom levels.
3. **The wire (10m).** Trainer → Network Console → `scan`. Inventory command coils, forcible
   outputs, and spoofable input registers.
4. **Attacks (30m).** Run TRAINING SCENARIOS 1→7. After each, note what the dispatcher (rail HMI)
   would and would not see — e.g., an unauthorized OPEN shows up on the map, but output-forcing
   damage does not change the dispatcher's open/closed picture at all. That gap is a lesson in
   why HMI-level monitoring misses field-level attacks.
5. **Defense (20m).** `BRIDGE-MECHANICAL-ANALYSIS.md` §6: map each attack to its detection
   signature and the independent (non-PLC) safety control that stops it.

## Reset

Clear shared state from a browser console on either page:

```js
localStorage.removeItem('scrail_bridge_sync_v1');
```

Then reload both tabs. The trainer's own **Reset / Repair Selected Bridge** button clears local
damage, forces, and spoofs without touching sync.
