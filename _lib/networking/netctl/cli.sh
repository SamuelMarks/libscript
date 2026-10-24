#!/bin/sh
# ## Overview
# Network control utility for managing local services, reverse proxies, SPAs, WebSockets, and declarative ingress.
# 
# ## Usage
# Execute this script to manage networking configurations or apply a libscript.json ingress definition.

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
NETCTL_DIR="${SCRIPT_DIR}"
export LIBSCRIPT_ROOT_DIR NETCTL_DIR

for LIB in "_lib/networking/netctl/lib/prelude.sh" "_lib/networking/netctl/lib/state.sh" "_lib/networking/netctl/lib/nginx.sh" "_lib/networking/netctl/lib/caddy.sh" "_lib/networking/netctl/lib/apache.sh" "_lib/networking/netctl/lib/traefik.sh" "_lib/networking/netctl/lib/vagrantfile.sh" ${_LIBSCRIPT_DUMMY_NO_RUN:-}; do
  SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}"'/'"${LIB}"
  export SCRIPT_NAME
  if [ -f "${SCRIPT_NAME}" ]; then
    # shellcheck disable=SC1090
    . "${SCRIPT_NAME}"
  fi
done

# ## usage
# Displays command-line usage instructions and exit status 1.
usage() {
  cat <<EOF
netctl - Singular and Additive network config generator

Usage:
  netctl [COMMAND] [ARGS...]
  netctl [OPTIONS...]

Commands:
  init                           Initialize .netctl.json
  domain <server_name>           Set domain / server_name
  listen <port>                  Add a listening port
  static <path> <target>         Add a static file route
  spa <path> <target>            Add a Single-Page Application static route with index.html fallback
  proxy <path> <target>          Add a reverse proxy route
  ws <path> <target>             Add a WebSocket reverse proxy route
  rewrite <path> <pattern>       Add a rewrite rule
  apply <libscript.json>         Generate and optionally reload reverse proxy from .ingress block
  emit <format>                  Emit the configuration for a given format
                                 Formats: nginx, caddy, apache, dockerfile, vagrantfile

Options (Singular mode):
  --domain <server_name>         Set domain / server_name
  --listen <port>                Add a listening port
  --static <path> <target>       Add a static route
  --spa <path> <target>          Add a SPA static route
  --proxy <path> <target>        Add a proxy route
  --ws <path> <target>           Add a WebSocket proxy route
  --rewrite <path> <pattern>     Add a rewrite rule
  --emit <format>                Emit to specified format and exit
EOF
  exit 1
}

# ## emit_by_format
# Dispatches emission to the specified proxy format backend.
emit_by_format() {
  case "$1" in
    nginx) netctl_emit_nginx ;;
    caddy) netctl_emit_caddy ;;
    apache|apache2|httpd|iis) netctl_emit_apache ;;
    traefik) netctl_emit_traefik ;;
    dockerfile) netctl_emit_dockerfile ;;
    vagrantfile) netctl_emit_vagrantfile ;;
    *) printf '%s
' "Unknown format: $1" >&2; exit 1 ;;
  esac
}

# ## netctl_apply_manifest
# Parses .ingress from a libscript.json manifest, emits reverse proxy configuration, and optionally reloads the web server.
netctl_apply_manifest() {
  _json_file="${1:-libscript.json}"
  shift || true
  _format=""
  _out_file=""
  _do_reload=0

  while [ $# -gt 0 ]; do
    case "$1" in
      --format) _format="$2"; shift 2 ;;
      --out) _out_file="$2"; shift 2 ;;
      --reload) _do_reload=1; shift ;;
      *) shift ;;
    esac
  done

  if [ ! -f "$_json_file" ]; then
    printf 'Error: Manifest file not found: %s
' "$_json_file" >&2
    exit 1
  fi

  if ! jq -e '.ingress != null' "$_json_file" >/dev/null 2>&1; then
    exit 0
  fi

  _manifest_dir=$(cd -- "$(dirname -- "$_json_file")" && pwd)

  if [ -z "$_format" ]; then
    _format=$(jq -r '.ingress.provider // .ingress.engine // "nginx"' "$_json_file" 2>/dev/null || printf 'nginx')
  fi

  NETCTL_STATE_FILE=$(mktemp "${TMPDIR:-/tmp}/netctl_apply.XXXXXX")
  export NETCTL_STATE_FILE
  trap 'rm -f "$NETCTL_STATE_FILE" "$NETCTL_STATE_FILE.tmp"' EXIT

  jq -n --arg mdir "$_manifest_dir" --slurpfile doc "$_json_file" '
    ($doc[0].ingress // {}) as $ing |
    def resolve_path(p):
      if p == null or p == "" then ""
      elif (p | startswith("/")) then p
      elif (p | startswith("./")) then ($mdir + "/" + (p | ltrimstr("./")))
      else ($mdir + "/" + p) end;
    {
      domain: ($ing.domain // $ing.server_name // "_"),
      listen: (
        if ($ing.listen | type) == "array" then [ $ing.listen[] | tostring ]
        elif ($ing.listen != null) then [ ($ing.listen | tostring) ]
        else ["80"] end
      ),
      routes: (
        ($ing.routes // {}) |
        if type == "object" then
          with_entries(
            .key as $k | .value as $v |
            if ($v | type) == "string" then
              if ($v | startswith("http://") or startswith("https://")) then
                {key: $k, value: {type: "proxy", target: $v}}
              elif ($v | startswith("ws://") or startswith("wss://")) then
                {key: $k, value: {type: "ws", target: ($v | sub("^ws://"; "http://") | sub("^wss://"; "https://"))}}
              else
                {key: $k, value: {type: "static", target: resolve_path($v)}}
              end
            elif ($v | type) == "object" then
              if $v.ws then
                {key: $k, value: {type: "ws", target: ($v.ws | sub("^ws://"; "http://") | sub("^wss://"; "https://"))}}
              elif $v.proxy then
                {key: $k, value: {type: "proxy", target: $v.proxy}}
              elif $v.spa == true or $v.type == "spa" then
                {key: $k, value: {type: "spa", target: resolve_path($v.static // $v.target // $v.root // ".")}}
              elif $v.static then
                {key: $k, value: {type: "static", target: resolve_path($v.static)}}
              elif $v.type == "ws" then
                {key: $k, value: {type: "ws", target: ($v.target | sub("^ws://"; "http://") | sub("^wss://"; "https://"))}}
              elif $v.type == "proxy" then
                {key: $k, value: {type: "proxy", target: $v.target}}
              elif $v.type == "static" then
                {key: $k, value: {type: "static", target: resolve_path($v.target)}}
              elif $v.type == "rewrite" then
                {key: $k, value: {type: "rewrite", pattern: $v.pattern}}
              else
                {key: $k, value: {type: "static", target: resolve_path($v.target // ".")}}
              end
            else empty end
          )
        elif type == "array" then
          reduce .[] as $item ({};
            ($item.path // "/") as $k |
            if $item.type == "spa" or $item.spa == true then
              . + {($k): {type: "spa", target: resolve_path($item.target // $item.static // ".")}}
            elif $item.type == "ws" or $item.ws != null then
              . + {($k): {type: "ws", target: (($item.target // $item.ws) | sub("^ws://"; "http://") | sub("^wss://"; "https://"))}}
            elif $item.type == "proxy" or $item.proxy != null then
              . + {($k): {type: "proxy", target: ($item.target // $item.proxy)}}
            elif $item.type == "rewrite" then
              . + {($k): {type: "rewrite", pattern: $item.pattern}}
            else
              . + {($k): {type: "static", target: resolve_path($item.target // $item.static // ".")}}
            end
          )
        else {} end
      )
    }
  ' > "$NETCTL_STATE_FILE"

  if [ -n "$_out_file" ]; then
    mkdir -p "$(dirname -- "$_out_file")"
    emit_by_format "$_format" > "$_out_file"
  elif [ "$_do_reload" -eq 1 ]; then
    _conf_dir="${LIBSCRIPT_DATA_DIR:-/tmp/data}/ingress"
    mkdir -p "$_conf_dir"
    _out_file="${_conf_dir}/${_format}.conf"
    emit_by_format "$_format" > "$_out_file"
    if [ "$_format" = "nginx" ] && command -v nginx >/dev/null 2>&1; then
      if [ -d /etc/nginx/conf.d ] && [ -w /etc/nginx/conf.d ]; then
        _dom=$(jq -r '.domain // empty' "$NETCTL_STATE_FILE" 2>/dev/null || true)
        rm -f /etc/nginx/conf.d/libscript_ingress.conf
        if [ -n "$_dom" ] && [ "$_dom" != "_" ]; then
          cp "$_out_file" "/etc/nginx/conf.d/${_dom}.conf"
        else
          cp "$_out_file" /etc/nginx/conf.d/libscript_ingress.conf
        fi
        nginx -s reload >/dev/null 2>&1 || systemctl restart nginx >/dev/null 2>&1 || true
      fi
    elif [ "$_format" = "caddy" ] && command -v caddy >/dev/null 2>&1; then
      caddy reload --config "$_out_file" >/dev/null 2>&1 || true
    fi
  else
    emit_by_format "$_format"
  fi
}

[ $# -eq 0 ] && usage

SINGULAR_MODE=0
EMIT_FORMAT=""

case "$1" in
  download|install|ls|ls-remote|use|start|stop|restart|install-service|uninstall-service|env|logs|status|health)
    printf '%s
' "netctl is a native shell module. No installation or daemon management required."
    exit 0
    ;;
  uninstall)
    exec "$NETCTL_DIR/uninstall.sh"
    ;;
  test)
    exec "$NETCTL_DIR/test.sh"
    ;;
  init) netctl_init; exit 0 ;;
  domain) netctl_set_domain "$2"; exit 0 ;;
  listen) netctl_add_listen "$2"; exit 0 ;;
  static) netctl_add_static "$2" "$3"; exit 0 ;;
  spa) netctl_add_spa "$2" "$3"; exit 0 ;;
  proxy) netctl_add_proxy "$2" "$3"; exit 0 ;;
  ws) netctl_add_ws "$2" "$3"; exit 0 ;;
  rewrite) netctl_add_rewrite "$2" "$3"; exit 0 ;;
  apply)
    shift
    netctl_apply_manifest "$@"
    exit 0
    ;;
  emit)
    emit_by_format "$2"
    exit 0
    ;;
  -h|--help|-\?|/\?) usage ;;
  *) SINGULAR_MODE=1 ;;
esac

if [ "$SINGULAR_MODE" -eq 1 ]; then
  NETCTL_STATE_FILE=$(mktemp)
  export NETCTL_STATE_FILE

  trap 'rm -f "$NETCTL_STATE_FILE" "$NETCTL_STATE_FILE.tmp"' EXIT

  netctl_init

  while [ $# -gt 0 ]; do
    case "$1" in
      --domain)
        netctl_set_domain "$2"
        shift 2
        ;;
      --listen)
        netctl_add_listen "$2"
        shift 2
        ;;
      --static)
        netctl_add_static "$2" "$3"
        shift 3
        ;;
      --spa)
        netctl_add_spa "$2" "$3"
        shift 3
        ;;
      --proxy)
        netctl_add_proxy "$2" "$3"
        shift 3
        ;;
      --ws)
        netctl_add_ws "$2" "$3"
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
        printf '%s
' "Unknown option: $1" >&2
        usage
        ;;
    esac
  done

  if [ -n "$EMIT_FORMAT" ]; then
    emit_by_format "$EMIT_FORMAT"
  fi
fi
