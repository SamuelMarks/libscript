#!/bin/sh
# ## Overview
# Queries hooks/log_stream and renders FluentBit [INPUT] tail and [OUTPUT] sink configurations idempotently.
#
# ## Usage
# ./traits/logging/agent.sh [component...]

set -feu

if [ "${SCRIPT_NAME-}" ]; then
  THIS_FILE="${SCRIPT_NAME}"
elif [ "${BASH_SOURCE-}" ]; then
  THIS_FILE="${BASH_SOURCE}"
elif [ "${ZSH_VERSION-}" ]; then
  # libscript-allow-eval
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
export STACK="${STACK:-}${THIS_FILE}:"
SCRIPT_DIR=$(cd -- "$(dirname -- "${THIS_FILE}")" && pwd)
: "${LIBSCRIPT_ROOT_DIR:=$(d="$SCRIPT_DIR"; while [ ! -f "$d/libscript.sh" ]; do n="${d%/*}"; [ -z "$n" ] && n="/"; [ "$d" = "$n" ] && break; d="$n"; done; printf '%s\n' "$d")}"
export LIBSCRIPT_ROOT_DIR

SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/_lib/_common/hooks.sh"
export SCRIPT_NAME
# shellcheck disable=SC1090
. "${SCRIPT_NAME}"

# ## render_fluentbit_conf
# Emits fluent-bit.conf for the specified components into the target sysroot.
render_fluentbit_conf() {
  sysroot="${LIBSCRIPT_TARGET_SYSROOT:-/}"
  fb_dir="${sysroot%/}/etc/fluent-bit"
  mkdir -p "$fb_dir"
  fb_conf="${fb_dir}/fluent-bit.conf"
  {
    printf '# BEGIN libscript-managed: fluentbit\n'
    for comp in "$@"; do
      ls_json="$(libscript_exec_hook "$comp" "log_stream" 2>/dev/null || true)"
      if [ -n "$ls_json" ]; then
        lpath="$(printf '%s\n' "$ls_json" | jq -r '.log_files[0] // "/var/log/syslog"')"
        printf '[INPUT]
    Name tail
    Path %s
    Tag libscript.%s

' "$lpath" "$comp"
      fi
    done
    printf '[OUTPUT]
    Name stdout
    Match libscript.*
'
    printf '# END libscript-managed: fluentbit\n'
  } > "$fb_conf"
  printf '[INFO] FluentBit configuration rendered at %s.\n' "$fb_conf"
}

if [ "${1:-}" = "--help" ] || [ "${1:-}" = "-h" ]; then
  printf '%s\n' "Usage: $0 [component...]"
  exit 0
fi

if [ $# -eq 0 ]; then
  render_fluentbit_conf "postgres" "nginx"
else
  render_fluentbit_conf "$@"
fi
