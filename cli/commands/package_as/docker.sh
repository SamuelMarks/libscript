#!/bin/sh
# ## Overview
# Dual-modality container export driver for Docker and Docker Compose.
# Generates online layer-cached or completely air-gapped offline Dockerfile
# and multi-service docker-compose.yml configurations.
#
# ## Usage
# Run `docker.sh [--compose] [--offline|--online] [args...]`

set -feu

if [ "${SCRIPT_NAME-}" ]; then
  THIS_FILE="${SCRIPT_NAME}"
elif [ "${BASH_SOURCE-}" ]; then
  THIS_FILE="${BASH_SOURCE}"
else
  THIS_FILE="${0}"
fi

case "${STACK+x}" in
  *':'"${THIS_FILE}"':'*)
    printf '[STOP]     processing "%s"
' "${THIS_FILE}" >&2
    if (return 0 2>/dev/null); then return; else exit 0; fi ;;
  *) printf '[CONTINUE] processing "%s"
' "${THIS_FILE}" >&2 ;;
esac
export STACK="${STACK:-}${THIS_FILE}"':'
SCRIPT_DIR=$(cd -- "$(dirname -- "${THIS_FILE}")" && pwd)
: "${LIBSCRIPT_ROOT_DIR:=$(d="$SCRIPT_DIR"; while [ ! -f "$d/libscript.sh" ]; do n="${d%/*}"; [ -z "$n" ] && n="/"; [ "$d" = "$n" ] && break; d="$n"; done; printf '%s
' "$d")}"
export LIBSCRIPT_ROOT_DIR

IS_COMPOSE=0
for arg in "$@"; do
  if [ "$arg" = "--compose" ]; then
    IS_COMPOSE=1
    break
  fi
done

if [ "$IS_COMPOSE" -eq 1 ]; then
  exec "${LIBSCRIPT_ROOT_DIR}/cli/commands/packaging/formats/pkg_docker_compose.sh" "$@"
else
  exec "${LIBSCRIPT_ROOT_DIR}/cli/commands/packaging/formats/pkg_docker.sh" "$@"
fi
