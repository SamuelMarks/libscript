#!/bin/sh
# ## Overview
# ReactOS kernel and userland compilation and base staging engine.
# Supports full source builds via _lib/toolchains/rosbe (CMake + Ninja bootcd/livecd + modules/optional)
# or upstream ISO extraction via _lib/reactos/distro/base.sh.
#
# ## Usage
# ./_lib/reactos/setup.sh [--strict | --allow-stub] [--from-source] [compile|install|clean]

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

STRICT_BUILD="${LIBSCRIPT_STRICT_IMAGE_BUILD:-0}"
ALLOW_STUB="${LIBSCRIPT_ALLOW_STUB:-0}"
FROM_SOURCE="${REACTOS_BUILD_FROM_SOURCE:-0}"
ACTION_ARG=''

while [ $# -gt 0 ]; do
  case "$1" in
    --help|-h)
      printf 'Usage: %s [--strict | --allow-stub] [--from-source] [compile|install|clean]\n' "$THIS_FILE"
      exit 0
      ;;
    --strict)
      STRICT_BUILD='1'
      ALLOW_STUB='0'
      shift
      ;;
    --allow-stub)
      ALLOW_STUB='1'
      STRICT_BUILD='0'
      shift
      ;;
    --from-source)
      FROM_SOURCE='1'
      shift
      ;;
    *)
      ACTION_ARG="$1"
      shift
      ;;
  esac
done

export LIBSCRIPT_STRICT_IMAGE_BUILD="$STRICT_BUILD"
export LIBSCRIPT_ALLOW_STUB="$ALLOW_STUB"

ACTION="${ACTION_ARG:-${ACTION:-install}}"
TARGET_SYSROOT="${LIBSCRIPT_TARGET_SYSROOT:-${LIBSCRIPT_ROOT_DIR}/build/reactos-sysroot}"
STAMP_DIR="${TARGET_SYSROOT}/var/lib/libscript/stamps"
STAMP_FILE="${STAMP_DIR}/.stamp.reactos_system"
REACTOS_VER="${REACTOS_VERSION:-0.4.16}"
TARGET_ARCH="${LIBSCRIPT_TARGET_ARCH:-i686}"

# ## stage_optional_modules
# Generates a CMakeLists.txt in modules/optional/libscript to slipstream staged files via add_cd_file().
stage_optional_modules() {
  _src_root="$1"
  _payload_dir="$2"
  [ -d "$_payload_dir" ] || return 0
  _opt_dir="${_src_root}/modules/optional/libscript"
  mkdir -p "$_opt_dir"
  : > "${_opt_dir}/CMakeLists.txt"
  set +f
  for _item in "${_payload_dir}"/*; do
    [ -f "$_item" ] || continue
    _base="${_item##*/}"
    cp -f "$_item" "${_opt_dir}/${_base}"
    # shellcheck disable=SC2016
    printf 'add_cd_file(FILE "${CMAKE_CURRENT_SOURCE_DIR}/%s" DESTINATION reactos/libscript FOR all)\n' "$_base" >> "${_opt_dir}/CMakeLists.txt"
  done
  set -f
}

if [ "$ACTION" = 'clean' ]; then
  rm -f "$STAMP_FILE" "${TARGET_SYSROOT}/.libscript-stamps/reactos-base.stamp"
  printf '[INFO] Cleaned ReactOS system stamps in %s.\n' "$TARGET_SYSROOT"
  exit 0
fi

if [ -f "$STAMP_FILE" ] && [ -f "${TARGET_SYSROOT}/iso_root/freeldr.sys" ]; then
  printf '[SKIP] ReactOS system already staged: %s\n' "$STAMP_FILE"
  exit 0
fi

mkdir -p "$STAMP_DIR" "${TARGET_SYSROOT}/iso_root"
STAMP_MODE='repack'

if [ "$FROM_SOURCE" = '1' ]; then
  ROS_SRC="${REACTOS_SRC_DIR:-${LIBSCRIPT_BUILD_DIR:-${LIBSCRIPT_ROOT_DIR}/build}/reactos-src}"
  ROS_ARCH='i386'
  case "$TARGET_ARCH" in
    x86_64|amd64) ROS_ARCH='amd64' ;;
    *) ROS_ARCH='i386' ;;
  esac

  STACK='' "${LIBSCRIPT_ROOT_DIR}/_lib/toolchains/rosbe/setup.sh"
  _ros_caller_this="$THIS_FILE"
  _ros_caller_dir="$SCRIPT_DIR"
  LIBSCRIPT_ROSBE_ARCH="$ROS_ARCH"
  export LIBSCRIPT_ROSBE_ARCH
  SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/_lib/toolchains/rosbe/env.sh"
  export SCRIPT_NAME
  # shellcheck disable=SC1090,SC1091
  . "${SCRIPT_NAME}"
  unset SCRIPT_NAME || true
  THIS_FILE="$_ros_caller_this"
  SCRIPT_DIR="$_ros_caller_dir"

  if [ ! -d "$ROS_SRC" ] && [ "${LIBSCRIPT_OFFLINE:-0}" != '1' ] && command -v git >/dev/null 2>&1; then
    git clone --depth 1 https://github.com/reactos/reactos.git "$ROS_SRC" || true
  fi

  if [ -f "${ROS_SRC}/CMakeLists.txt" ] && command -v cmake >/dev/null 2>&1 && command -v ninja >/dev/null 2>&1; then
    stage_optional_modules "$ROS_SRC" "${TARGET_SYSROOT}/iso_root/libscript"
    _bld_dir="${LIBSCRIPT_BUILD_DIR:-${LIBSCRIPT_ROOT_DIR}/build}/reactos-build-${ROS_ARCH}"
    mkdir -p "$_bld_dir"
    if [ -x "${ROS_SRC}/configure.sh" ]; then
      (cd "$_bld_dir" && "${ROS_SRC}/configure.sh" -DARCH="$ROS_ARCH")
      ninja -C "${_bld_dir}/output-MinGW-${ROS_ARCH}" bootcd
      STAMP_MODE='source'
    elif [ "$ALLOW_STUB" = '1' ]; then
      STAMP_MODE='stub-source'
    elif [ "$STRICT_BUILD" = '1' ]; then
      printf '[ERROR] Strict ReactOS source build failed: configure.sh missing in %s\n' "$ROS_SRC" >&2
      exit 1
    fi
  elif [ "$STRICT_BUILD" = '1' ] && [ "$ALLOW_STUB" != '1' ]; then
    printf '[ERROR] Strict ReactOS source build requested, but REACTOS_SRC_DIR (%s) or cmake/ninja is unavailable.\n' "$ROS_SRC" >&2
    exit 1
  fi
fi

if [ "$STAMP_MODE" != 'source' ]; then
  _flag='--allow-stub'
  [ "$STRICT_BUILD" = '1' ] && _flag='--strict'
  STACK='' "${SCRIPT_DIR}/distro/base.sh" "$_flag" "$TARGET_SYSROOT" "$REACTOS_VER" "$TARGET_ARCH"
fi

printf 'mode=%s\ntimestamp=%s\n' "$STAMP_MODE" "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" > "${STAMP_FILE}.tmp"
mv "${STAMP_FILE}.tmp" "$STAMP_FILE"
printf '[OK]    reactos_system staged successfully (mode=%s): %s\n' "$STAMP_MODE" "$STAMP_FILE"
