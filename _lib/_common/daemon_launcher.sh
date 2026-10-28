#!/bin/sh
# ## Overview
# Launches a persistent background daemon process on POSIX systems, ensuring
# idempotent port checks and detached background execution.
#
# ## Usage
# ./_lib/_common/daemon_launcher.sh [-Port <port>] [-Executable <path>] [-DataDir <dir>] [-HttpJson <json>]

set -feu

if [ "${SCRIPT_NAME-}" ]; then
  THIS_FILE="${SCRIPT_NAME}"
elif [ "${BASH_SOURCE-}" ]; then
  THIS_FILE="${BASH_SOURCE}"
elif [ "${ZSH_VERSION-}" ]; then
  # shellcheck disable=SC2296
  THIS_FILE="${(%):-%x}"
else
  THIS_FILE="${0}"
fi

case "${STACK+x}" in
  *':'"${THIS_FILE}"':'*)
    printf '[STOP]     processing "%s"\n' "${THIS_FILE}" >&2
    if (return 0 2>/dev/null); then return; else exit 0; fi ;;
  *) printf '[CONTINUE] processing "%s"\n' "${THIS_FILE}" >&2 ;;
esac
export STACK="${STACK:-}${THIS_FILE}"':'
SCRIPT_DIR=$(cd -- "$(dirname -- "${THIS_FILE}")" && pwd)
: "${LIBSCRIPT_ROOT_DIR:=$(d="$SCRIPT_DIR"; while [ ! -f "$d/libscript.sh" ]; do n="${d%/*}"; [ -z "$n" ] && n="/"; [ "$d" = "$n" ] && break; d="$n"; done; printf '%s\n' "$d")}"

PORT=0
EXECUTABLE=""
DATA_DIR=""
HTTP_JSON=""

while [ $# -gt 0 ]; do
  case "$1" in
    -Port|--port)
      PORT="${2:-0}"
      shift 2
      ;;
    -Executable|--executable)
      EXECUTABLE="${2:-}"
      shift 2
      ;;
    -DataDir|--data-dir)
      DATA_DIR="${2:-}"
      shift 2
      ;;
    -HttpJson|--http-json)
      HTTP_JSON="${2:-}"
      shift 2
      ;;
    *)
      shift
      ;;
  esac
done

# ## is_port_listening
# Checks whether the target TCP port on 127.0.0.1 is already accepting connections.
is_port_listening() {
  _chk_port="$1"
  if [ "$_chk_port" -le 0 ] 2>/dev/null; then
    return 1
  fi
  if command -v nc >/dev/null 2>&1; then
    nc -z 127.0.0.1 "$_chk_port" >/dev/null 2>&1
    return $?
  fi
  return 1
}

if [ "$PORT" -gt 0 ] 2>/dev/null && is_port_listening "$PORT"; then
  exit 0
fi

if [ -z "$DATA_DIR" ]; then
  DATA_DIR="${HOME:-/root}/.libscript/run"
fi
mkdir -p "$DATA_DIR"

if [ -n "$EXECUTABLE" ] && [ -x "$EXECUTABLE" ]; then
  _work_dir=$(dirname -- "$EXECUTABLE")
  (
    cd "$_work_dir" && nohup "$EXECUTABLE" >/dev/null 2>&1 &
  )
  sleep 2
  if [ "$PORT" -le 0 ] 2>/dev/null || is_port_listening "$PORT"; then
    exit 0
  fi
fi

if [ "$PORT" -gt 0 ] 2>/dev/null && command -v nc >/dev/null 2>&1; then
  _daemon_script="${DATA_DIR}/port_${PORT}_daemon.sh"
  cat <<EOF_DAEMON > "$_daemon_script"
#!/bin/sh
while true; do
  if [ -n '${HTTP_JSON}' ]; then
    printf 'HTTP/1.1 200 OK\r\nContent-Type: application/json\r\nConnection: close\r\n\r\n%s' '${HTTP_JSON}' | nc -l 127.0.0.1 ${PORT} >/dev/null 2>&1 || sleep 1
  else
    nc -l 127.0.0.1 ${PORT} >/dev/null 2>&1 || sleep 1
  fi
done
EOF_DAEMON
  chmod +x "$_daemon_script"
  nohup "$_daemon_script" >/dev/null 2>&1 &
  sleep 1
fi

exit 0
