#!/usr/bin/env bash
#
# deploy.sh — TrainTracks ICS/SCADA Bridge Lab deployer
#
# Copies the lab into a web root and (optionally) installs a systemd unit that
# serves it with `python3 -m http.server`. Designed for an offline Donovia Rail
# training host. Idempotent — safe to re-run.
#
# Usage:
#   sudo ./deploy.sh                       # deploy to /var/www/html, install+start service on :8080
#   sudo ./deploy.sh --port 9090           # different port
#   sudo ./deploy.sh --web-root /srv/lab   # different web root
#   sudo ./deploy.sh --no-service          # just copy files, don't touch systemd
#   sudo ./deploy.sh --uninstall           # stop/disable service and remove the unit
#   ./deploy.sh --help
#
set -euo pipefail

# ---- defaults (override via flags) -----------------------------------------
WEB_ROOT="/var/www/html"
PORT="8080"
BIND="0.0.0.0"
SVC_USER="www-data"
SERVICE_NAME="bridge"
INSTALL_SERVICE="yes"
UNINSTALL="no"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ---- pretty output ----------------------------------------------------------
c_ok()   { printf '  \033[0;32m✓\033[0m %s\n' "$*"; }
c_info() { printf '  \033[0;36m·\033[0m %s\n' "$*"; }
c_warn() { printf '  \033[0;33m!\033[0m %s\n' "$*"; }
c_err()  { printf '  \033[0;31m✗\033[0m %s\n' "$*" >&2; }
hr()     { printf '\033[2m%s\033[0m\n' "────────────────────────────────────────────────────────"; }

usage() {
  sed -n '2,/^set -euo/{/^set -euo/d;s/^# \{0,1\}//;p}' "$0"
  exit 0
}

# ---- arg parsing ------------------------------------------------------------
while [ $# -gt 0 ]; do
  case "$1" in
    --web-root) WEB_ROOT="$2"; shift 2 ;;
    --port)     PORT="$2"; shift 2 ;;
    --bind)     BIND="$2"; shift 2 ;;
    --user)     SVC_USER="$2"; shift 2 ;;
    --name)     SERVICE_NAME="$2"; shift 2 ;;
    --no-service) INSTALL_SERVICE="no"; shift ;;
    --uninstall)  UNINSTALL="yes"; shift ;;
    -h|--help)  usage ;;
    *) c_err "unknown option: $1"; echo "try --help"; exit 2 ;;
  esac
done

UNIT_PATH="/etc/systemd/system/${SERVICE_NAME}.service"

need_root() {
  if [ "$(id -u)" -ne 0 ]; then
    c_err "this action needs root. re-run with sudo."
    exit 1
  fi
}

have_systemd() { command -v systemctl >/dev/null 2>&1 && [ -d /run/systemd/system ]; }

# ---- uninstall path ---------------------------------------------------------
if [ "$UNINSTALL" = "yes" ]; then
  need_root
  hr; printf '\033[1mTrainTracks — uninstall\033[0m\n'; hr
  if have_systemd && [ -f "$UNIT_PATH" ]; then
    systemctl stop  "${SERVICE_NAME}.service" 2>/dev/null && c_ok "stopped ${SERVICE_NAME}.service" || c_info "service not running"
    systemctl disable "${SERVICE_NAME}.service" 2>/dev/null && c_ok "disabled ${SERVICE_NAME}.service" || true
    rm -f "$UNIT_PATH" && c_ok "removed $UNIT_PATH"
    systemctl daemon-reload
  else
    c_info "no systemd unit found at $UNIT_PATH"
  fi
  c_warn "web files left in place at $WEB_ROOT (remove manually if desired)"
  exit 0
fi

# ---- locate python3 ---------------------------------------------------------
PYTHON_BIN="$(command -v python3 || true)"
if [ -z "$PYTHON_BIN" ]; then
  c_err "python3 not found in PATH — required to serve the lab."
  exit 1
fi

# ---- preflight: confirm source files ---------------------------------------
hr; printf '\033[1mTrainTracks — deploy\033[0m\n'; hr
REQUIRED="index.html rail.html trainer.html"
for f in $REQUIRED; do
  if [ ! -f "${SCRIPT_DIR}/${f}" ]; then
    c_err "missing source file: ${SCRIPT_DIR}/${f}"
    c_err "run this script from inside the unpacked TrainTracks/ directory."
    exit 1
  fi
done
c_ok "source files present in ${SCRIPT_DIR}"

# ---- copy files (needs root if web root isn't writable) ---------------------
if [ ! -w "$(dirname "$WEB_ROOT")" ] && [ ! -w "$WEB_ROOT" 2>/dev/null ]; then
  need_root
fi
[ "$INSTALL_SERVICE" = "yes" ] && have_systemd && need_root || true

mkdir -p "$WEB_ROOT/docs"
install -m 0644 "${SCRIPT_DIR}/index.html"   "$WEB_ROOT/index.html"
install -m 0644 "${SCRIPT_DIR}/rail.html"    "$WEB_ROOT/rail.html"
install -m 0644 "${SCRIPT_DIR}/trainer.html" "$WEB_ROOT/trainer.html"
c_ok "deployed apps -> $WEB_ROOT (index.html, rail.html, trainer.html)"

for d in README.md Bridge_Usage.md; do
  [ -f "${SCRIPT_DIR}/${d}" ] && install -m 0644 "${SCRIPT_DIR}/${d}" "$WEB_ROOT/${d}"
done
for d in docs/BRIDGE-MECHANICAL-ANALYSIS.md docs/INTEGRATION-README.md; do
  [ -f "${SCRIPT_DIR}/${d}" ] && install -m 0644 "${SCRIPT_DIR}/${d}" "$WEB_ROOT/${d}"
done
c_ok "deployed docs -> $WEB_ROOT/docs"

# ---- ownership --------------------------------------------------------------
if id "$SVC_USER" >/dev/null 2>&1; then
  if [ "$(id -u)" -eq 0 ]; then
    chown -R "${SVC_USER}:${SVC_USER}" "$WEB_ROOT"/index.html "$WEB_ROOT"/rail.html "$WEB_ROOT"/trainer.html "$WEB_ROOT"/docs 2>/dev/null || true
    c_ok "ownership set to ${SVC_USER}"
  fi
else
  c_warn "user '${SVC_USER}' not found — skipping chown (override with --user)"
fi

# ---- systemd unit -----------------------------------------------------------
if [ "$INSTALL_SERVICE" = "yes" ]; then
  if have_systemd; then
    need_root
    cat > "$UNIT_PATH" <<EOF
[Unit]
Description=TrainTracks ICS/SCADA Bridge Lab (static web server)
Documentation=file://${WEB_ROOT}/README.md
After=network.target

[Service]
Type=simple
WorkingDirectory=${WEB_ROOT}
ExecStart=${PYTHON_BIN} -m http.server ${PORT} --bind ${BIND} --directory ${WEB_ROOT}
Restart=on-failure
RestartSec=3
User=${SVC_USER}
Group=${SVC_USER}
NoNewPrivileges=true
ProtectSystem=full
PrivateTmp=true

[Install]
WantedBy=multi-user.target
EOF
    c_ok "wrote $UNIT_PATH"
    systemctl daemon-reload
    systemctl enable "${SERVICE_NAME}.service" >/dev/null 2>&1 && c_ok "enabled ${SERVICE_NAME}.service (start on boot)"
    systemctl restart "${SERVICE_NAME}.service"
    sleep 1
    if systemctl is-active --quiet "${SERVICE_NAME}.service"; then
      c_ok "service is running"
    else
      c_err "service failed to start — check: journalctl -u ${SERVICE_NAME} -n 30"
      exit 1
    fi
  else
    c_warn "systemd not available — skipping service install"
    INSTALL_SERVICE="no"
  fi
fi

# ---- health check -----------------------------------------------------------
HOST_IP="$(hostname -I 2>/dev/null | awk '{print $1}')"; [ -z "${HOST_IP:-}" ] && HOST_IP="<host>"
if command -v curl >/dev/null 2>&1 && [ "$INSTALL_SERVICE" = "yes" ]; then
  if curl -fsS "http://127.0.0.1:${PORT}/index.html" -o /dev/null 2>/dev/null; then
    c_ok "health check passed (http://127.0.0.1:${PORT}/index.html)"
  else
    c_warn "could not reach the server locally yet — give it a moment, then check the URL"
  fi
fi

# ---- summary ----------------------------------------------------------------
hr; printf '\033[1mDone.\033[0m\n'
c_info "Launcher : http://${HOST_IP}:${PORT}/"
c_info "Rail HMI : http://${HOST_IP}:${PORT}/rail.html"
c_info "Trainer  : http://${HOST_IP}:${PORT}/trainer.html"
echo
if [ "$INSTALL_SERVICE" = "yes" ]; then
  c_info "Manage   : systemctl {status|restart|stop} ${SERVICE_NAME}"
else
  c_info "Run now  : ${PYTHON_BIN} -m http.server ${PORT} --bind ${BIND} --directory ${WEB_ROOT}"
fi
c_warn "Open rail.html and trainer.html in separate tabs (same host:port) for live bridge sync."
hr
