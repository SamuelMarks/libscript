#!/bin/sh
# ## Overview
# Behavioral test suite for the 51 Tier 1.5 / Tier 2 / Tier 3 Base System, Init, Networking,
# Audio, Display Manager, Desktop, Bootloader, Virtualization, Orchestration, and Cloud Provider recipes (Section 10.8).
#
# ## Usage
# ./tests/test_tier15_2_3_system_orchestration_cloud.sh

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

FAILURES=0
CHECKS=0

# ## pass_check
# Records a passing behavioral assertion.
pass_check() {
  CHECKS=$((CHECKS + 1))
  printf '[PASS] %s\n' "$1"
}

# ## fail_check
# Records a failing behavioral assertion.
fail_check() {
  CHECKS=$((CHECKS + 1))
  FAILURES=$((FAILURES + 1))
  printf '[FAIL] %s\n' "$1" >&2
}

TEST_WS=$(mktemp -d "${TMPDIR:-/tmp}/libscript_tier15_2_3_test.XXXXXX")
trap 'rm -rf "$TEST_WS"' EXIT INT TERM

FAKE_HOME="${TEST_WS}/home"
FAKE_LS_HOME="${TEST_WS}/ls_home"
FAKE_DL_DIR="${TEST_WS}/downloads"
FAKE_SYSROOT="${TEST_WS}/sysroot"
mkdir -p "$FAKE_HOME" "$FAKE_LS_HOME" "$FAKE_DL_DIR" "$FAKE_SYSROOT"
printf '# untouched bashrc\n' > "${FAKE_HOME}/.bashrc"
printf '# untouched profile\n' > "${FAKE_HOME}/.profile"
printf '# untouched zshrc\n' > "${FAKE_HOME}/.zshrc"

# ## build_mock_tarball
# Builds a mock tarball containing an executable mock binary at <comp>-<ver>/bin/<bin_name>.
build_mock_tarball() {
  _comp="$1"
  _ver="$2"
  _bin="$3"
  _stage="${TEST_WS}/stage_${_comp}_${_ver}"
  mkdir -p "${_stage}/${_comp}-${_ver}/bin" "${FAKE_DL_DIR}/${_comp}"
  cat <<SHIM > "${_stage}/${_comp}-${_ver}/bin/${_bin}"
#!/bin/sh
printf '%s mock version %s\n' "${_bin}" "${_ver}"
exit 0
SHIM
  chmod +x "${_stage}/${_comp}-${_ver}/bin/${_bin}"
  _archive="${FAKE_DL_DIR}/${_comp}/${_comp}-${_ver}.tar.gz"
  tar -czf "$_archive" -C "$_stage" "${_comp}-${_ver}"
  rm -rf "$_stage"
  printf '%s\n' "${_comp}-${_ver}.tar.gz"
}

# ## verify_component_offline_vm
# Verifies offline tarball install, 2x idempotent re-install, and component test execution.
verify_component_offline_vm() {
  _cat="$1"
  _comp="$2"
  _bin="$3"
  _ver="$4"
  _prefix=$(printf '%s' "$_comp" | tr 'a-z-' 'A-Z_')

  _arch_name=$(build_mock_tarball "$_comp" "$_ver" "$_bin")
  _dl_url="https://example.invalid/${_comp}/${_arch_name}"

  if env -u STACK \
    HOME="$FAKE_HOME" \
    LIBSCRIPT_HOME="$FAKE_LS_HOME" \
    DOWNLOAD_DIR="$FAKE_DL_DIR" \
    LIBSCRIPT_TARGET_SYSROOT="$FAKE_SYSROOT" \
    "${_prefix}_INSTALL_METHOD=libscript_native" \
    "${_prefix}_DOWNLOAD_URL=${_dl_url}" \
    "${LIBSCRIPT_ROOT_DIR}/_lib/${_cat}/${_comp}/cli.sh" install "$_comp" "$_ver" >/dev/null 2>&1; then
    if [ -x "${FAKE_LS_HOME}/${_comp}/${_ver}/bin/${_bin}" ]; then
      pass_check "${_cat}/${_comp}: offline install placed ${_bin} in isolated LIBSCRIPT_HOME"
    else
      fail_check "${_cat}/${_comp}: binary ${_bin} missing at ${FAKE_LS_HOME}/${_comp}/${_ver}/bin/${_bin}"
      return
    fi
  else
    fail_check "${_cat}/${_comp}: offline install command failed"
    return
  fi

  _idem_out=$(env -u STACK \
    HOME="$FAKE_HOME" \
    LIBSCRIPT_HOME="$FAKE_LS_HOME" \
    DOWNLOAD_DIR="$FAKE_DL_DIR" \
    LIBSCRIPT_TARGET_SYSROOT="$FAKE_SYSROOT" \
    "${_prefix}_INSTALL_METHOD=libscript_native" \
    "${_prefix}_DOWNLOAD_URL=${_dl_url}" \
    "${LIBSCRIPT_ROOT_DIR}/_lib/${_cat}/${_comp}/cli.sh" install "$_comp" "$_ver" 2>&1 || true)
  case "$_idem_out" in
    *"already installed"*)
      pass_check "${_cat}/${_comp}: 2x install exited early idempotently"
      ;;
    *)
      fail_check "${_cat}/${_comp}: 2x install did not report already installed: ${_idem_out}"
      ;;
  esac

  if env -u STACK \
    HOME="$FAKE_HOME" \
    LIBSCRIPT_HOME="$FAKE_LS_HOME" \
    "${_prefix}_VERSION=${_ver}" \
    "${LIBSCRIPT_ROOT_DIR}/_lib/${_cat}/${_comp}/test.sh" >/dev/null 2>&1; then
    pass_check "${_cat}/${_comp}: smoke test passed against isolated ${_bin}"
  else
    fail_check "${_cat}/${_comp}: smoke test failed"
  fi
}

printf '=== 1. Verifying All 51 Tier 1.5 / Tier 2 / Tier 3 Components (Offline Install + 2x Idempotency + Test) ===\n'

COMPONENT_MATRIX='
base-system|dbus|dbus-daemon|1.16.0
base-system|locales|localedef|2.40
base-system|ntp|ntpd|4.2.8p18
base-system|sysctl|sysctl|4.0.5
base-system|tzdata|zdump|2024b
init-systems|launchd|launchctl|1.0.0
init-systems|smf|svcadm|5.11
init-systems|supervisord|supervisord|4.2.5
init-systems|windows-scm|sc|10.0.0
networking|bind9|named|9.20.4
networking|coredns|coredns|1.12.0
networking|dnsmasq|dnsmasq|2.90
networking|firewalld|firewall-cmd|2.3.0
networking|frr|vtysh|10.2.1
networking|keepalived|keepalived|2.3.2
networking|tailscale|tailscale|1.78.1
networking|ufw|ufw|0.36.2
audio|jack|jackd|1.9.22
audio|sndio|sndiod|1.10.0
display-managers|ly|ly|1.0.3
desktops|i3|i3|4.24
desktops|mate|mate-session|1.28.0
bootloaders|grub|grub-install|2.12
bootloaders|limine|limine|8.6.0
bootloaders|refind|refind-install|0.14.2
bootloaders|systemd-boot|bootctl|257
virtualization|lima|limactl|1.0.3
virtualization|multipass|multipass|1.14.1
virtualization|utm|utmctl|4.6.4
virtualization|wsl|wsl|2.4.8
orchestration|ansible|ansible|2.18.1
orchestration|buildah|buildah|1.38.0
orchestration|cilium|cilium|0.16.22
orchestration|consul|consul|1.20.1
orchestration|containerd|containerd|2.0.1
orchestration|cri-o|crio|1.31.3
orchestration|helm-controller|helm-controller|0.16.5
orchestration|k3s|k3s|1.31.4
orchestration|kubeadm|kubeadm|1.32.0
orchestration|libvirt|virsh|10.10.0
orchestration|lxc|lxc-ls|6.0.2
orchestration|lxd|lxd|5.21.2
orchestration|opensearch-dashboards|opensearch-dashboards|2.18.0
orchestration|podman|podman|5.3.1
orchestration|pulumi|pulumi|3.144.1
orchestration|rancher|rancher|2.10.1
orchestration|skopeo|skopeo|1.17.0
orchestration|terraform|terraform|1.10.3
orchestration|tofu|tofu|1.9.0
cloud-providers|oci|oci|3.51.4
cloud-providers|ovh|ovhcloud|0.6.0
'

for row in $COMPONENT_MATRIX; do
  [ -n "$row" ] || continue
  c_cat=$(printf '%s' "$row" | cut -d'|' -f1)
  c_name=$(printf '%s' "$row" | cut -d'|' -f2)
  c_bin=$(printf '%s' "$row" | cut -d'|' -f3)
  c_ver=$(printf '%s' "$row" | cut -d'|' -f4)
  verify_component_offline_vm "$c_cat" "$c_name" "$c_bin" "$c_ver"
done

printf '=== 2. Verifying Declarative Sysroot Staging (locales, sysctl, tzdata, grub, limine, refind, systemd-boot) ===\n'

for _staged_rel in \
  'etc/locale.conf' \
  'etc/locale.gen' \
  'etc/sysctl.d/99-libscript.conf' \
  'etc/timezone' \
  'boot/grub/grub.cfg' \
  'boot/limine/limine.conf' \
  'boot/EFI/refind/refind.conf' \
  'boot/loader/loader.conf'; do
  if [ -f "${FAKE_SYSROOT}/${_staged_rel}" ]; then
    pass_check "sysroot staged ${_staged_rel}"
  else
    fail_check "sysroot missing ${_staged_rel}"
  fi
done

if [ -L "${FAKE_SYSROOT}/etc/localtime" ]; then
  pass_check 'sysroot staged /etc/localtime timezone symlink'
else
  fail_check 'sysroot missing /etc/localtime symlink'
fi

printf '=== 3. Verifying Side-by-Side Multi-Version Coexistence & Switching (terraform 1.9.8 vs 1.10.3) ===\n'

_tf_old_arch=$(build_mock_tarball 'terraform' '1.9.8' 'terraform')
env -u STACK \
  HOME="$FAKE_HOME" \
  LIBSCRIPT_HOME="$FAKE_LS_HOME" \
  DOWNLOAD_DIR="$FAKE_DL_DIR" \
  TERRAFORM_INSTALL_METHOD='libscript_native' \
  TERRAFORM_DOWNLOAD_URL="https://example.invalid/terraform/${_tf_old_arch}" \
  "${LIBSCRIPT_ROOT_DIR}/libscript.sh" install terraform 1.9.8 >/dev/null 2>&1

_run_198=$(env -u STACK HOME="$FAKE_HOME" LIBSCRIPT_HOME="$FAKE_LS_HOME" "${LIBSCRIPT_ROOT_DIR}/libscript.sh" run terraform 1.9.8 -- --version 2>&1)
_run_1103=$(env -u STACK HOME="$FAKE_HOME" LIBSCRIPT_HOME="$FAKE_LS_HOME" "${LIBSCRIPT_ROOT_DIR}/libscript.sh" run terraform 1.10.3 -- --version 2>&1)

case "$_run_198" in
  *"1.9.8"*) pass_check 'side-by-side run terraform 1.9.8 resolved 1.9.8 binary' ;;
  *) fail_check "side-by-side run terraform 1.9.8 mismatch: ${_run_198}" ;;
esac

case "$_run_1103" in
  *"1.10.3"*) pass_check 'side-by-side run terraform 1.10.3 resolved 1.10.3 binary' ;;
  *) fail_check "side-by-side run terraform 1.10.3 mismatch: ${_run_1103}" ;;
esac

for _fmt in sh cmd ps1 fish json; do
  _env_out=$(env -u STACK HOME="$FAKE_HOME" LIBSCRIPT_HOME="$FAKE_LS_HOME" "${LIBSCRIPT_ROOT_DIR}/libscript.sh" env terraform 1.10.3 --format="$_fmt" 2>&1)
  case "$_env_out" in
    *"terraform/1.10.3/bin"*|*'terraform\1.10.3\bin'*)
      pass_check "env --format=${_fmt} emits isolated terraform 1.10.3 bin path"
      ;;
    *)
      fail_check "env --format=${_fmt} missing terraform 1.10.3 bin path: ${_env_out}"
      ;;
  esac
done

printf '=== 4. Verifying Cloud Provider DRY_RUN Drivers (OCI & OVHcloud) & Tag Formatting ===\n'

_oci_ip=$(env -u STACK DRY_RUN='true' "${LIBSCRIPT_ROOT_DIR}/_lib/cloud-providers/oci/cli.sh" node ip test-oci-vm 2>/dev/null)
if [ "$_oci_ip" = '203.0.113.21' ]; then
  pass_check 'oci node ip DRY_RUN returned simulated public IP 203.0.113.21'
else
  fail_check "oci node ip DRY_RUN mismatch: ${_oci_ip}"
fi

_ovh_ip=$(env -u STACK DRY_RUN='true' "${LIBSCRIPT_ROOT_DIR}/_lib/cloud-providers/ovh/cli.sh" node ip test-ovh-vm 2>/dev/null)
if [ "$_ovh_ip" = '203.0.113.22' ]; then
  pass_check 'ovh node ip DRY_RUN returned simulated public IP 203.0.113.22'
else
  fail_check "ovh node ip DRY_RUN mismatch: ${_ovh_ip}"
fi

for _cloud_act in \
  'compartment ensure ocid1.compartment.oc1..demo' \
  'network create demo-vcn us-ashburn-1' \
  'firewall create demo-nsg' \
  'node create demo-vm Oracle-Linux-9 us-ashburn-1' \
  'node sync demo-vm' \
  'node scp-from demo-vm /tmp/remote /tmp/local'; do
  # shellcheck disable=SC2086
  if env -u STACK DRY_RUN='true' "${LIBSCRIPT_ROOT_DIR}/_lib/cloud-providers/oci/cli.sh" $_cloud_act >/dev/null 2>&1; then
    pass_check "oci DRY_RUN passed: ${_cloud_act}"
  else
    fail_check "oci DRY_RUN failed: ${_cloud_act}"
  fi
done

for _ovh_act in \
  'project ensure demo-ovh-proj' \
  'network create demo-vrack GRA11' \
  'firewall create 203.0.113.22' \
  'node create demo-vm Ubuntu-24.04 GRA11' \
  'node sync demo-vm' \
  'node scp-from demo-vm /tmp/remote /tmp/local'; do
  # shellcheck disable=SC2086
  if env -u STACK DRY_RUN='true' "${LIBSCRIPT_ROOT_DIR}/_lib/cloud-providers/ovh/cli.sh" $_ovh_act >/dev/null 2>&1; then
    pass_check "ovh DRY_RUN passed: ${_ovh_act}"
  else
    fail_check "ovh DRY_RUN failed: ${_ovh_act}"
  fi
done

_tag_check=$(
  SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/_lib/cloud/core/tags.sh"
  export SCRIPT_NAME
  # shellcheck disable=SC1090
  . "${SCRIPT_NAME}"
  printf '%s|%s\n' "$(libscript_format_tags oci)" "$(libscript_format_tags ovh)"
)
case "$_tag_check" in
  *'--freeform-tags'*'--label'*)
    pass_check 'tags.sh formats both oci (--freeform-tags) and ovh (--label) tags'
    ;;
  *)
    fail_check "tags.sh oci/ovh tag formatting mismatch: ${_tag_check}"
    ;;
esac

printf '=== 5. Verifying Non-Invasive Profile Isolation & Package Mapper Resolution ===\n'

if [ "$(cat "${FAKE_HOME}/.bashrc")" = '# untouched bashrc' ] && \
   [ "$(cat "${FAKE_HOME}/.profile")" = '# untouched profile' ] && \
   [ "$(cat "${FAKE_HOME}/.zshrc")" = '# untouched zshrc' ]; then
  pass_check 'zero mutation of ~/.bashrc, ~/.profile, and ~/.zshrc across all 51 installs'
else
  fail_check 'shell profile files were mutated during component installation'
fi

if (
  SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/_lib/_common/pkg_mapper.sh"
  export SCRIPT_NAME
  # shellcheck disable=SC1090
  . "${SCRIPT_NAME}"
  [ "$(PKG_MGR='apk' map_package 'bind9')" = 'bind' ]
  [ "$(PKG_MGR='apt-get' map_package 'grub')" = 'grub2-common' ]
  [ "$(PKG_MGR='winget' map_package 'terraform')" = 'Hashicorp.Terraform' ]
  [ "$(PKG_MGR='brew' map_package 'tofu')" = 'opentofu' ]
  [ "$(PKG_MGR='winget' map_package 'oci')" = 'Oracle.OCICLI' ]
  [ "$(PKG_MGR='brew' map_package 'ovh')" = 'ovhcloud-cli' ]
); then
  pass_check 'pkg_mapper.sh resolves cross-OS package names for Section 10.8 recipes'
else
  fail_check 'pkg_mapper.sh mapping assertion failed'
fi

if [ "$FAILURES" -gt 0 ]; then
  printf '[FAIL] Tier 1.5/2/3 System, Orchestration & Cloud Test Suite failed (%d/%d checks failed)\n' "$FAILURES" "$CHECKS" >&2
  exit 1
fi

printf '[SUCCESS] All %d behavioral checks passed across 51 components!\n' "$CHECKS"
exit 0
