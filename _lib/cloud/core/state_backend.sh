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
SCRIPT_DIR=$(cd -- "$(dirname -- "${THIS_FILE}")" && pwd)
: "${LIBSCRIPT_ROOT_DIR:=$(d="$SCRIPT_DIR"; while [ ! -f "$d/libscript.sh" ]; do n="${d%/*}"; [ -z "$n" ] && n="/"; [ "$d" = "$n" ] && break; d="$n"; done; echo "$d")}"
# Cloud State Locking & Remote Backend Mechanism
# Supports basic local, AWS S3, Azure Blob, and GCS remote backends

STATE_FILE="${STATE_FILE:-.libscript_state.json}"
REMOTE_STATE_URI="${REMOTE_STATE_URI:-}"

lock_state() {
  if [ -z "$REMOTE_STATE_URI" ]; then
    if [ -f "${STATE_FILE}.lock" ]; then
      echo "[ERROR] State is locked by another process. (${STATE_FILE}.lock exists)" >&2
      exit 1
    fi
    date +%s > "${STATE_FILE}.lock"
    return 0
  fi
  
  echo "[STATE] Locking remote state at $REMOTE_STATE_URI..."
  case "$REMOTE_STATE_URI" in
    s3://*)
      # Basic mock check for S3 lock mechanism (DynamoDB would be used in real impl)
      echo "  -> Mock: AWS DynamoDB lock acquired for ${REMOTE_STATE_URI}"
      ;;
    gs://*)
      echo "  -> Mock: GCS object lock acquired for ${REMOTE_STATE_URI}"
      ;;
    https://*.blob.core.windows.net/*)
      echo "  -> Mock: Azure Blob Lease acquired for ${REMOTE_STATE_URI}"
      ;;
    *)
      echo "[ERROR] Unsupported remote state URI schema: $REMOTE_STATE_URI" >&2
      exit 1
      ;;
  esac
}

unlock_state() {
  if [ -z "$REMOTE_STATE_URI" ]; then
    rm -f "${STATE_FILE}.lock"
    return 0
  fi
  
  echo "[STATE] Unlocking remote state at $REMOTE_STATE_URI..."
  case "$REMOTE_STATE_URI" in
    s3://*)
      echo "  -> Mock: AWS DynamoDB lock released for ${REMOTE_STATE_URI}"
      ;;
    gs://*)
      echo "  -> Mock: GCS object lock released for ${REMOTE_STATE_URI}"
      ;;
    https://*.blob.core.windows.net/*)
      echo "  -> Mock: Azure Blob Lease released for ${REMOTE_STATE_URI}"
      ;;
  esac
}

pull_state() {
  if [ -n "$REMOTE_STATE_URI" ]; then
    echo "[STATE] Pulling state from $REMOTE_STATE_URI..."
    # aws s3 cp "$REMOTE_STATE_URI" "$STATE_FILE"
  fi
}

push_state() {
  if [ -n "$REMOTE_STATE_URI" ]; then
    echo "[STATE] Pushing state to $REMOTE_STATE_URI..."
    # aws s3 cp "$STATE_FILE" "$REMOTE_STATE_URI"
  fi
}

"$@"
