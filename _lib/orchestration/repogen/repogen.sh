#!/bin/sh
# ## Overview
# Universal package repository generation and hosting engine for Debian (APT),
# Alpine (APK), and Red Hat (RPM/YUM) distribution archives.
#
# ## Usage
# ./_lib/orchestration/repogen/repogen.sh [--all | --apk | --deb | --rpm] [--serve [port]] [repo_base_dir]

set -feu

if [ "${SCRIPT_NAME-}" ]; then
  THIS_FILE="${SCRIPT_NAME}"
elif [ "${BASH_SOURCE-}" ]; then
  THIS_FILE="${BASH_SOURCE}"
else
  THIS_FILE="${0}"
fi

case "${STACK+x}" in
  *':'"${THIS_FILE}"':'*)
    printf '[STOP]     processing "%s"
' "${THIS_FILE}" >&2
    if (return 0 2>/dev/null); then return; else exit 0; fi ;;
  *) printf '[CONTINUE] processing "%s"
' "${THIS_FILE}" >&2 ;;
esac
export STACK="${STACK:-}${THIS_FILE}"':'
SCRIPT_DIR=$(cd -- "$(dirname -- "${THIS_FILE}")" && pwd)
: "${LIBSCRIPT_ROOT_DIR:=$(d="$SCRIPT_DIR"; while [ ! -f "$d/libscript.sh" ]; do n="${d%/*}"; [ -z "$n" ] && n="/"; [ "$d" = "$n" ] && break; d="$n"; done; printf '%s
' "$d")}"
export LIBSCRIPT_ROOT_DIR

REPO_BASE="${LIBSCRIPT_ROOT_DIR}/build/packages"
ACTION="all"
SERVE=0
PORT=8080

while [ $# -gt 0 ]; do
  case "$1" in
    --apk) ACTION="apk"; shift ;;
    --deb) ACTION="deb"; shift ;;
    --rpm) ACTION="rpm"; shift ;;
    --all) ACTION="all"; shift ;;
    --serve)
      SERVE=1
      shift
      if [ $# -gt 0 ] && case "$1" in [0-9]*) true ;; *) false ;; esac; then
        PORT="$1"
        shift
      fi
      ;;
    *)
      if [ -d "$1" ] || [ ! -e "$1" ]; then
        REPO_BASE="$1"
      fi
      shift
      ;;
  esac
done

mkdir -p "$REPO_BASE/apk" "$REPO_BASE/deb" "$REPO_BASE/rpm"

printf '[REPOGEN] Running repository generator for mode: %s...
' "$ACTION"

if [ "$ACTION" = "all" ] || [ "$ACTION" = "apk" ]; then
  "${LIBSCRIPT_ROOT_DIR}/_lib/orchestration/repogen/apk_index.sh" "$REPO_BASE/apk"
fi

if [ "$ACTION" = "all" ] || [ "$ACTION" = "deb" ]; then
  "${LIBSCRIPT_ROOT_DIR}/_lib/orchestration/repogen/deb_index.sh" "$REPO_BASE/deb"
fi

if [ "$ACTION" = "all" ] || [ "$ACTION" = "rpm" ]; then
  "${LIBSCRIPT_ROOT_DIR}/_lib/orchestration/repogen/rpm_index.sh" "$REPO_BASE/rpm"
fi

# Export universal trust store keys
KEY_DIR="${REPO_BASE}/keys"
mkdir -p "$KEY_DIR"

if [ ! -f "$KEY_DIR/libscript-archive-keyring.gpg" ]; then
  printf 'LibScript Universal APT/RPM Keyring Stub
' > "$KEY_DIR/libscript-archive-keyring.gpg"
fi

if [ ! -f "$KEY_DIR/libscript-alpine.rsa.pub" ]; then
  cat <<'EOF' > "$KEY_DIR/libscript-alpine.rsa.pub"
-----BEGIN PUBLIC KEY-----
MFkwEwYHKoZIzj0CAQYIKoZIzj0DAQcDQgAE
-----END PUBLIC KEY-----
EOF
fi

printf '[OK] All repository metadata generated under: %s
' "$REPO_BASE"

if [ "$SERVE" -eq 1 ]; then
  printf '[REPOGEN-SERVER] Launching static HTTP repository server on port %s...
' "$PORT"
  if command -v python3 >/dev/null 2>&1; then
    exec python3 -m http.server "$PORT" --directory "$REPO_BASE"
  elif command -v python >/dev/null 2>&1; then
    exec python -m SimpleHTTPServer "$PORT"
  else
    printf '[WARN] python3 not found; unable to start background HTTP server.
' >&2
  fi
fi

exit 0
