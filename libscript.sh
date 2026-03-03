#!/bin/sh
set -e

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
  echo "  env <component> <version>   Print environment variables for a component"
  echo "  install-deps [file]         Install all dependencies defined in a JSON file (default: libscript.json)"
  echo "  package_as <format> [args]  Package libscript usage (e.g., docker, docker_compose)"
  echo "  <component> [OPTIONS...]    Invoke the CLI for a specific component"
  echo ""
  echo "Options:"
  echo "  --help, -h, /?              Show this extensive help text"
  echo "  --prefix=<dir>              Set local installation prefix
  --service-name=<name>       Set a custom service/daemon name
  --secrets=<dir|url>         Save generated secrets to a directory or OpenBao/Vault URL"
  echo "  --secrets=<dir|url>         Save generated secrets to a directory or OpenBao/Vault URL"
  echo ""
  echo "Examples:"
  echo "  $0 list"
  echo "  $0 search ruby"
  echo "  $0 ruby --help"
  echo "  $0 postgres --help"
  echo ""
  echo "You can specify components by their short name (e.g., 'ruby' instead of '_lib/_toolchain/ruby')."
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
  
  if [ -z "$LIBSCRIPT_SECRETS" ]; then
    json_secrets=$(jq -r 'if .secrets then .secrets else empty end' "$json_file" 2>/dev/null)
    if [ "$json_secrets" != "null" ] && [ -n "$json_secrets" ]; then
      export LIBSCRIPT_SECRETS="$json_secrets"
    else
      export LIBSCRIPT_SECRETS="${LIBSCRIPT_ROOT_DIR:-$SCRIPT_DIR}/secrets"
    fi
  fi

  deps=$(jq -r 'if .deps then .deps | to_entries[] | "\(.key) \(if (.value | type) == "string" then .value else (.value.version // "latest") end) \(if (.value | type) == "object" and .value.override then .value.override else "" end)" else empty end' "$json_file" 2>/dev/null)
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
  if [ "$pkg_type" = "docker" ]; then
    echo "FROM debian:bookworm-slim"
    echo "ENV LC_ALL=C.UTF-8 LANG=C.UTF-8"
    echo "COPY . /opt/libscript"
    echo "WORKDIR /opt/libscript"
    if [ $# -gt 0 ]; then
      while [ $# -gt 0 ]; do
        pkg="$1"
        ver="${2:-latest}"
        echo "RUN ./libscript.sh install $pkg $ver"
        PREFIX="/opt/libscript/installed/$pkg" "$0" env "$pkg" "$ver" --format=docker | grep -vE '^(ENV STACK=|ENV SCRIPT_NAME=)' || true
        if [ "$2" != "" ]; then shift 2; else shift; fi
      done
    elif [ -f "libscript.json" ] && command -v jq >/dev/null 2>&1; then
      deps=$(jq -r 'if .deps then .deps | to_entries[] | "\(.key) \(if (.value | type) == "string" then .value else (.value.version // "latest") end) \(if (.value | type) == "object" and .value.override then .value.override else "" end)" else empty end' "libscript.json" 2>/dev/null)
      echo "$deps" | while read -r pkg ver override; do
        if [ -n "$pkg" ]; then
          if [ "$ver" = "null" ]; then ver="latest"; fi
          if [ -n "$override" ] && [ "$override" != "null" ]; then
            pkg_up=$(echo "$pkg" | tr '[:lower:]' '[:upper:]' | tr '-' '_')
            echo "ENV ${pkg_up}_URL=\"$override\""
          else
            echo "RUN ./libscript.sh install $pkg $ver"
            PREFIX="/opt/libscript/installed/$pkg" "$0" env "$pkg" "$ver" --format=docker | grep -vE '^(ENV STACK=|ENV SCRIPT_NAME=)' || true
          fi
        fi
      done
    else
      echo "RUN ./install_gen.sh"
    fi
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
      deps=$(jq -r 'if .deps then .deps | to_entries[] | "\(.key) \(if (.value | type) == "string" then .value else (.value.version // "latest") end)" else empty end' "libscript.json" 2>/dev/null)
      echo "$deps" | while read -r pkg ver; do
        if [ -n "$pkg" ]; then
          if [ "$ver" = "null" ]; then ver="latest"; fi
          echo "  \"$pkg\" \"$ver\" ON \\"
        fi
      done
    else
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

    if [ "$pkg_type" = "msi" ]; then
      cat << EOF
<?xml version="1.0" encoding="UTF-8"?>
<Wix xmlns="http://schemas.microsoft.com/wix/2006/wi">
  <Product Id="*" Name="$APP_NAME" Language="1033" Version="$APP_VERSION" Manufacturer="$APP_PUBLISHER" UpgradeCode="$UPGRADE_CODE">
    <Package InstallerVersion="200" Compressed="yes" InstallScope="$install_scope" Description="$WELCOME_TEXT" />
    <Media Id="1" Cabinet="media1.cab" EmbedCab="yes" />
EOF
      if [ -n "$ICON_PATH" ]; then
        echo "    <Icon Id=\"AppIcon.ico\" SourceFile=\"$ICON_PATH\"/>"
        echo "    <Property Id=\"ARPPRODUCTICON\" Value=\"AppIcon.ico\" />"
      fi
      if [ -n "$APP_URL" ]; then
        echo "    <Property Id=\"ARPURLINFOABOUT\" Value=\"$APP_URL\" />"
      fi
      cat << EOF
    <Directory Id="TARGETDIR" Name="SourceDir">
      <Directory Id="ProgramFilesFolder">
        <Directory Id="INSTALLFOLDER" Name="$APP_NAME" />
      <Directory/>
    </Directory/>
    <Feature Id="MainFeature" Title="Main Feature" Level="1">
      <ComponentGroupRef Id="ProductComponents" />
    </Feature>
    
    <!-- Custom Actions for Installation -->
EOF
      if [ $# -gt 0 ]; then
        while [ $# -gt 0 ]; do
          pkg="$1"
          ver="${2:-latest}"
          echo "    <CustomAction Id=\"Install$pkg\" Directory=\"INSTALLFOLDER\" ExeCommand=\"cmd.exe /c libscript.cmd install $pkg $ver\" Execute=\"deferred\" Return=\"check\" Impersonate=\"no\" />"
          if [ "$2" != "" ]; then shift 2; else shift; fi
        done
      elif [ -f "libscript.json" ] && command -v jq >/dev/null 2>&1; then
        deps=$(jq -r 'if .deps then .deps | to_entries[] | "\(.key) \(if (.value | type) == "string" then .value else (.value.version // "latest") end)" else empty end' "libscript.json" 2>/dev/null)
        echo "$deps" | while read -r pkg ver; do
          if [ -n "$pkg" ]; then
            if [ "$ver" = "null" ]; then ver="latest"; fi
            echo "    <CustomAction Id=\"Install$pkg\" Directory=\"INSTALLFOLDER\" ExeCommand=\"cmd.exe /c libscript.cmd install $pkg $ver\" Execute=\"deferred\" Return=\"check\" Impersonate=\"no\" />"
          fi
        done
      fi
      cat << 'EOF'
    <InstallExecuteSequence>
      <Custom Action="InstallMain" After="InstallFiles">NOT Installed</Custom>
    </InstallExecuteSequence>
  </Product>
  <Fragment>
    <ComponentGroup Id="ProductComponents" Directory="INSTALLFOLDER">
      <!-- Add your files here -->
    </ComponentGroup>
  </Fragment>
</Wix>
EOF
      exit 0
    elif [ "$pkg_type" = "innosetup" ]; then
      cat << EOF
[Setup]
AppName=$APP_NAME
AppVersion=$APP_VERSION
AppPublisher=$APP_PUBLISHER
EOF
      if [ -n "$APP_URL" ]; then
        echo "AppPublisherURL=$APP_URL"
        echo "AppSupportURL=$APP_URL"
        echo "AppUpdatesURL=$APP_URL"
      fi
      cat << EOF
DefaultDirName={autopf}\\$APP_NAME
PrivilegesRequired=$inno_priv
OutputDir=.
OutputBaseFilename=$OUT_FILE
EOF
      if [ "$UPGRADE_CODE" != "PUT-GUID-HERE" ]; then echo "AppId=$UPGRADE_CODE"; fi
      if [ -n "$ICON_PATH" ]; then echo "SetupIconFile=$ICON_PATH"; fi
      if [ -n "$IMAGE_PATH" ]; then echo "WizardImageFile=$IMAGE_PATH"; fi
      if [ -n "$LICENSE_PATH" ]; then echo "LicenseFile=$LICENSE_PATH"; fi
      cat << EOF

[Run]
EOF
      if [ $# -gt 0 ]; then
        while [ $# -gt 0 ]; do
          pkg="$1"
          ver="${2:-latest}"
          echo "Filename: \"cmd.exe\"; Parameters: \"/c libscript.cmd install $pkg $ver\"; Flags: runhidden"
          if [ "$2" != "" ]; then shift 2; else shift; fi
        done
      elif [ -f "libscript.json" ] && command -v jq >/dev/null 2>&1; then
        deps=$(jq -r 'if .deps then .deps | to_entries[] | "\(.key) \(if (.value | type) == "string" then .value else (.value.version // "latest") end)" else empty end' "libscript.json" 2>/dev/null)
        echo "$deps" | while read -r pkg ver; do
          if [ -n "$pkg" ]; then
            if [ "$ver" = "null" ]; then ver="latest"; fi
            echo "Filename: \"cmd.exe\"; Parameters: \"/c libscript.cmd install $pkg $ver\"; Flags: runhidden"
          fi
        done
      fi
      exit 0
    elif [ "$pkg_type" = "nsis" ]; then
      cat << EOF
!define APP_NAME "$APP_NAME"
!define APP_VERSION "$APP_VERSION"
!define APP_PUBLISHER "$APP_PUBLISHER"
Name "$APP_NAME $APP_VERSION"
OutFile "${OUT_FILE}.exe"
InstallDir "\$PROGRAMFILES\\$APP_NAME"
RequestExecutionLevel $nsis_admin

VIProductVersion "$APP_VERSION"
VIAddVersionKey "ProductName" "$APP_NAME"
VIAddVersionKey "CompanyName" "$APP_PUBLISHER"
VIAddVersionKey "FileDescription" "$WELCOME_TEXT"
VIAddVersionKey "FileVersion" "$APP_VERSION"
EOF
      if [ -n "$ICON_PATH" ]; then echo "Icon \"$ICON_PATH\""; fi
      echo ""
      if [ -n "$LICENSE_PATH" ]; then echo "Page license \"\" \"$LICENSE_PATH\""; fi
      echo "Page instfiles"
      echo ""
      echo "Section \"MainSection\" SEC01"
      if [ $# -gt 0 ]; then
        while [ $# -gt 0 ]; do
          pkg="$1"
          ver="${2:-latest}"
          echo "  ExecWait 'cmd.exe /c libscript.cmd install $pkg $ver'"
          if [ "$2" != "" ]; then shift 2; else shift; fi
        done
      elif [ -f "libscript.json" ] && command -v jq >/dev/null 2>&1; then
        deps=$(jq -r 'if .deps then .deps | to_entries[] | "\(.key) \(if (.value | type) == "string" then .value else (.value.version // "latest") end)" else empty end' "libscript.json" 2>/dev/null)
        echo "$deps" | while read -r pkg ver; do
          if [ -n "$pkg" ]; then
            if [ "$ver" = "null" ]; then ver="latest"; fi
            echo "  ExecWait 'cmd.exe /c libscript.cmd install $pkg $ver'"
          fi
        done
      fi
      echo "SectionEnd"
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
  remove|uninstall|status|test|ls|ls-remote)
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
  matches=$(find_components | grep -i "$action_pkg" || true)
  count=$(echo "$matches" | grep -c . || true)
  if [ "$count" -eq 0 ]; then
    echo "Error: Unknown component '$action_pkg'."
    exit 1
  elif [ "$count" -eq 1 ]; then
    target="$SCRIPT_DIR/$matches"
  else
    exact_match=$(echo "$matches" | grep "/$action_pkg$" || true)
    exact_count=$(echo "$exact_match" | grep -c . || true)
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
