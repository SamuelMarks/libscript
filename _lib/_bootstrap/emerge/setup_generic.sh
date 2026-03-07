#!/bin/sh
set -feu
if [ "${SCRIPT_NAME-}" ]; then
  this_file="${SCRIPT_NAME}"
elif [ "${BASH_SOURCE-}" ]; then
  this_file="${BASH_SOURCE}"
elif [ "${ZSH_VERSION-}" ]; then
  this_file="${0}"
else
  this_file="${0}"
fi
case "${STACK+x}" in
  *':'"${this_file}"':'*)
    printf '[STOP]     processing "%s"\n' "${this_file}"
    if (return 0 2>/dev/null); then return; else exit 0; fi ;;
  *) printf '[CONTINUE] processing "%s"\n' "${this_file}" ;;
esac
export STACK="${STACK:-}${this_file}"':'

if ! command -v emerge >/dev/null 2>&1; then
  if [ -f /etc/os-release ] && grep -qi "gentoo" /etc/os-release; then
    echo "Warning: emerge not found on a Gentoo Linux system. This is highly unusual." >&2
  else
    echo "Warning: The 'emerge' package manager is only applicable on Gentoo Linux. Skipping." >&2
  fi
fi
