#!/bin/sh
# ## Overview
# Verifies Alsa-Ucm-Conf functionality.
#
# ## Usage
# ./test.sh

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
export STACK="${STACK:-}${THIS_FILE}:"
SCRIPT_DIR=$(cd -- "$(dirname -- "${THIS_FILE}")" && pwd)
: "${LIBSCRIPT_ROOT_DIR:=$(d="$SCRIPT_DIR"; while [ ! -f "$d/libscript.sh" ]; do n="${d%/*}"; [ -z "$n" ] && n="/"; [ "$d" = "$n" ] && break; d="$n"; done; printf '%s\n' "$d")}"

if [ -d /usr/share/alsa/ucm2 ] || [ -d /usr/share/alsa/ucm ] || [ -f /usr/share/alsa/ucm2/ucm.conf ]; then
  exit 0
fi

if command -v apk >/dev/null 2>&1 && apk info -e alsa-ucm-conf >/dev/null 2>&1; then
  exit 0
fi

if command -v dpkg-query >/dev/null 2>&1 && dpkg-query -W -f='${Status}\n' alsa-ucm-conf 2>/dev/null | grep -q 'install ok installed'; then
  exit 0
fi

if command -v rpm >/dev/null 2>&1 && (rpm -q alsa-ucm >/dev/null 2>&1 || rpm -q alsa-ucm-conf >/dev/null 2>&1); then
  exit 0
fi

exit 1
