#!/bin/sh
# ## Overview
# Detects pre-existing system installations of Python 3.11+ and Node.js 18/20+ via PATH scanning.
#
# ## Usage
# ./packaging/detect_runtimes.sh

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

# ## detect_python
# Detects Python 3 binary and outputs detected version.
detect_python() {
  _py=""
  if command -v python3 >/dev/null 2>&1; then
    _py="python3"
  elif command -v python >/dev/null 2>&1; then
    _py="python"
  fi

  if [ -n "$_py" ]; then
    _ver="$($_py --version 2>&1 | awk '{print $2}')"
    printf 'Detected Python: %s (%s)
' "$(command -v "$_py")" "$_ver"
    FOUND_PYTHON_EXE="$(command -v "$_py")"
    export FOUND_PYTHON_EXE
  fi
}

# ## detect_node
# Detects Node.js binary and outputs detected version.
detect_node() {
  if command -v node >/dev/null 2>&1; then
    _ver="$(node --version 2>&1)"
    printf 'Detected Node.js: %s (%s)
' "$(command -v node)" "$_ver"
    FOUND_NODE_EXE="$(command -v node)"
    export FOUND_NODE_EXE
  fi
}

detect_python
detect_node
exit 0
