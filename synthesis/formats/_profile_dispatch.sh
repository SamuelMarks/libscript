#!/bin/sh
# ## Overview
# Internal T3 helper routing format-first `--profile` invocations to the matching OS, unikernel, or RTOS packager.
# ## Usage
# synthesis/formats/_profile_dispatch.sh <default_format> --profile <profile> [options...]
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

# ## show_help
# Displays usage instructions for _profile_dispatch.sh.
show_help() {
  printf 'Usage: %s <default_format> --profile <path|preset> [--output <path>] [--dry-run] [--allow-stub] [--strict] [--offline]\n' "$THIS_FILE"
}

# ## resolve_any_profile
# Searches synthesis/profiles/ families to resolve a profile file path or preset name.
resolve_any_profile() {
  _rap="$1"
  if [ -f "$_rap" ]; then
    printf '%s\n' "$_rap"
    return 0
  fi
  for _sub in '' 'linux/' 'lfs/' 'freebsd/' 'illumos/' 'reactos/' 'dos/' 'unikernel/' 'rtos/' 'cloud/' 'hypervisor/'; do
    if [ -f "${LIBSCRIPT_ROOT_DIR}/synthesis/profiles/${_sub}${_rap}.json" ]; then
      printf '%s\n' "${LIBSCRIPT_ROOT_DIR}/synthesis/profiles/${_sub}${_rap}.json"
      return 0
    fi
  done
  printf '%s\n' "$_rap"
  return 0
}

if [ "${1:-}" = '--help' ] || [ "${1:-}" = '-h' ]; then
  show_help
  exit 0
fi

DEF_FMT="${1:-qcow2}"
shift || true

FMT="$DEF_FMT"
PROFILE=''
OUTPUT=''
FWD_FLAGS=''

while [ $# -gt 0 ]; do
  case "$1" in
    --help|-h) show_help; exit 0 ;;
    --profile|-p) PROFILE="$2"; shift 2 ;;
    --profile=*) PROFILE="${1#*=}"; shift ;;
    --format|-f) FMT="$2"; shift 2 ;;
    --format=*) FMT="${1#*=}"; shift ;;
    --output|-o|--out) OUTPUT="$2"; shift 2 ;;
    --output=*|--out=*) OUTPUT="${1#*=}"; shift ;;
    --arch) FWD_FLAGS="${FWD_FLAGS} --arch $2"; shift 2 ;;
    --arch=*) FWD_FLAGS="${FWD_FLAGS} --arch=${1#*=}"; shift ;;
    --initramfs-compress) FWD_FLAGS="${FWD_FLAGS} --initramfs-compress $2"; shift 2 ;;
    --initramfs-compress=*) FWD_FLAGS="${FWD_FLAGS} --initramfs-compress=${1#*=}"; shift ;;
    --dry-run) FWD_FLAGS="${FWD_FLAGS} --dry-run"; shift ;;
    --strict) FWD_FLAGS="${FWD_FLAGS} --strict"; shift ;;
    --allow-stub) FWD_FLAGS="${FWD_FLAGS} --allow-stub"; shift ;;
    --offline) FWD_FLAGS="${FWD_FLAGS} --offline"; shift ;;
    *) shift ;;
  esac
done

PROFILE=$(resolve_any_profile "$PROFILE")
if [ ! -f "$PROFILE" ]; then
  printf '[ERROR] Profile not found: %s\n' "$PROFILE" >&2
  exit 1
fi

if ! command -v jq >/dev/null 2>&1 && [ -f "${LIBSCRIPT_ROOT_DIR}/_lib/utilities/jq/env.sh" ]; then
  _pd_this="${THIS_FILE}"; _pd_dir="${SCRIPT_DIR}"; _pd_stack="${STACK}"
  SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/_lib/utilities/jq/env.sh"
  export SCRIPT_NAME
  # shellcheck disable=SC1090,SC1091
  . "${SCRIPT_NAME}" >/dev/null 2>&1 || true
  unset SCRIPT_NAME || true
  THIS_FILE="${_pd_this}"; SCRIPT_DIR="${_pd_dir}"; STACK="${_pd_stack}"; export STACK
fi

OS_FAM=''
if command -v jq >/dev/null 2>&1; then
  OS_FAM=$(jq -r '.target.os_family // .target.os // (if .freebsd_version != null then "freebsd" elif .illumos_version != null then "illumos" elif .reactos_version != null then "reactos" else "linux-glibc" end)' "$PROFILE" 2>/dev/null || printf 'linux-glibc')
fi

TARGET_DRIVER="${SCRIPT_DIR}/linux_distro.sh"
case "$OS_FAM" in
  freebsd*) TARGET_DRIVER="${SCRIPT_DIR}/freebsd_distro.sh" ;;
  illumos*|sunos*) TARGET_DRIVER="${SCRIPT_DIR}/illumos_distro.sh" ;;
  reactos*) TARGET_DRIVER="${SCRIPT_DIR}/reactos_distro.sh" ;;
  freedos*|msdos*) TARGET_DRIVER="${SCRIPT_DIR}/dos_distro.sh" ;;
  unikernel-*|osv|mirage*|unikraft|nanos|rumprun) TARGET_DRIVER="${SCRIPT_DIR}/unikernel_img.sh" ;;
  rtos-*|zephyr|freertos) TARGET_DRIVER="${SCRIPT_DIR}/rtos_distro.sh" ;;
  *) TARGET_DRIVER="${SCRIPT_DIR}/linux_distro.sh" ;;
esac

if [ -n "$OUTPUT" ]; then
  # shellcheck disable=SC2086
  STACK='' exec "$TARGET_DRIVER" --profile "$PROFILE" --format "$FMT" --output "$OUTPUT" $FWD_FLAGS
else
  # shellcheck disable=SC2086
  STACK='' exec "$TARGET_DRIVER" --profile "$PROFILE" --format "$FMT" $FWD_FLAGS
fi
