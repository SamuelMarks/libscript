#!/bin/sh
# ## Overview
# Test suite for the ollama component.
#
# ## Usage
# Execute this script to perform a component-specific test.

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

SCRIPT_DIR=$(cd -- "$(dirname -- "${THIS_FILE}")" && pwd)
if [ -f "$SCRIPT_DIR/env.sh" ]; then
  unset SCRIPT_NAME || true
  _ls_src_this="${THIS_FILE:-}"; _ls_src_dir="${SCRIPT_DIR:-}"
  SCRIPT_NAME="$SCRIPT_DIR/env.sh"
  export SCRIPT_NAME
  # shellcheck disable=SC1090,SC1091
  . "${SCRIPT_NAME}"
  unset SCRIPT_NAME || true
  [ -n "${_ls_src_this:-}" ] && THIS_FILE="$_ls_src_this"
  [ -n "${_ls_src_dir:-}" ] && SCRIPT_DIR="$_ls_src_dir"
fi

# ## run_ollama_service_unit_tests
# Exercises service.sh configure, ensure-models, and verify_ollama_model_inference SIGSEGV self-healing using isolated mock binaries.
run_ollama_service_unit_tests() {
  _t_dir=$(mktemp -d "${TMPDIR:-/tmp}/libscript_ollama_test.XXXXXX")
  _t_bin="${_t_dir}/bin"
  _t_models="${_t_dir}/ollama_models"
  _t_data="${_t_dir}/data"
  mkdir -p "$_t_bin" "$_t_models" "$_t_data"

  cat > "${_t_bin}/ollama" <<'EOF_MOCK_OLLAMA'
#!/bin/sh
echo "ollama $*" >> "${MOCK_OLLAMA_LOG}"
case "${1:-}" in
  --version|-v)
    printf 'ollama version is 0.5.0-mock\n'
    ;;
  list)
    printf 'NAME\tID\tSIZE\tMODIFIED\n'
    if [ -f "${MOCK_OLLAMA_STATE}" ]; then
      cat "${MOCK_OLLAMA_STATE}"
    fi
    ;;
  pull)
    printf '%s\t999888\t1.6 GB\tjust now\n' "${2:-}" >> "${MOCK_OLLAMA_STATE}"
    printf '1\n' > "${MOCK_OLLAMA_REPULLED}"
    ;;
  rm)
    if [ -f "${MOCK_OLLAMA_STATE}" ]; then
      grep -v "^${2:-}	" "${MOCK_OLLAMA_STATE}" > "${MOCK_OLLAMA_STATE}.tmp" || true
      mv "${MOCK_OLLAMA_STATE}.tmp" "${MOCK_OLLAMA_STATE}"
    fi
    ;;
esac
exit 0
EOF_MOCK_OLLAMA
  chmod +x "${_t_bin}/ollama"

  cat > "${_t_bin}/curl" <<'EOF_MOCK_CURL'
#!/bin/sh
case "$*" in
  */api/tags*)
    if [ -f "${MOCK_OLLAMA_REPULLED}" ]; then
      printf '{"models":[{"name":"gemma:2b","details":{"family":"gemma"}}]}\n'
    else
      printf '{"models":[{"name":"gemma:2b","details":{"family":"llama"}}]}\n'
    fi
    ;;
  *)
    if [ -f "${MOCK_OLLAMA_REPULLED}" ]; then
      printf '{"response":"1","done":true}\n'
    else
      printf '{"error":"llama-server process has terminated: signal: segmentation fault (core dumped)"}\n'
    fi
    ;;
esac
exit 0
EOF_MOCK_CURL
  chmod +x "${_t_bin}/curl"

  MOCK_OLLAMA_LOG="${_t_dir}/ollama.log"
  MOCK_OLLAMA_STATE="${_t_dir}/state.txt"
  MOCK_OLLAMA_REPULLED="${_t_dir}/repulled.flag"
  : > "$MOCK_OLLAMA_LOG"
  printf 'llama3.2:1b\t111222\t1.3 GB\tjust now\ngemma:2b\t111222\t1.3 GB\tjust now\n' > "$MOCK_OLLAMA_STATE"
  export MOCK_OLLAMA_LOG MOCK_OLLAMA_STATE MOCK_OLLAMA_REPULLED

  (
    PATH="${_t_bin}:${PATH}"
    LIBSCRIPT_HOME="${_t_dir}/home"
    LIBSCRIPT_DATA_DIR="$_t_data"
    LIBSCRIPT_INIT_SYSTEM='none'
    OLLAMA_MODELS_DIR="$_t_models"
    OLLAMA_MODELS="$_t_models"
    OLLAMA_READY_TIMEOUT='1'
    OLLAMA_VERIFY_INFERENCE='1'
    STACK=""
    export PATH LIBSCRIPT_HOME LIBSCRIPT_DATA_DIR LIBSCRIPT_INIT_SYSTEM OLLAMA_MODELS_DIR OLLAMA_MODELS OLLAMA_READY_TIMEOUT OLLAMA_VERIFY_INFERENCE STACK
    sh "$SCRIPT_DIR/service.sh" configure "$_t_models"
    [ -d "${_t_models}/manifests" ] && [ -d "${_t_models}/blobs" ]
    STACK=""
    sh "$SCRIPT_DIR/service.sh" ensure-models "gemma:2b"
    grep -q "ollama rm gemma:2b" "$MOCK_OLLAMA_LOG"
    grep -q "ollama pull gemma:2b" "$MOCK_OLLAMA_LOG"
    ! grep -q "ollama cp" "$MOCK_OLLAMA_LOG"
  )
  _t_rc=$?
  rm -rf "$_t_dir"
  return "$_t_rc"
}

run_ollama_service_unit_tests

if command -v ollama >/dev/null 2>&1; then
  ollama --version
elif [ -f "$SCRIPT_DIR/cli.sh" ]; then
  sh "$SCRIPT_DIR/cli.sh" --help >/dev/null
else
  exit 0
fi
