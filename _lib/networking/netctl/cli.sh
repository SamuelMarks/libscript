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
NETCTL_DIR="${SCRIPT_DIR}"
export LIBSCRIPT_ROOT_DIR NETCTL_DIR

for LIB in "_lib/_common/log.sh" "_lib/networking/netctl/lib/prelude.sh" "_lib/networking/netctl/lib/state.sh" "_lib/networking/netctl/lib/nginx.sh" "_lib/networking/netctl/lib/caddy.sh" "_lib/networking/netctl/lib/apache.sh" "_lib/networking/netctl/lib/traefik.sh" "_lib/networking/netctl/lib/vagrantfile.sh" ${_LIBSCRIPT_DUMMY_NO_RUN:-}; do
  SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}"'/'"${LIB}"
  export SCRIPT_NAME
  if [ -f "${SCRIPT_NAME}" ]; then
    # shellcheck disable=SC1090
    . "${SCRIPT_NAME}"
  fi
done
unset SCRIPT_NAME || true

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

# ## netctl_reload_proxy
# Reloads the active web proxy server abstractly via _lib/_common/service.sh.
netctl_reload_proxy() {
  _nrp_fmt="${1:-nginx}"
  if [ -f "${LIBSCRIPT_ROOT_DIR}/_lib/_common/service.sh" ]; then
    SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/_lib/_common/service.sh"
    export SCRIPT_NAME
    # shellcheck disable=SC1090
    . "${SCRIPT_NAME}"
    unset SCRIPT_NAME || true
  fi
  log_info "[DAEMON] [RELOAD] Reloading ${_nrp_fmt} reverse proxy daemon..."
  case "$_nrp_fmt" in
    nginx)
      if command -v nginx >/dev/null 2>&1; then
        nginx -t >/dev/null 2>&1 || sudo nginx -t >/dev/null 2>&1 || true
        if nginx -s reload >/dev/null 2>&1 || sudo nginx -s reload >/dev/null 2>&1 || libscript_service reload nginx >/dev/null 2>&1; then
          log_info "[DAEMON] [ACTIVE] ${_nrp_fmt} reverse proxy reloaded successfully."
        else
          libscript_service restart nginx >/dev/null 2>&1 || true
          log_info "[DAEMON] [ACTIVE] ${_nrp_fmt} reverse proxy restarted."
        fi
      fi
      ;;
    caddy)
      if command -v caddy >/dev/null 2>&1; then
        libscript_service reload caddy >/dev/null 2>&1 || true
        log_info "[DAEMON] [ACTIVE] ${_nrp_fmt} reverse proxy reloaded successfully."
      fi
      ;;
    apache|apache2|httpd)
      libscript_service reload httpd >/dev/null 2>&1 || libscript_service reload apache2 >/dev/null 2>&1 || true
      log_info "[DAEMON] [ACTIVE] ${_nrp_fmt} reverse proxy reloaded successfully."
      ;;
  esac
}

# ## netctl_ensure_static_permissions
# Ensures parent home/application directories have o+x traverse permissions and static_dir has o+rX.
netctl_ensure_static_permissions() {
  _nes_state="$1"
  _nes_mdir="$2"
  [ -f "$_nes_state" ] || return 0
  if [ -n "${REMOTE_HOME:-}" ] && [ -d "${REMOTE_HOME}" ]; then
    chmod o+x "${REMOTE_HOME}" 2>/dev/null || sudo chmod o+x "${REMOTE_HOME}" 2>/dev/null || true
  fi
  if [ -d "$_nes_mdir" ]; then
    chmod o+x "$_nes_mdir" 2>/dev/null || sudo chmod o+x "$_nes_mdir" 2>/dev/null || true
    _parent_d=$(dirname -- "$_nes_mdir")
    [ -d "$_parent_d" ] && [ "$_parent_d" != "/" ] && { chmod o+x "$_parent_d" 2>/dev/null || sudo chmod o+x "$_parent_d" 2>/dev/null || true; }
  fi
  _static_targets=$(jq -r '.routes // {} | to_entries[]? | select(.value.type == "static" or .value.type == "spa") | .value.target // empty' "$_nes_state" 2>/dev/null || true)
  if [ -n "$_static_targets" ]; then
    printf '%s\n' "$_static_targets" | while IFS= read -r _st_dir; do
      [ -n "$_st_dir" ] || continue
      if [ -d "$_st_dir" ]; then
        chmod -R o+rX "$_st_dir" 2>/dev/null || sudo chmod -R o+rX "$_st_dir" 2>/dev/null || true
        _cur_p=$(dirname -- "$_st_dir")
        while [ -n "$_cur_p" ] && [ "$_cur_p" != "/" ] && [ "$_cur_p" != "." ]; do
          chmod o+x "$_cur_p" 2>/dev/null || sudo chmod o+x "$_cur_p" 2>/dev/null || true
          _cur_p=$(dirname -- "$_cur_p")
        done
      fi
    done
  fi
}

# ## netctl_remove_manifest_ingress
# Removes managed reverse-proxy virtual host configs for a libscript.json manifest and reloads the proxy.
netctl_remove_manifest_ingress() {
  _rmi_arg="${1:-libscript.json}"
  _rmi_dom=""
  _rmi_fmt='nginx'
  if [ -f "$_rmi_arg" ] && command -v jq >/dev/null 2>&1; then
    _rmi_dom=$(jq -r '.ingress.domain // .domain // empty' "$_rmi_arg" 2>/dev/null || true)
    _rmi_fmt=$(jq -r '.ingress.provider // .ingress.engine // "nginx"' "$_rmi_arg" 2>/dev/null || printf 'nginx')
  else
    _rmi_dom="$_rmi_arg"
  fi
  if [ -n "$_rmi_dom" ] && [ "$_rmi_dom" != "libscript.json" ]; then
    for _vhost in "/etc/nginx/conf.d/${_rmi_dom}.conf" "/etc/nginx/sites-enabled/${_rmi_dom}" "/etc/nginx/sites-available/${_rmi_dom}" "/etc/httpd/conf.d/${_rmi_dom}.conf" "/etc/apache2/sites-enabled/${_rmi_dom}.conf"; do
      if [ -f "$_vhost" ] || [ -L "$_vhost" ]; then
        log_info "[ROUTES] [REMOVE] Removing virtual host config ${_vhost}..."
        rm -f "$_vhost" 2>/dev/null || sudo rm -f "$_vhost" 2>/dev/null || true
      fi
    done
  fi
  netctl_reload_proxy "$_rmi_fmt"
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
    *) printf '%s\n' "Unknown format: $1" >&2; exit 1 ;;
  esac
}

# ## netctl_log_state_routes
# Logs the configured domain, listen ports, and each route in NETCTL_STATE_FILE to stderr.
netctl_log_state_routes() {
  _nls_fmt="$1"
  _nls_state="$2"
  [ -f "$_nls_state" ] || return 0
  _nls_dom=$(jq -r '.domain // "_"' "$_nls_state" 2>/dev/null || printf '_')
  _nls_ports=$(jq -r '(.listen // ["80"]) | join(", ")' "$_nls_state" 2>/dev/null || printf '80')
  log_info "[ROUTES] Configuring ${_nls_fmt} ingress for domain '${_nls_dom}' (listen: ${_nls_ports})..."
  _nls_routes=$(jq -r --arg dom "$_nls_dom" '.routes // {} | to_entries[]? | "[ROUTE] [\((.value.type // "static") | ascii_upcase)] \($dom)\(.key) -> \(.value.target // .value.pattern // "")"' "$_nls_state" 2>/dev/null || true)
  if [ -n "$_nls_routes" ]; then
    printf '%s\n' "$_nls_routes" | while IFS= read -r _rline; do
      [ -n "$_rline" ] || continue
      log_info "$_rline"
    done
  fi
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
    printf 'Error: Manifest file not found: %s\n' "$_json_file" >&2
    exit 1
  fi

  if ! jq -e '.ingress != null' "$_json_file" >/dev/null 2>&1; then
    exit 0
  fi

  _manifest_dir=$(cd -- "$(dirname -- "$_json_file")" && pwd)

  for _nc_ef in "${_manifest_dir}/.env" "${_manifest_dir}/.env.secrets" "${_manifest_dir}/.env.libscript"; do
    if [ -f "$_nc_ef" ]; then
      set -a
      set +u
      # shellcheck disable=SC1090,SC1091
      . "$_nc_ef" 2>/dev/null || true
      set -u
      set +a
    fi
  done

  if [ -f "${LIBSCRIPT_ROOT_DIR}/_lib/_common/env_printer.sh" ]; then
    SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/_lib/_common/env_printer.sh"
    # shellcheck disable=SC1090,SC1091
    . "${LIBSCRIPT_ROOT_DIR}/_lib/_common/env_printer.sh"
    unset SCRIPT_NAME || true
    libscript_hydrate_manifest_env "$_json_file" || true
  fi

  if [ -z "$_format" ]; then
    _format=$(jq -r '.ingress.provider // .ingress.engine // "nginx"' "$_json_file" 2>/dev/null || printf 'nginx')
  fi

  NETCTL_STATE_FILE=$(mktemp "${TMPDIR:-/tmp}/netctl_apply.XXXXXX")
  export NETCTL_STATE_FILE
  trap 'rm -f "$NETCTL_STATE_FILE" "$NETCTL_STATE_FILE.tmp"' EXIT

  jq -n --arg mdir "$_manifest_dir" --slurpfile doc "$_json_file" '
    ($doc[0].ingress // {}) as $ing |
    def expand_env(s):
      if (s | type) != "string" then s
      else
        reduce range(3) as $_ (s;
          gsub("\\$\\{(?<k>[A-Za-z_][A-Za-z0-9_]*):-(?<d>[^}]*)\\}"; (env[.k] // "") | if . == "" then .d else . end) |
          gsub("\\$\\{(?<k>[A-Za-z_][A-Za-z0-9_]*)\\}"; env[.k] // "")
        )
      end;
    def resolve_path(p):
      (expand_env(p)) as $ep |
      if $ep == null or $ep == "" then ""
      elif ($ep | startswith("/")) then $ep
      elif ($ep | startswith("./")) then ($mdir + "/" + ($ep | ltrimstr("./")))
      else ($mdir + "/" + $ep) end;
    {
      domain: expand_env($ing.domain // $ing.server_name // "_"),
      listen: (
        if ($ing.listen | type) == "array" then [ $ing.listen[] | tostring | expand_env(.) ]
        elif ($ing.listen != null) then [ ($ing.listen | tostring | expand_env(.)) ]
        else ["80"] end
      ),
      routes: (
        ($ing.routes // {}) |
        if type == "object" then
          with_entries(
            .key as $k | .value as $v |
            if ($v | type) == "string" then
              (expand_env($v)) as $ev |
              if ($ev | startswith("http://") or startswith("https://")) then
                {key: $k, value: {type: "proxy", target: $ev}}
              elif ($ev | startswith("ws://") or startswith("wss://")) then
                {key: $k, value: {type: "ws", target: ($ev | sub("^ws://"; "http://") | sub("^wss://"; "https://"))}}
              else
                {key: $k, value: {type: "static", target: resolve_path($ev)}}
              end
            elif ($v | type) == "object" then
              if $v.ws then
                {key: $k, value: {type: "ws", target: (expand_env($v.ws) | sub("^ws://"; "http://") | sub("^wss://"; "https://"))}}
              elif $v.proxy then
                {key: $k, value: {type: "proxy", target: expand_env($v.proxy)}}
              elif $v.spa == true or $v.type == "spa" then
                {key: $k, value: {type: "spa", target: resolve_path($v.static // $v.target // $v.root // ".")}}
              elif $v.static then
                {key: $k, value: {type: "static", target: resolve_path($v.static)}}
              elif $v.type == "ws" then
                {key: $k, value: {type: "ws", target: (expand_env($v.target) | sub("^ws://"; "http://") | sub("^wss://"; "https://"))}}
              elif $v.type == "proxy" then
                {key: $k, value: {type: "proxy", target: expand_env($v.target)}}
              elif $v.type == "static" then
                {key: $k, value: {type: "static", target: resolve_path($v.target)}}
              elif $v.type == "rewrite" then
                {key: $k, value: {type: "rewrite", pattern: expand_env($v.pattern)}}
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
              . + {($k): {type: "ws", target: (expand_env($item.target // $item.ws) | sub("^ws://"; "http://") | sub("^wss://"; "https://"))}}
            elif $item.type == "proxy" or $item.proxy != null then
              . + {($k): {type: "proxy", target: expand_env($item.target // $item.proxy)}}
            elif $item.type == "rewrite" then
              . + {($k): {type: "rewrite", pattern: expand_env($item.pattern)}}
            else
              . + {($k): {type: "static", target: resolve_path($item.target // $item.static // ".")}}
            end
          )
        else {} end
      )
    }
  ' > "$NETCTL_STATE_FILE"

  if [ -n "$_out_file" ]; then
    netctl_log_state_routes "$_format" "$NETCTL_STATE_FILE"
    mkdir -p "$(dirname -- "$_out_file")"
    emit_by_format "$_format" > "$_out_file"
    log_info "[ROUTES] [WRITE] Wrote ${_format} config -> ${_out_file}"
  elif [ "$_do_reload" -eq 1 ]; then
    netctl_log_state_routes "$_format" "$NETCTL_STATE_FILE"
    _conf_dir="${LIBSCRIPT_DATA_DIR:-/tmp/data}/ingress"
    mkdir -p "$_conf_dir"
    _dom=$(jq -r '.domain // empty' "$NETCTL_STATE_FILE" 2>/dev/null || true)
    if [ "$_format" = "nginx" ] && [ -n "$_dom" ] && [ "$_dom" != "_" ]; then
      if [ -f "/etc/letsencrypt/live/${_dom}/fullchain.pem" ]; then
        log_info "[ROUTES] [TLS] Confirmed SSL certificate for '${_dom}' at /etc/letsencrypt/live/${_dom}/fullchain.pem."
      elif [ -f "/etc/nginx/ssl/${_dom}.crt" ]; then
        log_info "[ROUTES] [TLS] Confirmed SSL certificate for '${_dom}' at /etc/nginx/ssl/${_dom}.crt."
      elif command -v openssl >/dev/null 2>&1; then
        mkdir -p /etc/nginx/ssl 2>/dev/null || sudo mkdir -p /etc/nginx/ssl 2>/dev/null || true
        openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout "/etc/nginx/ssl/${_dom}.key" -out "/etc/nginx/ssl/${_dom}.crt" -subj "/CN=${_dom}" >/dev/null 2>&1 || \
          sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout "/etc/nginx/ssl/${_dom}.key" -out "/etc/nginx/ssl/${_dom}.crt" -subj "/CN=${_dom}" >/dev/null 2>&1 || true
        log_info "[ROUTES] [TLS] Generated self-signed SSL certificate for '${_dom}' at /etc/nginx/ssl/${_dom}.crt."
      fi
    fi
    _out_file="${_conf_dir}/${_format}.conf"
    emit_by_format "$_format" > "$_out_file"
    netctl_ensure_static_permissions "$NETCTL_STATE_FILE" "$_manifest_dir"
    if [ "$_format" = "nginx" ] && command -v nginx >/dev/null 2>&1; then
      if [ -d /etc/nginx/conf.d ]; then
        if [ -n "$_dom" ] && [ "$_dom" != "_" ]; then
          _dest="/etc/nginx/conf.d/${_dom}.conf"
        else
          _dest='/etc/nginx/conf.d/libscript_ingress.conf'
        fi
        if [ -f "$_dest" ] && cmp -s "$_out_file" "$_dest" 2>/dev/null; then
          log_info "[ROUTES] [CONFIRM] ${_format} virtual host config ${_dest} is up-to-date."
        elif [ -w /etc/nginx/conf.d ]; then
          rm -f /etc/nginx/conf.d/libscript_ingress.conf /etc/nginx/sites-enabled/default 2>/dev/null || true
          cp "$_out_file" "$_dest"
          if [ -d /etc/nginx/sites-available ] && [ -n "$_dom" ] && [ "$_dom" != "_" ]; then
            cp "$_out_file" "/etc/nginx/sites-available/${_dom}.conf" 2>/dev/null || true
          fi
          log_info "[ROUTES] [WRITE] Installed ${_format} virtual host config -> ${_dest}"
        elif command -v sudo >/dev/null 2>&1 && sudo -n true >/dev/null 2>&1; then
          sudo rm -f /etc/nginx/conf.d/libscript_ingress.conf /etc/nginx/sites-enabled/default 2>/dev/null || true
          sudo cp "$_out_file" "$_dest"
          if [ -d /etc/nginx/sites-available ] && [ -n "$_dom" ] && [ "$_dom" != "_" ]; then
            sudo cp "$_out_file" "/etc/nginx/sites-available/${_dom}.conf" 2>/dev/null || true
          fi
          log_info "[ROUTES] [WRITE] Installed ${_format} virtual host config -> ${_dest}"
        fi
        netctl_reload_proxy "nginx"
      else
        log_info "[ROUTES] [WRITE] Generated ${_format} virtual host config -> ${_out_file}"
        netctl_reload_proxy "nginx"
      fi
    elif [ "$_format" = "caddy" ] && command -v caddy >/dev/null 2>&1; then
      log_info "[ROUTES] [WRITE] Installed Caddy config -> ${_out_file}"
      caddy reload --config "$_out_file" >/dev/null 2>&1 || netctl_reload_proxy "caddy"
    else
      log_info "[ROUTES] [WRITE] Generated ${_format} config -> ${_out_file}"
      netctl_reload_proxy "$_format"
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
    printf '%s\n' 'netctl is a native shell module. No installation or daemon management required.'
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
  ingress)
    shift
    netctl_apply_manifest "${1:-libscript.json}" --reload
    exit 0
    ;;
  remove-ingress|unroute)
    shift
    netctl_remove_manifest_ingress "${1:-libscript.json}"
    exit 0
    ;;
  reload)
    shift
    netctl_reload_proxy "${1:-nginx}"
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
        printf '%s\n' "Unknown option: $1" >&2
        usage
        ;;
    esac
  done

  if [ -n "$EMIT_FORMAT" ]; then
    emit_by_format "$EMIT_FORMAT"
  fi
fi
