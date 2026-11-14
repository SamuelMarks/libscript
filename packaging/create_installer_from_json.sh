#!/bin/sh
# ## Overview
# Generates deterministic POSIX (.sh) and Windows Batch (.cmd) stack installer packages
# from a JSON manifest using _lib/utilities/jq and _lib/orchestration/resolve_stack.sh.
#
# ## Usage
# ./packaging/create_installer_from_json.sh -f <manifest.json> [-o <output_dir>] [-a <0|1>]

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

VERBOSE=0
ALL_DEPS=0
HELP=0
OUTPUT_FOLDER="${LIBSCRIPT_ROOT_DIR}/tmp"
BASE="${BASE:-alpine:latest debian:bookworm-slim}"
FILENAME=""

# ## show_help
# Displays command-line usage instructions and available options.
show_help() {
  printf 'Create install scripts from JSON.\n\n'
  printf '  -a <0|1>   whether to install all dependencies (required AND optional)\n'
  printf '  -f <file>  path to JSON manifest\n'
  printf '  -o <dir>   output folder (defaults to ./tmp)\n'
  printf '  -b <list>  base images for docker (default: "%s")\n' "$BASE"
  printf '  -v         increase verbosity\n'
  printf '  -h, --help show help text\n'
}

for _arg in "$@"; do
  if [ "$_arg" = "--help" ] || [ "$_arg" = "-h" ] || [ "$_arg" = "/?" ] || [ "$_arg" = "-?" ]; then
    show_help
    exit 0
  fi
done

while getopts 'a:b:f:o:vh' opt; do
  case "${opt}" in
    a) ALL_DEPS="${OPTARG}" ;;
    b) BASE="${OPTARG}" ;;
    f) FILENAME="${OPTARG}" ;;
    o) OUTPUT_FOLDER="${OPTARG}" ;;
    v) VERBOSE=$((VERBOSE + 1)) ;;
    h) HELP=1 ;;
    *) ;;
  esac
done
export ALL_DEPS OUTPUT_FOLDER BASE VERBOSE

shift "$((OPTIND - 1))"
if [ $# -gt 0 ]; then
  printf '[WARN] Extra arguments provided: %s\n' "$*" >&2
fi

if [ "$HELP" -ge 1 ]; then
  show_help
  exit 0
fi

if [ -z "$FILENAME" ]; then
  show_help >&2
  printf 'Error: JSON file must be specified with -f\n' >&2
  exit 2
fi

if [ ! -f "$FILENAME" ]; then
  show_help >&2
  printf 'Error: JSON file specified with -f must exist: %s\n' "$FILENAME" >&2
  exit 2
fi

# ## ensure_jq
# Ensures jq is available on PATH, bootstrapping _lib/utilities/jq if required.
ensure_jq() {
  if command -v jq >/dev/null 2>&1; then
    return 0
  fi
  if [ -f "${LIBSCRIPT_ROOT_DIR}/_lib/utilities/jq/env.sh" ]; then
    SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/_lib/utilities/jq/env.sh"
    export SCRIPT_NAME
    # shellcheck disable=SC1091
    . "${LIBSCRIPT_ROOT_DIR}/_lib/utilities/jq/env.sh" >/dev/null 2>&1 || true
    unset SCRIPT_NAME || true
  fi
  if ! command -v jq >/dev/null 2>&1; then
    STACK="" "${LIBSCRIPT_ROOT_DIR}/libscript.sh" install jq latest >/dev/null 2>&1
    if [ -f "${LIBSCRIPT_ROOT_DIR}/_lib/utilities/jq/env.sh" ]; then
      SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/_lib/utilities/jq/env.sh"
      export SCRIPT_NAME
      # shellcheck disable=SC1091
      . "${LIBSCRIPT_ROOT_DIR}/_lib/utilities/jq/env.sh" >/dev/null 2>&1 || true
      unset SCRIPT_NAME || true
    fi
  fi
}

ensure_jq
mkdir -p "$OUTPUT_FOLDER"

PLAN_OUT="${OUTPUT_FOLDER}/execution-plan.json"
"${LIBSCRIPT_ROOT_DIR}/_lib/orchestration/resolve_stack.sh" "$FILENAME" "$PLAN_OUT"

APP_NAME=$(jq -r '.name // .profile_name // "libscript-stack"' "$FILENAME")
INSTALL_SH="${OUTPUT_FOLDER}/install_${APP_NAME}.sh"
INSTALL_CMD="${OUTPUT_FOLDER}/install_${APP_NAME}.cmd"

cat << GEN_SH > "$INSTALL_SH"
#!/bin/sh
set -feu
SCRIPT_DIR=\$(cd -- "\$(dirname -- "\$0")" && pwd)
: "\${LIBSCRIPT_ROOT_DIR:=${LIBSCRIPT_ROOT_DIR}}"
if jq -e '.stages' "\${SCRIPT_DIR}/execution-plan.json" >/dev/null 2>&1; then
  exec "\${LIBSCRIPT_ROOT_DIR}/_lib/orchestration/execute_plan.sh" "\${SCRIPT_DIR}/execution-plan.json" "\$@"
fi
for _pkg in \$(jq -r '.selected[]?.name // empty' "\${SCRIPT_DIR}/execution-plan.json"); do
  "\${LIBSCRIPT_ROOT_DIR}/libscript.sh" install "\$_pkg" latest
done
GEN_SH
chmod +x "$INSTALL_SH"

cat << GEN_CMD > "$INSTALL_CMD"
@echo off
setlocal EnableDelayedExpansion
set "SCRIPT_DIR=%~dp0"
if "%LIBSCRIPT_ROOT_DIR%"=="" set "LIBSCRIPT_ROOT_DIR=${LIBSCRIPT_ROOT_DIR}"
jq -e ".stages" "%SCRIPT_DIR%execution-plan.json" >nul 2>&1
if not errorlevel 1 (
    call "%LIBSCRIPT_ROOT_DIR%\_lib\orchestration\execute_plan.cmd" "%SCRIPT_DIR%execution-plan.json" %*
    exit /b !ERRORLEVEL!
)
for /f "usebackq delims=" %%P in (\`jq -r ".selected[]?.name // empty" "%SCRIPT_DIR%execution-plan.json"\`) do (
    call "%LIBSCRIPT_ROOT_DIR%\libscript.cmd" install "%%P" latest || exit /b 1
)
exit /b 0
GEN_CMD

printf '[OK] Generated installer plan and scripts in %s\n' "$OUTPUT_FOLDER"
exit 0
