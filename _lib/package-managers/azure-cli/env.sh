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
if command -v az >/dev/null 2>&1; then
    echo "Azure CLI is already installed."
    exit 0

# Load caching downloader
SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
. "$LIBSCRIPT_ROOT_DIR/_lib/_common/pkg_mgr.sh"

OS=$(uname -s)
PACKAGE_NAME="azure-cli"
export PACKAGE_NAME

case "$OS" in
    Linux)
        echo "Installing Azure CLI on Linux..."
        libscript_download "https://aka.ms/InstallAzureCLIDeb" "install_azure_cli.sh"
        sudo bash install_azure_cli.sh
        rm install_azure_cli.sh
        ;;
    Darwin)
        echo "Installing Azure CLI on macOS..."
        if command -v brew >/dev/null 2>&1; then
            brew install azure-cli
        else
            echo "Homebrew is required for Azure CLI installation on macOS."
            exit 1
        fi
    CYGWIN*|MINGW*|MSYS*)
        echo "Installing Azure CLI on Windows..."
        libscript_download "https://aka.ms/InstallAzureCLIWIn" "AzureCLI.msi"
        msiexec.exe /i AzureCLI.msi /qn /norestart
        rm AzureCLI.msi
    *)
        echo "Unsupported OS: $OS"
        exit 1
esac
