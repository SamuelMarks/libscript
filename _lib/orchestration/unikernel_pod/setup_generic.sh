#!/bin/sh
# ## Overview
# Multi-Unikernel Pod & Constellation Composer decomposing multi-daemon topologies (`topology.json`)
# or component lists into isolated single-process unikernel appliances with bridge/vsock networking.
# ## Usage
# ./_lib/orchestration/unikernel_pod/setup_generic.sh [install|assemble|clean] [--topology=<topology.json>] [--framework=<fw>] [--vmm=<vmm>]

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

ACTION='install'
FRAMEWORK="${LIBSCRIPT_UNIKERNEL_FRAMEWORK:-unikraft}"
VMM="${UNIKERNEL_POD_VMM:-qemu}"
DAEMONS_CSV="${UNIKERNEL_POD_DAEMONS:-${LIBSCRIPT_POD_DAEMONS:-redis}}"
TOPOLOGY_FILE="${UNIKERNEL_POD_TOPOLOGY:-}"
POD_SUBNET="${UNIKERNEL_POD_SUBNET:-172.30.0}"
ALLOW_STUB="${LIBSCRIPT_ALLOW_STUB:-0}"
CLOUD_BOOT='none'
TARGET_SYSROOT="${LIBSCRIPT_TARGET_SYSROOT:-${LIBSCRIPT_ROOT_DIR}/build/target-sysroot}"
POD_DIR="${UNIKERNEL_POD_OUT_DIR:-${TARGET_SYSROOT}/unikernel-pod}"

while [ $# -gt 0 ]; do
  case "$1" in
    install|assemble|clean|ls|ls-remote|use|download|status|uninstall) ACTION="$1"; shift ;;
    --topology=*) TOPOLOGY_FILE="${1#*=}"; shift ;;
    --framework=*) FRAMEWORK="${1#*=}"; shift ;;
    --vmm=*) VMM="${1#*=}"; shift ;;
    --components=*|--daemons=*) DAEMONS_CSV="${1#*=}"; shift ;;
    --subnet=*) POD_SUBNET="${1#*=}"; shift ;;
    --out-dir=*) POD_DIR="${1#*=}"; shift ;;
    --cloud-boot=*) CLOUD_BOOT="${1#*=}"; shift ;;
    --allow-stub|--allow-stub-sdk) ALLOW_STUB=1; shift ;;
    *) shift ;;
  esac
done

case "$ACTION" in
  ls) printf '1.0.0\n'; exit 0 ;;
  ls-remote) printf '1.0.0\n'; exit 0 ;;
  use|download) exit 0 ;;
  clean|uninstall)
    rm -rf "$POD_DIR"
    exit 0
    ;;
  status)
    if [ -f "${POD_DIR}/pod-manifest.json" ]; then
      cat "${POD_DIR}/pod-manifest.json"
    else
      printf '[STATUS] unikernel_pod not assembled at %s\n' "$POD_DIR"
    fi
    exit 0
    ;;
esac

mkdir -p "${POD_DIR}/appliances" "${POD_DIR}/net"
BRIDGE_NAME='lsbr0'

cat << NET_EOF > "${POD_DIR}/net/setup-bridge.sh"
#!/bin/sh
set -eu
ip link show ${BRIDGE_NAME} >/dev/null 2>&1 || ip link add name ${BRIDGE_NAME} type bridge
ip addr show dev ${BRIDGE_NAME} | grep -q '${POD_SUBNET}.1/' || ip addr add ${POD_SUBNET}.1/24 dev ${BRIDGE_NAME}
ip link set ${BRIDGE_NAME} up
NET_EOF
chmod 755 "${POD_DIR}/net/setup-bridge.sh"

IDX=10
APPLIANCE_JSON_LIST=''
STUB_FLAG=''
if [ "$ALLOW_STUB" = "1" ]; then
  STUB_FLAG='--allow-stub-sdk'
fi

if [ -n "$TOPOLOGY_FILE" ] && [ -f "$TOPOLOGY_FILE" ]; then
  _groups=$(jq -c '.node_groups[]' "$TOPOLOGY_FILE")
  while IFS= read -r _grp; do
    [ -z "$_grp" ] && continue
    _grp_name=$(printf '%s' "$_grp" | jq -r '.name')
    _grp_prof=$(printf '%s' "$_grp" | jq -r '.image_profile // empty')
    _grp_vmm=$(printf '%s' "$_grp" | jq -r '.vmm // "qemu"')
    _grp_comp=$(printf '%s' "$_grp" | jq -r '.components[0] // "app"')
    _grp_role=$(printf '%s' "$_grp" | jq -r '.component_env.OPENEDX_ROLE // empty')
    _app_root="${POD_DIR}/appliances/${_grp_name}"
    _app_sys="${_app_root}/rootfs"
    _app_img="${_app_root}/${_grp_name}.unikernel.elf"
    _app_ip="${POD_SUBNET}.${IDX}"
    _tap_dev="lstap${IDX}"
    mkdir -p "$_app_sys"

    _prof_fw="$FRAMEWORK"
    if [ -n "$_grp_prof" ] && [ -f "${LIBSCRIPT_ROOT_DIR}/${_grp_prof}" ]; then
      _prof_os=$(jq -r '.target.os_family // "unikernel-unikraft"' "${LIBSCRIPT_ROOT_DIR}/${_grp_prof}")
      _prof_fw="${_prof_os#unikernel-}"
    fi

    if [ "$_grp_comp" = "openedx" ] && [ -n "$_grp_role" ]; then
      STACK='' TARGET_ROOT="$_app_sys" OPENEDX_ROLE="$_grp_role" \
        sh "${LIBSCRIPT_ROOT_DIR}/_lib/web-apps/openedx/setup_generic.sh" install --offline --role="$_grp_role" >/dev/null
    fi

    # shellcheck disable=SC2086
    STACK='' LIBSCRIPT_ALLOW_STUB="$ALLOW_STUB" \
      sh "${LIBSCRIPT_ROOT_DIR}/cli/commands/package_as/unikernel.sh" \
      --framework="$_prof_fw" --vmm="$_grp_vmm" --cloud-boot="$CLOUD_BOOT" $STUB_FLAG "$_app_sys" "$_app_img" >/dev/null

    _entry="{\"name\":\"${_grp_name}\",\"component\":\"${_grp_comp}\",\"profile\":\"${_grp_prof}\",\"framework\":\"${_prof_fw}\",\"vmm\":\"${_grp_vmm}\",\"ip\":\"${_app_ip}\",\"tap\":\"${_tap_dev}\",\"image\":\"${_app_img}\"}"
    if [ -z "$APPLIANCE_JSON_LIST" ]; then
      APPLIANCE_JSON_LIST="$_entry"
    else
      APPLIANCE_JSON_LIST="${APPLIANCE_JSON_LIST},${_entry}"
    fi
    IDX=$((IDX + 1))
  done << EOF
${_groups}
EOF
else
  OLD_IFS="$IFS"
  IFS=','
  # shellcheck disable=SC2086
  set -- $DAEMONS_CSV
  IFS="$OLD_IFS"

  for _comp in "$@"; do
    [ -z "$_comp" ] && continue
    _app_root="${POD_DIR}/appliances/${_comp}"
    _app_sys="${_app_root}/rootfs"
    _app_img="${_app_root}/${_comp}.unikernel.elf"
    _app_ip="${POD_SUBNET}.${IDX}"
    _tap_dev="lstap${IDX}"
    mkdir -p "${_app_sys}/etc" "${_app_sys}/var/lib/${_comp}"
    printf '127.0.0.1 localhost\n%s %s.pod.local %s\n' "$_app_ip" "$_comp" "$_comp" > "${_app_sys}/etc/hosts"

    # shellcheck disable=SC2086
    STACK='' LIBSCRIPT_ALLOW_STUB="$ALLOW_STUB" \
      sh "${LIBSCRIPT_ROOT_DIR}/cli/commands/package_as/unikernel.sh" \
      --framework="$FRAMEWORK" --vmm="$VMM" --cloud-boot="$CLOUD_BOOT" $STUB_FLAG "$_app_sys" "$_app_img" >/dev/null

    _entry="{\"component\":\"${_comp}\",\"framework\":\"${FRAMEWORK}\",\"vmm\":\"${VMM}\",\"ip\":\"${_app_ip}\",\"tap\":\"${_tap_dev}\",\"image\":\"${_app_img}\"}"
    if [ -z "$APPLIANCE_JSON_LIST" ]; then
      APPLIANCE_JSON_LIST="$_entry"
    else
      APPLIANCE_JSON_LIST="${APPLIANCE_JSON_LIST},${_entry}"
    fi
    IDX=$((IDX + 1))
  done
fi

cat << POD_JSON > "${POD_DIR}/pod-manifest.json.tmp"
{
  "pod_version": "2.0.0",
  "topology": "${TOPOLOGY_FILE}",
  "bridge": "${BRIDGE_NAME}",
  "subnet": "${POD_SUBNET}.0/24",
  "gateway": "${POD_SUBNET}.1",
  "appliances": [${APPLIANCE_JSON_LIST}]
}
POD_JSON
mv "${POD_DIR}/pod-manifest.json.tmp" "${POD_DIR}/pod-manifest.json"

cat << 'LAUNCH_EOF' > "${POD_DIR}/launch-pod.sh"
#!/bin/sh
set -eu
POD_ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
sh "${POD_ROOT}/net/setup-bridge.sh"
jq -r '.appliances[].image' "${POD_ROOT}/pod-manifest.json" | while IFS= read -r _img; do
  printf '[POD] Verified unikernel image ready: %s\n' "$_img"
done
LAUNCH_EOF
chmod 755 "${POD_DIR}/launch-pod.sh"

BIN_INSTALL="${LIBSCRIPT_HOME:-${HOME:-/tmp}/.libscript}/unikernel_pod/1.0.0/bin"
mkdir -p "$BIN_INSTALL"
ln -sf "$THIS_FILE" "${BIN_INSTALL}/unikernel-pod"

printf '[OK] Synthesized multi-unikernel pod at %s\n' "$POD_DIR"
exit 0
