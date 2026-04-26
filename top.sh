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
  echo "  provision <provider> ...    Provision a cloud environment"
  echo "  deprovision <provider> ...  Deprovision a cloud environment"
  echo "  <component> [OPTIONS...]    Invoke the CLI for a specific component"
  echo ""
  echo "Options:"
  echo "  --help, -h, /?              Show this extensive help text"
  echo "  --prefix=<dir>              Set local installation prefix"
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
      rel_dir="${dir#$SCRIPT_DIR/}"
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

if [ "$cmd" = "install-deps" ]; then
  json_file="${1:-libscript.json}"
  if [ ! -f "$json_file" ]; then
    echo "Error: $json_file not found." >&2
    exit 1
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

  deps=$("${LIBSCRIPT_ROOT_DIR:-.}/scripts/resolve_stack.sh" "$json_file" 2>/dev/null | jq -r '.selected[] | "\(.name) \(.version // "latest") \(.override // "")"' 2>/dev/null || true)
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
    while [ $# -gt 0 ]; do
      case "$1" in
        --layer|-l)
          layer_filter="$2"
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
      deps_list=$("${LIBSCRIPT_ROOT_DIR:-.}/scripts/resolve_stack.sh" "libscript.json" 2>/dev/null | jq -r '.selected[] | "\(.layer // "deps") \(.name) \(.version // "latest") \(.override // "")"' 2>/dev/null || true)
    fi

    if [ -n "$deps_list" ]; then
      gen_script=$(printf '%b\n' "$deps_list" | awk -v l_filter="$layer_filter" '

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
             print "echo '\''ADD ${" pkg_up "_URL} /opt/libscript_cache/" pkg "/" filename "'\'' >> \"$tmp_add\""
             print "echo '\''RUN ./libscript.sh install " pkg " ${" pkg_up "_VERSION}'\'' >> \"$tmp_run\""
             print "PREFIX=\"/opt/libscript/installed/" pkg "\" \"$0\" env \"" pkg "\" \"" ver "\" --format=docker | grep -vE \"^(ENV STACK=|ENV SCRIPT_NAME=)\" >> \"$tmp_run\" || true"
         } else {
             if (ver == "" || ver == "null") ver = "latest"
             print "echo '\''ENV " pkg_up "_VERSION=\"" ver "\"'\'' >> \"$tmp_env_add\""
             print "echo '\''RUN ./libscript.sh install " pkg " ${" pkg_up "_VERSION}'\'' >> \"$tmp_run\""
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
    echo "version: '3.8'"
    echo "services:"
    echo "  libscript-app:"
    echo "    build:"
    echo "      context: ."
    echo "      dockerfile: Dockerfile"
    if [ $# -gt 0 ]; then
      echo "    environment:"
      while [ $# -gt 0 ]; do
        pkg="$1"
        ver="${2:-latest}"
        PREFIX="/opt/libscript/installed/$pkg" "$0" env "$pkg" "$ver" --format=docker_compose | grep -vE '^(STACK=|SCRIPT_NAME=)' | sed 's/^/      - /g' || true
        if [ "$2" != "" ]; then shift 2; else shift; fi
      done
    elif [ -f "libscript.json" ] && command -v jq >/dev/null 2>&1; then
      deps=$(jq -r 'if .deps then .deps | to_entries[] | "\(.key) \(if (.value | type) == "string" then .value else (.value.version // "latest") end) \(if (.value | type) == "object" and .value.override then .value.override else "" end)" else empty end' "libscript.json" 2>/dev/null)
      if [ -n "$deps" ]; then
        echo "    environment:"
        echo "$deps" | while read -r pkg ver override; do
          if [ -n "$pkg" ]; then
            if [ "$ver" = "null" ]; then ver="latest"; fi
            if [ -n "$override" ] && [ "$override" != "null" ]; then
              pkg_up=$(echo "$pkg" | tr '[:lower:]' '[:upper:]' | tr '-' '_')
              echo "      - ${pkg_up}_URL=\"$override\""
            else
              PREFIX="/opt/libscript/installed/$pkg" "$0" env "$pkg" "$ver" --format=docker_compose | grep -vE '^(STACK=|SCRIPT_NAME=)' | sed 's/^/      - /g' || true
            fi
          fi
        done
      fi
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
      deps=$("${LIBSCRIPT_ROOT_DIR:-.}/scripts/resolve_stack.sh" "libscript.json" 2>/dev/null | jq -r '.selected[] | "\(.name) \(.version // "latest")"' 2>/dev/null || true)
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
  for item in $(echo "$selected" | tr -d '"'); do
    # Assuming user installs the default version for now, or parses it
    ./libscript.sh install "$item" latest
  done
else
  echo "Installation cancelled."
fi
EOF
    exit 0
  elif [ "$pkg_type" = "msi" ] || [ "$pkg_type" = "innosetup" ] || [ "$pkg_type" = "nsis" ]; then
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

    fi
  fi
