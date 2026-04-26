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
SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
LIBSCRIPT_ROOT_DIR="${LIBSCRIPT_ROOT_DIR:-${SCRIPT_DIR}}"
export LIBSCRIPT_ROOT_DIR

# Source logging
for lib in '_lib/_common/log.sh' ; do
  SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}"'/'"${lib}"
  export SCRIPT_NAME
  # shellcheck disable=SC1090
  . "${SCRIPT_NAME}"
done

show_help() {
  echo "LibScript Global CLI"
  echo "===================="
  echo ""
  echo "Usage: $0 [COMMAND] [ARGS...]"
  echo ""
  echo "Commands:"
  echo "  list                        List all available components"
  echo "  search <query>              Search available components by name or description"
  echo "  process-downloads [file]    Process an aria2-formatted download list"
  echo "  env <component> <version>   Print environment variables for a component"
  echo "  install-deps [file]         Install all dependencies defined in a JSON file (default: libscript.json)"
  echo "  package_as <format> [args]  Package libscript usage (e.g., docker, docker_compose)"
  echo "  start [package_name...]     Start services (or all deps in json)"
  echo "  stop [package_name...]      Stop services"
  echo "  status [package_name...]    Show service status"
  echo "  health [package_name...]    Check service health"
  echo "  restart [package_name...]   Restart services"
  echo "  logs [-f] [package_name...]  Show service logs (real-time stream)"
  echo "  up [package_name...]        Alias for start"
  echo "  down [package_name...]      Alias for stop"
  echo "  provision <provider> ...    Provision a cloud environment"
  echo "  deprovision <provider> ...  Deprovision a cloud environment"
  echo "  <component> [OPTIONS...]    Invoke the CLI for a specific component"
  echo ""
  echo "Options:"
  echo "  --help, -h, /?              Show this extensive help text"
  echo "  --prefix=<dir>              Set local installation prefix"
  echo "  --log-format=<text|json>    Set log output format"
  echo "  --log-level=<0-4>           Set minimum log level (0=DEBUG, 1=INFO, etc)"
  echo "  --log-file=<path>           Set a file to mirror all logs to"
  echo "  --service-name=<name>       Set a custom service/daemon name"
  echo "  --secrets=<dir|url>         Save generated secrets to a directory or OpenBao/Vault URL"
  echo "  --listen=<str>                Global listen (port, addr:port, unix:socket)
  --listen-port=<port>        Global port to listen on"
  echo "  --listen-address=<addr>     Global address to listen on"
  echo "  --listen-socket=<socket>    Global unix socket to listen on"
  echo ""
  echo "Examples:"
  echo "  $0 list"
  echo "  $0 search ruby"
  echo "  $0 ruby --help"
  echo "  $0 postgres --help"
  echo ""
  echo "You can specify components by their short name (e.g., 'ruby' instead of '_lib/languages/ruby')."
  echo "If there are multiple matches, it will ask you to be more specific."
  echo ""
}

find_components() {
  find "$SCRIPT_DIR" -name "cli.sh" | while read -r cli_script; do
    dir=$(dirname "$cli_script")
    if [ -f "$dir/vars.schema.json" ]; then
      rel_dir="${dir#"$SCRIPT_DIR"/}"
      if [ "$rel_dir" != "$dir" ]; then
        echo "$rel_dir"
      fi
    fi
  done
}

get_desc() {
  schema="$SCRIPT_DIR/$1/vars.schema.json"
  if command -v jq >/dev/null 2>&1; then
    jq -r '
      def aliases: [ .properties[]? | select(.versionAliases) | .versionAliases[] ] | unique | join(", ");
      if .description then
        if (aliases | length > 0) then .description + " [version aliases: " + aliases + "]" else .description end
      else "" end
    ' "$schema" 2>/dev/null || true
  fi
}

while [ $# -gt 0 ]; do
  case "$1" in
    --cache-dir=*)
      export LIBSCRIPT_CACHE_DIR="${1#*=}"
      shift
      ;;
    --log-format=*)
      export LIBSCRIPT_LOG_FORMAT="${1#*=}"
      shift
      ;;
    --log-level=*)
      export LIBSCRIPT_LOG_LEVEL="${1#*=}"
      shift
      ;;
    --log-file=*)
      export LIBSCRIPT_LOG_FILE="${1#*=}"
      shift
      ;;
    --prefix=*)
      export PREFIX="${1#*=}"
      shift
      ;;
    --listen=*)
      listen_str="${1#*=}"
      if echo "$listen_str" | grep -q "^unix:"; then
        export LIBSCRIPT_LISTEN_SOCKET="${listen_str#unix:}"
      elif echo "$listen_str" | grep -q ":"; then
        export LIBSCRIPT_LISTEN_ADDRESS="${listen_str%%:*}"
        export LIBSCRIPT_LISTEN_PORT="${listen_str##*:}"
      else
        export LIBSCRIPT_LISTEN_PORT="$listen_str"
      fi
      shift
      ;;
    --listen-port=*)
      export LIBSCRIPT_LISTEN_PORT="${1#*=}"
      shift
      ;;
    --listen-address=*)
      export LIBSCRIPT_LISTEN_ADDRESS="${1#*=}"
      shift
      ;;
    --listen-socket=*)
      export LIBSCRIPT_LISTEN_SOCKET="${1#*=}"
      shift
      ;;
    --service-name=*)
      export LIBSCRIPT_SERVICE_NAME="${1#*=}"
      shift
      ;;
    --secrets=*)
      export LIBSCRIPT_SECRETS="${1#*=}"
      shift
      ;;
    *)
      break
      ;;
  esac
done
cmd="$1"
if [ -z "$cmd" ] || [ "$cmd" = "--help" ] || [ "$cmd" = "-h" ] || [ "$cmd" = "/?" ]; then
  show_help
  exit 0
fi

if [ "$cmd" = "--version" ] || [ "$cmd" = "-v" ]; then
  echo "${LIBSCRIPT_VERSION:-dev}"
  exit 0
fi

shift || true

if [ "$cmd" = "list" ]; then
  echo "Available components:"
  find_components | sort | while read -r comp; do
    desc=$(get_desc "$comp")
    if [ -n "$desc" ]; then
      printf "  %-40s - %s\n" "$comp" "$desc"
    else
      printf "  %s\n" "$comp"
    fi
  done
  exit 0
fi

if [ "$cmd" = "process-downloads" ]; then
  list_file="$1"
for lib in '_lib/_common/pkg_mgr.sh' ; do
  SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}"'/'"${lib}"
  export SCRIPT_NAME
  # shellcheck disable=SC1090
  . "${SCRIPT_NAME}"
done
  libscript_process_aria2_file "$list_file"
  exit 0
fi

if [ "$cmd" = "provision" ]; then
  shift
  exec "$SCRIPT_DIR/scripts/deploy_cloud.sh" "$@"
fi

if [ "$cmd" = "deprovision" ]; then
  shift
  exec "$SCRIPT_DIR/scripts/teardown_cloud.sh" "$@"
fi


if [ "$cmd" = "search" ]; then
  query="$1"
  if [ -z "$query" ]; then
    echo "Error: please provide a search query."
    exit 1
  fi
  echo "Searching for '$query'..."
  find_components | sort | while read -r comp; do
    desc=$(get_desc "$comp")
    if echo "$comp $desc" | grep -i "$query" >/dev/null 2>&1; then
      if [ -n "$desc" ]; then
        printf "  %-40s - %s\n" "$comp" "$desc"
      else
        printf "  %s\n" "$comp"
      fi
    fi
  done
  exit 0
fi

if [ "$cmd" = "start" ] || [ "$cmd" = "stop" ] || [ "$cmd" = "status" ] || [ "$cmd" = "health" ] || [ "$cmd" = "logs" ] || [ "$cmd" = "restart" ] || [ "$cmd" = "up" ] || [ "$cmd" = "down" ]; then
  action="$cmd"
  if [ "$action" = "up" ]; then action="start"; fi
  if [ "$action" = "down" ]; then action="stop"; fi
  follow_logs=0
  skip_hooks=0
  new_args=""
  for arg in "$@"; do
    if [ "$arg" = "-f" ] || [ "$arg" = "--follow" ]; then
      follow_logs=1
    elif [ "$arg" = "--no-hooks" ]; then
      skip_hooks=1
    else
      new_args="$new_args \"$arg\""
    fi
  done
  eval "set -- $new_args"
  
  if [ $# -eq 0 ] || [ "$1" = "libscript.json" ] || [ "${1##*.}" = "json" ]; then
    json_file="${1:-libscript.json}"
    if [ ! -f "$json_file" ]; then
      echo "Error: $json_file not found." >&2
      exit 1
    fi
    if ! command -v jq >/dev/null 2>&1; then
    if [ -f "${LIBSCRIPT_ROOT_DIR:-.}/_lib/utilities/jq/setup.sh" ]; then
      "${LIBSCRIPT_ROOT_DIR:-.}/_lib/utilities/jq/setup.sh"
    fi
  fi
  if ! command -v jq >/dev/null 2>&1; then
      echo "Error: jq is required to parse $json_file." >&2
      exit 1
    fi
    if [ "$skip_hooks" -eq 0 ]; then
      if [ "$action" = "start" ] || [ "$action" = "up" ]; then
        "${LIBSCRIPT_ROOT_DIR:-.}/scripts/run_hooks.sh" "$json_file" "build"
        "${LIBSCRIPT_ROOT_DIR:-.}/scripts/run_hooks.sh" "$json_file" "pre_start"
      fi
    fi

    if ! deps=$("${LIBSCRIPT_ROOT_DIR:-.}/scripts/resolve_stack.sh" "$json_file" 2>/dev/null | jq -r '.selected[] | "\(.name) \(.version // "latest")"' 2>/dev/null); then
      deps=""
    fi
    if [ -n "$deps" ]; then
      echo "$deps" > "$json_file.tmpdeps"
      while read -r pkg ver; do
        if [ -n "$pkg" ]; then
          if [ "$ver" = "null" ]; then ver="latest"; fi
          if [ "$action" = "logs" ] && [ "$follow_logs" = "1" ]; then
            "$0" "$pkg" "$action" "$pkg" "$ver" -f 2>&1 | awk -v prefix="$pkg" '{print "\033[36m" prefix " |\033[0m " $0; fflush()}' &
          elif [ "$action" = "status" ] || [ "$action" = "health" ] || [ "$action" = "logs" ]; then
            echo "=== $pkg ==="
            "$0" "$pkg" "$action" "$pkg" "$ver"
          else
            "$0" "$pkg" "$action" "$pkg" "$ver" &
          fi
        fi
      done < "$json_file.tmpdeps"
      rm -f "$json_file.tmpdeps"
    fi

    if [ "$action" = "start" ] || [ "$action" = "up" ]; then
      "${LIBSCRIPT_ROOT_DIR:-.}/scripts/daemonize.sh" "$action" "$json_file"
      "${LIBSCRIPT_ROOT_DIR:-.}/scripts/setup_ingress.sh" "$action" "$json_file"
    elif [ "$action" = "stop" ] || [ "$action" = "down" ]; then
      "${LIBSCRIPT_ROOT_DIR:-.}/scripts/setup_ingress.sh" "$action" "$json_file"
      "${LIBSCRIPT_ROOT_DIR:-.}/scripts/daemonize.sh" "$action" "$json_file"
    elif [ "$action" = "status" ]; then
      "${LIBSCRIPT_ROOT_DIR:-.}/scripts/daemonize.sh" "$action" "$json_file"
    fi

    wait
    exit 0
  else
    for pkg in "$@"; do
      if [ "$action" = "logs" ] && [ "$follow_logs" = "1" ]; then
        "$0" "$pkg" "$action" "$pkg" "latest" -f 2>&1 | awk -v prefix="$pkg" '{print "\033[36m" prefix " |\033[0m " $0; fflush()}' &
      elif [ "$action" = "status" ] || [ "$action" = "health" ] || [ "$action" = "logs" ]; then
        echo "=== $pkg ==="
        "$0" "$pkg" "$action" "$pkg" "latest"
      else
        "$0" "$pkg" "$action" "$pkg" "latest" &
      fi
    done
    wait
    exit 0
  fi
fi

if [ "$cmd" = "install-deps" ]; then
  json_file="${1:-libscript.json}"
  if [ ! -f "$json_file" ]; then
    echo "Error: $json_file not found." >&2
    exit 1
  fi
  if ! command -v jq >/dev/null 2>&1; then
    if [ -f "${LIBSCRIPT_ROOT_DIR:-.}/_lib/utilities/jq/setup.sh" ]; then
      "${LIBSCRIPT_ROOT_DIR:-.}/_lib/utilities/jq/setup.sh"
    fi
  fi
  if ! command -v jq >/dev/null 2>&1; then
    echo "Error: jq is required to parse $json_file." >&2
    exit 1
  fi
  
  if [ -z "${LIBSCRIPT_SECRETS:-}" ]; then
    json_secrets=$(jq -r 'if .secrets then .secrets else empty end' "$json_file" 2>/dev/null)
    if [ "$json_secrets" != "null" ] && [ -n "$json_secrets" ]; then
      export LIBSCRIPT_SECRETS="$json_secrets"
    else
      export LIBSCRIPT_SECRETS="${LIBSCRIPT_ROOT_DIR:-$SCRIPT_DIR}/secrets"
    fi
  fi

  if ! deps=$("${LIBSCRIPT_ROOT_DIR:-.}/scripts/resolve_stack.sh" "$json_file" 2>/dev/null | jq -r '.selected[] | "\(.name) \(.version // "latest") \(.override // "")"' 2>/dev/null); then
    deps=""
  fi
  if [ -z "$deps" ]; then
    echo "No dependencies found in $json_file."
    exit 0
  fi
  
  # Parallel Download Phase
  echo "Downloading dependencies in parallel..."
  echo "$deps" | while read -r pkg ver override; do
    if [ -n "$pkg" ]; then
      if [ "$ver" = "null" ]; then ver="latest"; fi
      if [ -z "$override" ] || [ "$override" = "null" ]; then
        "$0" download "$pkg" "$ver" &
      fi
    fi
  done
  wait
  
  # Serial Install Phase
  echo "Installing dependencies sequentially..."
  echo "$deps" | while read -r pkg ver override; do
    if [ -n "$pkg" ]; then
      if [ "$ver" = "null" ]; then ver="latest"; fi
      if [ -n "$override" ] && [ "$override" != "null" ]; then
        echo "Skipping installation of $pkg (override provided: $override)"
      else
        echo "Installing $pkg $ver..."
        "$0" install "$pkg" "$ver"
      fi
    fi
  done
  exit 0
fi

if [ "$cmd" = "db-search" ]; then
  query="$1"
  DB_FILE="${LIBSCRIPT_ROOT_DIR:-$SCRIPT_DIR}/libscript.sqlite"
  if [ ! -f "$DB_FILE" ]; then
    echo "Error: Database not found. Run update-db first." >&2
    exit 1
  fi
  sqlite3 -column -header "$DB_FILE" "
    SELECT c.name, v.version, f.url, f.checksum 
    FROM components c 
    LEFT JOIN versions v ON c.id = v.component_id 
    LEFT JOIN files f ON v.id = f.version_id 
    WHERE c.name LIKE '%$query%' OR v.version LIKE '%$query%'
  "
  exit 0
fi

if [ "$cmd" = "update-db" ]; then
  if [ -x "$SCRIPT_DIR/update_db.sh" ]; then
    exec "$SCRIPT_DIR/update_db.sh"
  elif [ -f "$SCRIPT_DIR/update_db.sh" ]; then
    exec sh "$SCRIPT_DIR/update_db.sh"
  else
    echo "Error: update_db.sh not found." >&2
    exit 1
  fi
fi

if [ "$cmd" = "semver" ]; then
  v1="$1"
  op="$2"
  v2="$3"
  if [ -z "$v1" ] || [ -z "$op" ] || [ -z "$v2" ]; then
    echo "Usage: $0 semver <v1> <operator> <v2>" >&2
    echo "Operators: = != > < >= <=" >&2
    exit 1
  fi
  res=$(awk -v v1="$v1" -v v2="$v2" '
    function cmp(a, b) {
      la=split(a, aa, /[^0-9]+/)
      lb=split(b, bb, /[^0-9]+/)
      len = la > lb ? la : lb
      for (i=1; i<=len; i++) {
        av = aa[i] + 0; bv = bb[i] + 0
        if (av < bv) return -1
        if (av > bv) return 1
      }
      return 0
    }
    BEGIN { print cmp(v1, v2) }
  ')
  case "$op" in
    "=")  [ "$res" -eq 0 ] && exit 0 || exit 1 ;;
    "!=") [ "$res" -ne 0 ] && exit 0 || exit 1 ;;
    ">")  [ "$res" -eq 1 ] && exit 0 || exit 1 ;;
    "<")  [ "$res" -eq -1 ] && exit 0 || exit 1 ;;
    ">=") [ "$res" -ge 0 ] && exit 0 || exit 1 ;;
    "<=") [ "$res" -le 0 ] && exit 0 || exit 1 ;;
    *) echo "Unknown operator: $op" >&2; exit 1 ;;
  esac
fi

if [ "$cmd" = "package_as" ]; then
  pkg_type="$1"
  shift
  if [ "$pkg_type" = "docker" ] || [ "$pkg_type" = "dockerfile" ]; then
    base_image="debian:bookworm-slim"
    layer_filter=""
    artifact_type=""
    while [ $# -gt 0 ]; do
      case "$1" in
        --layer|-l)
          layer_filter="$2"
          shift 2
          ;;
        --artifact|-a)
          artifact_type="$2"
          if [ "$artifact_type" = "deb" ]; then
            base_image="debian:bookworm-slim"
          elif [ "$artifact_type" = "rpm" ]; then
            base_image="almalinux:9"
          elif [ "$artifact_type" = "apk" ]; then
            base_image="alpine:latest"
          elif [ "$artifact_type" = "txz" ]; then
            base_image="freebsd"
          elif [ "$artifact_type" = "msi" ] || [ "$artifact_type" = "exe" ]; then
            base_image="mcr.microsoft.com/windows/servercore:ltsc2022"
          fi
          shift 2
          ;;
        --base|--base-image)
          base_image="$2"
          if [ "$base_image" = "debian" ]; then
    base_image="debian:bookworm-slim"
    layer_filter=""
          elif [ "$base_image" = "alpine" ]; then
            base_image="alpine:latest"
          fi
          shift 2
          ;;
        *)
          break
          ;;
      esac
    done

    echo "FROM $base_image"
    echo "ARG TARGETOS=linux"
    echo "ARG TARGETARCH=amd64"
    echo "ENV LC_ALL=C.UTF-8 LANG=C.UTF-8"
    echo "ENV LIBSCRIPT_ROOT_DIR=\"/opt/libscript\""
    echo "ENV LIBSCRIPT_BUILD_DIR=\"/opt/libscript_build\""
    echo "ENV LIBSCRIPT_DATA_DIR=\"/opt/libscript_data\""
    echo "ENV LIBSCRIPT_CACHE_DIR=\"/opt/libscript_cache\""
    
    tmp_env_add=$(mktemp)
    tmp_add=$(mktemp)
    tmp_run=$(mktemp)
    
    OUT_DIR="$(cd "$OUT_DIR" && pwd)"
    deps_list=""
    if [ $# -gt 0 ]; then
      while [ $# -gt 0 ]; do
        pkg="$1"
        ver="${2:-latest}"
        if echo "$3" | grep -q "^http"; then
          override="$3"
          shift 3
        elif [ "$2" != "" ]; then
          override=""
          shift 2
        else
          override=""
          shift
        fi
        deps_list="${deps_list}cli ${pkg} ${ver} ${override}\n"
      done
    elif [ -f "libscript.json" ] && command -v jq >/dev/null 2>&1; then
      if ! deps_list=$("${LIBSCRIPT_ROOT_DIR:-.}/scripts/resolve_stack.sh" "libscript.json" 2>/dev/null | jq -r '.selected[] | "\(.layer // "deps") \(.name) \(.version // "latest") \(.override // "")"' 2>/dev/null); then
        deps_list=""
      fi
      else
        deps_list=$(find_components | sort | awk '{printf "%s latest ", $1}')
    fi

    if [ -n "$deps_list" ]; then
      gen_script=$(printf '%b\n' "$deps_list" | awk -v l_filter="$layer_filter" -v artifact_type="$artifact_type" '

      BEGIN {
         if (l_filter != "") {
            split(l_filter, f_arr, ",")
            for (f in f_arr) {
               allowed_layers[f_arr[f]] = 1
               allowed_layers[f_arr[f] "s"] = 1
            }
         }
      }
      NF > 0 {
         layer = $1
         pkg = $2
         ver = $3
         url = $4
         
         if (l_filter != "" && !(layer in allowed_layers) && layer != "cli") next;
         
         if (seen[pkg]) next;
         seen[pkg] = 1;

         pkg_up = toupper(pkg)
         sub(/^.*\//, "", pkg_up); gsub(/-/, "_", pkg_up)

         if (url != "" && url != "null") {
             extracted_ver = ""
             if (match(url, /[0-9]+\.[0-9]+(\.[0-9]+)?/)) {
                 extracted_ver = substr(url, RSTART, RLENGTH)
             }

             if ((ver == "" || ver == "latest" || ver == "null") && extracted_ver != "") {
                 ver = extracted_ver
             }
             
             if (ver == "" || ver == "null") ver = "latest"

             if (ver != "latest") {
                 escaped_ver = ver
                 temp_url = ""
                 remaining = url
                 while (i = index(remaining, ver)) {
                     temp_url = temp_url substr(remaining, 1, i - 1) "${" pkg_up "_VERSION}"
                     remaining = substr(remaining, i + length(ver))
                 }
                 url = temp_url remaining
             }
             
             if (match(url, /(amd64|arm64|x86_64|aarch64|386|armv7l|x64)/)) {
                 arch_str = substr(url, RSTART, RLENGTH)
                 gsub(arch_str, "${TARGETARCH}", url)
             }
             if (match(url, /(linux|darwin|windows)/)) {
                 os_str = substr(url, RSTART, RLENGTH)
                 gsub(os_str, "${TARGETOS}", url)
             }

             n = split(url, parts, "/")
             filename = parts[n]
             sub(/\?.*$/, "", filename)

             print "echo '\''ENV " pkg_up "_VERSION=\"" ver "\"'\'' >> \"$tmp_env_add\""
             print "echo '\''ENV " pkg_up "_URL=\"" url "\"'\'' >> \"$tmp_env_add\""
             if (artifact_type == "deb") {
                 print "echo '\''RUN apt-get update && apt-get install -y /opt/libscript/*-" pkg "_*.deb'\'' >> \"$tmp_run\""
             } else if (artifact_type == "rpm") {
                 print "echo '\''RUN dnf install -y /opt/libscript/*-" pkg "-*.rpm'\'' >> \"$tmp_run\""
             } else if (artifact_type == "apk") {
                 print "echo '\''RUN apk add --allow-untrusted /opt/libscript/*-" pkg "-*.apk'\'' >> \"$tmp_run\""
             } else if (artifact_type == "txz") {
                 print "echo '\''RUN pkg install -y /opt/libscript/*-" pkg "*.txz /opt/libscript/*-" pkg "*.pkg || true'\'' >> \"$tmp_run\""
             } else if (artifact_type == "msi") {
                 print "echo '\''RUN for %I in (C:\\opt\\libscript\\*-" pkg "-*.msi) do msiexec /i \"%I\" /qn /norestart'\'' >> \"$tmp_run\""
             } else if (artifact_type == "exe") {
                 print "echo '\''RUN for %I in (C:\\opt\\libscript\\*-" pkg "-*.exe) do \"%I\" /SILENT /VERYSILENT'\'' >> \"$tmp_run\""
             } else {
                 print "echo '\''ADD ${" pkg_up "_URL} /opt/libscript_cache/" pkg "/" filename "'\'' >> \"$tmp_add\""
                 print "echo '\''RUN ./libscript.sh install " pkg " ${" pkg_up "_VERSION}'\'' >> \"$tmp_run\""
             }
             print "PREFIX=\"/opt/libscript/installed/" pkg "\" \"$0\" env \"" pkg "\" \"" ver "\" --format=docker | grep -vE \"^(ENV STACK=|ENV SCRIPT_NAME=)\" >> \"$tmp_run\" || true"
         } else {
             if (ver == "" || ver == "null") ver = "latest"
             print "echo '\''ENV " pkg_up "_VERSION=\"" ver "\"'\'' >> \"$tmp_env_add\""
             if (artifact_type == "deb") {
                 print "echo '\''RUN apt-get update && apt-get install -y /opt/libscript/*-" pkg "_*.deb'\'' >> \"$tmp_run\""
             } else if (artifact_type == "rpm") {
                 print "echo '\''RUN dnf install -y /opt/libscript/*-" pkg "-*.rpm'\'' >> \"$tmp_run\""
             } else if (artifact_type == "apk") {
                 print "echo '\''RUN apk add --allow-untrusted /opt/libscript/*-" pkg "-*.apk'\'' >> \"$tmp_run\""
             } else if (artifact_type == "txz") {
                 print "echo '\''RUN pkg install -y /opt/libscript/*-" pkg "*.txz /opt/libscript/*-" pkg "*.pkg || true'\'' >> \"$tmp_run\""
             } else if (artifact_type == "msi") {
                 print "echo '\''RUN for %I in (C:\\opt\\libscript\\*-" pkg "-*.msi) do msiexec /i \"%I\" /qn /norestart'\'' >> \"$tmp_run\""
             } else if (artifact_type == "exe") {
                 print "echo '\''RUN for %I in (C:\\opt\\libscript\\*-" pkg "-*.exe) do \"%I\" /SILENT /VERYSILENT'\'' >> \"$tmp_run\""
             } else {
                 print "echo '\''RUN ./libscript.sh install " pkg " ${" pkg_up "_VERSION}'\'' >> \"$tmp_run\""
             }
             print "PREFIX=\"/opt/libscript/installed/" pkg "\" \"$0\" env \"" pkg "\" \"" ver "\" --format=docker | grep -vE \"^(ENV STACK=|ENV SCRIPT_NAME=)\" >> \"$tmp_run\" || true"
         }
      }')
      eval "$gen_script"
    else
      echo "RUN ./install_gen.sh" >> "$tmp_run"
    fi
    
    cat "$tmp_env_add"
    cat "$tmp_add"
    echo "COPY . /opt/libscript"
    echo "WORKDIR /opt/libscript"
    cat "$tmp_run"
    
    rm -f "$tmp_env_add" "$tmp_add" "$tmp_run"
    exit 0
  elif [ "$pkg_type" = "docker_compose" ]; then
    base_image="debian:bookworm-slim"
    while [ $# -gt 0 ]; do
      case "$1" in
        --base|--base-image)
          base_image="$2"
          if [ "$base_image" = "debian" ]; then
            base_image="debian:bookworm-slim"
          elif [ "$base_image" = "alpine" ]; then
            base_image="alpine:latest"
          fi
          shift 2
          ;;
        *)
          break
          ;;
      esac
    done

    deps_list=""
    if [ $# -gt 0 ]; then
      while [ $# -gt 0 ]; do
        pkg="$1"
        ver="${2:-latest}"
        if echo "$3" | grep -q "^http"; then
          override="$3"
          shift 3
        elif [ "$2" != "" ]; then
          override=""
          shift 2
        else
          override=""
          shift
        fi
        deps_list="${deps_list}cli ${pkg} ${ver} ${override}\n"
      done
    elif [ -f "libscript.json" ] && command -v jq >/dev/null 2>&1; then
      if ! deps_list=$("${LIBSCRIPT_ROOT_DIR:-.}/scripts/resolve_stack.sh" "libscript.json" 2>/dev/null | jq -r '.selected[] | "\(.layer // "deps") \(.name) \(.version // "latest") \(.override // "")"' 2>/dev/null); then
        deps_list=""
      fi
      else
        deps_list=$(find_components | sort | awk '{printf "%s latest ", $1}')
    fi

    if [ -n "$deps_list" ]; then
      echo "version: '3.8'"
      echo "services:"

      sorted_deps=$(printf '%b\n' "$deps_list" | awk '
      function get_priority(pkg) {
          if (pkg ~ /^(fluentbit|docker|etcd|openvpn|kubernetes_k0s|kubernetes_thw)$/) return 10;
          if (pkg ~ /^(postgres|mysql|mariadb|mongodb|redis|valkey|sqlite|rabbitmq|celery)$/) return 20;
          if (pkg ~ /^(php|python|nodejs|ruby|java|go|rust|c|cpp|csharp|bun|deno|elixir|jq|kotlin|swift|wait4x|zig|sh|cc)$/) return 30;
          if (pkg ~ /^(nginx|caddy|httpd|firecrawl|jupyterhub)$/) return 40;
          return 50;
      }
      NF > 0 {
          if (seen[$2]) next;
          seen[$2] = 1;
          lines[++count] = $0;
          priorities[count] = get_priority($2);
      }
      END {
          for (i = 1; i <= count; i++) {
              for (j = i + 1; j <= count; j++) {
                  if (priorities[i] > priorities[j]) {
                      temp = lines[i]; lines[i] = lines[j]; lines[j] = temp;
                      temp_p = priorities[i]; priorities[i] = priorities[j]; priorities[j] = temp_p;
                  }
              }
          }
          for (i = 1; i <= count; i++) {
              print lines[i];
          }
      }')

      prev_pkg=""
      echo "$sorted_deps" | while read -r layer pkg ver override; do
        if [ -n "$pkg" ]; then
          if [ "$ver" = "null" ]; then ver="latest"; fi
          
          df="Dockerfile.$pkg"
          echo "FROM $base_image" > "$df"
          echo "ARG TARGETOS=linux" >> "$df"
          echo "ARG TARGETARCH=amd64" >> "$df"
          echo "ENV LC_ALL=C.UTF-8 LANG=C.UTF-8" >> "$df"
          echo "ENV LIBSCRIPT_ROOT_DIR=\"/opt/libscript\"" >> "$df"
          echo "ENV LIBSCRIPT_BUILD_DIR=\"/opt/libscript_build\"" >> "$df"
          echo "ENV LIBSCRIPT_DATA_DIR=\"/opt/libscript_data\"" >> "$df"
          echo "ENV LIBSCRIPT_CACHE_DIR=\"/opt/libscript_cache\"" >> "$df"
          
          pkg_up=$(echo "$pkg" | tr '[:lower:]' '[:upper:]' | tr '-' '_')
          echo "ENV ${pkg_up}_VERSION=\"$ver\"" >> "$df"
          if [ -n "$override" ] && [ "$override" != "null" ]; then
              echo "ENV ${pkg_up}_URL=\"$override\"" >> "$df"
              filename=$(basename "${override%%\?*}")
              echo "ADD \${${pkg_up}_URL} /opt/libscript_cache/$pkg/$filename" >> "$df"
          fi
          echo "COPY . /opt/libscript" >> "$df"
          echo "WORKDIR /opt/libscript" >> "$df"
          echo "RUN ./libscript.sh install $pkg \${${pkg_up}_VERSION}" >> "$df"

          healthcheck="[\"CMD-SHELL\", \"echo '$pkg is ok' || exit 1\"]"
          if [ "$pkg" = "postgres" ]; then healthcheck="[\"CMD\", \"pg_isready\", \"-U\", \"postgres\"]"; fi
          if [ "$pkg" = "mysql" ] || [ "$pkg" = "mariadb" ]; then healthcheck="[\"CMD\", \"mysqladmin\", \"ping\", \"-h\", \"localhost\"]"; fi
          if [ "$pkg" = "redis" ] || [ "$pkg" = "valkey" ]; then healthcheck="[\"CMD\", \"redis-cli\", \"ping\"]"; fi
          if [ "$pkg" = "mongodb" ]; then healthcheck="[\"CMD\", \"mongosh\", \"--eval\", \"db.adminCommand('ping')\"]"; fi
          if [ "$pkg" = "rabbitmq" ]; then healthcheck="[\"CMD\", \"rabbitmq-diagnostics\", \"ping\"]"; fi
          if [ "$pkg" = "nginx" ] || [ "$pkg" = "caddy" ] || [ "$pkg" = "httpd" ]; then healthcheck="[\"CMD-SHELL\", \"curl -f http://localhost/ || exit 1\"]"; fi
          if [ "$pkg" = "php" ]; then healthcheck="[\"CMD-SHELL\", \"php -v || exit 1\"]"; fi
          if [ "$pkg" = "python" ]; then healthcheck="[\"CMD-SHELL\", \"python3 --version || exit 1\"]"; fi
          if [ "$pkg" = "nodejs" ]; then healthcheck="[\"CMD-SHELL\", \"node -v || exit 1\"]"; fi
          if [ "$pkg" = "fluentbit" ]; then healthcheck="[\"CMD-SHELL\", \"wget -qO- http://127.0.0.1:2020/api/v1/health || exit 1\"]"; fi

          if [ -f "libscript.json" ] && command -v jq >/dev/null 2>&1; then
              if ! custom_hc=$(jq -r ".deps[\"$pkg\"].healthcheck // .servers[\"$pkg\"].healthcheck // .databases[\"$pkg\"].healthcheck // .third_party[\"$pkg\"].healthcheck // .storage[\"$pkg\"].healthcheck // .toolchains[\"$pkg\"].healthcheck // empty | if type == \"object\" then .test | tojson elif type == \"string\" then \"[\\\"CMD-SHELL\\\", \\\"\" + . + \"\\\"]\" else empty end" libscript.json 2>/dev/null); then
                custom_hc=""
              fi
              if [ -n "$custom_hc" ] && [ "$custom_hc" != "null" ]; then
                  healthcheck="$custom_hc"
              fi
          fi

          echo "  $pkg:"
          echo "    build:"
          echo "      context: ."
          echo "      dockerfile: $df"
          echo "    healthcheck:"
          echo "      test: $healthcheck"
          echo "      interval: 5s"
          echo "      retries: 5"
          echo "      start_period: 5s"
          
          if [ -n "$prev_pkg" ]; then
              echo "    depends_on:"
              echo "      $prev_pkg:"
              echo "        condition: service_healthy"
          fi
          
          echo "    environment:"
          if [ -n "$override" ] && [ "$override" != "null" ]; then
            echo "      - ${pkg_up}_URL=\"$override\""
          fi
          if env_out=$(PREFIX="/opt/libscript/installed/$pkg" "$0" env "$pkg" "$ver" --format=docker_compose 2>/dev/null); then
            echo "$env_out" | grep -vE '^(STACK=|SCRIPT_NAME=)' | sed 's/^/      - /g'
          fi
          
          prev_pkg="$pkg"
        fi
      done
    fi
    exit 0
  elif [ "$pkg_type" = "TUI" ]; then
    cat << 'EOF'
#!/bin/sh
if command -v whiptail >/dev/null; then DIALOG=whiptail; elif command -v dialog >/dev/null; then DIALOG=dialog; else echo "Error: dialog or whiptail required." >&2; exit 1; fi
EOF
    echo 'selected=$($DIALOG --title "LibScript Installer" --checklist "Select components to install:" 20 60 10 \'
    if [ $# -gt 0 ]; then
      while [ $# -gt 0 ]; do
        pkg="$1"
        ver="${2:-latest}"
        echo "  \"$pkg\" \"$ver\" ON \\"
        if [ "$2" != "" ]; then shift 2; else shift; fi
      done
    elif [ -f "libscript.json" ] && command -v jq >/dev/null 2>&1; then
      if ! deps=$("${LIBSCRIPT_ROOT_DIR:-.}/scripts/resolve_stack.sh" "libscript.json" 2>/dev/null | jq -r '.selected[] | "\(.name) \(.version // "latest")"' 2>/dev/null); then
        deps=""
      fi
      echo "$deps" | while read -r pkg ver; do
        if [ -n "$pkg" ]; then
          if [ "$ver" = "null" ]; then ver="latest"; fi
          echo "  \"$pkg\" \"$ver\" ON \\"
        fi
      done
      # list all available components
      find_components | sort | while read -r comp; do
        echo "  \"$comp\" \"latest\" OFF \\"
      done
    fi
    cat << 'EOF'
  3>&1 1>&2 2>&3)
if [ $? -eq 0 ] && [ -n "$selected" ]; then
  action=$($DIALOG --title "Action" --menu "What would you like to produce?" 15 60 8 \
    "install" "Install locally now" \
    "dockerfile" "Dockerfile" \
    "docker_compose" "Dockerfiles + docker-compose" \
    "msi" ".msi installer" \
    "innosetup" ".exe (InnoSetup)" \
    "nsis" ".exe (NSIS)" \
    "pkg" "macOS .pkg installer" \
    "dmg" "macOS .dmg installer" \
    "deb" ".deb package" \
    "rpm" ".rpm package" \
    3>&1 1>&2 2>&3)
  
  if [ -n "$action" ]; then
    offline_ans=$($DIALOG --title "Options" --yesno "Enable --offline mode?" 10 40; echo $?)
    os_ans=$($DIALOG --title "Target OS" --checklist "Select OS targets:" 15 50 5 \
      "windows" "Windows" ON \
      "dos" "DOS" OFF \
      "linux" "Linux" ON \
      "macos" "macOS" OFF \
      "bsd" "BSD" OFF \
      3>&1 1>&2 2>&3)
    
    extra_args=""
    if [ "$offline_ans" = "0" ]; then extra_args="$extra_args --offline"; fi
    for os in $(echo "$os_ans" | tr -d '"'); do
      extra_args="$extra_args --os-$os"
    done
    
    items=""
    for item in $(echo "$selected" | tr -d '"'); do
      items="$items $item latest"
    done
    
    if [ "$action" = "install" ]; then
      for item in $(echo "$selected" | tr -d '"'); do
        ./libscript.sh install "$item" latest
      done
    else
      if [ "$action" = "dockerfile" ]; then action="docker"; fi
      ./libscript.sh package_as "$action" $items $extra_args
    fi
  else
    echo "Cancelled."
  fi
else
  echo "Installation cancelled."
fi
EOF
    APP_NAME="libscript"
    APP_VERSION="1.0.0"
    APP_PUBLISHER="LibScript"
    APP_URL="https://example.com"
    OUT_DIR="."
    OFFLINE="0"

    while [ $# -gt 0 ]; do
      case "$1" in
        --app-name) APP_NAME="$2"; shift 2 ;;
        --app-version) APP_VERSION="$2"; shift 2 ;;
        --app-publisher) APP_PUBLISHER="$2"; shift 2 ;;
        --app-url) APP_URL="$2"; shift 2 ;;
        --out-dir) OUT_DIR="$2"; shift 2 ;;
        --offline) OFFLINE="1"; shift ;;
        -*) echo "Error: Unknown option $1" >&2; exit 1 ;;
        *) break ;;
      esac
    OUT_DIR="$(cd "$OUT_DIR" && pwd)"
    done

    deps_list=""
    if [ $# -gt 0 ]; then
      while [ $# -gt 0 ]; do
        deps_list="$deps_list $1 ${2:-latest}"
        if [ "$2" != "" ]; then shift 2; else shift; fi
      done
    elif [ -f "libscript.json" ] && command -v jq >/dev/null 2>&1; then
      deps_list=$("${LIBSCRIPT_ROOT_DIR:-.}/scripts/resolve_stack.sh" "libscript.json" 2>/dev/null | jq -r '.selected[] | "\(.name) \(.version // "latest")"' 2>/dev/null | tr '\n' ' ')
      else
        deps_list=$(find_components | sort | awk '{printf "%s latest ", $1}')
    fi

    if [ "$OFFLINE" = "1" ]; then
      set -- $deps_list
      while [ $# -gt 0 ]; do
        pkg=$1; ver=$2; shift 2
        "$SCRIPT_DIR/libscript.sh" download "$pkg" "$ver" || true
      done
    fi

    if [ "$pkg_type" = "deb" ]; then
      echo "#!/bin/sh"
      echo "set -e"
      echo "OUT_DIR=\"$OUT_DIR\""
      echo "mkdir -p \"\$OUT_DIR\""
      meta_depends=""
      set -- $deps_list
      while [ $# -gt 0 ]; do
        pkg=$1; ver=$2; shift 2
        pkg_name="${APP_NAME}-${pkg}"
        if [ -n "$meta_depends" ]; then meta_depends="${meta_depends}, "; fi
        meta_depends="${meta_depends}${pkg_name} (= ${APP_VERSION})"
        echo "echo \"Building $pkg_name ...\""
        echo "BUILD_DIR=\"/tmp/${pkg_name}_build\""
        echo "rm -rf \"\$BUILD_DIR\" && mkdir -p \"\$BUILD_DIR/DEBIAN\""
        echo "cat << 'EOF' > \"\$BUILD_DIR/DEBIAN/control\""
        echo "Package: $pkg_name"
        echo "Version: $APP_VERSION"
        echo "Architecture: all"
        echo "Maintainer: $APP_PUBLISHER"
        echo "Description: $APP_NAME deployment - $pkg"
        echo "EOF"
        echo "cat << 'EOF' > \"\$BUILD_DIR/DEBIAN/postinst\""
        echo "#!/bin/sh"
        echo "set -e"
        echo "if command -v libscript.sh >/dev/null; then libscript.sh install_service $pkg $ver; elif [ -f /opt/libscript/libscript.sh ]; then cd /opt/libscript && ./libscript.sh install_service $pkg $ver; fi"
        echo "EOF"
        echo "chmod 0755 \"\$BUILD_DIR/DEBIAN/postinst\""
        echo "cat << 'EOF' > \"\$BUILD_DIR/DEBIAN/prerm\""
        echo "#!/bin/sh"
        echo "set -e"
        echo "if command -v libscript.sh >/dev/null; then libscript.sh uninstall $pkg --purge-data; elif [ -f /opt/libscript/libscript.sh ]; then cd /opt/libscript && ./libscript.sh uninstall $pkg --purge-data; fi"
        echo "EOF"
        echo "chmod 0755 \"\$BUILD_DIR/DEBIAN/prerm\""
        echo "mkdir -p \"\$BUILD_DIR/opt/libscript\""; if [ "$OFFLINE" = "1" ]; then echo "cp -a \"$SCRIPT_DIR\"/.* \"$SCRIPT_DIR\"/* \"\$BUILD_DIR/opt/libscript/\" 2>/dev/null || true"; echo "rm -rf \"\$BUILD_DIR/opt/libscript/.git\""; fi
        echo "dpkg-deb --build \"\$BUILD_DIR\" \"\$OUT_DIR/${pkg_name}_${APP_VERSION}_all.deb\""
        echo "rm -rf \"\$BUILD_DIR\""
      done
      echo "echo \"Building ${APP_NAME}-meta ...\""
      echo "BUILD_DIR=\"/tmp/${APP_NAME}-meta_build\""
      echo "rm -rf \"\$BUILD_DIR\" && mkdir -p \"\$BUILD_DIR/DEBIAN\""
      echo "cat << 'EOF' > \"\$BUILD_DIR/DEBIAN/control\""
      echo "Package: ${APP_NAME}-meta"
      echo "Version: $APP_VERSION"
      echo "Architecture: all"
      echo "Maintainer: $APP_PUBLISHER"
      if [ -n "$meta_depends" ]; then echo "Depends: $meta_depends"; fi
      echo "Description: $APP_NAME deployment metapackage"
      echo "EOF"
      echo "mkdir -p \"\$BUILD_DIR/opt/libscript\""; if [ "$OFFLINE" = "1" ]; then echo "cp -a \"$SCRIPT_DIR\"/.* \"$SCRIPT_DIR\"/* \"\$BUILD_DIR/opt/libscript/\" 2>/dev/null || true"; echo "rm -rf \"\$BUILD_DIR/opt/libscript/.git\""; fi
      echo "dpkg-deb --build \"\$BUILD_DIR\" \"\$OUT_DIR/${APP_NAME}-meta_${APP_VERSION}_all.deb\""
      echo "rm -rf \"\$BUILD_DIR\""
      echo "echo \"Done!\""
      exit 0
    elif [ "$pkg_type" = "rpm" ]; then
      echo "#!/bin/sh"
      echo "set -e"
      echo "OUT_DIR=\"$OUT_DIR\""
      echo "mkdir -p \"\$OUT_DIR\""
      meta_depends=""
      set -- $deps_list
      while [ $# -gt 0 ]; do
        pkg=$1; ver=$2; shift 2
        pkg_name="${APP_NAME}-${pkg}"
        if [ -n "$meta_depends" ]; then meta_depends="${meta_depends}, "; fi
        meta_depends="${meta_depends}${pkg_name} = ${APP_VERSION}"
        echo "echo \"Building $pkg_name ...\""
        echo "BUILD_DIR=\"/tmp/${pkg_name}_rpmbuild\""
        echo "mkdir -p \"\$BUILD_DIR/BUILD\" \"\$BUILD_DIR/RPMS\" \"\$BUILD_DIR/SOURCES\" \"\$BUILD_DIR/SPECS\" \"\$BUILD_DIR/SRPMS\""
        echo "cat << 'EOF' > \"\$BUILD_DIR/SPECS/${pkg_name}.spec\""
        echo "Name: $pkg_name"
        echo "Version: $APP_VERSION"
        echo "Release: 1%{?dist}"
        echo "Summary: $APP_NAME deployment - $pkg"
        echo "License: MIT"
        echo "BuildArch: noarch"
        echo "%description"
        echo "$APP_NAME deployment - $pkg"
        echo "%install"
        echo "mkdir -p %{buildroot}/opt/libscript"; if [ "$OFFLINE" = "1" ]; then echo "cp -a \"$SCRIPT_DIR\"/.* \"$SCRIPT_DIR\"/* %{buildroot}/opt/libscript/ 2>/dev/null || true"; echo "rm -rf %{buildroot}/opt/libscript/.git"; fi
        echo "touch %{buildroot}/var/lib/libscript/.${pkg_name}_installed"
        echo "%post"
        echo "if command -v libscript.sh >/dev/null; then libscript.sh install_service $pkg $ver; elif [ -f /opt/libscript/libscript.sh ]; then cd /opt/libscript && ./libscript.sh install_service $pkg $ver; fi"
        echo "%preun"
        echo "if command -v libscript.sh >/dev/null; then libscript.sh uninstall $pkg --purge-data; elif [ -f /opt/libscript/libscript.sh ]; then cd /opt/libscript && ./libscript.sh uninstall $pkg --purge-data; fi"
        echo "%files"
        echo "/var/lib/libscript/.${pkg_name}_installed"
        echo "EOF"
        echo "rpmbuild --define \"_topdir \$BUILD_DIR\" -bb \"\$BUILD_DIR/SPECS/${pkg_name}.spec\""
        echo "find \"\$BUILD_DIR/RPMS\" -name \"*.rpm\" -exec cp {} \"\$OUT_DIR/\" \\;"
        echo "rm -rf \"\$BUILD_DIR\""
      done
      echo "echo \"Building ${APP_NAME}-meta ...\""
      echo "BUILD_DIR=\"/tmp/${APP_NAME}-meta_rpmbuild\""
      echo "mkdir -p \"\$BUILD_DIR/BUILD\" \"\$BUILD_DIR/RPMS\" \"\$BUILD_DIR/SOURCES\" \"\$BUILD_DIR/SPECS\" \"\$BUILD_DIR/SRPMS\""
      echo "cat << 'EOF' > \"\$BUILD_DIR/SPECS/${APP_NAME}-meta.spec\""
      echo "Name: ${APP_NAME}-meta"
      echo "Version: $APP_VERSION"
      echo "Release: 1%{?dist}"
      echo "Summary: $APP_NAME deployment metapackage"
      echo "License: MIT"
      echo "BuildArch: noarch"
      if [ -n "$meta_depends" ]; then echo "Requires: $meta_depends"; fi
      echo "%description"
      echo "$APP_NAME deployment metapackage"
      echo "%install"
      echo "mkdir -p %{buildroot}/opt/libscript"; if [ "$OFFLINE" = "1" ]; then echo "cp -a \"$SCRIPT_DIR\"/.* \"$SCRIPT_DIR\"/* %{buildroot}/opt/libscript/ 2>/dev/null || true"; echo "rm -rf %{buildroot}/opt/libscript/.git"; fi
      echo "touch %{buildroot}/var/lib/libscript/.${APP_NAME}-meta_installed"
      echo "%files"
      echo "/var/lib/libscript/.${APP_NAME}-meta_installed"
      echo "EOF"
      echo "rpmbuild --define \"_topdir \$BUILD_DIR\" -bb \"\$BUILD_DIR/SPECS/${APP_NAME}-meta.spec\""
      echo "find \"\$BUILD_DIR/RPMS\" -name \"*.rpm\" -exec cp {} \"\$OUT_DIR/\" \\;"
      echo "rm -rf \"\$BUILD_DIR\""
      echo "echo \"Done!\""
      exit 0
    elif [ "$pkg_type" = "apk" ]; then
      echo "#!/bin/sh"
      echo "set -e"
      echo "OUT_DIR=\"$OUT_DIR\""
      echo "mkdir -p \"\$OUT_DIR\""
      meta_depends=""
      set -- $deps_list
      while [ $# -gt 0 ]; do
        pkg=$1; ver=$2; shift 2
        pkg_name="${APP_NAME}-${pkg}"
        if [ -n "$meta_depends" ]; then meta_depends="${meta_depends} "; fi
        meta_depends="${meta_depends}${pkg_name}"
        echo "echo \"Building $pkg_name ...\""
        echo "BUILD_DIR=\"/tmp/${pkg_name}_apkbuild\""
        echo "mkdir -p \"\$BUILD_DIR\""
        echo "cat << 'EOF' > \"\$BUILD_DIR/APKBUILD\""
        echo "pkgname=\"$pkg_name\""
        echo "pkgver=\"$APP_VERSION\""
        echo "pkgrel=1"
        echo "pkgdesc=\"$APP_NAME deployment - $pkg\""
        echo "url=\"$APP_URL\""
        echo "arch=\"noarch\""
        echo "license=\"MIT\""
        echo "depends=\"\""
        echo "install=\"\$pkgname.post-install \$pkgname.pre-deinstall\""
        echo "build() { return 0; }"
        echo "package() {"
        echo "  mkdir -p \"\$pkgdir/var/lib/libscript\""
        echo "  touch \"\$pkgdir/var/lib/libscript/.${pkg_name}_installed\""
        echo "}"
        echo "EOF"
        echo "cat << 'EOF' > \"\$BUILD_DIR/${pkg_name}.post-install\""
        echo "#!/bin/sh"
        echo "if command -v libscript.sh >/dev/null; then libscript.sh install_service $pkg $ver; elif [ -f /opt/libscript/libscript.sh ]; then cd /opt/libscript && ./libscript.sh install_service $pkg $ver; fi"
        echo "EOF"
        echo "chmod +x \"\$BUILD_DIR/${pkg_name}.post-install\""
        echo "cat << 'EOF' > \"\$BUILD_DIR/${pkg_name}.pre-deinstall\""
        echo "#!/bin/sh"
        echo "if command -v libscript.sh >/dev/null; then libscript.sh uninstall $pkg --purge-data; elif [ -f /opt/libscript/libscript.sh ]; then cd /opt/libscript && ./libscript.sh uninstall $pkg --purge-data; fi"
        echo "EOF"
        echo "chmod +x \"\$BUILD_DIR/${pkg_name}.pre-deinstall\""
        echo "if [ \"\$(id -u)\" = \"0\" ]; then ABUILD_OPTS=\"-F\"; else ABUILD_OPTS=\"\"; fi"
        echo "cd \"\$BUILD_DIR\" && abuild \$ABUILD_OPTS -P \"\$BUILD_DIR/out\" rootpkg"
        echo "find \"\$BUILD_DIR/out\" -name \"*.apk\" -exec cp {} \"\$OUT_DIR/\" \\;"
        echo "rm -rf \"\$BUILD_DIR\""
      done
      echo "echo \"Building ${APP_NAME}-meta ...\""
      echo "BUILD_DIR=\"/tmp/${APP_NAME}-meta_apkbuild\""
      echo "mkdir -p \"\$BUILD_DIR\""
      echo "cat << 'EOF' > \"\$BUILD_DIR/APKBUILD\""
      echo "pkgname=\"${APP_NAME}-meta\""
      echo "pkgver=\"$APP_VERSION\""
      echo "pkgrel=1"
      echo "pkgdesc=\"$APP_NAME deployment metapackage\""
      echo "url=\"$APP_URL\""
      echo "arch=\"noarch\""
      echo "license=\"MIT\""
      echo "depends=\"$meta_depends\""
      echo "build() { return 0; }"
      echo "package() {"
      echo "  mkdir -p \"\$pkgdir/var/lib/libscript\""
      echo "  touch \"\$pkgdir/var/lib/libscript/.${APP_NAME}-meta_installed\""
      echo "}"
      echo "EOF"
      echo "if [ \"\$(id -u)\" = \"0\" ]; then ABUILD_OPTS=\"-F\"; else ABUILD_OPTS=\"\"; fi"
      echo "cd \"\$BUILD_DIR\" && abuild \$ABUILD_OPTS -P \"\$BUILD_DIR/out\" rootpkg"
      echo "find \"\$BUILD_DIR/out\" -name \"*.apk\" -exec cp {} \"\$OUT_DIR/\" \\;"
      echo "rm -rf \"\$BUILD_DIR\""
      echo "echo \"Done!\""
      exit 0
    elif [ "$pkg_type" = "txz" ]; then
      echo "#!/bin/sh"
      echo "set -e"
      echo "OUT_DIR=\"$OUT_DIR\""
      echo "mkdir -p \"\$OUT_DIR\""
      meta_depends=""
      set -- $deps_list
      while [ $# -gt 0 ]; do
        pkg=$1; ver=$2; shift 2
        pkg_name="${APP_NAME}-${pkg}"
        if [ -n "$meta_depends" ]; then meta_depends="${meta_depends}, "; fi
        meta_depends="${meta_depends}\"${pkg_name}\": {\"version\": \"$APP_VERSION\", \"origin\": \"misc/${pkg_name}\"}"
        echo "echo \"Building $pkg_name ...\""
        echo "BUILD_DIR=\"/tmp/${pkg_name}_pkgbuild\""
        echo "mkdir -p \"\$BUILD_DIR/root/opt/libscript\""
        echo "mkdir -p \"\$BUILD_DIR/root/var/lib/libscript\""
        if [ "$OFFLINE" = "1" ]; then echo "cp -a \"$SCRIPT_DIR\"/.* \"$SCRIPT_DIR\"/* \"\$BUILD_DIR/root/opt/libscript/\" 2>/dev/null || true"; echo "rm -rf \"\$BUILD_DIR/root/opt/libscript/.git\""; fi
        echo "touch \"\$BUILD_DIR/root/var/lib/libscript/.${pkg_name}_installed\""
        echo "mkdir -p \"\$BUILD_DIR/meta\""
        echo "cat << 'EOF' > \"\$BUILD_DIR/meta/+MANIFEST\""
        echo "name: \"$pkg_name\""
        echo "version: \"$APP_VERSION\""
        echo "origin: \"misc/$pkg_name\""
        echo "comment: \"$APP_NAME deployment - $pkg\""
        echo "desc: \"$APP_NAME deployment - $pkg\""
        echo "maintainer: \"$APP_PUBLISHER\""
        echo "www: \"$APP_URL\""
        echo "prefix: \"/\""
        echo "scripts: {"
        echo "  post-install: \"if command -v libscript.sh >/dev/null; then libscript.sh install_service $pkg $ver; elif [ -f /opt/libscript/libscript.sh ]; then cd /opt/libscript && ./libscript.sh install_service $pkg $ver; fi\","
        echo "  pre-deinstall: \"if command -v libscript.sh >/dev/null; then libscript.sh uninstall $pkg --purge-data; elif [ -f /opt/libscript/libscript.sh ]; then cd /opt/libscript && ./libscript.sh uninstall $pkg --purge-data; fi\""
        echo "}"
        echo "EOF"
        echo "cd \"\$BUILD_DIR/root\" && find . -type f -o -type l | sed -e 's|^./||' > \"\$BUILD_DIR/meta/pkg-plist\""
        echo "pkg create -m \"\$BUILD_DIR/meta\" -r \"\$BUILD_DIR/root\" -o \"\$OUT_DIR\""
        echo "rm -rf \"\$BUILD_DIR\""
      done
      echo "echo \"Building ${APP_NAME}-meta ...\""
      echo "BUILD_DIR=\"/tmp/${APP_NAME}-meta_pkgbuild\""
      echo "mkdir -p \"\$BUILD_DIR/root/var/lib/libscript\""
      echo "touch \"\$BUILD_DIR/root/var/lib/libscript/.${APP_NAME}-meta_installed\""
      echo "mkdir -p \"\$BUILD_DIR/meta\""
      echo "cat << 'EOF' > \"\$BUILD_DIR/meta/+MANIFEST\""
      echo "name: \"${APP_NAME}-meta\""
      echo "version: \"$APP_VERSION\""
      echo "origin: \"misc/${APP_NAME}-meta\""
      echo "comment: \"$APP_NAME deployment metapackage\""
      echo "desc: \"$APP_NAME deployment metapackage\""
      echo "maintainer: \"$APP_PUBLISHER\""
      echo "www: \"$APP_URL\""
      echo "prefix: \"/\""
      if [ -n "$meta_depends" ]; then
        echo "deps: {"
        echo "  $meta_depends"
        echo "}"
      fi
      echo "EOF"
      echo "cd \"\$BUILD_DIR/root\" && find . -type f -o -type l | sed -e 's|^./||' > \"\$BUILD_DIR/meta/pkg-plist\""
      echo "pkg create -m \"\$BUILD_DIR/meta\" -r \"\$BUILD_DIR/root\" -o \"\$OUT_DIR\""
      echo "rm -rf \"\$BUILD_DIR\""
      echo "echo \"Done!\""
      exit 0
    fi
  elif [ "$pkg_type" = "msi" ] || [ "$pkg_type" = "innosetup" ] || [ "$pkg_type" = "nsis" ] || [ "$pkg_type" = "pkg" ] || [ "$pkg_type" = "dmg" ]; then
    install_scope="perMachine"
    inno_priv="admin"
    nsis_admin="admin"
    APP_NAME="LibScript Deployment"
    APP_VERSION="1.0.0.0"
    APP_PUBLISHER="LibScript"
    APP_URL=""
    UPGRADE_CODE="PUT-GUID-HERE"
    OUT_FILE="LibScriptInstaller"
    ICON_PATH=""
    IMAGE_PATH=""
    LICENSE_PATH=""
    WELCOME_TEXT="Welcome to the LibScript Deployment Installer"
    OFFLINE="0"

    while [ $# -gt 0 ]; do
      case "$1" in
        --user-mode) install_scope="perUser"; inno_priv="lowest"; nsis_admin="user"; shift ;;
        --elevated-mode) install_scope="perMachine"; inno_priv="admin"; nsis_admin="admin"; shift ;;
        --app-name) APP_NAME="$2"; shift 2 ;;
        --app-version) APP_VERSION="$2"; shift 2 ;;
        --app-publisher) APP_PUBLISHER="$2"; shift 2 ;;
        --app-url) APP_URL="$2"; shift 2 ;;
        --upgrade-code) UPGRADE_CODE="$2"; shift 2 ;;
        --out-file) OUT_FILE="$2"; shift 2 ;;
        --icon) ICON_PATH="$2"; shift 2 ;;
        --image) IMAGE_PATH="$2"; shift 2 ;;
        --license) LICENSE_PATH="$2"; shift 2 ;;
        --welcome) WELCOME_TEXT="$2"; shift 2 ;;
        --offline) OFFLINE="1"; shift ;;
        -*) echo "Error: Unknown option $1" >&2; exit 1 ;;
        *) break ;;
      esac
    done



    PRODUCT_CODE="*"
    _SVC_NAME=$(echo "$APP_NAME" | tr " " "_")
    _UPGRADE_ID="${APP_NAME}|${_SVC_NAME}|x64"
    _PRODUCT_ID="${APP_NAME}|${_SVC_NAME}|x64|${APP_VERSION}"

    if command -v jq >/dev/null 2>&1 && command -v sha256sum >/dev/null 2>&1; then
      if [ "$UPGRADE_CODE" = "PUT-GUID-HERE" ]; then
        _UPGRADE_HASH=$(printf "%s" "$_UPGRADE_ID" | sha256sum | awk '{print $1}')
        UPGRADE_CODE=$(jq -n -r '
          def hex_to_guid: .[0:8] + "-" + .[8:12] + "-" + .[12:16] + "-" + .[16:20] + "-" + .[20:32];
          def as_uuidv5_bits: .[0:12] + "5" + .[13:] | .[0:16] + "a" + .[17:];
          def guid_from_string: .[0:32] | as_uuidv5_bits | hex_to_guid;
          $ARGS.positional[0] | guid_from_string
        ' --args "$_UPGRADE_HASH")
      fi
      if [ "$pkg_type" = "msi" ]; then
        _PRODUCT_HASH=$(printf "%s" "$_PRODUCT_ID" | sha256sum | awk '{print $1}')
        PRODUCT_CODE=$(jq -n -r '
          def hex_to_guid: .[0:8] + "-" + .[8:12] + "-" + .[12:16] + "-" + .[16:20] + "-" + .[20:32];
          def as_uuidv5_bits: .[0:12] + "5" + .[13:] | .[0:16] + "a" + .[17:];
          def guid_from_string: .[0:32] | as_uuidv5_bits | hex_to_guid;
          $ARGS.positional[0] | guid_from_string
        ' --args "$_PRODUCT_HASH")
      fi
    elif command -v powershell >/dev/null 2>&1 || command -v pwsh >/dev/null 2>&1; then
      _PS="powershell"
      command -v pwsh >/dev/null 2>&1 && _PS="pwsh"
      _PS_SCRIPT="
        param([string]\$id)
        \$b = [System.Text.Encoding]::UTF8.GetBytes(\$id)
        \$h = [System.Security.Cryptography.SHA256]::Create().ComputeHash(\$b)
        \$x = [System.BitConverter]::ToString(\$h).Replace('-', '').ToLower()
        Write-Output (\$x.Substring(0,8) + '-' + \$x.Substring(8,4) + '-5' + \$x.Substring(13,3) + '-a' + \$x.Substring(17,3) + '-' + \$x.Substring(20,12))
      "
      if [ "$UPGRADE_CODE" = "PUT-GUID-HERE" ]; then
        UPGRADE_CODE=$($_PS -NoProfile -Command "$_PS_SCRIPT" -id "$_UPGRADE_ID")
      fi
      if [ "$pkg_type" = "msi" ]; then
        PRODUCT_CODE=$($_PS -NoProfile -Command "$_PS_SCRIPT" -id "$_PRODUCT_ID")
      fi
    fi

    if [ "$pkg_type" = "msi" ]; then
      wxs_file="${OUT_FILE}.wxs"
      exec 3>&1
      exec 1> "$wxs_file"

      cat << EOF2
<?xml version="1.0" encoding="UTF-8"?>
<Wix xmlns="http://schemas.microsoft.com/wix/2006/wi">
  <Product Id="$PRODUCT_CODE" Name="$APP_NAME" Language="1033" Version="$APP_VERSION" Manufacturer="$APP_PUBLISHER" UpgradeCode="$UPGRADE_CODE">
    <Package InstallerVersion="200" Compressed="yes" InstallScope="$install_scope" Description="$WELCOME_TEXT" />
    <Media Id="1" Cabinet="media1.cab" EmbedCab="yes" />
EOF2
      if [ -n "$ICON_PATH" ]; then
        echo "    <Icon Id=\"AppIcon.ico\" SourceFile=\"$ICON_PATH\"/>"
        echo "    <Property Id=\"ARPPRODUCTICON\" Value=\"AppIcon.ico\" />"
      fi
      if [ -n "$APP_URL" ]; then
        echo "    <Property Id=\"ARPURLINFOABOUT\" Value=\"$APP_URL\" />"
      fi
      
      deps_list=""
      if [ $# -gt 0 ]; then
        while [ $# -gt 0 ]; do
          deps_list="$deps_list $1 ${2:-latest}"
          if [ "$2" != "" ]; then shift 2; else shift; fi
        done
      elif [ -f "libscript.json" ] && command -v jq >/dev/null 2>&1; then
        deps_list=$("${LIBSCRIPT_ROOT_DIR:-.}/scripts/resolve_stack.sh" "libscript.json" 2>/dev/null | jq -r '.selected[] | "\(.name) \(.version // "latest")"' 2>/dev/null | tr '\n' ' ')
      else
        deps_list=$(find_components | sort | awk '{printf "%s latest ", $1}')
      fi

      echo "    <Directory Id=\"TARGETDIR\" Name=\"SourceDir\">"
      echo "      <Directory Id=\"ProgramFilesFolder\">"
      echo "        <Directory Id=\"INSTALLFOLDER\" Name=\"$APP_NAME\" />"
      echo "      </Directory>"
      echo "    </Directory>"
      
      set -- $deps_list
      while [ $# -gt 0 ]; do
        pkg=$1; ver=$2; shift 2
        echo "Function CheckPorts_$pkg()" > "validate_${pkg}.vbs"
        echo "  Session.Property(\"VALID_$pkg\") = \"1\"" >> "validate_${pkg}.vbs"
        echo "  Dim shell, exec, port" >> "validate_${pkg}.vbs"
        echo "  Set shell = CreateObject(\"WScript.Shell\")" >> "validate_${pkg}.vbs"
        
        schema_file=$(find "$SCRIPT_DIR/_lib" -name "vars.schema.json" | grep "/$pkg/" | head -n 1)
        if [ -f "$schema_file" ]; then
          vars_json=$(jq -r '.properties | to_entries[] | select(.key | startswith("LIBSCRIPT_GLOBAL_") | not) | .key' "$schema_file")
          if [ -n "$vars_json" ]; then
            for varname in $vars_json; do
              if case "$varname" in *"_PORT"* | *"_PORT_SECURE"*) true;; *) false;; esac; then
                echo "  port = Session.Property(\"PROP_${pkg}_${varname}\")" >> "validate_${pkg}.vbs"
                echo "  If port <> \"\" Then" >> "validate_${pkg}.vbs"
                echo "    Set exec = shell.Exec(\"cmd.exe /c netstat -an | findstr /R /C:"":\" & port & \" .*LISTENING\"\"\")" >> "validate_${pkg}.vbs"
                echo "    exec.StdOut.ReadAll()" >> "validate_${pkg}.vbs"
                echo "    If exec.ExitCode = 0 Then" >> "validate_${pkg}.vbs"
                echo "      MsgBox \"Port \" & port & \" is already in use.\", 16, \"Validation Error\"" >> "validate_${pkg}.vbs"
                echo "      Session.Property(\"VALID_$pkg\") = \"0\"" >> "validate_${pkg}.vbs"
                echo "    End If" >> "validate_${pkg}.vbs"
                echo "  End If" >> "validate_${pkg}.vbs"
              fi
            done
          fi
        fi
        echo "End Function" >> "validate_${pkg}.vbs"
        echo "    <Binary Id=\"Bin_Val_$pkg\" SourceFile=\"validate_${pkg}.vbs\" />"
        echo "    <CustomAction Id=\"CA_Val_$pkg\" BinaryKey=\"Bin_Val_$pkg\" VBScriptCall=\"CheckPorts_$pkg\" Return=\"check\" />"
      done

      # Features
      set -- $deps_list
      while [ $# -gt 0 ]; do
        pkg=$1; ver=$2; shift 2
        echo "    <Feature Id=\"Feature_$pkg\" Title=\"Install $pkg\" Level=\"1\">"
        echo "      <ComponentGroupRef Id=\"ProductComponents\" />"
        echo "    </Feature>"
      done

      # UI Generation
      echo "    <UI Id=\"CustomUI\">"
      echo "      <Property Id=\"DefaultUIFont\" Value=\"WixUI_Font_Normal\" />"
      
      echo "      <Dialog Id=\"Dlg_Features\" Width=\"370\" Height=\"270\" Title=\"Select Components\">"
      echo "        <Control Id=\"Lbl_Select\" Type=\"Text\" X=\"20\" Y=\"10\" Width=\"330\" Height=\"15\" Text=\"Select the components you want to install:\" />"
      y=30
      set -- $deps_list
      while [ $# -gt 0 ]; do
        pkg=$1; ver=$2; shift 2
        echo "        <Control Id=\"Chk_$pkg\" Type=\"CheckBox\" X=\"20\" Y=\"${y}\" Width=\"330\" Height=\"15\" Property=\"INSTALL_$pkg\" CheckBoxValue=\"1\" Text=\"Install $pkg\" />"
        y=$((y + 20))
      done
      echo "        <Control Id=\"Next\" Type=\"PushButton\" X=\"236\" Y=\"243\" Width=\"56\" Height=\"17\" Default=\"yes\" Text=\"Next\">"
      echo "          <Publish Event=\"EndDialog\" Value=\"Return\">1</Publish>"
      echo "        </Control>"
      echo "      </Dialog>"
      
      set -- $deps_list
      while [ $# -gt 0 ]; do
        pkg=$1; ver=$2; shift 2
        echo "      <Property Id=\"INSTALL_$pkg\" Value=\"1\" Secure=\"yes\" />"
      done
      
      set -- $deps_list
      has_custom_ui=0
      dialogs=""
      while [ $# -gt 0 ]; do
        pkg=$1; ver=$2; shift 2
        schema_file=$(find "$SCRIPT_DIR/_lib" -name "vars.schema.json" | grep "/$pkg/" | head -n 1)
        if [ -f "$schema_file" ]; then
          vars_json=$(jq -c '.properties | to_entries[] | select(.key | startswith("LIBSCRIPT_GLOBAL_") | not) | {key: .key, desc: (.value.description // .key), def: (.value.default // "")}' "$schema_file")
          if [ -n "$vars_json" ]; then
            has_custom_ui=1
            echo "      <Dialog Id=\"Dlg_${pkg}\" Width=\"370\" Height=\"270\" Title=\"Configuration for ${pkg}\">"
            y=20
            echo "$vars_json" | while read -r item; do
              varname=$(echo "$item" | jq -r '.key')
              desc=$(echo "$item" | jq -r '.desc')
              defval=$(echo "$item" | jq -r '.def')
              
              if [ $y -gt 220 ]; then break; fi
              
              echo "        <Control Id=\"Lbl_${varname}\" Type=\"Text\" X=\"20\" Y=\"${y}\" Width=\"330\" Height=\"15\" Text=\"${desc}:\" />"
              y=$((y + 15))
              if case "$varname" in *"_PASSWORD"*) true;; *) false;; esac; then
                echo "        <Control Id=\"Txt_${varname}\" Type=\"Edit\" X=\"20\" Y=\"${y}\" Width=\"330\" Height=\"18\" Property=\"PROP_${pkg}_${varname}\" Password=\"yes\" />"
              else
                echo "        <Control Id=\"Txt_${varname}\" Type=\"Edit\" X=\"20\" Y=\"${y}\" Width=\"330\" Height=\"18\" Property=\"PROP_${pkg}_${varname}\" />"
              fi
              y=$((y + 20))
            done
            echo "        <Control Id=\"Next\" Type=\"PushButton\" X=\"236\" Y=\"243\" Width=\"56\" Height=\"17\" Default=\"yes\" Text=\"Next\">"
            echo "          <Publish Event=\"DoAction\" Value=\"CA_Val_$pkg\">1</Publish>"
            echo "          <Publish Event=\"EndDialog\" Value=\"Return\"><![CDATA[VALID_$pkg=\"1\"]]></Publish>"
            echo "        </Control>"
            echo "      </Dialog>"
            
            echo "$vars_json" | while read -r item; do
              varname=$(echo "$item" | jq -r '.key')
              defval=$(echo "$item" | jq -r '.def')
              echo "    <Property Id=\"PROP_${pkg}_${varname}\" Value=\"${defval}\" Secure=\"yes\" />"
            done
            
            dialogs="$dialogs Dlg_${pkg}"
          fi
        fi
      done

      # MSI Uninstaller Confirmations
      set -- $deps_list
      while [ $# -gt 0 ]; do
        pkg=$1; ver=$2; shift 2
        echo "      <Dialog Id=\"Dlg_Uninst_${pkg}\" Width=\"370\" Height=\"270\" Title=\"Uninstall $pkg\">"
        echo "        <Control Id=\"Msg\" Type=\"Text\" X=\"20\" Y=\"20\" Width=\"330\" Height=\"30\" Text=\"Do you want to completely remove the Data Directory and all records for $pkg?\" />"
        echo "        <Control Id=\"YesBtn\" Type=\"PushButton\" X=\"100\" Y=\"100\" Width=\"56\" Height=\"17\" Text=\"Yes\">"
        echo "          <Publish Property=\"PURGE_$pkg\" Value=\"--purge-data\">1</Publish>"
        echo "          <Publish Event=\"EndDialog\" Value=\"Return\">1</Publish>"
        echo "        </Control>"
        echo "        <Control Id=\"NoBtn\" Type=\"PushButton\" X=\"170\" Y=\"100\" Width=\"56\" Height=\"17\" Default=\"yes\" Text=\"No\">"
        echo "          <Publish Property=\"PURGE_$pkg\" Value=\"\">1</Publish>"
        echo "          <Publish Event=\"EndDialog\" Value=\"Return\">1</Publish>"
        echo "        </Control>"
        echo "      </Dialog>"
        echo "      <Property Id=\"PURGE_$pkg\" Value=\"\" Secure=\"yes\" />"
        dialogs="$dialogs Dlg_Uninst_${pkg}"
      done
      
      echo "      <Dialog Id=\"Dlg_Action\" Width=\"370\" Height=\"270\" Title=\"Action\">"
      echo "        <Control Id=\"Grp\" Type=\"RadioButtonGroup\" Property=\"ACTION_CHOICE\" X=\"20\" Y=\"20\" Width=\"330\" Height=\"200\">"
      echo "          <RadioButtonGroup Property=\"ACTION_CHOICE\">"
      echo "            <RadioButton Value=\"install\" X=\"0\" Y=\"0\" Width=\"330\" Height=\"15\" Text=\"Install locally now\" />"
      echo "            <RadioButton Value=\"docker\" X=\"0\" Y=\"20\" Width=\"330\" Height=\"15\" Text=\"Dockerfile\" />"
      echo "            <RadioButton Value=\"docker_compose\" X=\"0\" Y=\"40\" Width=\"330\" Height=\"15\" Text=\"Dockerfiles + docker-compose\" />"
      echo "            <RadioButton Value=\"msi\" X=\"0\" Y=\"60\" Width=\"330\" Height=\"15\" Text=\".msi installer\" />"
      echo "            <RadioButton Value=\"innosetup\" X=\"0\" Y=\"80\" Width=\"330\" Height=\"15\" Text=\".exe (InnoSetup)\" />"
      echo "            <RadioButton Value=\"nsis\" X=\"0\" Y=\"100\" Width=\"330\" Height=\"15\" Text=\".exe (NSIS)\" />"
      echo "            <RadioButton Value=\"deb\" X=\"0\" Y=\"120\" Width=\"330\" Height=\"15\" Text=\".deb package\" />"
      echo "            <RadioButton Value=\"rpm\" X=\"0\" Y=\"140\" Width=\"330\" Height=\"15\" Text=\".rpm package\" />"
      echo "          </RadioButtonGroup>"
      echo "        </Control>"
      echo "        <Control Id=\"Next\" Type=\"PushButton\" X=\"236\" Y=\"243\" Width=\"56\" Height=\"17\" Default=\"yes\" Text=\"Next\">"
      echo "          <Publish Event=\"EndDialog\" Value=\"Return\">1</Publish>"
      echo "        </Control>"
      echo "      </Dialog>"
      echo "      <Property Id=\"ACTION_CHOICE\" Value=\"install\" Secure=\"yes\" />"
      echo "      <Dialog Id=\"Dlg_Options\" Width=\"370\" Height=\"270\" Title=\"Options &amp; OS Targets\">"
      echo "        <Control Id=\"Chk_Offline\" Type=\"CheckBox\" X=\"20\" Y=\"20\" Width=\"330\" Height=\"15\" Property=\"OPT_OFFLINE\" CheckBoxValue=\"1\" Text=\"Enable --offline mode\" />"
      echo "        <Control Id=\"Chk_Win\" Type=\"CheckBox\" X=\"20\" Y=\"40\" Width=\"330\" Height=\"15\" Property=\"OPT_WIN\" CheckBoxValue=\"1\" Text=\"Target: Windows\" />"
      echo "        <Control Id=\"Chk_DOS\" Type=\"CheckBox\" X=\"20\" Y=\"60\" Width=\"330\" Height=\"15\" Property=\"OPT_DOS\" CheckBoxValue=\"1\" Text=\"Target: DOS\" />"
      echo "        <Control Id=\"Chk_Linux\" Type=\"CheckBox\" X=\"20\" Y=\"80\" Width=\"330\" Height=\"15\" Property=\"OPT_LINUX\" CheckBoxValue=\"1\" Text=\"Target: Linux\" />"
      echo "        <Control Id=\"Chk_Mac\" Type=\"CheckBox\" X=\"20\" Y=\"100\" Width=\"330\" Height=\"15\" Property=\"OPT_MAC\" CheckBoxValue=\"1\" Text=\"Target: macOS\" />"
      echo "        <Control Id=\"Chk_BSD\" Type=\"CheckBox\" X=\"20\" Y=\"120\" Width=\"330\" Height=\"15\" Property=\"OPT_BSD\" CheckBoxValue=\"1\" Text=\"Target: BSD\" />"
      echo "        <Control Id=\"Next\" Type=\"PushButton\" X=\"236\" Y=\"243\" Width=\"56\" Height=\"17\" Default=\"yes\" Text=\"Next\">"
      echo "          <Publish Event=\"EndDialog\" Value=\"Return\">1</Publish>"
      echo "        </Control>"
      echo "      </Dialog>"
      echo "      <Property Id=\"OPT_OFFLINE\" Value=\"0\" Secure=\"yes\" />"
      echo "      <Property Id=\"OPT_WIN\" Value=\"1\" Secure=\"yes\" />"
      echo "      <Property Id=\"OPT_DOS\" Value=\"0\" Secure=\"yes\" />"
      echo "      <Property Id=\"OPT_LINUX\" Value=\"1\" Secure=\"yes\" />"
      echo "      <Property Id=\"OPT_MAC\" Value=\"0\" Secure=\"yes\" />"
      echo "      <Property Id=\"OPT_BSD\" Value=\"0\" Secure=\"yes\" />"
      echo "      <InstallUISequence>"
      echo "        <Show Dialog=\"Dlg_Features\" After=\"CostFinalize\">NOT Installed</Show>"
      last_dlg="Dlg_Features"
      set -- $deps_list
      while [ $# -gt 0 ]; do
        pkg=$1; ver=$2; shift 2
        has_dlg=0
        for d in $dialogs; do
          if [ "$d" = "Dlg_${pkg}" ]; then has_dlg=1; break; fi
        done
        if [ "$has_dlg" = "1" ]; then
          echo "        <Show Dialog=\"Dlg_${pkg}\" After=\"$last_dlg\"><![CDATA[NOT Installed AND INSTALL_$pkg=\"1\"]]></Show>"
          last_dlg="Dlg_${pkg}"
        fi
      done
      
      echo "        <Show Dialog=\"Dlg_Action\" After=\"$last_dlg\">NOT Installed</Show>"
      echo "        <Show Dialog=\"Dlg_Options\" After=\"Dlg_Action\">NOT Installed</Show>"
      # UI sequence for uninstall
      last_uninst_dlg="CostFinalize"
      set -- $deps_list
      while [ $# -gt 0 ]; do
        pkg=$1; ver=$2; shift 2
        echo "        <Show Dialog=\"Dlg_Uninst_${pkg}\" After=\"$last_uninst_dlg\">REMOVE=\"ALL\"</Show>"
        last_uninst_dlg="Dlg_Uninst_${pkg}"
      done
      echo "      </InstallUISequence>"
      echo "    </UI>"

      # Install Actions
      set -- $deps_list
      while [ $# -gt 0 ]; do
        pkg=$1; ver=$2; shift 2
        if [ "$OFFLINE" = "1" ]; then
          run_params="/c \"[INSTALLFOLDER]libscript.cmd\" install_service $pkg $ver"
        else
          run_params="/c libscript.cmd install_service $pkg $ver"
        fi
        schema_file=$(find "$SCRIPT_DIR/_lib" -name "vars.schema.json" | grep "/$pkg/" | head -n 1)
        if [ -f "$schema_file" ]; then
          vars_json=$(jq -r '.properties | to_entries[] | select(.key | startswith("LIBSCRIPT_GLOBAL_") | not) | .key' "$schema_file")
          if [ -n "$vars_json" ]; then
            append_params=$(echo "$vars_json" | awk -v pkg="$pkg" '{printf " --%s=\"[PROP_%s_%s]\"", $1, pkg, $1}')
            run_params="$run_params$append_params"
          fi
        fi
        echo "    <CustomAction Id=\"Install$pkg\" Directory=\"INSTALLFOLDER\" ExeCommand=\"cmd.exe $run_params\" Execute=\"deferred\" Return=\"check\" Impersonate=\"no\" />"
        
        # Uninstall Actions
        if [ "$OFFLINE" = "1" ]; then
          echo "    <CustomAction Id=\"Uninstall$pkg\" Directory=\"INSTALLFOLDER\" ExeCommand=\"cmd.exe /c \"\"\"[INSTALLFOLDER]libscript.cmd\"\"\" uninstall $pkg [PURGE_$pkg] --service-name [PROP_${pkg}_$(echo "$pkg" | tr \"a-z\" \"A-Z\")_SERVICE_NAME]\" Execute=\"deferred\" Return=\"check\" Impersonate=\"no\" />"
        else
          echo "    <CustomAction Id=\"Uninstall$pkg\" Directory=\"INSTALLFOLDER\" ExeCommand=\"cmd.exe /c libscript.cmd uninstall $pkg [PURGE_$pkg] --service-name [PROP_${pkg}_$(echo "$pkg" | tr \"a-z\" \"A-Z\")_SERVICE_NAME]\" Execute=\"deferred\" Return=\"check\" Impersonate=\"no\" />"
        fi
      done

      echo "Function GenerateStack()" > "generate_stack.vbs"
      echo "  Dim shell, cmd, args, action" >> "generate_stack.vbs"
      echo "  Set shell = CreateObject(""WScript.Shell"")" >> "generate_stack.vbs"
      echo "  action = Session.Property(""ACTION_CHOICE"")" >> "generate_stack.vbs"
      echo "  If action = ""install"" Then Exit Function" >> "generate_stack.vbs"
      echo "  args = "" """ >> "generate_stack.vbs"
      echo "  If Session.Property(""OPT_OFFLINE"") = ""1"" Then args = args & ""--offline """ >> "generate_stack.vbs"
      echo "  If Session.Property(""OPT_WIN"") = ""1"" Then args = args & ""--os-windows """ >> "generate_stack.vbs"
      echo "  If Session.Property(""OPT_DOS"") = ""1"" Then args = args & ""--os-dos """ >> "generate_stack.vbs"
      echo "  If Session.Property(""OPT_LINUX"") = ""1"" Then args = args & ""--os-linux """ >> "generate_stack.vbs"
      echo "  If Session.Property(""OPT_MAC"") = ""1"" Then args = args & ""--os-macos """ >> "generate_stack.vbs"
      echo "  If Session.Property(""OPT_BSD"") = ""1"" Then args = args & ""--os-bsd """ >> "generate_stack.vbs"
      if [ "$OFFLINE" = "1" ]; then
        echo "  cmd = ""cmd.exe /c """""" & Session.Property(""INSTALLFOLDER"") & ""libscript.cmd"""""" package_as "" & action" >> "generate_stack.vbs"
      else
        echo "  cmd = ""cmd.exe /c libscript.cmd package_as "" & action" >> "generate_stack.vbs"
      fi
      echo "  cmd = cmd & "" """ >> "generate_stack.vbs"
      set -- $deps_list
      while [ $# -gt 0 ]; do
        pkg=$1; ver=$2; shift 2
        echo "  If Session.Property(""INSTALL_$pkg"") = ""1"" Then cmd = cmd & ""$pkg $ver """ >> "generate_stack.vbs"
      done
      echo "  cmd = cmd & args" >> "generate_stack.vbs"
      echo "  shell.Run cmd, 0, True" >> "generate_stack.vbs"
      echo "End Function" >> "generate_stack.vbs"
      echo "    <Binary Id=\"Bin_GenStack\" SourceFile=\"generate_stack.vbs\" />"
      echo "    <CustomAction Id=\"CA_GenStack\" BinaryKey=\"Bin_GenStack\" VBScriptCall=\"GenerateStack\" Return=\"ignore\" Impersonate=\"no\" Execute=\"deferred\" />"
      echo "    <InstallExecuteSequence>"
      set -- $deps_list
      while [ $# -gt 0 ]; do
        pkg=$1; ver=$2; shift 2
        echo "      <Custom Action=\"Install$pkg\" Before=\"InstallFinalize\"><![CDATA[NOT Installed AND ACTION_CHOICE=\"install\" AND INSTALL_$pkg=\"1\"]]></Custom>"
        echo "      <Custom Action=\"Uninstall$pkg\" Before=\"RemoveFiles\">REMOVE=\"ALL\"</Custom>"
      done
      echo "      <Custom Action=\"CA_GenStack\" Before=\"InstallFinalize\"><![CDATA[NOT Installed AND ACTION_CHOICE<>\"install\"]]></Custom>"
      echo "    </InstallExecuteSequence>"
      
      echo "  </Product>"
      echo "  <Fragment>"
      echo "    <ComponentGroup Id=\"ProductComponents\" Directory=\"INSTALLFOLDER\">"
      echo "    </ComponentGroup>"
      echo "  </Fragment>"
      echo "</Wix>"

      exec 1>&3 3>&-
      
      if [ "$OS" = "Windows_NT" ] || command -v candle.exe >/dev/null 2>&1 || command -v wix.exe >/dev/null 2>&1; then
        if command -v wix.exe >/dev/null 2>&1; then
          wix.exe build -ext WixToolset.UI.wixext -o "${OUT_FILE}.msi" "$wxs_file"
        else
          candle.exe "$wxs_file"
          light.exe -ext WixUIExtension -out "${OUT_FILE}.msi" "${OUT_FILE}.wixobj"
        fi
      else
        wixl -o "${OUT_FILE}.msi" "$wxs_file"
      fi
      exit 0
    elif [ "$pkg_type" = "innosetup" ]; then
      cat << EOF2
[Setup]
AppName=$APP_NAME
AppVersion=$APP_VERSION
AppPublisher=$APP_PUBLISHER
EOF2
      if [ -n "$APP_URL" ]; then
        echo "AppPublisherURL=$APP_URL"
        echo "AppSupportURL=$APP_URL"
        echo "AppUpdatesURL=$APP_URL"
      fi
      cat << EOF2
DefaultDirName={autopf}\\$APP_NAME
PrivilegesRequired=$inno_priv
OutputDir=.
OutputBaseFilename=$OUT_FILE
EOF2
      if [ "$UPGRADE_CODE" != "PUT-GUID-HERE" ]; then echo "AppId=$UPGRADE_CODE"; fi
      if [ -n "$ICON_PATH" ]; then echo "SetupIconFile=$ICON_PATH"; fi
      if [ -n "$IMAGE_PATH" ]; then echo "WizardImageFile=$IMAGE_PATH"; fi
      if [ -n "$LICENSE_PATH" ]; then echo "LicenseFile=$LICENSE_PATH"; fi

      deps_list=""
      if [ $# -gt 0 ]; then
        while [ $# -gt 0 ]; do
          deps_list="$deps_list $1 ${2:-latest}"
          if [ "$2" != "" ]; then shift 2; else shift; fi
        done
      elif [ -f "libscript.json" ] && command -v jq >/dev/null 2>&1; then
        deps_list=$("${LIBSCRIPT_ROOT_DIR:-.}/scripts/resolve_stack.sh" "libscript.json" 2>/dev/null | jq -r '.selected[] | "\(.name) \(.version // "latest")"' 2>/dev/null | tr '\n' ' ')
      else
        deps_list=$(find_components | sort | awk '{printf "%s latest ", $1}')
      fi

      if [ "$OFFLINE" = "1" ]; then
        echo ""
        echo "[Files]"
        echo "Source: \"$SCRIPT_DIR\\*\"; DestDir: \"{app}\"; Flags: ignoreversion recursesubdirs createallsubdirs"
      fi

      echo ""
      echo "[Types]"
      echo "Name: \"custom\"; Description: \"Custom installation\"; Flags: iscustom"
      echo "Name: \"full\"; Description: \"Full installation\""
      echo ""
      echo "[Components]"
      set -- $deps_list
      while [ $# -gt 0 ]; do
        pkg=$1; ver=$2; shift 2
        echo "Name: \"$pkg\"; Description: \"$pkg\"; Types: full custom"
      done

      echo ""
      echo "[Code]"
      echo "var"

      set -- $deps_list
      while [ $# -gt 0 ]; do
        pkg=$1; ver=$2; shift 2
        schema_file=$(find "$SCRIPT_DIR/_lib" -name "vars.schema.json" | grep "/$pkg/" | head -n 1)
        if [ -f "$schema_file" ]; then
          vars_json=$(jq -c '.properties | to_entries[] | select(.key | startswith("LIBSCRIPT_GLOBAL_") | not) | {key: .key, desc: (.value.description // .key), def: (.value.default // "")}' "$schema_file")
          if [ -n "$vars_json" ]; then
            echo "  Page_$pkg: TInputQueryWizardPage;"
            echo "$vars_json" | jq -r '.key' | while read -r varname; do
              echo "  Var_${pkg}_${varname}: String;"
            done
          fi
        fi
      done

      echo "procedure InitializeWizard;"
      echo "begin"
      echo "  ActionPage := CreateInputOptionPage(wpSelectComponents, 'Action', 'What would you like to produce?', 'Please select an action to perform with the selected components.', True, False);"
      echo "  ActionPage.Add('Install locally now');"
      echo "  ActionPage.Add('Dockerfile');"
      echo "  ActionPage.Add('Dockerfiles + docker-compose');"
      echo "  ActionPage.Add('.msi installer');"
      echo "  ActionPage.Add('.exe (InnoSetup)');"
      echo "  ActionPage.Add('.exe (NSIS)');"
      echo "  ActionPage.Add('.pkg installer');"
      echo "  ActionPage.Add('.dmg installer');"
      echo "  ActionPage.Add('.deb package');"
      echo "  ActionPage.Add('.rpm package');"
      echo "  ActionPage.Values[0] := True;"
      echo "  OfflinePage := CreateInputOptionPage(ActionPage.ID, 'Options & OS Targets', 'Select offline mode and Target OS', '', False, True);"
      echo "  OfflinePage.Add('Enable --offline mode');"
      echo "  OfflinePage.Add('Target: Windows');"
      echo "  OfflinePage.Add('Target: DOS');"
      echo "  OfflinePage.Add('Target: Linux');"
      echo "  OfflinePage.Add('Target: macOS');"
      echo "  OfflinePage.Add('Target: BSD');"
      echo "  OfflinePage.Values[1] := True;"
      echo "  OfflinePage.Values[3] := True;"
      set -- $deps_list
      while [ $# -gt 0 ]; do
        pkg=$1; ver=$2; shift 2
        schema_file=$(find "$SCRIPT_DIR/_lib" -name "vars.schema.json" | grep "/$pkg/" | head -n 1)
        if [ -f "$schema_file" ]; then
          vars_json=$(jq -c '.properties | to_entries[] | select(.key | startswith("LIBSCRIPT_GLOBAL_") | not) | {key: .key, desc: (.value.description // .key), def: (.value.default // "")}' "$schema_file")
          if [ -n "$vars_json" ]; then
            echo "  Page_$pkg := CreateInputQueryPage(wpSelectComponents, 'Configuration for $pkg', 'Please specify settings', '');"
            var_idx=0
            echo "$vars_json" | while read -r item; do
              desc=$(echo "$item" | jq -r '.desc')
              defval=$(echo "$item" | jq -r '.def')
              varname=$(echo "$item" | jq -r '.key')
              if case "$varname" in *"_PASSWORD"*) true;; *) false;; esac; then
                echo "  Page_$pkg.Add('$desc:', True);"
              else
                echo "  Page_$pkg.Add('$desc:', False);"
              fi
              echo "  Page_$pkg.Values[$var_idx] := '$defval';"
              var_idx=$((var_idx + 1))
            done
          fi
        fi
      done
      echo "end;"

      echo "function ShouldSkipPage(PageID: Integer): Boolean;"
      echo "begin"
      echo "  Result := False;"
      set -- $deps_list
      while [ $# -gt 0 ]; do
        pkg=$1; ver=$2; shift 2
        schema_file=$(find "$SCRIPT_DIR/_lib" -name "vars.schema.json" | grep "/$pkg/" | head -n 1)
        if [ -f "$schema_file" ]; then
          if [ -n "$(jq -c '.properties' "$schema_file")" ]; then
            echo "  if (PageID = Page_$pkg.ID) and not IsComponentSelected('$pkg') then"
            echo "    Result := True;"
          fi
        fi
      done
      echo "end;"

      echo "function NextButtonClick(PageId: Integer): Boolean;"
      echo "var"
      echo "  ResultCode: Integer;"
      echo "begin"
      echo "  Result := True;"
      set -- $deps_list
      while [ $# -gt 0 ]; do
        pkg=$1; ver=$2; shift 2
        schema_file=$(find "$SCRIPT_DIR/_lib" -name "vars.schema.json" | grep "/$pkg/" | head -n 1)
        if [ -f "$schema_file" ]; then
          vars_json=$(jq -r '.properties | to_entries[] | select(.key | startswith("LIBSCRIPT_GLOBAL_") | not) | .key' "$schema_file")
          if [ -n "$vars_json" ]; then
            echo "  if PageId = Page_$pkg.ID then begin"
            var_idx=0
            for varname in $vars_json; do
              if case "$varname" in *"_PORT"* | *"_PORT_SECURE"*) true;; *) false;; esac; then
                echo "    if (Page_$pkg.Values[$var_idx] <> '') then begin"
                echo "      if Exec('cmd.exe', '/c netstat -an | findstr /R /C:"":'' + Page_$pkg.Values[$var_idx] + '' .*LISTENING""', '', SW_HIDE, ewWaitUntilTerminated, ResultCode) then begin"
                echo "        if ResultCode = 0 then begin"
                echo "          MsgBox('Port ' + Page_$pkg.Values[$var_idx] + ' is already in use. Please select a different port.', mbError, MB_OK);"
                echo "          Result := False;"
                echo "          Exit;"
                echo "        end;"
                echo "      end;"
                echo "    end;"
              fi
              var_idx=$((var_idx + 1))
            done
            echo "  end;"
          fi
        fi
      done
      echo "end;"

      # Uninstallation Hooks
      echo "procedure CurUninstallStepChanged(CurUninstallStep: TUninstallStep);"
      echo "var"
      echo "  ResultCode: Integer;"
      echo "begin"
      echo "  if CurUninstallStep = usUninstall then begin"
      set -- $deps_list
      while [ $# -gt 0 ]; do
        pkg=$1; ver=$2; shift 2
        echo "    if MsgBox('Do you want to completely remove the Data Directory and all records for $pkg?', mbConfirmation, MB_YESNO) = idYes then begin"
        if [ "$OFFLINE" = "1" ]; then
          echo "      Exec('cmd.exe', '/c \"\"{app}\\libscript.cmd\"\" uninstall $pkg --purge-data --service-name ' + Get_${pkg}_$(echo "$pkg" | tr \"a-z\" \"A-Z\")_SERVICE_NAME(''), '', SW_HIDE, ewWaitUntilTerminated, ResultCode);"
        else
          echo "      Exec('cmd.exe', '/c libscript.cmd uninstall $pkg --purge-data --service-name ' + Get_${pkg}_$(echo "$pkg" | tr \"a-z\" \"A-Z\")_SERVICE_NAME(''), '', SW_HIDE, ewWaitUntilTerminated, ResultCode);"
        fi
        echo "    end else begin"
        if [ "$OFFLINE" = "1" ]; then
          echo "      Exec('cmd.exe', '/c \"\"{app}\\libscript.cmd\"\" uninstall $pkg --service-name ' + Get_${pkg}_$(echo "$pkg" | tr \"a-z\" \"A-Z\")_SERVICE_NAME(''), '', SW_HIDE, ewWaitUntilTerminated, ResultCode);"
        else
          echo "      Exec('cmd.exe', '/c libscript.cmd uninstall $pkg --service-name ' + Get_${pkg}_$(echo "$pkg" | tr \"a-z\" \"A-Z\")_SERVICE_NAME(''), '', SW_HIDE, ewWaitUntilTerminated, ResultCode);"
        fi
        echo "    end;"
      done
      echo "  end;"
      echo "end;"
      echo "  ActionPage: TInputOptionWizardPage;"
      echo "  OfflinePage: TInputOptionWizardPage;"

      set -- $deps_list
      while [ $# -gt 0 ]; do
        pkg=$1; ver=$2; shift 2
        schema_file=$(find "$SCRIPT_DIR/_lib" -name "vars.schema.json" | grep "/$pkg/" | head -n 1)
        if [ -f "$schema_file" ]; then
          vars_json=$(jq -r '.properties | to_entries[] | select(.key | startswith("LIBSCRIPT_GLOBAL_") | not) | .key' "$schema_file")
          if [ -n "$vars_json" ]; then
            var_idx=0
            for varname in $vars_json; do
              echo "function Get_${pkg}_${varname}(Param: String): String;"
              echo "begin"
              echo "  Result := Page_$pkg.Values[$var_idx];"
              echo "end;"
              var_idx=$((var_idx + 1))
            done
          fi
        fi
      done

      echo ""
      echo "function GetAction(Param: String): String;"
      echo "begin"
      echo "  if ActionPage.Values[1] then Result := 'docker'"
      echo "  else if ActionPage.Values[2] then Result := 'docker_compose'"
      echo "  else if ActionPage.Values[3] then Result := 'msi'"
      echo "  else if ActionPage.Values[4] then Result := 'innosetup'"
      echo "  else if ActionPage.Values[5] then Result := 'nsis'"
      echo "  else if ActionPage.Values[6] then Result := 'pkg'"
      echo "  else if ActionPage.Values[7] then Result := 'dmg'"
      echo "  else if ActionPage.Values[8] then Result := 'deb'"
      echo "  else if ActionPage.Values[9] then Result := 'rpm'"
      echo "  else Result := 'install';"
      echo "end;"
      echo "function GetExtraArgs(Param: String): String;"
      echo "var S: String;"
      echo "begin"
      echo "  S := '';"
      echo "  if OfflinePage.Values[0] then S := S + ' --offline';"
      echo "  if OfflinePage.Values[1] then S := S + ' --os-windows';"
      echo "  if OfflinePage.Values[2] then S := S + ' --os-dos';"
      echo "  if OfflinePage.Values[3] then S := S + ' --os-linux';"
      echo "  if OfflinePage.Values[4] then S := S + ' --os-macos';"
      echo "  if OfflinePage.Values[5] then S := S + ' --os-bsd';"
      echo "  Result := S;"
      echo "end;"
      echo "function IsInstall: Boolean;"
      echo "begin Result := ActionPage.Values[0]; end;"
      echo "function IsGenerate: Boolean;"
      echo "begin Result := not ActionPage.Values[0]; end;"
      echo "function GetGenerateParams(Param: String): String;"
      echo "var S: String;"
      echo "begin"
      echo "  if '{app}' <> '' then"
      echo "    S := '/c \"\"\"{app}\\libscript.cmd\"\"\" package_as ' + GetAction('') + ' ';";
      echo "  else";
      echo "    S := '/c libscript.cmd package_as ' + GetAction('') + ' ';";
      set -- $deps_list
      while [ $# -gt 0 ]; do
        pkg=$1; ver=$2; shift 2
        echo "  if IsComponentSelected('$pkg') then S := S + '$pkg $ver ';";
      done
      echo "  S := S + GetExtraArgs('');"
      echo "  Result := S;"
      echo "end;"
      echo "[Run]"
      set -- $deps_list
      while [ $# -gt 0 ]; do
        pkg=$1; ver=$2; shift 2
        if [ "$OFFLINE" = "1" ]; then
          run_params="/c \"\"{app}\\libscript.cmd\"\" install_service $pkg $ver"
        else
          run_params="/c libscript.cmd install_service $pkg $ver"
        fi
        schema_file=$(find "$SCRIPT_DIR/_lib" -name "vars.schema.json" | grep "/$pkg/" | head -n 1)
        if [ -f "$schema_file" ]; then
          vars_json=$(jq -r '.properties | to_entries[] | select(.key | startswith("LIBSCRIPT_GLOBAL_") | not) | .key' "$schema_file")
          if [ -n "$vars_json" ]; then
            append_params=$(echo "$vars_json" | awk -v pkg="$pkg" '{printf " --%s=\"{code:Get_%s_%s}\"", $1, pkg, $1}')
            run_params="$run_params$append_params"
          fi
        fi
        echo "Filename: \"cmd.exe\"; Parameters: \"$run_params\"; Components: $pkg; Flags: runhidden; Check: IsInstall"
      done
      if [ "$OFFLINE" = "1" ]; then
        echo "Filename: \"cmd.exe\"; Parameters: \"{code:GetGenerateParams}\"; WorkingDir: \"{app}\"; Flags: runhidden; Check: IsGenerate"
      else
        echo "Filename: \"cmd.exe\"; Parameters: \"{code:GetGenerateParams}\"; Flags: runhidden; Check: IsGenerate"
      fi
      exit 0
    elif [ "$pkg_type" = "nsis" ] || [ "$pkg_type" = "pkg" ] || [ "$pkg_type" = "dmg" ]; then
      cat << EOF2
!define APP_NAME "$APP_NAME"
!define APP_VERSION "$APP_VERSION"
!define APP_PUBLISHER "$APP_PUBLISHER"
Name "$APP_NAME \$APP_VERSION"
OutFile "${OUT_FILE}.exe"
InstallDir "\$PROGRAMFILES\\$APP_NAME"
RequestExecutionLevel $nsis_admin

VIProductVersion "$APP_VERSION"
VIAddVersionKey "ProductName" "$APP_NAME"
VIAddVersionKey "CompanyName" "$APP_PUBLISHER"
VIAddVersionKey "FileDescription" "$WELCOME_TEXT"
VIAddVersionKey "FileVersion" "$APP_VERSION"
EOF2
      if [ -n "$ICON_PATH" ]; then echo "Icon \"$ICON_PATH\""; fi
      echo ""
      
      deps_list=""
      if [ $# -gt 0 ]; then
        while [ $# -gt 0 ]; do
          deps_list="$deps_list $1 ${2:-latest}"
          if [ "$2" != "" ]; then shift 2; else shift; fi
        done
      elif [ -f "libscript.json" ] && command -v jq >/dev/null 2>&1; then
        deps_list=$("${LIBSCRIPT_ROOT_DIR:-.}/scripts/resolve_stack.sh" "libscript.json" 2>/dev/null | jq -r '.selected[] | "\(.name) \(.version // "latest")"' 2>/dev/null | tr '\n' ' ')
      else
        deps_list=$(find_components | sort | awk '{printf "%s latest ", $1}')
      fi

      if [ "$OFFLINE" = "1" ]; then
        echo "Section \"Core\""
        echo "  SetOutPath \"\$INSTDIR\""
        echo "  File /r \"$SCRIPT_DIR\\*.*\""
        echo "SectionEnd"
      fi
      echo "Include nsDialogs.nsh"
      echo "Page components"
      
      set -- $deps_list
      while [ $# -gt 0 ]; do
        pkg=$1; ver=$2; shift 2
        schema_file=$(find "$SCRIPT_DIR/_lib" -name "vars.schema.json" | grep "/$pkg/" | head -n 1)
        if [ -f "$schema_file" ]; then
          vars_json=$(jq -c '.properties | to_entries[] | select(.key | startswith("LIBSCRIPT_GLOBAL_") | not) | {key: .key, desc: (.value.description // .key), def: (.value.default // "")}' "$schema_file")
          if [ -n "$vars_json" ]; then
            echo "Var Dialog_$pkg"
            echo "$vars_json" | jq -r '.key' | while read -r varname; do
              echo "Var HWND_${pkg}_${varname}"
              echo "Var VAL_${pkg}_${varname}"
            done
            
            echo "Page custom pgCustom_$pkg pgLeave_$pkg"
          fi
        fi
      done
      
      if [ -n "$LICENSE_PATH" ]; then echo "Page license \"\" \"$LICENSE_PATH\""; fi
      echo "Page custom ActionPageCreate ActionPageLeave"
      echo "Page custom OptionsPageCreate OptionsPageLeave"
      echo "Page instfiles"
      echo ""
      
      set -- $deps_list
      while [ $# -gt 0 ]; do
        pkg=$1; ver=$2; shift 2
        echo "Section \"$pkg\" SEC_$pkg"
        if [ "$OFFLINE" = "1" ]; then
          run_params="/c \"\$INSTDIR\\libscript.cmd\" install_service $pkg $ver"
        else
          run_params="/c libscript.cmd install_service $pkg $ver"
        fi
        schema_file=$(find "$SCRIPT_DIR/_lib" -name "vars.schema.json" | grep "/$pkg/" | head -n 1)
        if [ -f "$schema_file" ]; then
          vars_json=$(jq -r '.properties | to_entries[] | select(.key | startswith("LIBSCRIPT_GLOBAL_") | not) | .key' "$schema_file")
          if [ -n "$vars_json" ]; then
            append_params=$(echo "$vars_json" | awk -v pkg="$pkg" '{printf " --%s=\"\$VAL_%s_%s\"", $1, pkg, $1}')
            run_params="$run_params$append_params"
          fi
        fi
        echo "  \${If} \$Action_Choice == \"install\""
        echo "  ExecWait 'cmd.exe $run_params'"
        echo "  \${EndIf}"
        echo "SectionEnd"
      done

      set -- $deps_list
      while [ $# -gt 0 ]; do
        pkg=$1; ver=$2; shift 2
        schema_file=$(find "$SCRIPT_DIR/_lib" -name "vars.schema.json" | grep "/$pkg/" | head -n 1)
        if [ -f "$schema_file" ]; then
          vars_json=$(jq -c '.properties | to_entries[] | select(.key | startswith("LIBSCRIPT_GLOBAL_") | not) | {key: .key, desc: (.value.description // .key), def: (.value.default // "")}' "$schema_file")
          if [ -n "$vars_json" ]; then
            echo "Function pgCustom_$pkg"
            echo "  SectionGetFlags \${SEC_$pkg} \$0"
            echo "  IntOp \$0 \$0 & 1"
            echo "  IntCmp \$0 1 +2"
            echo "    Abort"
            echo "  nsDialogs::Create 1018"
            echo "  Pop \$Dialog_$pkg"
            
            y=0
            echo "$vars_json" | while read -r item; do
              varname=$(echo "$item" | jq -r '.key')
              desc=$(echo "$item" | jq -r '.desc')
              defval=$(echo "$item" | jq -r '.def')
              if [ $y -gt 130 ]; then break; fi
              
              echo "  \${NSD_CreateLabel} 0 ${y}u 100% 12u \"$desc:\""
              echo "  Pop \$0"
              y=$((y + 12))
              
              if case "$varname" in *"_PASSWORD"*) true;; *) false;; esac; then
                echo "  \${NSD_CreatePassword} 0 ${y}u 100% 12u \"$defval\""
              else
                echo "  \${NSD_CreateText} 0 ${y}u 100% 12u \"$defval\""
              fi
              echo "  Pop \$HWND_${pkg}_${varname}"
              y=$((y + 14))
            done
            echo "  nsDialogs::Show"
            echo "FunctionEnd"
            
            echo "Function pgLeave_$pkg"
            echo "$vars_json" | jq -r '.key' | while read -r varname; do
              echo "  \${NSD_GetText} \$HWND_${pkg}_${varname} \$VAL_${pkg}_${varname}"
              
              if case "$varname" in *"_PORT"* | *"_PORT_SECURE"*) true;; *) false;; esac; then
                echo "  StrCmp \$VAL_${pkg}_${varname} \"\" +4 0"
                echo "  nsExec::ExecToStack 'cmd.exe /c netstat -an | findstr /R /C:\":\$VAL_${pkg}_${varname} .*LISTENING\"'"
                echo "  Pop \$0"
                echo "  IntCmp \$0 0 0 +3"
                echo "    MessageBox MB_ICONSTOP \"Port \$VAL_${pkg}_${varname} is already in use.\""
                echo "    Abort"
              fi
            done
            echo "FunctionEnd"
          fi
        fi
      done

      echo "Var Dialog_Action"
      echo "Var R_Install"
      echo "Var R_Docker"
      echo "Var R_DC"
      echo "Var R_MSI"
      echo "Var R_Inno"
      echo "Var R_NSIS"
      echo "Var R_PKG"
      echo "Var R_DMG"
      echo "Var R_Deb"
      echo "Var R_RPM"
      echo "Var Action_Choice"
      echo "Var Dialog_Options"
      echo "Var C_Offline"
      echo "Var C_Win"
      echo "Var C_DOS"
      echo "Var C_Linux"
      echo "Var C_Mac"
      echo "Var C_BSD"
      echo "Var Opt_Offline"
      echo "Var Opt_Win"
      echo "Var Opt_DOS"
      echo "Var Opt_Linux"
      echo "Var Opt_Mac"
      echo "Var Opt_BSD"
      echo "Function ActionPageCreate"
      echo "  nsDialogs::Create 1018"
      echo "  Pop \$Dialog_Action"
      echo "  \${NSD_CreateLabel} 0 0 100% 12u \"What would you like to produce?\""
      echo "  Pop \$0"
      echo "  \${NSD_CreateRadioButton} 0 15u 100% 12u \"Install locally now\""
      echo "  Pop \$R_Install"
      echo "  \${NSD_Check} \$R_Install"
      echo "  \${NSD_CreateRadioButton} 0 30u 100% 12u \"Dockerfile\""
      echo "  Pop \$R_Docker"
      echo "  \${NSD_CreateRadioButton} 0 45u 100% 12u \"Dockerfiles + docker-compose\""
      echo "  Pop \$R_DC"
      echo "  \${NSD_CreateRadioButton} 0 60u 100% 12u \".msi installer\""
      echo "  Pop \$R_MSI"
      echo "  \${NSD_CreateRadioButton} 0 75u 100% 12u \".exe (InnoSetup)\""
      echo "  Pop \$R_Inno"
      echo "  \${NSD_CreateRadioButton} 0 90u 100% 12u \".exe (NSIS)\""
      echo "  Pop \$R_NSIS"
      echo "  \${NSD_CreateRadioButton} 0 105u 100% 12u \".pkg installer\""
      echo "  Pop \$R_PKG"
      echo "  \${NSD_CreateRadioButton} 0 120u 100% 12u \".dmg installer\""
      echo "  Pop \$R_DMG"
      echo "  \${NSD_CreateRadioButton} 0 135u 100% 12u \".deb package\""
      echo "  Pop \$R_Deb"
      echo "  \${NSD_CreateRadioButton} 0 150u 100% 12u \".rpm package\""
      echo "  Pop \$R_RPM"
      echo "  nsDialogs::Show"
      echo "FunctionEnd"
      echo "Function ActionPageLeave"
      echo "  StrCpy \$Action_Choice \"install\""
      echo "  \${NSD_GetState} \$R_Docker \$0"
      echo "  \${If} \$0 == \${BST_CHECKED}"
      echo "    StrCpy \$Action_Choice \"docker\""
      echo "  \${EndIf}"
      echo "  \${NSD_GetState} \$R_DC \$0"
      echo "  \${If} \$0 == \${BST_CHECKED}"
      echo "    StrCpy \$Action_Choice \"docker_compose\""
      echo "  \${EndIf}"
      echo "  \${NSD_GetState} \$R_MSI \$0"
      echo "  \${If} \$0 == \${BST_CHECKED}"
      echo "    StrCpy \$Action_Choice \"msi\""
      echo "  \${EndIf}"
      echo "  \${NSD_GetState} \$R_Inno \$0"
      echo "  \${If} \$0 == \${BST_CHECKED}"
      echo "    StrCpy \$Action_Choice \"innosetup\""
      echo "  \${EndIf}"
      echo "  \${NSD_GetState} \$R_NSIS \$0"
      echo "  \${If} \$0 == \${BST_CHECKED}"
      echo "    StrCpy \$Action_Choice \"nsis\""
      echo "  \${EndIf}"
      echo "  \${NSD_GetState} \$R_Deb \$0"
      echo "  \${If} \$0 == \${BST_CHECKED}"
      echo "    StrCpy \$Action_Choice \"deb\""
      echo "  \${EndIf}"
      echo "  \${NSD_GetState} \$R_RPM \$0"
      echo "  \${If} \$0 == \${BST_CHECKED}"
      echo "    StrCpy \$Action_Choice \"rpm\""
      echo "  \${EndIf}"
      echo "FunctionEnd"
      echo "Function OptionsPageCreate"
      echo "  nsDialogs::Create 1018"
      echo "  Pop \$Dialog_Options"
      echo "  \${NSD_CreateLabel} 0 0 100% 12u \"Options & OS Targets\""
      echo "  Pop \$0"
      echo "  \${NSD_CreateCheckbox} 0 15u 100% 12u \"Enable --offline mode\""
      echo "  Pop \$C_Offline"
      echo "  \${NSD_CreateCheckbox} 0 30u 100% 12u \"Target: Windows\""
      echo "  Pop \$C_Win"
      echo "  \${NSD_Check} \$C_Win"
      echo "  \${NSD_CreateCheckbox} 0 45u 100% 12u \"Target: DOS\""
      echo "  Pop \$C_DOS"
      echo "  \${NSD_CreateCheckbox} 0 60u 100% 12u \"Target: Linux\""
      echo "  Pop \$C_Linux"
      echo "  \${NSD_Check} \$C_Linux"
      echo "  \${NSD_CreateCheckbox} 0 75u 100% 12u \"Target: macOS\""
      echo "  Pop \$C_Mac"
      echo "  \${NSD_CreateCheckbox} 0 90u 100% 12u \"Target: BSD\""
      echo "  Pop \$C_BSD"
      echo "  nsDialogs::Show"
      echo "FunctionEnd"
      echo "Function OptionsPageLeave"
      echo "  \${NSD_GetState} \$C_Offline \$0"
      echo "  StrCpy \$Opt_Offline \$0"
      echo "  \${NSD_GetState} \$C_Win \$0"
      echo "  StrCpy \$Opt_Win \$0"
      echo "  \${NSD_GetState} \$C_DOS \$0"
      echo "  StrCpy \$Opt_DOS \$0"
      echo "  \${NSD_GetState} \$C_Linux \$0"
      echo "  StrCpy \$Opt_Linux \$0"
      echo "  \${NSD_GetState} \$C_Mac \$0"
      echo "  StrCpy \$Opt_Mac \$0"
      echo "  \${NSD_GetState} \$C_BSD \$0"
      echo "  StrCpy \$Opt_BSD \$0"
      echo "FunctionEnd"
      echo "Section \"-Generate\" SEC_GENERATE"
      echo "  \${If} \$Action_Choice != \"install\""
      echo "    Var /GLOBAL GenCmd"
      echo "    StrCpy \$GenCmd \"\""
      echo "    \${If} \$Opt_Offline == \${BST_CHECKED}"
      echo "      StrCpy \$GenCmd \"\$GenCmd --offline \""
      echo "    \${EndIf}"
      echo "    \${If} \$Opt_Win == \${BST_CHECKED}"
      echo "      StrCpy \$GenCmd \"\$GenCmd --os-windows \""
      echo "    \${EndIf}"
      echo "    \${If} \$Opt_DOS == \${BST_CHECKED}"
      echo "      StrCpy \$GenCmd \"\$GenCmd --os-dos \""
      echo "    \${EndIf}"
      echo "    \${If} \$Opt_Linux == \${BST_CHECKED}"
      echo "      StrCpy \$GenCmd \"\$GenCmd --os-linux \""
      echo "    \${EndIf}"
      echo "    \${If} \$Opt_Mac == \${BST_CHECKED}"
      echo "      StrCpy \$GenCmd \"\$GenCmd --os-macos \""
      echo "    \${EndIf}"
      echo "    \${If} \$Opt_BSD == \${BST_CHECKED}"
      echo "      StrCpy \$GenCmd \"\$GenCmd --os-bsd \""
      echo "    \${EndIf}"
      echo "    Var /GLOBAL PkgArgs"
      echo "    StrCpy \$PkgArgs \"\""
      set -- $deps_list
      while [ $# -gt 0 ]; do
        pkg=$1; ver=$2; shift 2
        echo "    SectionGetFlags \${SEC_$pkg} \$0"
        echo "    IntOp \$0 \$0 & 1"
        echo "    \${If} \$0 == 1"
        echo "      StrCpy \$PkgArgs \"\$PkgArgs $pkg $ver \""
        echo "    \${EndIf}"
      done
      if [ "$OFFLINE" = "1" ]; then
        echo "    ExecWait 'cmd.exe /c \"\$INSTDIR\\libscript.cmd\" package_as \$Action_Choice \$PkgArgs \$GenCmd'"
      else
        echo "    ExecWait 'cmd.exe /c libscript.cmd package_as \$Action_Choice \$PkgArgs \$GenCmd'"
      fi
      echo "  \${EndIf}"
      echo "SectionEnd"
      # Uninstaller
      echo "Section \"Uninstall\""
      set -- $deps_list
      while [ $# -gt 0 ]; do
        pkg=$1; ver=$2; shift 2
        echo "  MessageBox MB_YESNO \"Do you want to completely remove the Data Directory and all records for $pkg?\" IDYES purge_$pkg IDNO keep_$pkg"
        echo "  purge_$pkg:"
        if [ "$OFFLINE" = "1" ]; then
          echo "    ExecWait 'cmd.exe /c \"\$INSTDIR\\libscript.cmd\" uninstall $pkg --purge-data --service-name \$VAL_${pkg}_$(echo "$pkg" | tr \"a-z\" \"A-Z\")_SERVICE_NAME'"
        else
          echo "    ExecWait 'cmd.exe /c libscript.cmd uninstall $pkg --purge-data --service-name \$VAL_${pkg}_$(echo "$pkg" | tr \"a-z\" \"A-Z\")_SERVICE_NAME'"
        fi
        echo "    Goto end_$pkg"
        echo "  keep_$pkg:"
        if [ "$OFFLINE" = "1" ]; then
          echo "    ExecWait 'cmd.exe /c \"\$INSTDIR\\libscript.cmd\" uninstall $pkg --service-name \$VAL_${pkg}_$(echo "$pkg" | tr \"a-z\" \"A-Z\")_SERVICE_NAME'"
        else
          echo "    ExecWait 'cmd.exe /c libscript.cmd uninstall $pkg --service-name \$VAL_${pkg}_$(echo "$pkg" | tr \"a-z\" \"A-Z\")_SERVICE_NAME'"
        fi
        echo "  end_$pkg:"
      done
      echo "SectionEnd"

      exit 0
    elif [ "$pkg_type" = "pkg" ] || [ "$pkg_type" = "dmg" ]; then
      PKG_STAGE="${OUT_FILE}_stage"
      rm -rf "$PKG_STAGE"
      mkdir -p "$PKG_STAGE/packages" "$PKG_STAGE/resources" "$PKG_STAGE/scripts"
      
      if [ -n "$WELCOME_TEXT" ]; then
        echo "<html><body><h1>Welcome</h1><p>$WELCOME_TEXT</p></body></html>" > "$PKG_STAGE/resources/welcome.html"
      fi
      if [ -n "$LICENSE_PATH" ] && [ -f "$LICENSE_PATH" ]; then
        cp "$LICENSE_PATH" "$PKG_STAGE/resources/license.html"
      fi
      
      deps_list=""
      if [ $# -gt 0 ]; then
        while [ $# -gt 0 ]; do
          deps_list="$deps_list $1 ${2:-latest}"
          if [ "$2" != "" ]; then shift 2; else shift; fi
        done
      elif [ -f "libscript.json" ] && command -v jq >/dev/null 2>&1; then
        deps_list=$("${LIBSCRIPT_ROOT_DIR:-.}/scripts/resolve_stack.sh" "libscript.json" 2>/dev/null | jq -r '.selected[] | "\(.name) \(.version // "latest")"' 2>/dev/null | tr '\n' ' ')
      else
        deps_list=$(find_components | sort | awk '{printf "%s latest ", $1}')
      fi
      
      set -- $deps_list
      while [ $# -gt 0 ]; do
        pkg=$1; ver=$2; shift 2
        comp_dir="$PKG_STAGE/comp_${pkg}"
        mkdir -p "$comp_dir/root/opt/libscript"
        mkdir -p "$comp_dir/scripts"
        
        cat << "EOF_SCRIPT" > "$comp_dir/scripts/postinstall"
#!/bin/sh
export PATH="/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"
USER_NAME=$(stat -f "%Su" /dev/console 2>/dev/null || echo "$SUDO_USER")
if [ -z "$USER_NAME" ] || [ "$USER_NAME" = "root" ]; then
  USER_NAME="$USER"
fi
EOF_SCRIPT

        schema_file=$(find "$SCRIPT_DIR/_lib" -name "vars.schema.json" | grep "/$pkg/" | head -n 1)
        params=""
        if [ -f "$schema_file" ]; then
          vars_json=$(jq -c '.properties | to_entries[] | select(.key | startswith("LIBSCRIPT_GLOBAL_") | not) | {key: .key, desc: (.value.description // .key), def: (.value.default // "")}' "$schema_file")
          if [ -n "$vars_json" ]; then
            echo "$vars_json" | while read -r item; do
              varname=$(echo "$item" | jq -r '.key')
              desc=$(echo "$item" | jq -r '.desc' | sed 's/"/\"/g')
              defval=$(echo "$item" | jq -r '.def' | sed 's/"/\"/g')
              
              if case "$varname" in *"_PASSWORD"*) true;; *) false;; esac; then
                hidden="with hidden answer"
              else
                hidden=""
              fi
              
              cat << EOF_PROMPT >> "$comp_dir/scripts/postinstall"
VAL_${varname}=\$(sudo -u "\$USER_NAME" osascript -e 'Tell application "System Events" to display dialog "Configuration for ${pkg}

${desc}:" default answer "${defval}" ${hidden}' -e 'text returned of result' 2>/dev/null)
export ${varname}="\$VAL_${varname}"
EOF_PROMPT

              if case "$varname" in *"_PORT"* | *"_PORT_SECURE"*) true;; *) false;; esac; then
                cat << EOF_PROMPT >> "$comp_dir/scripts/postinstall"
while netstat -an | grep -q "[.:]\$VAL_${varname} .*LISTEN"; do
  VAL_${varname}=\$(sudo -u "\$USER_NAME" osascript -e 'Tell application "System Events" to display dialog "Port '"\$VAL_${varname}"' is already in use. Please enter a different port:" default answer ""' -e 'text returned of result' 2>/dev/null)
  export ${varname}="\$VAL_${varname}"
done
EOF_PROMPT
              fi
            done
            params=$(echo "$vars_json" | jq -r '.key' | awk -v pkg="$pkg" '{printf " --%s=\"$VAL_%s\"", $1, $1}')
          fi
        fi

        cat << EOF_SCRIPT >> "$comp_dir/scripts/postinstall"
if command -v libscript.sh >/dev/null 2>&1; then
  libscript.sh install_service "$pkg" "$ver" $params
elif [ -f "/opt/libscript/libscript.sh" ]; then
  /opt/libscript/libscript.sh install_service "$pkg" "$ver" $params
elif [ -f "\$0/../../../libscript.sh" ]; then
  "\$0/../../../libscript.sh" install_service "$pkg" "$ver" $params
else
  sudo -u "\$USER_NAME" osascript -e 'Tell application "System Events" to display alert "libscript.sh not found. Installation of '"$pkg"' failed."'
  exit 1
fi

cat << "EOF_UNINST" > "/opt/libscript/uninstall_${pkg}.command"
#!/bin/sh
export PATH="/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"
USER_NAME=\$(stat -f "%Su" /dev/console 2>/dev/null || echo "\\$SUDO_USER")
if [ -z "\\$USER_NAME" ] || [ "\\$USER_NAME" = "root" ]; then
  USER_NAME="\\$USER"
fi

ans=\$(sudo -u "\\$USER_NAME" osascript -e 'Tell application "System Events" to display dialog "Do you want to completely remove the Data Directory and all records for '"$pkg"'?" buttons {"Yes", "No"} default button "No"' -e 'button returned of result' 2>/dev/null)

purge=""
if [ "\\$ans" = "Yes" ]; then
  purge="--purge-data"
fi

echo "Uninstalling $pkg..."
sudo libscript.sh uninstall "$pkg" \\$purge
echo "Uninstalled $pkg."
sleep 2
EOF_UNINST
chmod +x "/opt/libscript/uninstall_${pkg}.command"
EOF_SCRIPT

        chmod +x "$comp_dir/scripts/postinstall"
        
        if command -v pkgbuild >/dev/null 2>&1; then
          pkgbuild --root "$comp_dir/root" --scripts "$comp_dir/scripts" --identifier "com.libscript.comp.$pkg" --version "$APP_VERSION" "$PKG_STAGE/packages/$pkg.pkg"
        fi
      done

      if command -v productbuild >/dev/null 2>&1; then
        productbuild --synthesize --package-path "$PKG_STAGE/packages" "$PKG_STAGE/Distribution.xml"

        sed_cmd="sed -i"
        if [ "$(uname)" = "Darwin" ]; then sed_cmd="sed -i ''"; fi
        
        $sed_cmd -e '/<installer-gui-script/a\
    <title>'"$APP_NAME"'</title>\
    <options customize="always" require-scripts="false"/>' "$PKG_STAGE/Distribution.xml"

        if [ -n "$WELCOME_TEXT" ]; then
          $sed_cmd -e '/<installer-gui-script/a\
    <welcome file="welcome.html"/>' "$PKG_STAGE/Distribution.xml"
        fi
        
        if [ -n "$LICENSE_PATH" ] && [ -f "$LICENSE_PATH" ]; then
          $sed_cmd -e '/<installer-gui-script/a\
    <license file="license.html"/>' "$PKG_STAGE/Distribution.xml"
        fi
        
        set -- $deps_list
        while [ $# -gt 0 ]; do
          pkg=$1; ver=$2; shift 2
          $sed_cmd "s/choice id=\"com.libscript.comp.$pkg\" title=\"[^\"]*\"/choice id=\"com.libscript.comp.$pkg\" title=\"$pkg installer\"/g" "$PKG_STAGE/Distribution.xml"
        done

        productbuild --distribution "$PKG_STAGE/Distribution.xml" --package-path "$PKG_STAGE/packages" --resources "$PKG_STAGE/resources" "${OUT_FILE}.pkg"
        
        if [ "$pkg_type" = "dmg" ]; then
          hdiutil create -volname "$APP_NAME" -srcfolder "${OUT_FILE}.pkg" -ov -format UDZO "${OUT_FILE}.dmg"
          echo "Created ${OUT_FILE}.dmg"
        else
          echo "Created ${OUT_FILE}.pkg"
        fi
        rm -rf "$PKG_STAGE"
      else
        echo "Created source files in $PKG_STAGE"
        echo "pkgbuild/productbuild not found. Cannot build .pkg natively." >&2
      fi
      exit 0

    fi
  else
    echo "Error: Unsupported package format '$pkg_type'." >&2
    exit 1
  fi
fi

is_action=0
req_version=0
case "$cmd" in
  install|install_daemon|install_service|uninstall_daemon|uninstall_service|remove_daemon|remove_service)
    is_action=1; req_version=1 ;;
  remove|uninstall|status|health|test|ls|ls-remote|start|stop|restart|logs|up|down)
    is_action=1 ;;
  run|which|exec|env|download|serve|route)
    is_action=1; req_version=1 ;;
esac

action_pkg="$cmd"
if [ "$is_action" = "1" ]; then
  action_pkg="$1"
  if [ -z "$action_pkg" ]; then
    echo "Error: package_name is required for $cmd" >&2
    exit 1
  fi
  # We do not shift here because the local cli.sh expects the action as $1
  # But we need to pass "$cmd" "$action_pkg" "$@" to local cli.sh
  # Oh wait, we already shifted. So $1 is action_pkg.
  # Let's restore "$cmd" for the local cli.sh.
  set -- "$cmd" "$@"
fi

target=""
if [ -f "$SCRIPT_DIR/$action_pkg/cli.sh" ]; then
  target="$SCRIPT_DIR/$action_pkg"
else
  if ! matches=$(find_components | grep -i "$action_pkg"); then
    matches=""
  fi
  if ! count=$(echo "$matches" | grep -c .); then
    count=0
  fi
  if [ "$count" -eq 0 ]; then
    echo "Error: Unknown component '$action_pkg'."
    exit 1
  elif [ "$count" -eq 1 ]; then
    target="$SCRIPT_DIR/$matches"
  else
    if ! exact_match=$(echo "$matches" | grep "/$action_pkg$"); then
      exact_match=""
    fi
    if ! exact_count=$(echo "$exact_match" | grep -c .); then
      exact_count=0
    fi
    if [ "$exact_count" -eq 1 ]; then
      target="$SCRIPT_DIR/$exact_match"
    else
      echo "Error: Component '$action_pkg' is ambiguous. Matches:"
      echo "$matches" | sed 's/^/  /'
      exit 1
    fi
  fi
fi

if [ -x "$target/cli.sh" ]; then
  exec "$target/cli.sh" "$@"
elif [ -f "$target/cli.sh" ]; then
  exec sh "$target/cli.sh" "$@"
else
  echo "Error: Local CLI not found in $target"
  exit 1
fi
