#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
errantengine-console.py  —  ErrantEngine Terminal Trainer (SANDBOX)

A self-contained, offline terminal version of the Bridge Mechanical & SCADA Trainer.
It models the Congaree (bascule) and Cooper (swing) bridges and lets students walk the
attack/defense vectors from Bridge_Usage.md against an in-memory simulation.

  >>> THIS IS A TRAINING SIMULATOR. IT HAS NO NETWORK CAPABILITY. <<<
  There is no socket, no Modbus wire protocol, and no "target host" anywhere in this file.
  Every "coil", "register", and "spoof" mutates a local Python object and nothing else.
  It cannot connect to, scan, or affect any real or remote device.

Stdlib only. Python 3.8+.  Run:  python3 errantengine-console.py
"""

import sys, time, shlex

# ─────────────────────────────────────────────────────────────────────────────
# Cosmetic terminal styling
# ─────────────────────────────────────────────────────────────────────────────
USE_COLOR = sys.stdout.isatty() and "--no-color" not in sys.argv
def c(code, s):
    return f"\033[{code}m{s}\033[0m" if USE_COLOR else s
def green(s):  return c("0;32m".replace("m",""), s) if False else c("32", s)
def red(s):    return c("31", s)
def amber(s):  return c("33", s)
def cyan(s):   return c("36", s)
def purple(s): return c("35", s)
def dim(s):    return c("2",  s)
def bold(s):   return c("1",  s)

BANNER = r"""
 ███████╗██████╗ ██████╗ █████╗ ███╗   ██╗████████╗███████╗███╗   ██╗ ██████╗ ██╗███╗   ██╗███████╗
 ██╔════╝██╔══██╗██╔══██╗██╔══██╗████╗  ██║╚══██╔══╝██╔════╝████╗  ██║██╔════╝ ██║████╗  ██║██╔════╝
 █████╗  ██████╔╝██████╔╝███████║██╔██╗ ██║   ██║   █████╗  ██╔██╗ ██║██║  ███╗██║██╔██╗ ██║█████╗
 ██╔══╝  ██╔══██╗██╔══██╗██╔══██║██║╚██╗██║   ██║   ██╔══╝  ██║╚██╗██║██║   ██║██║██║╚██╗██║██╔══╝
 ███████╗██║  ██║██║  ██║██║  ██║██║ ╚████║   ██║   ███████╗██║ ╚████║╚██████╔╝██║██║ ╚████║███████╗
 ╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═══╝   ╚═╝   ╚══════╝╚═╝  ╚═══╝ ╚═════╝ ╚═╝╚═╝  ╚═══╝╚══════╝
"""

# ─────────────────────────────────────────────────────────────────────────────
# Simulation constants (ported from trainer.html)
# ─────────────────────────────────────────────────────────────────────────────
FULL_TRAVEL_SEC = 14.0
NOMINAL_CURRENT = 42
STALL_CURRENT   = 265
DMG_PER_SEC_BIND       = 9.0
DMG_PER_SEC_OVERTRAVEL = 16.0
LOCK_TRANSIT_SEC = 2.2

def clamp(v, lo=0.0, hi=100.0):
    return max(lo, min(hi, v))

def lock_unit(state):
    return {"cmd": state, "pos": 1.0 if state == "engaged" else 0.0, "faulted": False}

# ─────────────────────────────────────────────────────────────────────────────
# Bridge model
# ─────────────────────────────────────────────────────────────────────────────
class Bridge:
    def __init__(self, kind):
        self.kind = kind
        self.angle = 0.0
        self.op = None          # 'open'|'close'|None
        self.op_step = 0
        self.op_timer = 0.0
        self._step_entered = False
        self.motor = {"energized": False, "dir": 0, "current": 0}
        self.brake = "set"
        self.horn = False
        self.gates = "up"
        self.rail_signal = "clear"
        self.occupied = False
        self._flags = {}
        if kind == "bascule":
            self.name = "Congaree River Bridge"; self.id = "congaree"; self.angle_max = 78.0
            self.locks = {"spanLock": lock_unit("engaged"), "tailLock": lock_unit("engaged")}
            self.damage = {k: 0.0 for k in ("rackPinion","spanLock","tailLock","trunnion","shoes","structure")}
            self.centering = None
        else:
            self.name = "Cooper River Bridge"; self.id = "cooper"; self.angle_max = 90.0
            self.locks = {"railLock": lock_unit("engaged"), "endLift": lock_unit("engaged"), "wedge": lock_unit("engaged")}
            self.damage = {k: 0.0 for k in ("rackPinion","railLock","endLift","wedge","pivot","structure")}
            self.centering = "engaged"

    def faulted(self):
        return self.damage["rackPinion"] >= 100 or self.damage["structure"] >= 100 \
               or any(l["faulted"] for l in self.locks.values())

# ─────────────────────────────────────────────────────────────────────────────
# Engine: one bridge "PLC + field" sandbox
# ─────────────────────────────────────────────────────────────────────────────
class Sim:
    def __init__(self, log):
        self.bridges = {"congaree": Bridge("bascule"), "cooper": Bridge("swing")}
        self.target = "congaree"
        self.plc_enforced = True
        self.drive_speed = 100
        self.spoof = {}     # f"{id}:{addr}" -> value (held input register)
        self.forced = {}    # f"{id}:{addr}" -> value (held output coil)
        self.log = log

    @property
    def b(self):
        return self.bridges[self.target]

    # ── sensors (respect spoofing) ──────────────────────────────────────────
    def raw_sensor(self, b, addr):
        if addr == "30001": return round(b.angle / b.angle_max * 100)
        if addr == "30002": return round(b.motor["current"])
        if addr == "30003": return 1 if b.angle < b.angle_max * 0.01 else 0
        if addr == "30004": return 1 if b.angle > b.angle_max * 0.99 else 0
        if addr == "30008": return 1 if b.occupied else 0
        if b.kind == "bascule":
            if addr == "30005": return 1 if (b.locks["spanLock"]["pos"] < 0.1 or b.locks["spanLock"]["faulted"]) else 0
            if addr == "30006": return 1 if (b.locks["tailLock"]["pos"] < 0.1 or b.locks["tailLock"]["faulted"]) else 0
        else:
            if addr == "30005": return 1 if (b.locks["railLock"]["pos"] < 0.1 or b.locks["railLock"]["faulted"]) else 0
            if addr == "30006": return 1 if (b.locks["endLift"]["pos"] < 0.1 or b.locks["endLift"]["faulted"]) else 0
            if addr == "30007": return 1 if (b.locks["wedge"]["pos"] < 0.1 or b.locks["wedge"]["faulted"]) else 0
        return 0

    def sensor(self, b, addr):
        k = f"{b.id}:{addr}"
        return self.spoof[k] if k in self.spoof else self.raw_sensor(b, addr)

    # ── forced outputs (bypass PLC) ─────────────────────────────────────────
    def apply_forced(self, b):
        b._flags["forced_motor"] = False
        f = lambda a: self.forced.get(f"{b.id}:{a}")
        fo, fc = f("00101"), f("00102")
        if fo == 1:   b.motor.update(energized=True, dir=1);  b._flags["forced_motor"] = True
        elif fc == 1: b.motor.update(energized=True, dir=-1); b._flags["forced_motor"] = True
        elif (fo == 0 or fc == 0) and not b.op: b.motor.update(energized=False, dir=0)
        if f("00103") is not None: b.brake = "released" if f("00103") == 1 else "set"
        if f("00110") is not None: b.horn = (f("00110") == 1)
        if f("00111") is not None: b.gates = "down" if f("00111") == 1 else "up"
        lockmap = {"00104":"spanLock","00105":"tailLock"} if b.kind=="bascule" \
                  else {"00104":"railLock","00105":"endLift","00106":"wedge"}
        for a, name in lockmap.items():
            v = f(a)
            if v is not None: b.locks[name]["cmd"] = "released" if v == 1 else "engaged"
        if b.kind == "swing" and f("00107") is not None:
            b.centering = "released" if f("00107") == 1 else "engaged"

    # ── physics tick ────────────────────────────────────────────────────────
    def physics(self, b, dt):
        self.apply_forced(b)
        for l in b.locks.values():
            if l["faulted"]: continue
            tgt = 1.0 if l["cmd"] == "engaged" else 0.0
            if l["pos"] < tgt: l["pos"] = min(tgt, l["pos"] + dt / LOCK_TRANSIT_SEC)
            elif l["pos"] > tgt: l["pos"] = max(tgt, l["pos"] - dt / LOCK_TRANSIT_SEC)

        m = b.motor
        blocked, binds = False, []
        if m["energized"] and m["dir"] != 0:
            if b.brake == "set": blocked = True; binds.append("brake")
            eng = [k for k, l in b.locks.items() if l["pos"] > 0.05 and not l["faulted"]]
            if eng: blocked = True; binds += eng
            if b.kind == "swing" and b.centering == "engaged": blocked = True; binds.append("centering")

        plc_in_control = self.plc_enforced and not b._flags.get("forced_motor")

        if m["energized"] and m["dir"] != 0 and not blocked:
            if b.damage["rackPinion"] >= 100:
                m["current"] = int(STALL_CURRENT * 0.6)
            else:
                rate = (b.angle_max / FULL_TRAVEL_SEC) * (self.drive_speed / 100)
                b.angle += m["dir"] * rate * dt
                m["current"] = int(NOMINAL_CURRENT * (0.6 + 0.4 * (self.drive_speed / 100)))
                if plc_in_control:
                    if m["dir"] > 0 and self.sensor(b, "30004") == 1:
                        if f"{b.id}:30004" not in self.spoof: b.angle = b.angle_max
                        else: b.angle = min(b.angle, b.angle_max)
                        self.stop_motor(b, "reached FULL-OPEN limit")
                    elif m["dir"] < 0 and self.sensor(b, "30003") == 1:
                        if f"{b.id}:30003" not in self.spoof: b.angle = 0.0
                        else: b.angle = max(b.angle, 0.0)
                        self.seat(b)
                if b.angle > b.angle_max:
                    b.angle = b.angle_max
                    b.damage["structure"] = clamp(b.damage["structure"] + DMG_PER_SEC_OVERTRAVEL * dt)
                    m["current"] = STALL_CURRENT
                    self.maybe_fault(b, "_ot", "OVER-TRAVEL past open limit — driven into end stops, structural damage")
                if b.angle < 0:
                    b.angle = 0.0
                    b.damage["structure"] = clamp(b.damage["structure"] + DMG_PER_SEC_OVERTRAVEL * dt)
                    m["current"] = STALL_CURRENT
                    self.maybe_fault(b, "_ss", "SEAT SLAM — driven past seat into hard stop")
        elif m["energized"] and blocked:
            m["current"] = STALL_CURRENT
            b.damage["rackPinion"] = clamp(b.damage["rackPinion"] + DMG_PER_SEC_BIND * dt)
            for k in binds:
                if k in b.damage: b.damage[k] = clamp(b.damage[k] + DMG_PER_SEC_BIND * dt)
            if b.damage["rackPinion"] >= 100:
                self.maybe_fault(b, "_rp", "rack/pinion STRIPPED — drive inoperable")
            for k in binds:
                if k in b.locks and b.damage.get(k, 0) >= 100 and not b.locks[k]["faulted"]:
                    b.locks[k]["faulted"] = True
                    self.fault(b, f"{k} SHEARED — cannot secure for traffic")
        else:
            m["current"] = 0
            unconstrained = (b.brake == "released" and not m["energized"]
                             and not any(l["pos"] > 0.05 and not l["faulted"] for l in b.locks.values())
                             and not (b.kind == "swing" and b.centering == "engaged"))
            if unconstrained and 0.5 < b.angle < b.angle_max - 0.5:
                drift = 6 if b.kind == "bascule" else 3
                b.angle = clamp(b.angle + drift * dt, 0, b.angle_max)
                self.maybe_fault(b, "_drift",
                                 ("LEAF RUNAWAY" if b.kind == "bascule" else "SPAN WEATHERVANE")
                                 + " — brake released with no drive")

        if b.occupied and b.angle > 4:
            self.maybe_fault(b, "_load", "⚠ SPAN MOVED WHILE OCCUPIED — derailment / catastrophic")
            if b._flags.get("_load") and b.damage["structure"] < 30:
                b.damage["structure"] = clamp(b.damage["structure"] + 30)
        else:
            b._flags["_load"] = False

        if b.op:
            self.step_sequence(b, dt)

    def stop_motor(self, b, reason=""):
        b.motor.update(energized=False, dir=0, current=0)
        if reason: self.log(f"{b.name}: motor stop — {reason}", "info")

    def seat(self, b):
        b.motor.update(energized=False, dir=0, current=0)
        self.log(f"{b.name}: leaf/span seated", "info")

    def maybe_fault(self, b, flag, msg):
        if not b._flags.get(flag):
            b._flags[flag] = True
            self.fault(b, msg)

    def fault(self, b, msg):
        self.log(f"{b.name}: {msg}", "error")

    # ── sequence engine ─────────────────────────────────────────────────────
    def seqs(self, b):
        S = self.sensor
        if b.kind == "bascule":
            if b.op == "open":
                return [
                    (lambda: (setattr_state(b, rail_signal="stop", horn=True, gates="down"),
                              self.log(f"{b.name}: OPEN: horn, signals STOP, gates lowering", "warn")),
                     lambda: b.op_timer > 1.6),
                    (lambda: (set_lock(b, "spanLock", "released"), set_lock(b, "tailLock", "released"),
                              self.log(f"{b.name}: OPEN: driving span + tail locks to RELEASED", "info")),
                     lambda: S(b, "30005") == 1 and S(b, "30006") == 1),
                    (lambda: (setattr_state(b, brake="released"),
                              self.log(f"{b.name}: OPEN: machinery brake released", "info")),
                     lambda: b.op_timer > 0.5),
                    (lambda: (motor_on(b, 1), self.log(f"{b.name}: OPEN: drive RAISE — leaf rotating about trunnion", "info")),
                     lambda: not b.motor["energized"]),
                    (lambda: (setattr_state(b, brake="set"), self.finish(b, "OPEN complete — leaf FULL OPEN")),
                     lambda: True),
                ]
            else:
                return [
                    (lambda: (setattr_state(b, rail_signal="stop", horn=True),
                              self.log(f"{b.name}: CLOSE: horn, lowering leaf", "warn")),
                     lambda: b.op_timer > 1.0),
                    (lambda: (setattr_state(b, brake="released"), motor_on(b, -1),
                              self.log(f"{b.name}: CLOSE: drive LOWER — seating leaf", "info")),
                     lambda: not b.motor["energized"]),
                    (lambda: (setattr_state(b, brake="set"), set_lock(b, "spanLock", "engaged"),
                              set_lock(b, "tailLock", "engaged"),
                              self.log(f"{b.name}: CLOSE: driving locks to ENGAGED", "info")),
                     lambda: S(b, "30005") == 0 and S(b, "30006") == 0),
                    (lambda: (setattr_state(b, gates="up", rail_signal="clear", horn=False),
                              self.finish(b, "CLOSE complete — seated, locked, rail CLEAR")),
                     lambda: True),
                ]
        else:
            if b.op == "open":
                return [
                    (lambda: (setattr_state(b, rail_signal="stop", horn=True, gates="down"),
                              self.log(f"{b.name}: OPEN: horn, signals STOP, gates lowering", "warn")),
                     lambda: b.op_timer > 1.6),
                    (lambda: (set_lock(b, "railLock", "released"), set_lock(b, "wedge", "released"),
                              set_lock(b, "endLift", "released"),
                              self.log(f"{b.name}: OPEN: unlock miter rails, retract wedges + end lifts", "info")),
                     lambda: S(b, "30005") == 1 and S(b, "30006") == 1 and S(b, "30007") == 1),
                    (lambda: (set_centering(b, "released"), setattr_state(b, brake="released"),
                              self.log(f"{b.name}: OPEN: centering latch released, brake off", "info")),
                     lambda: b.op_timer > 0.6),
                    (lambda: (motor_on(b, 1), self.log(f"{b.name}: OPEN: drive SWING — span rotating about center pivot", "info")),
                     lambda: not b.motor["energized"]),
                    (lambda: (setattr_state(b, brake="set"), self.finish(b, "OPEN complete — span FULL OPEN (90°)")),
                     lambda: True),
                ]
            else:
                return [
                    (lambda: (setattr_state(b, rail_signal="stop", horn=True),
                              self.log(f"{b.name}: CLOSE: horn, swinging span back", "warn")),
                     lambda: b.op_timer > 1.0),
                    (lambda: (setattr_state(b, brake="released"), motor_on(b, -1),
                              self.log(f"{b.name}: CLOSE: drive SWING to center", "info")),
                     lambda: not b.motor["energized"]),
                    (lambda: (setattr_state(b, brake="set"), set_centering(b, "engaged"),
                              set_lock(b, "wedge", "engaged"), set_lock(b, "endLift", "engaged"),
                              set_lock(b, "railLock", "engaged"),
                              self.log(f"{b.name}: CLOSE: center latch, drive wedges, raise end lifts, lock rails", "info")),
                     lambda: S(b, "30005") == 0 and S(b, "30006") == 0 and S(b, "30007") == 0),
                    (lambda: (setattr_state(b, gates="up", rail_signal="clear", horn=False),
                              self.finish(b, "CLOSE complete — centered, ends raised, rail CLEAR")),
                     lambda: True),
                ]

    def step_sequence(self, b, dt):
        seq = self.seqs(b)
        if b.op_step >= len(seq):
            b.op = None; b.op_step = 0; return
        do, done = seq[b.op_step]
        if not b._step_entered:
            b._step_entered = True; b.op_timer = 0.0
            try: do()
            except Exception: pass
        b.op_timer += dt
        if done(b if False else None) if False else done():
            b.op_step += 1; b._step_entered = False
            if b.op_step >= len(seq):
                b.op = None; b.op_step = 0

    def finish(self, b, msg):
        self.log(f"{b.name}: {msg}", "ok")

    # ── command path ────────────────────────────────────────────────────────
    def command_coil(self, b, which):
        if which == "stop":
            b.op = None; b.op_step = 0; b._step_entered = False
            if not b._flags.get("forced_motor"): b.motor.update(energized=False, dir=0)
            self.log(f"{b.name}: STOP commanded", "warn"); return "stopped"
        if not self.plc_enforced:
            self.forced[f"{b.id}:{'00101' if which=='open' else '00102'}"] = 1
            self.forced[f"{b.id}:{'00102' if which=='open' else '00101'}"] = 0
            self.forced[f"{b.id}:00103"] = 1
            self.log(f"{b.name}: {which.upper()}_CMD with interlocks DISABLED — direct drive", "attack")
            return "direct"
        if which == "open":
            if self.sensor(b, "30008") == 1:
                self.log(f"{b.name}: INTERLOCK — span occupied, OPEN refused", "warn"); return "interlock"
            if b.angle > b.angle_max * 0.99: return "already-open"
        if which == "close" and b.angle < b.angle_max * 0.01:
            return "already-closed"
        b.op = which; b.op_step = 0; b._step_entered = False
        self.log(f"{b.name}: {which.upper()} sequence initiated (PLC-validated)", "info")
        return "sequence"

    def force_coil(self, b, addr, v):
        self.forced[f"{b.id}:{addr}"] = 1 if v else 0
        p = self.find_point(b, addr)
        nm = p[2] if p else addr
        self.log(f"{b.name}: OUTPUT FORCED {addr} ({nm}) = {1 if v else 0}  [bypasses PLC]", "attack")

    # ── point map ───────────────────────────────────────────────────────────
    def points(self, b):
        P = []
        def add(addr, cls, name, getter, desc): P.append((addr, cls, name, getter, desc))
        add("00001","cmd","OPEN_CMD",  lambda: 1 if b.op=="open" else 0, "Request open (PLC interlocks apply)")
        add("00002","cmd","CLOSE_CMD", lambda: 1 if b.op=="close" else 0, "Request close (PLC interlocks apply)")
        add("00003","cmd","STOP_CMD",  lambda: 0, "Halt sequence/motion")
        add("00101","out","DRIVE_SWING_OPEN" if b.kind=="swing" else "MOTOR_RAISE",
            lambda: 1 if (b.motor["energized"] and b.motor["dir"]>0) else 0, "Direct drive output — OPEN direction")
        add("00102","out","DRIVE_SWING_CLOSE" if b.kind=="swing" else "MOTOR_LOWER",
            lambda: 1 if (b.motor["energized"] and b.motor["dir"]<0) else 0, "Direct drive output — CLOSE direction")
        add("00103","out","BRAKE_RELEASE", lambda: 1 if b.brake=="released" else 0, "Direct brake solenoid (1=released)")
        if b.kind == "bascule":
            add("00104","out","SPANLOCK_RELEASE", lambda: 1 if b.locks["spanLock"]["cmd"]=="released" else 0, "Toe span-lock drive (1=release)")
            add("00105","out","TAILLOCK_RELEASE", lambda: 1 if b.locks["tailLock"]["cmd"]=="released" else 0, "Tail-lock drive (1=release)")
        else:
            add("00104","out","RAILLOCK_RELEASE", lambda: 1 if b.locks["railLock"]["cmd"]=="released" else 0, "Miter rail-lock drive (1=release)")
            add("00105","out","ENDLIFT_RETRACT",  lambda: 1 if b.locks["endLift"]["cmd"]=="released" else 0, "End-lift jacks (1=retract)")
            add("00106","out","WEDGE_RETRACT",    lambda: 1 if b.locks["wedge"]["cmd"]=="released" else 0, "Center wedge drive (1=retract)")
            add("00107","out","CENTERLATCH_REL",  lambda: 1 if b.centering=="released" else 0, "Centering latch (1=release)")
        add("00110","out","HORN", lambda: 1 if b.horn else 0, "Warning horn (1=on)")
        add("00111","out","GATE_LOWER", lambda: 1 if b.gates=="down" else 0, "Warning gates (1=down)")
        add("40002","hreg","DRIVE_SPEED", lambda: self.drive_speed, "Drive speed setpoint %")
        add("30001","ireg","POS_ANGLE", lambda: self.sensor(b,"30001"), "Position % open")
        add("30002","ireg","MOTOR_CURRENT", lambda: self.sensor(b,"30002"), "Drive motor current (A)")
        add("30003","ireg","CENTERED_LS" if b.kind=="swing" else "SEATED_LS", lambda: self.sensor(b,"30003"), "Limit: fully seated/centered")
        add("30004","ireg","OPEN_LS", lambda: self.sensor(b,"30004"), "Limit: fully open")
        if b.kind == "bascule":
            add("30005","ireg","SPANLOCK_RELEASED", lambda: self.sensor(b,"30005"), "Span lock released feedback")
            add("30006","ireg","TAILLOCK_RELEASED", lambda: self.sensor(b,"30006"), "Tail lock released feedback")
        else:
            add("30005","ireg","RAILLOCK_RELEASED", lambda: self.sensor(b,"30005"), "Rail lock released feedback")
            add("30006","ireg","ENDLIFT_RETRACTED", lambda: self.sensor(b,"30006"), "End-lift retracted feedback")
            add("30007","ireg","WEDGE_RETRACTED",   lambda: self.sensor(b,"30007"), "Center wedge retracted feedback")
        add("30008","ireg","SPAN_OCCUPIED", lambda: self.sensor(b,"30008"), "Track occupancy (1=train on span)")
        return P

    def find_point(self, b, addr):
        for p in self.points(b):
            if p[0] == addr: return p
        return None

    # ── advance the world until it settles (or a cap) ───────────────────────
    def advance(self, max_sec=70.0, dt=0.05):
        t, stable = 0.0, 0
        while t < max_sec:
            for b in self.bridges.values():
                self.physics(b, dt)
            t += dt
            busy = any(self._busy(b) for b in self.bridges.values())
            stable = 0 if busy else stable + 1
            if stable > 8 and t > 0.2:
                break
        return t

    def _busy(self, b):
        if b.op or b.motor["energized"]:
            return True
        for l in b.locks.values():
            tgt = 1.0 if l["cmd"] == "engaged" else 0.0
            if abs(l["pos"] - tgt) > 0.02 and not l["faulted"]:
                return True
        if b.brake == "released" and 0.5 < b.angle < b.angle_max - 0.5 \
           and not any(l["pos"] > 0.05 for l in b.locks.values()):
            return True
        return False

    def repair(self, which):
        self.bridges[which] = Bridge("bascule" if which == "congaree" else "swing")
        for d in (self.forced, self.spoof):
            for k in [k for k in d if k.startswith(which + ":")]:
                del d[k]
        self.log(f"{self.bridges[which].name}: reset to nominal — damage, forces, spoofs cleared", "ok")

# ── tiny state helpers (kept module-level for the lambdas above) ─────────────
def setattr_state(b, **kw):
    for k, v in kw.items(): setattr(b, k, v)
def set_lock(b, name, state): b.locks[name]["cmd"] = state
def set_centering(b, state): b.centering = state
def motor_on(b, d): b.motor.update(energized=True, dir=d)
def coil_name(b, addr):
    for a, cls, name, *_ in [(p[0],p[1],p[2]) + tuple() for p in []]:
        pass
    return addr

# ─────────────────────────────────────────────────────────────────────────────
# Scenarios — the V1..V8 vectors from Bridge_Usage.md, run on the local sandbox
# ─────────────────────────────────────────────────────────────────────────────
SCENARIOS = [
    ("V1 Reconnaissance", "T0846/T0888", "congaree",
     ["target congaree", "scan", "read 30001", "read 30005"],
     "No auth, no encryption — enumeration alone reveals the control surface."),
    ("V2 Unauthorized OPEN", "T0855", "congaree",
     ["target congaree", "repair", "write coil 00001 1"],
     "Write access = control. The HMI is not a security boundary; the bridge opens safely but without authorization."),
    ("V3 Output forcing — drive against locks", "T0831/T0821", "congaree",
     ["target congaree", "repair", "write coil 00101 1"],
     "Forcing a physical output bypasses every PLC interlock. Stall current with no motion → stripped rack/pinion."),
    ("V4 Sensor spoofing — lie to the interlock", "T0856/T0832", "congaree",
     ["target congaree", "repair", "spoof 30005 1", "spoof 30006 1", "write coil 00001 1"],
     "Falsified feedback weaponizes the SAFE command path. Interlocks are only as trustworthy as their sensors."),
    ("V5 Swing — rotate on the jacks", "T0831", "cooper",
     ["target cooper", "repair", "write coil 00101 1"],
     "Type-specific mechanics → type-specific attack. Driving while end lifts engaged shears the lift machinery."),
    ("V6 Defeat the limit — over-travel", "T0856/T0879", "cooper",
     ["target cooper", "repair", "spoof 30004 0", "write coil 00001 1"],
     "Hard-wired, independent over-travel cutouts — not a spoofable sensor — are what stop this."),
    ("V7 Open under load — catastrophe", "T0879/T0880", "congaree",
     ["target congaree", "repair", "occupancy on", "spoof 30008 0", "write coil 00001 1"],
     "Occupancy protection must be a hard-wired Safety Instrumented System independent of the PLC."),
]

# ─────────────────────────────────────────────────────────────────────────────
# Console
# ─────────────────────────────────────────────────────────────────────────────
class Console:
    def __init__(self):
        self.events = []
        self.sim = Sim(self.log)

    def log(self, msg, cls="info"):
        col = {"info": cyan, "warn": amber, "error": red, "attack": purple, "ok": green}.get(cls, str)
        self.events.append((cls, msg))
        print("   " + col(msg))

    def banner(self):
        print(purple(BANNER) if USE_COLOR else BANNER)
        print(bold("   ErrantEngine Terminal Trainer") + dim("  ·  Donovia Rail SCADA range"))
        print(dim("   ────────────────────────────────────────────────────────────────"))
        print("   " + amber("SANDBOX SIMULATOR — NO NETWORK I/O.") +
              dim(" Every command mutates an in-memory model only;"))
        print(dim("   there is no socket, no Modbus wire protocol, and no real or remote device."))
        print(dim("   Type ") + cyan("help") + dim(" for commands, ") + cyan("scenarios") + dim(" for the V1–V8 walkthroughs."))
        print()

    def prompt(self):
        b = self.sim.b
        st = self.state_word(b)
        tag = purple("attacker@kali") + dim(":") + cyan(b.id) + dim(f"[{st}]") + purple("$ ")
        return tag if USE_COLOR else f"attacker@kali:{b.id}[{st}]$ "

    def state_word(self, b):
        if b.faulted(): return "FAULTED"
        if b.op: return b.op.upper()
        if b.angle < b.angle_max * 0.02: return "closed"
        if b.angle > b.angle_max * 0.98: return "OPEN"
        return f"{round(b.angle / b.angle_max * 100)}%"

    # ── command handling ────────────────────────────────────────────────────
    def run_line(self, line):
        line = line.strip()
        if not line: return
        try: t = shlex.split(line)
        except ValueError: t = line.split()
        cmd, args = t[0].lower(), t[1:]
        s, b = self.sim, self.sim.b

        if cmd in ("help", "?"):       self.cmd_help()
        elif cmd in ("quit", "exit", "q"): raise EOFError
        elif cmd == "target":          self.cmd_target(args)
        elif cmd == "scan":            self.cmd_scan()
        elif cmd == "status":          self.cmd_status()
        elif cmd == "read":            self.cmd_read(args)
        elif cmd == "write":           self.cmd_write(args)
        elif cmd == "spoof":           self.cmd_spoof(args)
        elif cmd == "clearspoof":      self.cmd_clearspoof(args)
        elif cmd == "unforce":         self.cmd_unforce(args)
        elif cmd == "forces":          self.cmd_forces()
        elif cmd in ("open", "close", "stop"): self.cmd_op(cmd)
        elif cmd == "occupancy":       self.cmd_occ(args)
        elif cmd == "plc":             self.cmd_plc(args)
        elif cmd == "repair":          s.repair(s.target); self.settle()
        elif cmd == "scenarios":       self.cmd_scenarios()
        elif cmd == "scenario":        self.cmd_scenario(args)
        elif cmd == "tick":            self.cmd_tick(args)
        else: print("   " + red(f"unknown command: {cmd}") + dim("  (try 'help')"))

    def settle(self):
        self.sim.advance()

    def cmd_help(self):
        rows = [
            ("scan", "dump the Modbus point map + live values"),
            ("status", "telemetry + damage for the target bridge"),
            ("target <congaree|cooper>", "switch target bridge"),
            ("read <addr>", "read one point (e.g. read 30001)"),
            ("write coil <addr> <0|1>", "cmd-class→PLC; out-class→FORCE (bypass PLC)"),
            ("write hreg <addr> <val>", "set holding register (e.g. DRIVE_SPEED)"),
            ("spoof <ireg-addr> <val>", "inject a false sensor value"),
            ("clearspoof [addr|all]", "stop spoofing sensor(s)"),
            ("unforce [addr|all]", "release forced output coil(s)"),
            ("forces", "list active forces + spoofs"),
            ("open | close | stop", "operator command via the PLC"),
            ("occupancy <on|off>", "place/remove a train on the span"),
            ("plc <on|off>", "PLC interlock enforcement"),
            ("repair", "reset the target bridge to nominal"),
            ("scenarios", "list the V1–V8 vector walkthroughs"),
            ("scenario <n>", "run vector n on the sandbox"),
            ("tick <sec>", "advance the simulation by N seconds"),
            ("quit", "exit"),
        ]
        print(dim("   commands:"))
        for k, v in rows:
            print("   " + cyan(k.ljust(28)) + dim(v))

    def cmd_target(self, args):
        if not args or args[0] not in self.sim.bridges:
            print("   " + red("usage: target <congaree|cooper>")); return
        self.sim.target = args[0]
        print("   " + green(f"target → {self.sim.b.name}"))

    def cmd_scan(self):
        b = self.sim.b
        print("   " + green(f"── {b.name} ({b.kind}) — in-memory model ──"))
        cur = None
        labels = {"cmd":"COIL/cmd (PLC-validated)", "out":"COIL/out (forcible — bypass PLC)",
                  "hreg":"HOLDING REG", "ireg":"INPUT REG (sensor — spoofable)"}
        for addr, cls, name, getter, desc in self.sim.points(b):
            if cls != cur:
                cur = cls; print("   " + dim(f"[{labels[cls]}]"))
            k = f"{b.id}:{addr}"
            tag = ""
            if k in self.sim.forced: tag = purple("  «FORCED»")
            if k in self.sim.spoof:  tag = purple("  «SPOOFED»")
            val = str(getter()).ljust(4)
            line = f"     {cyan(addr)}  {name.ljust(18)} = {val}  {dim(desc)}{tag}"
            print(line)

    def cmd_status(self):
        b = self.sim.b
        print("   " + bold(b.name) + dim(f"  ({b.kind})  state=") + self.state_word(b))
        print(f"     position    {cyan(str(round(b.angle/b.angle_max*100)) + '%')}  ({b.angle:.1f}°)")
        mot = (amber(f"{'OPEN' if b.motor['dir']>0 else 'CLOSE'} {b.motor['current']}A")
               if b.motor["energized"] else dim("off"))
        print(f"     motor       {mot}")
        print(f"     brake       {(green('SET') if b.brake=='set' else amber('RELEASED'))}")
        print(f"     gates       {(green('UP') if b.gates=='up' else red('DOWN'))}    "
              f"signal {(green('CLEAR') if b.rail_signal=='clear' else red('STOP'))}    "
              f"horn {(amber('ON') if b.horn else dim('off'))}")
        locklabels = ({"spanLock":"span lock","tailLock":"tail lock"} if b.kind=="bascule"
                      else {"railLock":"rail locks","endLift":"end lifts","wedge":"wedges"})
        for k, lbl in locklabels.items():
            l = b.locks[k]
            if l["faulted"]: stt = purple("FAULTED")
            elif l["pos"] > 0.9: stt = stt = green("engaged/up")
            elif l["pos"] < 0.1: stt = amber("released/down")
            else: stt = cyan(f"{round(l['pos']*100)}%")
            stt = purple("FAULTED") if l["faulted"] else stt
            print(f"     {lbl.ljust(11)} {stt}")
        if b.kind == "swing":
            print(f"     centering   {(green('engaged') if b.centering=='engaged' else amber('released'))}")
        print(f"     occupied    {(red('TRAIN ON SPAN') if b.occupied else dim('clear'))}")
        dmg = "  ".join(
            f"{k}:{self._dmg(v)}" for k, v in b.damage.items() if v > 0
        ) or dim("none")
        print("     damage      " + dmg)

    def _dmg(self, v):
        s = f"{round(v)}"
        return red(s) if v >= 100 else amber(s) if v >= 50 else cyan(s)

    def cmd_read(self, args):
        if not args: print("   " + red("usage: read <addr>")); return
        p = self.sim.find_point(self.sim.b, args[0])
        if not p: print("   " + red(f"no such point: {args[0]}")); return
        print(f"     {cyan(p[0])} {p[2]} = {p[3]()}   {dim('('+p[4]+')')}")

    def cmd_write(self, args):
        if len(args) < 3:
            print("   " + red("usage: write <coil|hreg> <addr> <val>")); return
        kind, addr, vals = args[0].lower(), args[1], args[2]
        b = self.sim.b
        try: val = int(vals)
        except ValueError: print("   " + red("value must be a number")); return
        p = self.sim.find_point(b, addr)
        if not p: print("   " + red(f"no such point: {addr}")); return
        cls = p[1]
        if cls == "ireg":
            print("   " + amber("input registers are read-only on the wire — use 'spoof' to inject false data")); return
        if cls == "cmd":
            which = {"00001":"open", "00002":"close", "00003":"stop"}[addr]
            if val: self.sim.command_coil(b, which); self.settle()
        elif cls == "out":
            self.sim.force_coil(b, addr, val); self.settle()
        elif cls == "hreg" and addr == "40002":
            self.sim.drive_speed = max(1, min(100, val))
            print("   " + green(f"DRIVE_SPEED = {self.sim.drive_speed}%"))

    def cmd_spoof(self, args):
        if len(args) < 2: print("   " + red("usage: spoof <ireg-addr> <val>")); return
        addr = args[1] if args[0].lower() == "ireg" else args[0]
        valpos = 2 if args[0].lower() == "ireg" else 1
        b = self.sim.b
        p = self.sim.find_point(b, addr)
        if not p or p[1] != "ireg":
            print("   " + red("spoof targets input registers (30001+). e.g. spoof 30005 1")); return
        try: val = int(args[valpos])
        except (ValueError, IndexError): print("   " + red("need a value")); return
        self.sim.spoof[f"{b.id}:{addr}"] = val
        self.log(f"{b.name}: SENSOR SPOOFED {addr} ({p[2]}) = {val}  [false data injection]", "attack")
        self.settle()

    def cmd_clearspoof(self, args):
        b = self.sim.b
        if args and args[0] == "all":
            for k in [k for k in self.sim.spoof if k.startswith(b.id + ":")]: del self.sim.spoof[k]
            print("   " + green("all spoofs cleared")); self.settle(); return
        if args:
            k = f"{b.id}:{args[0]}"
            if k in self.sim.spoof: del self.sim.spoof[k]; print("   " + green(f"spoof cleared: {args[0]}"))
            else: print("   " + red("not spoofed"))
        self.settle()

    def cmd_unforce(self, args):
        b = self.sim.b
        if args and args[0] == "all":
            for k in [k for k in self.sim.forced if k.startswith(b.id + ":")]: del self.sim.forced[k]
            print("   " + green("all forces released")); self.settle(); return
        if args:
            k = f"{b.id}:{args[0]}"
            if k in self.sim.forced: del self.sim.forced[k]; print("   " + green(f"force released: {args[0]}"))
            else: print("   " + red("not forced"))
        self.settle()

    def cmd_forces(self):
        b = self.sim.b
        ff = [k for k in self.sim.forced if k.startswith(b.id + ":")]
        ss = [k for k in self.sim.spoof if k.startswith(b.id + ":")]
        if not ff and not ss: print("   " + green("no active forces or spoofs")); return
        for k in ff: print("   " + purple(f"FORCED  {k.split(':')[1]} = {self.sim.forced[k]}"))
        for k in ss: print("   " + purple(f"SPOOFED {k.split(':')[1]} = {self.sim.spoof[k]}"))

    def cmd_op(self, which):
        self.sim.command_coil(self.sim.b, which); self.settle()

    def cmd_occ(self, args):
        if not args or args[0] not in ("on", "off"): print("   " + red("usage: occupancy <on|off>")); return
        self.sim.b.occupied = (args[0] == "on")
        self.log(f"{self.sim.b.name}: track occupancy {'SET — train on span' if self.sim.b.occupied else 'cleared'}",
                 "warn" if self.sim.b.occupied else "info")

    def cmd_plc(self, args):
        if not args or args[0] not in ("on", "off"): print("   " + red("usage: plc <on|off>")); return
        self.sim.plc_enforced = (args[0] == "on")
        self.log(f"PLC interlock enforcement {'ENABLED' if self.sim.plc_enforced else 'DISABLED — command coils act as direct drives'}",
                 "info" if self.sim.plc_enforced else "attack")

    def cmd_tick(self, args):
        try: sec = float(args[0])
        except (ValueError, IndexError): sec = 5.0
        t, dt = 0.0, 0.05
        while t < sec:
            for b in self.sim.bridges.values(): self.sim.physics(b, dt)
            t += dt
        print("   " + dim(f"advanced {sec:.1f}s"))

    def cmd_scenarios(self):
        print(dim("   V-series vectors (from Bridge_Usage.md):"))
        for i, (title, att, *_rest) in enumerate(SCENARIOS, 1):
            print("   " + cyan(f"{i}.".ljust(4)) + title.ljust(40) + dim(att))
        print(dim("   run one with: ") + cyan("scenario <n>"))

    def cmd_scenario(self, args):
        try: i = int(args[0]) - 1; sc = SCENARIOS[i]
        except (ValueError, IndexError): print("   " + red("usage: scenario <n>  (see 'scenarios')")); return
        title, att, _tgt, steps, lesson = sc
        print()
        print("   " + purple(bold(f"▶ SCENARIO {args[0]} — {title}")) + dim(f"   [{att}]"))
        for step in steps:
            print("   " + dim("$ ") + cyan(step))
            self.run_line(step)
            time.sleep(0.05)
        print("   " + green("lesson: ") + lesson)
        print()

    def loop(self):
        self.banner()
        while True:
            try:
                line = input(self.prompt())
            except (EOFError, KeyboardInterrupt):
                print("\n   " + dim("session closed.")); break
            try:
                self.run_line(line)
            except EOFError:
                print("   " + dim("session closed.")); break
            except Exception as e:
                print("   " + red(f"error: {e}"))


def main():
    if "--help" in sys.argv or "-h" in sys.argv:
        print(__doc__); return
    Console().loop()

if __name__ == "__main__":
    main()
