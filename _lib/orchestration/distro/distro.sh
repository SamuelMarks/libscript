#!/bin/sh
# ## Overview
# Unified distribution synthesis entrypoint for LibScript, dispatching to
# Debian, Alpine, and Red Hat style OS synthesis pipelines.
#
# ## Usage
# ./_lib/orchestration/distro/distro.sh <build-debian | build-alpine | build-redhat> [options...]

set -feu

if [ "${SCRIPT_NAME-}" ]; then
  THIS_FILE="${SCRIPT_NAME}"
elif [ "${BASH_SOURCE-}" ]; then
  THIS_FILE="${BASH_SOURCE}"
elif [ "${ZSH_VERSION-}" ]; then
  # libscript-allow-eval
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
: "${LIBSCRIPT_ROOT_DIR:=$(d="$SCRIPT_DIR"; while [ ! -f "$d/libscript.sh" ]; do n="${d%/*}"; [ -z "$n" ] && n="/"; [ "$d" = "$n" ] && break; d="$n"; done; printf '%s\n' "$d")}"
export LIBSCRIPT_ROOT_DIR

ACTION="${1:-help}"
if [ $# -gt 0 ]; then shift; fi

case "$ACTION" in
  build-debian|debian)
    exec "${LIBSCRIPT_ROOT_DIR}/_lib/orchestration/distro/build_debian.sh" "$@"
    ;;
  build-alpine|alpine)
    exec "${LIBSCRIPT_ROOT_DIR}/_lib/orchestration/distro/build_alpine.sh" "$@"
    ;;
  build-redhat|redhat)
    exec "${LIBSCRIPT_ROOT_DIR}/_lib/orchestration/distro/build_redhat.sh" "$@"
    ;;
  *)
    printf 'Usage: %s <build-debian | build-alpine | build-redhat> [options...]\n' "${0##*/}"
    printf 'Commands:\n'
    printf '  build-debian   Synthesizes Debian-style distribution (.deb, apt, dpkg)\n'
    printf '  build-alpine   Synthesizes Alpine-style distribution (.apk, apk-tools, openrc)\n'
    printf '  build-redhat   Synthesizes Red Hat-style distribution (.rpm, dnf, rpmbuild)\n'
    exit 1
    ;;
esac
