#!/bin/sh
# ## Overview
# Smoke test for dos-pktdrv verifying T2 exit-code-2 rejection on `use`, 2x idempotency,
# and 16-bit execution of PCNTPKT.COM via kvikdos.
#
# ## Usage
# ./_lib/networking/dos-pktdrv/test.sh

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
: "${LIBSCRIPT_ROOT_DIR:=$(d="$SCRIPT_DIR"; while [ ! -f "$d/libscript.sh" ]; do n="${d%/*}"; [ -z "$n" ] && n="/"; [ "$d" = "$n" ] && break; d="$n"; done; printf '%s\n' "$d")}"

set +e
STACK='' "${SCRIPT_DIR}/cli.sh" use latest >/dev/null 2>&1
_use_rc=$?
set -e
[ "${_use_rc}" -eq 2 ]

STACK='' "${SCRIPT_DIR}/cli.sh" install latest >/dev/null
STACK='' "${SCRIPT_DIR}/cli.sh" install latest >/dev/null
STACK='' "${LIBSCRIPT_ROOT_DIR}/libscript.sh" install kvikdos latest >/dev/null

for _kvd_b in "${LIBSCRIPT_HOME:-${HOME:-/root}/.libscript}/kvikdos/default/bin" "${LIBSCRIPT_HOME:-${HOME:-/root}/.libscript}/kvikdos/latest/bin"; do
  [ -d "$_kvd_b" ] && PATH="${_kvd_b}:${PATH}"
done
export PATH

_pkt_dir="${LIBSCRIPT_HOME:-${HOME:-/root}/.libscript}/dos-pktdrv/default/dos"
[ -f "${_pkt_dir}/FDAPM.COM" ]
[ -f "${_pkt_dir}/PCNTPKT.COM" ]
[ -f "${_pkt_dir}/SHSUCDX.COM" ]
kvikdos "${_pkt_dir}/PCNTPKT.COM" | LC_ALL=C tr -d '\r' | grep -q 'PCNTPKT'
printf '[PASS] dos-pktdrv T2 contract and 8086 driver staging verified.\n'
