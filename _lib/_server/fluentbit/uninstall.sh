#!/bin/sh
set -e
if [ "${SCRIPT_NAME-}" ]; then
  this_file="${SCRIPT_NAME}"
else
  this_file="${0}"
fi
DIR=$(CDPATH='' cd -- "$(dirname -- "${this_file}")" && pwd)
LIBSCRIPT_ROOT_DIR="${LIBSCRIPT_ROOT_DIR:-$(d="${DIR}"; while [ ! -f "${d}/ROOT" ]; do d="$(dirname -- "${d}")"; done; printf '%s' "${d}")}"

SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}"'/_lib/_common/pkg_mgr.sh'
export SCRIPT_NAME
# shellcheck disable=SC1090
. "${SCRIPT_NAME}"

PURGE_DATA=0
for arg in "$@"; do
    case "$arg" in
        --purge-data) PURGE_DATA=1 ;;
    esac
done

# Optional: Disable services first if possible
if command -v systemctl >/dev/null 2>&1; then
    sudo systemctl stop fluent-bit || true
    sudo systemctl disable fluent-bit || true
elif command -v rc-service >/dev/null 2>&1; then
    sudo rc-service fluent-bit stop || true
    sudo rc-update del fluent-bit || true
elif command -v service >/dev/null 2>&1; then
    sudo service fluent-bit stop || true
fi

if [ -n "${PKG_MGR}" ]; then
    case "${PKG_MGR}" in
        apt-get)
            if [ "$PURGE_DATA" = "1" ]; then
                sudo apt-get purge -y fluent-bit
            else
                sudo apt-get remove -y fluent-bit
            fi
            ;;
        apk)     sudo apk del fluent-bit ;;
        brew)    brew uninstall fluent-bit ;;
        dnf)     sudo dnf remove -y fluent-bit ;;
        pacman)  sudo pacman -Rns --noconfirm fluent-bit ;;
        pkg)     sudo pkg delete -y fluent-bit ;;
        zypper)  sudo zypper remove -y fluent-bit ;;
        *)       echo "Manual uninstallation required for $PKG_MGR." ;;
    esac
fi

if [ -n "$INSTALLED_DIR" ] && [ -d "$INSTALLED_DIR" ]; then
  echo "Removing $INSTALLED_DIR..."
  rm -rf "$INSTALLED_DIR"
else
  echo "No local installation directory found for $PACKAGE_NAME at $INSTALLED_DIR."
fi

if [ "$PURGE_DATA" = "1" ]; then
    echo "Purging fluent-bit data and default configuration..."
    sudo rm -rf /etc/fluent-bit || true
    sudo rm -rf /var/log/fluent-bit || true
    
    if [ -d "$LIBSCRIPT_ROOT_DIR/data/fluentbit" ]; then
        rm -rf "$LIBSCRIPT_ROOT_DIR/data/fluentbit"
    fi
fi
