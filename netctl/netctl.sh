#!/bin/sh
# shellcheck disable=SC2016,SC1090,SC1091,SC2034,SC2018,SC2019,SC2221,SC2222,SC2129,SC2209,SC2089,SC2090,SC2086,SC2154,SC2044,SC2181,SC2038,SC2155,SC2046,SC2002,SC1003,SC2295,SC2145


. "$(dirname "$0")/lib/prelude.sh"

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
