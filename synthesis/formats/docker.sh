#!/bin/sh
# ## Overview
# Dual-modality container export driver for Docker and Docker Compose.
# Generates online layer-cached or completely air-gapped offline Dockerfile
# and multi-service docker-compose.yml configurations.
# ## Usage
# Run `docker.sh [--compose] [--offline|--online] [args...]`

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
    if [ "${LIBSCRIPT_DEBUG:-0}" = '1' ]; then printf '[STOP]     processing "%s"\n' "${THIS_FILE}" >&2; fi
    if (return 0 2>/dev/null); then return; else exit 0; fi ;;
  *) if [ "${LIBSCRIPT_DEBUG:-0}" = '1' ]; then printf '[CONTINUE] processing "%s"\n' "${THIS_FILE}" >&2; fi ;;
esac
export STACK="${STACK:-}${THIS_FILE}"':'
SCRIPT_DIR=$(cd -- "$(dirname -- "${THIS_FILE}")" && pwd)
: "${LIBSCRIPT_ROOT_DIR:=$(d="$SCRIPT_DIR"; while [ ! -f "$d/libscript.sh" ]; do n="${d%/*}"; [ -z "$n" ] && n="/"; [ "$d" = "$n" ] && break; d="$n"; done; printf '%s\n' "$d")}"
export LIBSCRIPT_ROOT_DIR

IS_COMPOSE=0
for arg in "$@"; do
  if [ "$arg" = "--compose" ]; then
    IS_COMPOSE=1
    break
  fi
done

if [ "$IS_COMPOSE" -eq 1 ]; then
  exec "${LIBSCRIPT_ROOT_DIR}/synthesis/formats/docker_compose.sh" "$@"
fi

base_image='debian:bookworm-slim'
is_offline=0
[ "${LIBSCRIPT_OFFLINE:-0}" = '1' ] && is_offline=1

while [ $# -gt 0 ]; do
  case "$1" in
    --help|-h|'/?'|'-?')
      printf 'Usage: %s [--compose] [--offline|--online] [--base <image>] [<component> [version] ...]\n' "${THIS_FILE}"
      exit 0
      ;;
    --offline|-o) is_offline=1; shift ;;
    --online) is_offline=0; shift ;;
    --base|--base-image)
      base_image="${2:-debian:bookworm-slim}"
      [ "$base_image" = 'debian' ] && base_image='debian:bookworm-slim'
      [ "$base_image" = 'alpine' ] && base_image='alpine:latest'
      shift 2
      ;;
    *) break ;;
  esac
done

printf 'FROM %s\n' "$base_image"
printf '%s\n' 'ARG TARGETOS=linux'
printf '%s\n' 'ARG TARGETARCH=amd64'
printf '%s\n' 'ENV LC_ALL=C.UTF-8 LANG=C.UTF-8'
printf '%s\n' 'ENV LIBSCRIPT_ROOT_DIR="/opt/libscript"'
printf '%s\n' 'ENV LIBSCRIPT_BUILD_DIR="/opt/libscript_build"'
printf '%s\n' 'ENV LIBSCRIPT_DATA_DIR="/opt/libscript_data"'
printf '%s\n' 'ENV LIBSCRIPT_CACHE_DIR="/opt/libscript_cache"'
if [ "$is_offline" -eq 1 ]; then
  printf '%s\n' 'ENV LIBSCRIPT_OFFLINE="1"'
fi
printf '%s\n' 'COPY . /opt/libscript'
printf '%s\n' 'WORKDIR /opt/libscript'

if [ $# -gt 0 ]; then
  while [ $# -gt 0 ]; do
    pkg="$1"
    ver="${2:-latest}"
    pkg_up=$(printf '%s' "$pkg" | tr '[:lower:]-' '[:upper:]_')
    printf 'ENV %s_VERSION="%s"\n' "$pkg_up" "$ver"
    if [ "$is_offline" -eq 1 ]; then
      printf 'RUN ./libscript.sh install %s "%s" --offline\n' "$pkg" "$ver"
    else
      printf 'RUN ./libscript.sh install %s "%s"\n' "$pkg" "$ver"
    fi
    if [ $# -ge 2 ]; then shift 2; else shift; fi
  done
elif [ -f 'libscript.json' ] && command -v jq >/dev/null 2>&1; then
  "${LIBSCRIPT_ROOT_DIR}/engine/solver/resolve_stack.sh" 'libscript.json' 2>/dev/null \
    | jq -r '.selected[]? | "\(.name) \(.version // "latest")"' 2>/dev/null \
    | while read -r pkg ver; do
        [ -n "$pkg" ] || continue
        if [ "$is_offline" -eq 1 ]; then
          printf 'RUN ./libscript.sh install %s "%s" --offline\n' "$pkg" "$ver"
        else
          printf 'RUN ./libscript.sh install %s "%s"\n' "$pkg" "$ver"
        fi
      done
fi
