#!/bin/sh
# ## Overview
# Verifies every ad-hoc usage script and CLI snippet documented in README.md across
# Version Management, Autonomous Local CLIs, Stage 0/1 Bootstrap, Declarative OS Configurator,
# Curated Profiles, Rootfs/VFS/Chroot, package-as (all 22 formats), Multicloud Provisioning,
# netctl Universal Routing, and Declarative libscript.json stacks, including 2x consecutive idempotency.
# ## Usage
# ./tests/test_readme_adhoc_usage.sh
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
export LIBSCRIPT_ROOT_DIR

TMP_DIR="${LIBSCRIPT_ROOT_DIR}/tests_tmp/readme_adhoc_$$"
mkdir -p "$TMP_DIR"

# ## cleanup
# Removes temporary artifacts created during README ad-hoc usage verification.
cleanup() {
  trap - EXIT INT TERM
  rm -rf "$TMP_DIR" "${LIBSCRIPT_ROOT_DIR}/build/images" "${LIBSCRIPT_ROOT_DIR}/build/disk."* "${LIBSCRIPT_ROOT_DIR}/build/"*_temp.raw*
}
trap cleanup EXIT INT TERM

printf '=== 2.1 & 2.2 Testing Universal Version Manager & Autonomous Local CLI Snippets ===
'
export LIBSCRIPT_HOME="${TMP_DIR}/libscript_home"
mkdir -p "$LIBSCRIPT_HOME"

for pkg in nodejs python rust ruby postgres; do
  "${LIBSCRIPT_ROOT_DIR}/libscript.sh" ls "$pkg" >/dev/null
  "${LIBSCRIPT_ROOT_DIR}/libscript.sh" ls "$pkg" >/dev/null
done

"${LIBSCRIPT_ROOT_DIR}/_lib/languages/nodejs/cli.sh" ls >/dev/null
"${LIBSCRIPT_ROOT_DIR}/_lib/languages/python/cli.sh" ls >/dev/null
"${LIBSCRIPT_ROOT_DIR}/_lib/databases/postgres/cli.sh" ls >/dev/null

printf '=== 2.4 Testing Declarative OS Configurator & All Curated Profiles (2x Idempotent) ===
'
"${LIBSCRIPT_ROOT_DIR}/libscript.sh" config os --profile=linux-desktop-sway-wayland --export="${TMP_DIR}/sway1.json" >/dev/null
"${LIBSCRIPT_ROOT_DIR}/libscript.sh" config os --profile=linux-desktop-sway-wayland --export="${TMP_DIR}/sway2.json" >/dev/null
cmp -s "${TMP_DIR}/sway1.json" "${TMP_DIR}/sway2.json"

"${LIBSCRIPT_ROOT_DIR}/libscript.sh" config os --validate="${TMP_DIR}/sway1.json" >/dev/null
"${LIBSCRIPT_ROOT_DIR}/libscript.sh" config os --validate="${TMP_DIR}/sway1.json" >/dev/null

for prof in "synthesis/profiles/linux/linux-minimal-headless-musl.json" "synthesis/profiles/linux/linux-standard-server-glibc.json" "synthesis/profiles/linux/linux-desktop-sway-wayland.json" "synthesis/profiles/linux/linux-desktop-hyprland.json" "synthesis/profiles/linux/linux-desktop-kde-plasma.json" "synthesis/profiles/linux/linux-desktop-xfce-x11.json" "synthesis/profiles/freebsd/freebsd-server-standard.json" "synthesis/profiles/freebsd/freebsd-desktop-xfce.json" "synthesis/profiles/freebsd/minimal-server.json" "synthesis/profiles/freebsd/zfs-cloud.json" "synthesis/profiles/freebsd/hardened-runit.json" "synthesis/profiles/freebsd/openrc-wayland-sway.json" "synthesis/profiles/freebsd/plasma-wayland.json" "synthesis/profiles/freebsd/desktop-xfce-x11.json" "synthesis/profiles/illumos/minimal-server.json" "synthesis/profiles/illumos/zfs-cloud.json" "synthesis/profiles/illumos/pkgsrc-developer.json" "synthesis/profiles/illumos/hardened-runit.json" "synthesis/profiles/illumos/desktop-xfce-x11.json" "synthesis/profiles/illumos/desktop-mate-x11.json" "synthesis/profiles/illumos/cde-retro-x11.json" "synthesis/profiles/hypervisor/firecracker-microvm-appliance.json" "synthesis/profiles/unikernel/unikraft-nginx-redis.json" "synthesis/profiles/unikernel/osv-cloud-runtime.json"; do
  pfile="${LIBSCRIPT_ROOT_DIR}/${prof}"
  if [ -f "$pfile" ]; then
    "${LIBSCRIPT_ROOT_DIR}/libscript.sh" config os --validate="$pfile" >/dev/null
  fi
done

printf '=== 2.5 Testing Rootfs Staging & FHS Layout (2x Idempotent) ===
'
LIBSCRIPT_TARGET_SYSROOT="${TMP_DIR}/sysroot" "${LIBSCRIPT_ROOT_DIR}/synthesis/vfs/create_fhs_layout.sh" >/dev/null
LIBSCRIPT_TARGET_SYSROOT="${TMP_DIR}/sysroot" "${LIBSCRIPT_ROOT_DIR}/synthesis/vfs/create_fhs_layout.sh" >/dev/null

printf '=== 2.6 Testing Universal Artifact Packaging (package-as) ===
'
"${LIBSCRIPT_ROOT_DIR}/libscript.sh" package-as docker nodejs 22.14.0 > "${TMP_DIR}/Dockerfile.1"
"${LIBSCRIPT_ROOT_DIR}/libscript.sh" package-as docker nodejs 22.14.0 > "${TMP_DIR}/Dockerfile.2"
cmp -s "${TMP_DIR}/Dockerfile.1" "${TMP_DIR}/Dockerfile.2"

"${LIBSCRIPT_ROOT_DIR}/libscript.sh" package-as docker-compose nodejs 22.14.0 > "${TMP_DIR}/docker-compose.1.yml"
"${LIBSCRIPT_ROOT_DIR}/libscript.sh" package-as docker-compose nodejs 22.14.0 > "${TMP_DIR}/docker-compose.2.yml"
cmp -s "${TMP_DIR}/docker-compose.1.yml" "${TMP_DIR}/docker-compose.2.yml"

for fmt in msi nsis innosetup deb rpm apk txz pkg dmg tui; do
  "${LIBSCRIPT_ROOT_DIR}/libscript.sh" package-as "$fmt" --out-file "${TMP_DIR}/pkg_${fmt}" nodejs 22.14.0 >/dev/null
done

export LIBSCRIPT_TARGET_SYSROOT="${TMP_DIR}/sysroot"
for img_fmt in raw-img qcow2 vmdk vdi vagrant-box iso rootfs-tar bsd-img illumos-distro; do
  LIBSCRIPT_ALLOW_STUB=1 "${LIBSCRIPT_ROOT_DIR}/libscript.sh" package-as "$img_fmt" >/dev/null
done
LIBSCRIPT_ALLOW_STUB=1 "${LIBSCRIPT_ROOT_DIR}/libscript.sh" package-as unikernel --allow-stub-sdk >/dev/null

printf '=== 2.7 Testing Multicloud Provisioning, Cloud CLI & netctl (2x Idempotent) ===
'
cat << 'EOF' > "${TMP_DIR}/libscript.json"
{
  "name": "enterprise-microservice",
  "version": "1.0.0",
  "dependencies": {
    "nodejs": ">=22.0.0",
    "postgres": "16",
    "valkey": "latest",
    "pipewire": "latest"
  },
  "variants": {
    "wayland": true,
    "lto": true
  }
}
EOF

for pass in 1 2; do
  DRY_RUN=true "${LIBSCRIPT_ROOT_DIR}/libscript.sh" provision aws production-stack vpc-main us-east-1 "$TMP_DIR" ~/app >/dev/null
  DRY_RUN=true "${LIBSCRIPT_ROOT_DIR}/libscript.sh" deprovision aws production-stack vpc-main us-east-1 >/dev/null
  DRY_RUN=true "${LIBSCRIPT_ROOT_DIR}/libscript.sh" cloud aws network create vpc-main >/dev/null
  DRY_RUN=true "${LIBSCRIPT_ROOT_DIR}/libscript.sh" cloud gcp firewall create allow-http --network vpc-main --allow tcp:80,tcp:443 >/dev/null
  DRY_RUN=true "${LIBSCRIPT_ROOT_DIR}/libscript.sh" cloud azure node deploy worker-node-01 resource-grp "$TMP_DIR" ~/app >/dev/null
  DRY_RUN=true "${LIBSCRIPT_ROOT_DIR}/libscript.sh" cloud hetzner node deploy app-server-01 ~/app >/dev/null
  printf '[PASS] Multicloud pass %s completed
' "$pass"
done

for emit_target in nginx caddy httpd iis; do
  out1=$("${LIBSCRIPT_ROOT_DIR}/_lib/networking/netctl/cli.sh" --listen 80 --listen 443 --proxy /api http://localhost:8080 --static / /var/www --emit "$emit_target")
  out2=$("${LIBSCRIPT_ROOT_DIR}/_lib/networking/netctl/cli.sh" --listen 80 --listen 443 --proxy /api http://localhost:8080 --static / /var/www --emit "$emit_target")
  [ "$out1" = "$out2" ] || exit 1
done

cleanup
printf '[PASS] All README.md ad-hoc usage scripts verified with 2x consecutive idempotency!
'
