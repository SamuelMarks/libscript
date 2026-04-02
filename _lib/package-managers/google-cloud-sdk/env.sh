#!/bin/sh
set -e

if command -v gcloud >/dev/null 2>&1; then
    echo "Google Cloud SDK is already installed."
    exit 0

# Load caching downloader
SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
. "$LIBSCRIPT_ROOT_DIR/_lib/_common/pkg_mgr.sh"

OS=$(uname -s)
PACKAGE_NAME="google-cloud-sdk"
export PACKAGE_NAME

case "$OS" in
    Linux)
        echo "Installing Google Cloud SDK on Linux..."
        libscript_download "https://sdk.cloud.google.com" "install_gcloud.sh"
        bash install_gcloud.sh --disable-prompts
        rm install_gcloud.sh
        ;;
    Darwin)
        echo "Installing Google Cloud SDK on macOS..."
        if command -v brew >/dev/null 2>&1; then
            brew install --cask google-cloud-sdk
        else
            libscript_download "https://sdk.cloud.google.com" "install_gcloud.sh"
            bash install_gcloud.sh --disable-prompts
            rm install_gcloud.sh
        fi
    CYGWIN*|MINGW*|MSYS*)
        echo "Installing Google Cloud SDK on Windows..."
        libscript_download "https://dl.google.com/dl/cloudsdk/channels/rapid/google-cloud-sdk-windows-x86_64-bundled-python.zip" "gcloud.zip"
        unzip gcloud.zip
        ./google-cloud-sdk/install.bat --quiet
        rm gcloud.zip
    *)
        echo "Unsupported OS: $OS"
        exit 1
esac
