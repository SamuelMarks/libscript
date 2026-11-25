#!/bin/sh
# ## Overview
# Unified CLI entrypoint to synthesize and package a FreeDOS or MIT MS-DOS distribution profile
# into floppy-img, qcow2, raw, iso, vmdk, vhd, or vagrant-box formats.
#
# ## Usage
# synthesis/formats/dos_distro.sh [--format <qcow2|floppy-img|raw|iso|vmdk|vhd|vagrant-box>] [--profile <profile.json>] [--output <path>] [--dry-run]

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

FORMAT="${LIBSCRIPT_DOS_DEFAULT_FORMAT:-qcow2}"
PROFILE="${LIBSCRIPT_DOS_DEFAULT_PROFILE:-${LIBSCRIPT_ROOT_DIR}/synthesis/profiles/dos/freedos-1.4-djgpp-i586.json}"
OUTPUT=''
FWD=''

# ## resolve_dos_profile
# Resolves a DOS profile preset or filesystem path under synthesis/profiles/dos/.
resolve_dos_profile() {
  _rdp="$1"
  if [ -f "${_rdp}" ]; then
    printf '%s\n' "${_rdp}"
    return 0
  fi
  for _sub in '' 'dos/'; do
    if [ -f "${LIBSCRIPT_ROOT_DIR}/synthesis/profiles/${_sub}${_rdp}.json" ]; then
      printf '%s\n' "${LIBSCRIPT_ROOT_DIR}/synthesis/profiles/${_sub}${_rdp}.json"
      return 0
    fi
  done
  printf '%s\n' "${_rdp}"
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --help|-h)
      printf 'Usage: %s [--format <qcow2|floppy-img|raw|iso|vmdk|vhd|vagrant-box>] [--profile <profile.json>] [--output <path>] [--dry-run]\n' "${THIS_FILE}"
      exit 0
      ;;
    --format|-f) FORMAT="$2"; shift 2 ;;
    --format=*) FORMAT="${1#*=}"; shift ;;
    --profile|-p) PROFILE="$2"; shift 2 ;;
    --profile=*) PROFILE="${1#*=}"; shift ;;
    --output|-o|--out) OUTPUT="$2"; shift 2 ;;
    --output=*|--out=*) OUTPUT="${1#*=}"; shift ;;
    --dry-run) FWD="${FWD} --dry-run"; shift ;;
    --strict) FWD="${FWD} --strict"; shift ;;
    --allow-stub) FWD="${FWD} --allow-stub"; shift ;;
    --offline) FWD="${FWD} --offline"; shift ;;
    *) shift ;;
  esac
done

PROFILE=$(resolve_dos_profile "${PROFILE}")
KERN='freedos'
if command -v jq >/dev/null 2>&1 && [ -f "${PROFILE}" ]; then
  _os_f=$(jq -r '.target.os_family // "freedos"' "${PROFILE}")
  _dver=$(jq -r '.dos_version // .kernel.version // ""' "${PROFILE}")
  if [ "${_os_f}" = 'msdos' ]; then
    case "${_dver}" in
      1.25*) KERN='msdos-1.25' ;;
      2.0*) KERN='msdos-2.0' ;;
      *) KERN='msdos-4.0' ;;
    esac
  fi
fi

set -- "--kernel=${KERN}" "--profile=${PROFILE}" "--format=${FORMAT}"
[ -n "${OUTPUT}" ] && set -- "$@" "--out=${OUTPUT}"
for _fl in ${FWD}; do
  set -- "$@" "${_fl}"
done
STACK='' exec "${LIBSCRIPT_ROOT_DIR}/synthesis/distro/synthesize-image.sh" "$@"
