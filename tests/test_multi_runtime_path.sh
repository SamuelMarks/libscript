#!/bin/sh
# ## Overview
# Verifies multi-component PATH inheritance and SERVICE_PATH emission when hydrating
# a backend manifest combining nodejs, postgres, python, and uv, ensuring no
# cross-component LIBSCRIPT_VERSION bleed occurs.
#
# ## Usage
# ./tests/test_multi_runtime_path.sh

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

_TEST_TMP=$(mktemp -d "${TMPDIR:-/tmp}/libscript_multi_path.XXXXXX")
trap 'rm -rf "$_TEST_TMP"' EXIT INT TERM

export LIBSCRIPT_HOME="${_TEST_TMP}/home/.libscript"
export UV_PYTHON_INSTALL_DIR="${_TEST_TMP}/home/.local/share/uv/python"

mkdir -p "${LIBSCRIPT_HOME}/nodejs/v20.11.0/bin"
mkdir -p "${LIBSCRIPT_HOME}/nodejs/default/bin"
mkdir -p "${LIBSCRIPT_HOME}/postgres/17/bin"
mkdir -p "${LIBSCRIPT_HOME}/postgres/15/bin"
mkdir -p "${UV_PYTHON_INSTALL_DIR}/cpython-3.12.4-linux-x86_64-gnu/bin"
mkdir -p "${LIBSCRIPT_HOME}/uv/latest/bin"
mkdir -p "${_TEST_TMP}/app/.venv/bin"
mkdir -p "${_TEST_TMP}/app/node_modules/.bin"

for _b in node npm npx; do
  printf '#!/bin/sh\nprintf "v20.11.0\\n"\n' > "${LIBSCRIPT_HOME}/nodejs/v20.11.0/bin/${_b}"
  chmod +x "${LIBSCRIPT_HOME}/nodejs/v20.11.0/bin/${_b}"
  printf '#!/bin/sh\nprintf "default\\n"\n' > "${LIBSCRIPT_HOME}/nodejs/default/bin/${_b}"
  chmod +x "${LIBSCRIPT_HOME}/nodejs/default/bin/${_b}"
done

for _b in psql pg_isready; do
  printf '#!/bin/sh\nprintf "17\\n"\n' > "${LIBSCRIPT_HOME}/postgres/17/bin/${_b}"
  chmod +x "${LIBSCRIPT_HOME}/postgres/17/bin/${_b}"
  printf '#!/bin/sh\nprintf "15\\n"\n' > "${LIBSCRIPT_HOME}/postgres/15/bin/${_b}"
  chmod +x "${LIBSCRIPT_HOME}/postgres/15/bin/${_b}"
done

for _b in python python3 pip; do
  printf '#!/bin/sh\nprintf "3.12.4-uv\\n"\n' > "${UV_PYTHON_INSTALL_DIR}/cpython-3.12.4-linux-x86_64-gnu/bin/${_b}"
  chmod +x "${UV_PYTHON_INSTALL_DIR}/cpython-3.12.4-linux-x86_64-gnu/bin/${_b}"
done

printf '#!/bin/sh\nprintf "venv-python\\n"\n' > "${_TEST_TMP}/app/.venv/bin/python"
chmod +x "${_TEST_TMP}/app/.venv/bin/python"
printf '#!/bin/sh\nprintf "uv-0.5\\n"\n' > "${LIBSCRIPT_HOME}/uv/latest/bin/uv"
chmod +x "${LIBSCRIPT_HOME}/uv/latest/bin/uv"

cat > "${_TEST_TMP}/app/libscript.json" << 'JSON_EOF'
{
  "deps": {
    "nodejs": "20.11.0",
    "postgres": "17",
    "python": "3.12",
    "uv": "latest"
  }
}
JSON_EOF

SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/_lib/_common/env_printer.sh"
export SCRIPT_NAME
# shellcheck disable=SC1090,SC1091
. "${SCRIPT_NAME}"
unset SCRIPT_NAME || true

libscript_hydrate_manifest_env "${_TEST_TMP}/app/libscript.json"

if [ -n "${LIBSCRIPT_VERSION:-}" ]; then
  printf '[FAIL] LIBSCRIPT_VERSION leaked after manifest hydration: %s\n' "${LIBSCRIPT_VERSION}" >&2
  exit 1
fi

for _tool in node npm npx psql pg_isready python pip uv; do
  if ! command -v "$_tool" >/dev/null 2>&1; then
    printf '[FAIL] Tool %s not found on PATH (%s)\n' "$_tool" "$PATH" >&2
    exit 1
  fi
done

_node_out=$("${LIBSCRIPT_HOME}/nodejs/v20.11.0/bin/node")
if [ "$(node)" != "$_node_out" ]; then
  printf '[FAIL] Expected node v20.11.0 ahead of default, got: %s\n' "$(node)" >&2
  exit 1
fi

if [ "$(psql)" != "17" ]; then
  printf '[FAIL] Expected psql 17 ahead of 15, got: %s\n' "$(psql)" >&2
  exit 1
fi

if [ "$(python)" != "venv-python" ]; then
  printf '[FAIL] Expected .venv/bin/python ahead of uv python, got: %s\n' "$(python)" >&2
  exit 1
fi

_emitted=$(libscript_print_manifest_env "sh" "${_TEST_TMP}/app/libscript.json")
case "$_emitted" in
  *"v20.11.0/bin"*) ;;
  *)
    printf '[FAIL] Emitted manifest env missing v20.11.0/bin:\n%s\n' "$_emitted" >&2
    exit 1
    ;;
esac
case "$_emitted" in
  *"cpython-3.12.4-linux-x86_64-gnu/bin"*) ;;
  *)
    printf '[FAIL] Emitted manifest env missing uv python bin:\n%s\n' "$_emitted" >&2
    exit 1
    ;;
esac
case "$_emitted" in
  *".venv/bin"*) ;;
  *)
    printf '[FAIL] Emitted manifest env missing .venv/bin:\n%s\n' "$_emitted" >&2
    exit 1
    ;;
esac

printf '[PASS] Multi-runtime PATH inheritance and SERVICE_PATH verification succeeded.\n'
exit 0
