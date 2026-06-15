#!/usr/bin/env bash
#
# install-console.sh — install the ErrantEngine Terminal Trainer (sandbox)
#
# Installs errantengine-console.py as a runnable command. The console is a
# self-contained training SIMULATOR: it has no network capability, no socket,
# and no Modbus wire protocol — it only mutates an in-memory model. This script
# just copies it onto PATH; it does NOT open any port or start any service.
#
# Usage:
#   ./install-console.sh                 # install to /usr/local/bin (root) or ~/.local/bin (user)
#   sudo ./install-console.sh            # force system-wide
#   ./install-console.sh --prefix DIR    # custom install dir
#   ./install-console.sh --uninstall     # remove it
#   ./install-console.sh --help
#
set -euo pipefail

NAME="errantengine-console"
SRC_BASENAME="errantengine-console.py"
PREFIX=""
UNINSTALL="no"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

c_ok()   { printf '  \033[0;32m✓\033[0m %s\n' "$*"; }
c_info() { printf '  \033[0;36m·\033[0m %s\n' "$*"; }
c_warn() { printf '  \033[0;33m!\033[0m %s\n' "$*"; }
c_err()  { printf '  \033[0;31m✗\033[0m %s\n' "$*" >&2; }

usage() { sed -n '2,/^set -euo/{/^set -euo/d;s/^# \{0,1\}//;p}' "$0"; exit 0; }

while [ $# -gt 0 ]; do
  case "$1" in
    --prefix)    PREFIX="$2"; shift 2 ;;
    --uninstall) UNINSTALL="yes"; shift ;;
    -h|--help)   usage ;;
    *) c_err "unknown option: $1"; echo "try --help"; exit 2 ;;
  esac
done

# choose default prefix: system-wide if root, else user-local
if [ -z "$PREFIX" ]; then
  if [ "$(id -u)" -eq 0 ]; then PREFIX="/usr/local/bin"; else PREFIX="${HOME}/.local/bin"; fi
fi
DEST="${PREFIX}/${NAME}"

if [ "$UNINSTALL" = "yes" ]; then
  if [ -f "$DEST" ]; then rm -f "$DEST" && c_ok "removed $DEST"; else c_info "not installed at $DEST"; fi
  exit 0
fi

# preflight
PYTHON_BIN="$(command -v python3 || true)"
if [ -z "$PYTHON_BIN" ]; then c_err "python3 not found in PATH (need 3.8+)"; exit 1; fi
PYV="$("$PYTHON_BIN" -c 'import sys;print("%d.%d"%sys.version_info[:2])')"
c_info "python3 ${PYV} at ${PYTHON_BIN}"

if [ ! -f "${SCRIPT_DIR}/${SRC_BASENAME}" ]; then
  c_err "missing ${SCRIPT_DIR}/${SRC_BASENAME} — run this from inside TrainTracks/"; exit 1
fi

# syntax-check before installing
"$PYTHON_BIN" -c "import py_compile,sys; py_compile.compile('${SCRIPT_DIR}/${SRC_BASENAME}', doraise=True)" \
  && c_ok "syntax check passed" || { c_err "syntax check failed"; exit 1; }

mkdir -p "$PREFIX"
install -m 0755 "${SCRIPT_DIR}/${SRC_BASENAME}" "$DEST"
c_ok "installed -> $DEST"

# smoke test
if "$DEST" --help >/dev/null 2>&1; then c_ok "runs (--help)"; else c_warn "could not run --help; check python3"; fi

# PATH hint
case ":${PATH}:" in
  *":${PREFIX}:"*) : ;;
  *) c_warn "${PREFIX} is not on your PATH. Add it, or run with: ${DEST}" ;;
esac

printf '\n'
c_info "Launch:  ${NAME}    (or: ${DEST})"
c_info "Guide :  docs/CONSOLE_USAGE.md"
c_warn "Sandbox only — no network I/O. Mutates an in-memory model; cannot touch a real device."
