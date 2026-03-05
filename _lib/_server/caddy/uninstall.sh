#!/bin/sh
# shellcheck disable=SC2016,SC1090,SC1091,SC2034,SC2018,SC2019,SC2221,SC2222,SC2129,SC2209,SC2089,SC2090,SC2086,SC2154,SC2044,SC2181,SC2038,SC2155,SC2046,SC2002,SC1003,SC2295,SC2145


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
. "${SCRIPT_NAME}"

# Optional: Disable services first if possible
if command -v systemctl >/dev/null 2>&1; then
    sudo systemctl stop caddy || true
    sudo systemctl disable caddy || true
elif command -v rc-service >/dev/null 2>&1; then
    sudo rc-service caddy stop || true
    sudo rc-update del caddy || true
fi

if [ -n "${PKG_MGR}" ]; then
    case "${PKG_MGR}" in
        apt-get) sudo apt-get remove -y caddy ;;
        apk)     sudo apk del caddy ;;
        brew)    brew uninstall caddy ;;
        dnf)     sudo dnf remove -y caddy ;;
        pacman)  sudo pacman -Rns --noconfirm caddy ;;
        zypper)  sudo zypper remove -y caddy ;;
        *)       echo "Manual uninstallation required for $PKG_MGR." ;;
    esac
fi

if [ -n "$INSTALLED_DIR" ] && [ -d "$INSTALLED_DIR" ]; then
  echo "Removing $INSTALLED_DIR..."
  rm -rf "$INSTALLED_DIR"
else
  echo "No local installation directory found for $PACKAGE_NAME at $INSTALLED_DIR."
fi
