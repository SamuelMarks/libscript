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
      . "$SCRIPT_DIR/cli/commands/packaging/formats/pkg_deb.sh"
    elif [ "$pkg_type" = "rpm" ]; then
      . "$SCRIPT_DIR/cli/commands/packaging/formats/pkg_rpm.sh"
    elif [ "$pkg_type" = "apk" ]; then
      . "$SCRIPT_DIR/cli/commands/packaging/formats/pkg_apk.sh"
    elif [ "$pkg_type" = "txz" ]; then
      . "$SCRIPT_DIR/cli/commands/packaging/formats/pkg_txz.sh"
    fi
