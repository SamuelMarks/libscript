#!/bin/sh
# ## Overview
# Multi-Unikernel Pod Composer decomposing multi-daemon component sets ({c0, c1, ...})
# into isolated single-process unikernel appliances wired over virtual bridge networking.
# ## Usage
# ./_lib/orchestration/unikernel_pod/setup.sh [install|assemble|clean] [--framework=<fw>] [--components=<c0,c1,...>]

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

ACTION="${1:-assemble}"
case "$ACTION" in
  install|assemble|compile|bootstrap|clean|ls|ls-remote|status) shift || true ;;
  *) ACTION='assemble' ;;
esac

FRAMEWORK="${LIBSCRIPT_UNIKERNEL_FRAMEWORK:-unikraft}"
DAEMONS_CSV="${LIBSCRIPT_POD_DAEMONS:-redis}"
VMM="${UNIKERNEL_POD_VMM:-qemu}"
SUBNET_PREFIX="${UNIKERNEL_POD_SUBNET:-172.30.0}"

while [ $# -gt 0 ]; do
  case "$1" in
    --framework=*) FRAMEWORK="${1#*=}"; shift ;;
    --components=*) DAEMONS_CSV="${1#*=}"; shift ;;
    --vmm=*) VMM="${1#*=}"; shift ;;
    *) shift ;;
  esac
done

TARGET_SYSROOT="${LIBSCRIPT_TARGET_SYSROOT:-${LIBSCRIPT_ROOT_DIR}/build/target-sysroot}"
POD_DIR="${UNIKERNEL_POD_OUT_DIR:-${TARGET_SYSROOT}/unikernel-pod}"

if [ "$ACTION" = "ls" ] || [ "$ACTION" = "ls-remote" ]; then
  printf '1.0.0\n'
  exit 0
fi

if [ "$ACTION" = "clean" ]; then
  rm -rf "$POD_DIR"
  exit 0
fi

mkdir -p "$POD_DIR"
POD_ENV="${POD_DIR}/pod.discovery.env"
POD_MANIFEST="${POD_DIR}/pod-manifest.json"
LAUNCH_SH="${POD_DIR}/launch_pod.sh"
TEARDOWN_SH="${POD_DIR}/teardown_pod.sh"
LAUNCH_CMD="${POD_DIR}/launch_pod.cmd"

: > "$POD_ENV"
IDX=10
APPLIANCES_JSON='['
FIRST_ITEM=1

_old_ifs="$IFS"
IFS=','
for _comp in $DAEMONS_CSV; do
  [ -n "$_comp" ] || continue
  _ip="${SUBNET_PREFIX}.${IDX}"
  _mac_hex=$(printf '%02x' "$IDX")
  _mac="52:54:00:30:00:${_mac_hex}"
  _up=$(printf '%s' "$_comp" | tr '[:lower:]-' '[:upper:]_')
  printf '%s_HOST=%s\n' "$_up" "$_ip" >> "$POD_ENV"
  IDX=$((IDX + 1))
done
IFS="$_old_ifs"

IDX=10
IFS=','
for _comp in $DAEMONS_CSV; do
  [ -n "$_comp" ] || continue
  _ip="${SUBNET_PREFIX}.${IDX}"
  _mac_hex=$(printf '%02x' "$IDX")
  _mac="52:54:00:30:00:${_mac_hex}"
  _app_dir="${POD_DIR}/appliances/${_comp}"
  mkdir -p "${_app_dir}/rootfs/etc" "${_app_dir}/images"
  cp -f "$POD_ENV" "${_app_dir}/rootfs/etc/pod.discovery.env"

  # Invoke component-specific unikernel adapter if available, then package image
  for _cat_cand in "${LIBSCRIPT_ROOT_DIR}"/_lib/*/"${_comp}"; do
    if [ -x "${_cat_cand}/unikernel_build.sh" ]; then
      STACK='' LIBSCRIPT_UNIKERNEL_FRAMEWORK="$FRAMEWORK" "${_cat_cand}/unikernel_build.sh" "${_app_dir}/rootfs" "${_app_dir}/images/${_comp}.${FRAMEWORK}.img" "$_ip" || true
    fi
  done

  if [ ! -s "${_app_dir}/images/${_comp}.${FRAMEWORK}.img" ]; then
    STACK='' LIBSCRIPT_UNIKERNEL_FRAMEWORK="$FRAMEWORK" "${LIBSCRIPT_ROOT_DIR}/cli/commands/package_as/unikernel.sh" --framework="$FRAMEWORK" --vmm="$VMM" "${_app_dir}/rootfs" "${_app_dir}/images/${_comp}.${FRAMEWORK}.img"
  fi

  if [ "$FIRST_ITEM" -eq 1 ]; then
    FIRST_ITEM=0
  else
    APPLIANCES_JSON="${APPLIANCES_JSON},"
  fi
  APPLIANCES_JSON="${APPLIANCES_JSON}{\"component\":\"${_comp}\",\"framework\":\"${FRAMEWORK}\",\"vmm\":\"${VMM}\",\"ipv4\":\"${_ip}\",\"mac\":\"${_mac}\",\"image\":\"appliances/${_comp}/images/${_comp}.${FRAMEWORK}.img\"}"
  IDX=$((IDX + 1))
done
IFS="$_old_ifs"
APPLIANCES_JSON="${APPLIANCES_JSON}]"

printf '{\n  "pod_version": "1.0.0",\n  "framework": "%s",\n  "vmm": "%s",\n  "bridge": "lsbr0",\n  "gateway": "%s.1",\n  "appliances": %s\n}\n' \
  "$FRAMEWORK" "$VMM" "$SUBNET_PREFIX" "$APPLIANCES_JSON" > "$POD_MANIFEST"

cat << 'LSH_EOF' > "$LAUNCH_SH"
#!/bin/sh
set -feu
POD_ROOT=$(cd -- "$(dirname -- "$0")" && pwd)
mkdir -p "${POD_ROOT}/pids"
for _app in "${POD_ROOT}"/appliances/*; do
  [ -d "$_app" ] || continue
  _name=$(basename "$_app")
  _img=$(find "${_app}/images" -type f | head -n 1 || true)
  [ -n "$_img" ] || continue
  if command -v qemu-system-x86_64 >/dev/null 2>&1; then
    qemu-system-x86_64 -m 256M -nographic -kernel "$_img" -daemonize -pidfile "${POD_ROOT}/pids/${_name}.pid" 2>/dev/null || true
  fi
  printf '[POD] Appliance %s staged (%s)\n' "$_name" "$_img"
done
LSH_EOF
chmod +x "$LAUNCH_SH"

cat << 'TSH_EOF' > "$TEARDOWN_SH"
#!/bin/sh
set -feu
POD_ROOT=$(cd -- "$(dirname -- "$0")" && pwd)
if [ -d "${POD_ROOT}/pids" ]; then
  for _pf in "${POD_ROOT}"/pids/*.pid; do
    [ -f "$_pf" ] || continue
    kill "$(cat "$_pf")" 2>/dev/null || true
    rm -f "$_pf"
  done
fi
printf '[POD] All unikernel pod appliances stopped.\n'
TSH_EOF
chmod +x "$TEARDOWN_SH"

cat << 'LCMD_EOF' > "$LAUNCH_CMD"
@echo off
setlocal EnableDelayedExpansion
set "POD_ROOT=%~dp0"
for /D %%A in ("%POD_ROOT%appliances\*") do (
    echo [POD] Unikernel appliance ready: %%~nxA
)
exit /b 0
LCMD_EOF
awk '{ sub(/\r$/, ""); printf "%s\r\n", $0 }' "$LAUNCH_CMD" > "${LAUNCH_CMD}.tmp" && mv "${LAUNCH_CMD}.tmp" "$LAUNCH_CMD"

BIN_INSTALL="${LIBSCRIPT_HOME:-${HOME:-/tmp}/.libscript}/unikernel_pod/1.0.0/bin"
mkdir -p "$BIN_INSTALL"
ln -sf "$THIS_FILE" "${BIN_INSTALL}/unikernel-pod"

printf '[OK] Synthesized multi-unikernel pod (%s, vmm=%s) at %s\n' "$FRAMEWORK" "$VMM" "$POD_DIR"
exit 0
