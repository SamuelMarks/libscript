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
if command -v aws >/dev/null 2>&1; then
    log_info "AWS CLI is already installed."
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
        log_info "Installing AWS CLI on Linux..."
        libscript_download "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" "awscliv2.zip"
        unzip awscliv2.zip
        sudo ./aws/install
        rm -rf aws awscliv2.zip
        ;;
    Darwin)
        log_info "Installing AWS CLI on macOS..."
        if command -v brew >/dev/null 2>&1; then
            brew install awscli
        else
            libscript_download "https://awscli.amazonaws.com/AWSCLIV2.pkg" "AWSCLIV2.pkg"
            sudo installer -pkg AWSCLIV2.pkg -target /
            rm AWSCLIV2.pkg
        fi
        ;;
    CYGWIN*|MINGW*|MSYS*)
        log_info "Installing AWS CLI on Windows..."
        libscript_download "https://awscli.amazonaws.com/AWSCLIV2.msi" "AWSCLIV2.msi"
        msiexec.exe /i AWSCLIV2.msi /qn /norestart
        rm AWSCLIV2.msi
        ;;
    *)
        log_info "Unsupported OS: $OS"
        exit 1
        ;;
esac
