#!/bin/sh
set -e

if command -v aws >/dev/null 2>&1; then
    echo "AWS CLI is already installed."
    exit 0

# Load caching downloader
SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
. "$LIBSCRIPT_ROOT_DIR/_lib/_common/pkg_mgr.sh"

OS=$(uname -s)
PACKAGE_NAME="awscli"
export PACKAGE_NAME

case "$OS" in
    Linux)
        echo "Installing AWS CLI on Linux..."
        libscript_download "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" "awscliv2.zip"
        unzip awscliv2.zip
        sudo ./aws/install
        rm -rf aws awscliv2.zip
        ;;
    Darwin)
        echo "Installing AWS CLI on macOS..."
        if command -v brew >/dev/null 2>&1; then
            brew install awscli
        else
            libscript_download "https://awscli.amazonaws.com/AWSCLIV2.pkg" "AWSCLIV2.pkg"
            sudo installer -pkg AWSCLIV2.pkg -target /
            rm AWSCLIV2.pkg
        fi
    CYGWIN*|MINGW*|MSYS*)
        echo "Installing AWS CLI on Windows..."
        libscript_download "https://awscli.amazonaws.com/AWSCLIV2.msi" "AWSCLIV2.msi"
        msiexec.exe /i AWSCLIV2.msi /qn /norestart
        rm AWSCLIV2.msi
    *)
        echo "Unsupported OS: $OS"
        exit 1
esac
