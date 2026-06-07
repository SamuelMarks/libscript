#!/bin/sh

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
    printf '[STOP]     processing "%s"\n' "${THIS_FILE}"
    if (return 0 2>/dev/null); then return; else exit 0; fi ;;
  *) printf '[CONTINUE] processing "%s"\n' "${THIS_FILE}" ;;
esac
export STACK="${STACK:-}${THIS_FILE}"':'
if command -v az >/dev/null 2>&1; then
    log_info "Azure CLI is already installed."
    exit 0
fi

# Load caching downloader
SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
. "$LIBSCRIPT_ROOT_DIR/_lib/_common/pkg_mgr.sh"

OS=$(uname -s)
: "${PACKAGE_NAME:=$(basename "$SCRIPT_DIR")}"
export PACKAGE_NAME

case "$OS" in
    Linux)
        log_info "Installing Azure CLI on Linux..."
        libscript_download "https://aka.ms/InstallAzureCLIDeb" "install_azure_cli.sh"
        sudo bash install_azure_cli.sh
        rm install_azure_cli.sh
        ;;
    Darwin)
        log_info "Installing Azure CLI on macOS..."
        if command -v brew >/dev/null 2>&1; then
            brew install azure-cli
        else
            log_info "Homebrew is required for Azure CLI installation on macOS."
            exit 1
        fi
        ;;
    CYGWIN*|MINGW*|MSYS*)
        log_info "Installing Azure CLI on Windows..."
        libscript_download "https://aka.ms/InstallAzureCLIWIn" "AzureCLI.msi"
        msiexec.exe /i AzureCLI.msi /qn /norestart
        rm AzureCLI.msi
        ;;
    *)
        log_info "Unsupported OS: $OS"
        exit 1
        ;;
esac
