#!/bin/sh
# ## Overview
# Runs CI tests for a given LibScript component on Unix platforms.
# It skips excluded components for specific OS environments and ensures
# that the component's setup and test scripts are executed in a clean state.
# 
# ## Usage
# ./run_test_component.sh <component_path> <os_name>

set -feu
# shellcheck disable=SC2296,SC3028,SC3040,SC3054
if [ "${SCRIPT_NAME-}" ]; then
  THIS_FILE="${SCRIPT_NAME}"
elif [ "${BASH_SOURCE-}" ]; then
  THIS_FILE="${BASH_SOURCE[0]}"
  set -o pipefail
elif [ "${ZSH_VERSION-}" ]; then
  THIS_FILE="${(%):-%x}"
  set -o pipefail
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

COMPONENT="$1"
OS_NAME="$2"

echo "========================================"
echo "Testing $COMPONENT"
echo "========================================"

EXCLUDED=0
if [ "$OS_NAME" = "macos-latest" ] && [ "$COMPONENT" = "_lib/package-managers/swupd" ]; then EXCLUDED=1; fi
if [ "$OS_NAME" = "ubuntu-latest" ] && [ "$COMPONENT" = "_lib/package-managers/mas" ]; then EXCLUDED=1; fi
if [ "$OS_NAME" = "macos-latest" ] && [ "$COMPONENT" = "_lib/package-managers/guix" ]; then EXCLUDED=1; fi
if [ "$OS_NAME" = "macos-latest" ] && [ "$COMPONENT" = "_lib/package-managers/pkg" ]; then EXCLUDED=1; fi
if [ "$OS_NAME" = "ubuntu-latest" ] && [ "$COMPONENT" = "_lib/package-managers/pkg" ]; then EXCLUDED=1; fi
if [ "$OS_NAME" = "macos-latest" ] && [ "$COMPONENT" = "_lib/package-managers/xbps" ]; then EXCLUDED=1; fi
if [ "$OS_NAME" = "ubuntu-latest" ] && [ "$COMPONENT" = "_lib/package-managers/xbps" ]; then EXCLUDED=1; fi
if [ "$OS_NAME" = "macos-latest" ] && [ "$COMPONENT" = "_lib/package-managers/emerge" ]; then EXCLUDED=1; fi
if [ "$OS_NAME" = "ubuntu-latest" ] && [ "$COMPONENT" = "_lib/package-managers/emerge" ]; then EXCLUDED=1; fi
if [ "$OS_NAME" = "ubuntu-latest" ] && [ "$COMPONENT" = "_lib/caches/valkey" ]; then EXCLUDED=1; fi
if [ "$OS_NAME" = "macos-latest" ] && [ "$COMPONENT" = "_lib/package-managers/apk" ]; then EXCLUDED=1; fi
if [ "$OS_NAME" = "macos-latest" ] && [ "$COMPONENT" = "_lib/package-managers/apt" ]; then EXCLUDED=1; fi
if [ "$OS_NAME" = "macos-latest" ] && [ "$COMPONENT" = "_lib/package-managers/dnf" ]; then EXCLUDED=1; fi
if [ "$OS_NAME" = "macos-latest" ] && [ "$COMPONENT" = "_lib/package-managers/pacman" ]; then EXCLUDED=1; fi
if [ "$OS_NAME" = "macos-latest" ] && [ "$COMPONENT" = "_lib/package-managers/zypper" ]; then EXCLUDED=1; fi
if [ "$OS_NAME" = "macos-latest" ] && [ "$COMPONENT" = "_lib/package-managers/flatpak" ]; then EXCLUDED=1; fi
if [ "$OS_NAME" = "macos-latest" ] && [ "$COMPONENT" = "_lib/package-managers/snap" ]; then EXCLUDED=1; fi
if [ "$OS_NAME" = "ubuntu-latest" ] && [ "$COMPONENT" = "_lib/package-managers/macports" ]; then EXCLUDED=1; fi
if [ "$OS_NAME" = "macos-latest" ] && [ "$COMPONENT" = "_lib/utilities/busybox" ]; then EXCLUDED=1; fi
if [ "$OS_NAME" = "ubuntu-latest" ] && [ "$COMPONENT" = "_lib/web-servers/iis" ]; then EXCLUDED=1; fi
if [ "$OS_NAME" = "macos-latest" ] && [ "$COMPONENT" = "_lib/web-servers/iis" ]; then EXCLUDED=1; fi
if [ "$OS_NAME" = "ubuntu-latest" ] && [ "$COMPONENT" = "_lib/orchestration/kubernetes-thw" ]; then EXCLUDED=1; fi
if [ "$OS_NAME" = "macos-latest" ] && [ "$COMPONENT" = "_lib/orchestration/kubernetes-k0s" ]; then EXCLUDED=1; fi
if [ "$OS_NAME" = "macos-latest" ] && [ "$COMPONENT" = "_lib/orchestration/kubernetes-thw" ]; then EXCLUDED=1; fi
if [ "$OS_NAME" = "macos-latest" ] && [ "$COMPONENT" = "_lib/languages/rust" ]; then EXCLUDED=1; fi
if [ "$OS_NAME" = "ubuntu-latest" ] && [ "$COMPONENT" = "_lib/security/openbao" ]; then EXCLUDED=1; fi
if [ "$OS_NAME" = "ubuntu-latest" ] && [ "$COMPONENT" = "stacks/cms/wordpress" ]; then EXCLUDED=1; fi
if [ "$OS_NAME" = "macos-latest" ] && [ "$COMPONENT" = "stacks/cms/wordpress" ]; then EXCLUDED=1; fi
if [ "$OS_NAME" = "macos-latest" ] && [ "$COMPONENT" = "stacks/scaffolds/serve-actix-diesel-auth-scaffold" ]; then EXCLUDED=1; fi
if [ "$OS_NAME" = "macos-latest" ] && [ "$COMPONENT" = "_lib/orchestration/docker" ]; then EXCLUDED=1; fi
if [ "$OS_NAME" = "macos-latest" ] && [ "$COMPONENT" = "_lib/databases/mongodb" ]; then EXCLUDED=1; fi
if [ "$OS_NAME" = "ubuntu-latest" ] && [ "$COMPONENT" = "_lib/databases/mongodb" ]; then EXCLUDED=1; fi

if [ "$EXCLUDED" = "1" ]; then
    echo "Skipping $COMPONENT on $OS_NAME (excluded)"
    exit 0
fi

cd "${LIBSCRIPT_ROOT_DIR}/$COMPONENT" || exit 1

if [ -f "env.sh" ]; then
    SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/$COMPONENT/env.sh"
    export SCRIPT_NAME
    . ./env.sh
fi

if [ -f ./setup.sh ]; then
    sh ./setup.sh || exit 1
elif [ -f ./setup_generic.sh ]; then
    sh ./setup_generic.sh || exit 1
fi

if [ -x ./test.sh ]; then
    ./test.sh || exit 1
else
    echo "No test.sh found"
fi

exit 0
