#!/bin/sh
# ## Overview
# Syncs the libscript repository to a Vagrant environment or a generic SSH target.
# It automatically detects if a Vagrant environment is specified and uses its SSH config.
#
# ## Usage
#   ./sync_libscript_to_targets.sh [vagrant_dir | target_user@target_host target_path]
#
#   Example 1 (Vagrant auto-detect): ./sync_libscript_to_targets.sh vagrant/windows-11
#   Example 2 (Manual target):       ./sync_libscript_to_targets.sh vagrant@127.0.0.1 C:/libscript

set -feu

if [ "${SCRIPT_NAME-}" ]; then
  THIS_FILE="${SCRIPT_NAME}"
elif [ "${BASH_SOURCE-}" ]; then
  THIS_FILE="${BASH_SOURCE}"
elif [ "${ZSH_VERSION-}" ]; then
  # shellcheck disable=SC2296
  THIS_FILE="${(%):-%x}"
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
REPO_ROOT=$(cd -- "$SCRIPT_DIR/.." && pwd)

if [ $# -lt 1 ]; then
  echo "Usage: $0 [vagrant_dir | target_user@target_host target_path]"
  exit 1
fi

TARGET="$1"
SSH_OPTS=""

if [ -d "$TARGET" ] && [ -f "$TARGET/Vagrantfile" ]; then
    # It's a vagrant directory
    VAGRANT_DIR="$TARGET"
    echo "[INFO] Detected Vagrant environment at $VAGRANT_DIR"
    
    # Must run vagrant ssh-config in the directory
    cd "$VAGRANT_DIR"
    export LIBSCRIPT_TEST_TARGET="${LIBSCRIPT_TEST_TARGET:-default}"
    vagrant ssh-config > ssh_config 2>/dev/null || true
    if [ ! -s "ssh_config" ]; then
        echo "[ERROR] Failed to generate vagrant ssh-config. Is the machine running? LIBSCRIPT_TEST_TARGET=$LIBSCRIPT_TEST_TARGET"
        exit 1
    fi
    SSH_OPTS="-e 'ssh -F $VAGRANT_DIR/ssh_config'"
    
    # Extract Host from config (usually default or name of machine)
    VAGRANT_HOST=$(awk '/^Host / {print $2; exit}' ssh_config)
    
    # Determine OS to set the right path
    if grep -q "windows" "Vagrantfile"; then
        TARGET_HOST="$VAGRANT_HOST"
        # Windows rsync usually puts it in the home dir if we just use a relative path
        TARGET_PATH="libscript" 
        echo "[INFO] Detected Windows guest. Syncing to home directory relative path."
        
        # Ensure target directory exists natively
        vagrant ssh -c "if not exist libscript mkdir libscript" >/dev/null 2>&1 || true
    else
        TARGET_HOST="$VAGRANT_HOST"
        TARGET_PATH="libscript"
        vagrant ssh -c "mkdir -p ~/libscript" >/dev/null 2>&1 || true
    fi
    cd "$REPO_ROOT"
else
    # Manual target
    if [ $# -lt 2 ]; then
      echo "Usage: $0 <target_user@target_host> <target_path>"
      exit 1
    fi
    TARGET_HOST="$1"
    TARGET_PATH="$2"
fi

echo "[INFO] Syncing libscript from $REPO_ROOT to $TARGET_HOST:$TARGET_PATH..."

if [ -n "${VAGRANT_DIR:-}" ]; then
    rsync -avz -e "ssh -F $VAGRANT_DIR/ssh_config" --exclude '.git' --exclude 'build' --exclude 'tests_tmp' --exclude 'vagrant' "$REPO_ROOT/" "$TARGET_HOST:$TARGET_PATH"
else
    rsync -avz --exclude '.git' --exclude 'build' --exclude 'tests_tmp' --exclude 'vagrant' "$REPO_ROOT/" "$TARGET_HOST:$TARGET_PATH"
fi

echo "[PASS] Rsync completed successfully."
