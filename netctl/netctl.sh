#!/bin/sh

set -feu
# shellcheck disable=SC2296,SC3028,SC3040,SC3054
if [ "${SCRIPT_NAME-}" ]; then
  this_file="${SCRIPT_NAME}"
elif [ "${BASH_SOURCE-}" ]; then
  this_file="${BASH_SOURCE[0]}"
  set -o pipefail
elif [ "${ZSH_VERSION-}" ]; then
  this_file="${(%):-%x}"
  set -o pipefail
else
  this_file="${0}"
fi

case "${STACK+x}" in
  *':'"${this_file}"':'*)
    printf '[STOP]     processing "%s"\n' "${this_file}"
    if (return 0 2>/dev/null); then return; else exit 0; fi ;;
  *) printf '[CONTINUE] processing "%s"\n' "${this_file}" ;;
esac
export STACK="${STACK:-}${this_file}"':'
for lib in 'lib/prelude.sh' ; do
  SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}"'/'"${lib}"
  export SCRIPT_NAME
  # shellcheck disable=SC1090
  . "${SCRIPT_NAME}"
done

. "$NETCTL_DIR/lib/state.sh"
. "$NETCTL_DIR/lib/nginx.sh"
. "$NETCTL_DIR/lib/caddy.sh"
. "$NETCTL_DIR/lib/apache.sh"
. "$NETCTL_DIR/lib/dockerfile.sh"
. "$NETCTL_DIR/lib/vagrantfile.sh"

usage() {
  cat <<EOF
netctl - Singular and Additive network config generator

Usage:
  netctl [COMMAND] [ARGS...]
  netctl [OPTIONS...]

Commands:
  init                           Initialize .netctl.json
  listen <port>                  Add a listening port
  static <path> <target>         Add a static file route
  proxy <path> <target>          Add a reverse proxy route
  rewrite <path> <pattern>       Add a rewrite rule
  emit <format>                  Emit the configuration for a given format
                                 Formats: nginx, caddy, apache, dockerfile, vagrantfile

Options (Singular mode):
  --listen <port>                Add a listening port
  --static <path> <target>       Add a static route
  --proxy <path> <target>        Add a proxy route
  --rewrite <path> <pattern>     Add a rewrite rule
  --emit <format>                Emit to specified format and exit
EOF
  exit 1
}

# If no arguments, show usage
[ $# -eq 0 ] && usage

SINGULAR_MODE=0
EMIT_FORMAT=""

# Check if we are using the sub-command (additive) mode or the flags (singular) mode
case "$1" in
  init) netctl_init; exit 0 ;;
  listen) netctl_add_listen "$2"; exit 0 ;;
  static) netctl_add_static "$2" "$3"; exit 0 ;;
  proxy) netctl_add_proxy "$2" "$3"; exit 0 ;;
  rewrite) netctl_add_rewrite "$2" "$3"; exit 0 ;;
  emit)
    case "$2" in
      nginx) netctl_emit_nginx ;;
      caddy) netctl_emit_caddy ;;
      apache) netctl_emit_apache ;;
      dockerfile) netctl_emit_dockerfile ;;
      vagrantfile) netctl_emit_vagrantfile ;;
      *) echo "Unknown format: $2" >&2; exit 1 ;;
    esac
    exit 0
    ;;
  -h|--help) usage ;;
  *) SINGULAR_MODE=1 ;;
esac

# Singular Mode (using flags)
if [ "$SINGULAR_MODE" -eq 1 ]; then
  # Create a temporary state file for singular runs to not pollute the working directory
  NETCTL_STATE_FILE=$(mktemp)
  export NETCTL_STATE_FILE
  
  # Ensure cleanup
  trap 'rm -f "$NETCTL_STATE_FILE" "$NETCTL_STATE_FILE.tmp"' EXIT
  
  netctl_init

  while [ $# -gt 0 ]; do
    case "$1" in
      --listen)
        netctl_add_listen "$2"
        shift 2
        ;;
      --static)
        netctl_add_static "$2" "$3"
        shift 3
        ;;
      --proxy)
        netctl_add_proxy "$2" "$3"
        shift 3
        ;;
      --rewrite)
        netctl_add_rewrite "$2" "$3"
        shift 3
        ;;
      --emit)
        EMIT_FORMAT="$2"
        shift 2
        ;;
      *)
        echo "Unknown option: $1" >&2
        usage
        ;;
    esac
  done

  if [ -n "$EMIT_FORMAT" ]; then
    case "$EMIT_FORMAT" in
      nginx) netctl_emit_nginx ;;
      caddy) netctl_emit_caddy ;;
      apache) netctl_emit_apache ;;
      dockerfile) netctl_emit_dockerfile ;;
      vagrantfile) netctl_emit_vagrantfile ;;
      *) echo "Unknown format: $EMIT_FORMAT" >&2; exit 1 ;;
    esac
  fi
fi
