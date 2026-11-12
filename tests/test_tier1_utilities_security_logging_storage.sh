#!/bin/sh
# ## Overview
# Behavioral test suite for the 40 Tier 1 Utility, Security, Logging, Storage, and Git Server recipes (Section 10.7).
#
# ## Usage
# ./tests/test_tier1_utilities_security_logging_storage.sh

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

TEST_WS=$(mktemp -d)
trap 'rm -rf "$TEST_WS"' EXIT INT TERM

FAKE_HOME="${TEST_WS}/home"
FAKE_LS_HOME="${TEST_WS}/ls_home"
FAKE_DL_DIR="${TEST_WS}/downloads"
mkdir -p "$FAKE_HOME" "$FAKE_LS_HOME" "$FAKE_DL_DIR"

printf '# sentinel-bashrc\n' > "${FAKE_HOME}/.bashrc"
printf '# sentinel-profile\n' > "${FAKE_HOME}/.profile"
printf '# sentinel-zshrc\n' > "${FAKE_HOME}/.zshrc"

FAILURES=0
CHECKS=0

# ## pass_check
# Records a passing test assertion.
pass_check() {
  CHECKS=$((CHECKS + 1))
  printf '[PASS] %s\n' "$1"
}

# ## fail_check
# Records a failing test assertion and increments FAILURES.
fail_check() {
  CHECKS=$((CHECKS + 1))
  FAILURES=$((FAILURES + 1))
  printf '[FAIL] %s\n' "$1" >&2
}

# ## build_mock_tarball
# Builds a synthetic upstream-layout .tar.gz archive containing a mock executable at _rel_bin.
build_mock_tarball() {
  _comp="$1"
  _rel_bin="$2"
  _ver="$3"
  _out_tgz="$4"
  _stage="${TEST_WS}/stage_${_comp}_${_ver}"
  rm -rf "$_stage"
  _full_bin="${_stage}/${_comp}-${_ver}/${_rel_bin}"
  mkdir -p "$(dirname "$_full_bin")"
  cat <<MOCK_EOF > "$_full_bin"
#!/bin/sh
printf '%s mock version %s (%s)\n' "${_comp}" "${_ver}" "\$*"
exit 0
MOCK_EOF
  chmod +x "$_full_bin"
  tar -czf "$_out_tgz" -C "$_stage" "${_comp}-${_ver}"
  rm -rf "$_stage"
}

# ## build_mock_flat_zip
# Builds a synthetic flat .zip archive containing a single binary (e.g., loki-linux-amd64 or vault).
build_mock_flat_zip() {
  _file_name="$1"
  _comp="$2"
  _ver="$3"
  _out_zip="$4"
  _stage="${TEST_WS}/zip_stage_${_comp}_${_ver}"
  rm -rf "$_stage"
  mkdir -p "$_stage"
  cat <<MOCK_EOF > "${_stage}/${_file_name}"
#!/bin/sh
printf '%s zip-mock version %s (%s)\n' "${_comp}" "${_ver}" "\$*"
exit 0
MOCK_EOF
  chmod +x "${_stage}/${_file_name}"
  (cd "$_stage" && zip -qr "$_out_zip" "$_file_name")
  rm -rf "$_stage"
}

# ## build_mock_raw_bin
# Builds a synthetic standalone executable binary download (e.g., garage or forgejo).
build_mock_raw_bin() {
  _comp="$1"
  _ver="$2"
  _out_bin="$3"
  cat <<MOCK_EOF > "$_out_bin"
#!/bin/sh
printf '%s raw-mock version %s (%s)\n' "${_comp}" "${_ver}" "\$*"
exit 0
MOCK_EOF
  chmod +x "$_out_bin"
}

# ## verify_component_lifecycle
# Verifies offline install, 2x idempotency, env isolation, and test.sh execution for a single component.
verify_component_lifecycle() {
  _cat="$1"
  _comp="$2"
  _bin="$3"
  _ver="$4"
  _layout="${5:-tar}"

  _prefix=$(printf '%s' "$_comp" | tr '[:lower:]-' '[:upper:]_')
  mkdir -p "${FAKE_DL_DIR}/${_comp}"

  case "$_layout" in
    zip-flat)
      _arc_name="${_comp}-${_ver}.zip"
      build_mock_flat_zip "${_bin}" "$_comp" "$_ver" "${FAKE_DL_DIR}/${_comp}/${_arc_name}"
      ;;
    zip-suffixed)
      _arc_name="${_comp}-${_ver}.zip"
      build_mock_flat_zip "${_bin}-linux-amd64" "$_comp" "$_ver" "${FAKE_DL_DIR}/${_comp}/${_arc_name}"
      ;;
    tar-underscore)
      _arc_name="${_comp}-${_ver}.tar.gz"
      build_mock_tarball "$_comp" "${_bin}_linux_amd64" "$_ver" "${FAKE_DL_DIR}/${_comp}/${_arc_name}"
      ;;
    tar-sh-launcher)
      _arc_name="${_comp}-${_ver}.tar.gz"
      build_mock_tarball "$_comp" "bin/${_bin}.sh" "$_ver" "${FAKE_DL_DIR}/${_comp}/${_arc_name}"
      ;;
    raw-bin)
      _arc_name="${_comp}-${_ver}-bin"
      build_mock_raw_bin "$_comp" "$_ver" "${FAKE_DL_DIR}/${_comp}/${_arc_name}"
      ;;
    *)
      _arc_name="${_comp}-${_ver}.tar.gz"
      build_mock_tarball "$_comp" "bin/${_bin}" "$_ver" "${FAKE_DL_DIR}/${_comp}/${_arc_name}"
      ;;
  esac

  _dl_url="https://example.invalid/${_comp}/${_arc_name}"

  if env HOME="$FAKE_HOME" LIBSCRIPT_HOME="$FAKE_LS_HOME" DOWNLOAD_DIR="$FAKE_DL_DIR" LIBSCRIPT_GLOBAL_INSTALL_METHOD="libscript_native" "${_prefix}_INSTALL_METHOD=libscript_native" "${_prefix}_DOWNLOAD_URL=${_dl_url}" STACK="" "${LIBSCRIPT_ROOT_DIR}/libscript.sh" install "$_comp" "$_ver" >/dev/null 2>&1; then
    if [ -x "${FAKE_LS_HOME}/${_comp}/${_ver}/bin/${_bin}" ]; then
      pass_check "${_cat}/${_comp}: initial offline install created executable bin/${_bin}"
    else
      fail_check "${_cat}/${_comp}: bin/${_bin} missing after install"
    fi
  else
    fail_check "${_cat}/${_comp}: initial offline install failed"
  fi

  _second_out=$(env HOME="$FAKE_HOME" LIBSCRIPT_HOME="$FAKE_LS_HOME" DOWNLOAD_DIR="$FAKE_DL_DIR" LIBSCRIPT_GLOBAL_INSTALL_METHOD="libscript_native" "${_prefix}_INSTALL_METHOD=libscript_native" "${_prefix}_DOWNLOAD_URL=${_dl_url}" STACK="" "${LIBSCRIPT_ROOT_DIR}/libscript.sh" install "$_comp" "$_ver" 2>&1 || true)

  case "$_second_out" in
    *"already installed"*)
      pass_check "${_cat}/${_comp}: 2x install exited idempotently ('already installed')"
      ;;
    *)
      fail_check "${_cat}/${_comp}: 2x install did not hit idempotent early exit"
      ;;
  esac

  if env HOME="$FAKE_HOME" LIBSCRIPT_HOME="$FAKE_LS_HOME" "${_prefix}_VERSION=${_ver}" STACK="" "${LIBSCRIPT_ROOT_DIR}/_lib/${_cat}/${_comp}/test.sh" >/dev/null 2>&1; then
    pass_check "${_cat}/${_comp}: smoke test.sh succeeded"
  else
    fail_check "${_cat}/${_comp}: smoke test.sh failed"
  fi
}

printf '=== 1. Testing Section 10.7 Tier 1 Utilities (21 Components) ===\n'
verify_component_lifecycle "utilities" "fd" "fd" "10.2.0" "tar"
verify_component_lifecycle "utilities" "ffmpeg" "ffmpeg" "7.1" "tar"
verify_component_lifecycle "utilities" "fzf" "fzf" "0.57.0" "tar"
verify_component_lifecycle "utilities" "git" "git" "2.47.1" "tar"
verify_component_lifecycle "utilities" "graphviz" "dot" "12.2.1" "tar"
verify_component_lifecycle "utilities" "htop" "htop" "3.3.0" "tar"
verify_component_lifecycle "utilities" "imagemagick" "magick" "7.1.1-43" "tar"
verify_component_lifecycle "utilities" "openssl" "openssl" "3.4.0" "tar"
verify_component_lifecycle "utilities" "pandoc" "pandoc" "3.6.2" "tar"
verify_component_lifecycle "utilities" "ripgrep" "rg" "14.1.1" "tar"
verify_component_lifecycle "utilities" "rsync" "rsync" "3.3.0" "tar"
verify_component_lifecycle "utilities" "sqlite-tools" "sqlite3" "3470200" "zip-flat"
verify_component_lifecycle "utilities" "tar" "tar" "1.35" "tar"
verify_component_lifecycle "utilities" "tree" "tree" "2.2.1" "tar"
verify_component_lifecycle "utilities" "unzip" "unzip" "6.0" "tar"
verify_component_lifecycle "utilities" "vim" "vim" "9.1.0950" "tar"
verify_component_lifecycle "utilities" "xorriso" "xorriso" "1.5.6" "tar"
verify_component_lifecycle "utilities" "xz" "xz" "5.6.3" "tar"
verify_component_lifecycle "utilities" "yq" "yq" "4.44.6" "tar-underscore"
verify_component_lifecycle "utilities" "zip" "zip" "3.0" "tar"
verify_component_lifecycle "utilities" "zstd" "zstd" "1.5.6" "tar"

printf '=== 2. Testing Section 10.7 Security, Logging, Storage Layers & Git Servers (19 Components) ===\n'
verify_component_lifecycle "security" "crowdsec" "crowdsec" "1.6.4" "tar"
verify_component_lifecycle "security" "fail2ban" "fail2ban-client" "1.1.0" "tar"
verify_component_lifecycle "security" "keycloak" "kc" "26.0.7" "tar-sh-launcher"
verify_component_lifecycle "security" "step-ca" "step-ca" "0.27.5" "tar"
verify_component_lifecycle "security" "vault" "vault" "1.18.3" "zip-flat"
verify_component_lifecycle "security" "wireguard" "wg" "1.0.20210914" "tar"
verify_component_lifecycle "logging" "grafana" "grafana" "11.4.0" "tar"
verify_component_lifecycle "logging" "loki" "loki" "3.3.2" "zip-suffixed"
verify_component_lifecycle "logging" "otel-collector" "otelcol" "0.116.1" "tar"
verify_component_lifecycle "logging" "prometheus" "prometheus" "3.1.0" "tar"
verify_component_lifecycle "logging" "vector" "vector" "0.43.1" "tar"
verify_component_lifecycle "storage-layers" "ceph" "ceph" "19.2.0" "tar"
verify_component_lifecycle "storage-layers" "garage" "garage" "1.0.1" "raw-bin"
verify_component_lifecycle "storage-layers" "glusterfs" "glusterd" "11.1" "tar"
verify_component_lifecycle "storage-layers" "juicefs" "juicefs" "1.2.1" "tar"
verify_component_lifecycle "storage-layers" "seaweedfs" "weed" "3.80" "tar"
verify_component_lifecycle "storage-layers" "zfs" "zfs" "2.2.7" "tar"
verify_component_lifecycle "git-servers" "cgit" "cgit" "1.2.3" "tar"
verify_component_lifecycle "git-servers" "forgejo" "forgejo" "9.0.3" "raw-bin"

printf '=== 3. Testing Side-by-Side Multi-Version Coexistence & Switching (ripgrep 14.1.0 vs 14.1.1) ===\n'
verify_component_lifecycle "utilities" "ripgrep" "rg" "14.1.0" "tar"

_run_1410=$(env HOME="$FAKE_HOME" LIBSCRIPT_HOME="$FAKE_LS_HOME" STACK="" "${LIBSCRIPT_ROOT_DIR}/_lib/utilities/ripgrep/cli.sh" run ripgrep 14.1.0 --version 2>&1)
_run_1411=$(env HOME="$FAKE_HOME" LIBSCRIPT_HOME="$FAKE_LS_HOME" STACK="" "${LIBSCRIPT_ROOT_DIR}/_lib/utilities/ripgrep/cli.sh" run ripgrep 14.1.1 --version 2>&1)

case "$_run_1410" in
  *"14.1.0"*) pass_check "ripgrep 14.1.0 executes side-by-side" ;;
  *) fail_check "ripgrep 14.1.0 side-by-side output mismatch: ${_run_1410}" ;;
esac

case "$_run_1411" in
  *"14.1.1"*) pass_check "ripgrep 14.1.1 executes side-by-side" ;;
  *) fail_check "ripgrep 14.1.1 side-by-side output mismatch: ${_run_1411}" ;;
esac

for _fmt in sh cmd ps1 fish json; do
  _env_out=$(env HOME="$FAKE_HOME" LIBSCRIPT_HOME="$FAKE_LS_HOME" STACK="" "${LIBSCRIPT_ROOT_DIR}/libscript.sh" env ripgrep 14.1.1 --format="$_fmt" 2>&1)
  case "$_env_out" in
    *"ripgrep/14.1.1/bin"*|*'ripgrep\14.1.1\bin'*)
      pass_check "env --format=${_fmt} emits isolated ripgrep 14.1.1 bin path"
      ;;
    *)
      fail_check "env --format=${_fmt} missing ripgrep 14.1.1 bin path: ${_env_out}"
      ;;
  esac
done

printf '=== 4. Testing Physical & Multi-Tenant Lifecycle Hooks (keycloak) ===\n'
if env HOME="$FAKE_HOME" LIBSCRIPT_HOME="$FAKE_LS_HOME" LIBSCRIPT_TARGET_SYSROOT="${TEST_WS}/sysroot" STACK="" "${LIBSCRIPT_ROOT_DIR}/_lib/security/keycloak/hooks/configure.sh" >/dev/null 2>&1 && env HOME="$FAKE_HOME" LIBSCRIPT_HOME="$FAKE_LS_HOME" LIBSCRIPT_TARGET_SYSROOT="${TEST_WS}/sysroot" STACK="" "${LIBSCRIPT_ROOT_DIR}/_lib/security/keycloak/hooks/provision_tenant.sh" --tenant=realm1 >/dev/null 2>&1; then
  pass_check "keycloak physical & logical hooks execute cleanly"
else
  fail_check "keycloak lifecycle hooks failed"
fi

printf '=== 5. Testing Cross-Platform Package Mapper Resolution ===\n'
SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/_lib/_common/pkg_mapper.sh"
export SCRIPT_NAME
# shellcheck disable=SC1090
. "${SCRIPT_NAME}"

PKG_MGR='apt-get'
export PKG_MGR
if [ "$(map_package fd)" = 'fd-find' ]; then
  pass_check 'pkg_mapper maps fd -> fd-find on apt-get'
else
  fail_check 'pkg_mapper fd apt-get mismatch'
fi
if [ "$(map_package zfs)" = 'zfsutils-linux' ]; then
  pass_check 'pkg_mapper maps zfs -> zfsutils-linux on apt-get'
else
  fail_check 'pkg_mapper zfs apt-get mismatch'
fi
PKG_MGR='winget'
export PKG_MGR
if [ "$(map_package ripgrep)" = 'BurntSushi.ripgrep.MSVC' ]; then
  pass_check 'pkg_mapper maps ripgrep -> BurntSushi.ripgrep.MSVC on winget'
else
  fail_check 'pkg_mapper ripgrep winget mismatch'
fi

printf '=== 6. Verifying Shell Profile Isolation ===\n'
if [ "$(cat "${FAKE_HOME}/.bashrc")" = "# sentinel-bashrc" ] && [ "$(cat "${FAKE_HOME}/.profile")" = "# sentinel-profile" ] && [ "$(cat "${FAKE_HOME}/.zshrc")" = "# sentinel-zshrc" ]; then
  pass_check "Zero mutation of ~/.bashrc, ~/.profile, and ~/.zshrc across all 40 components"
else
  fail_check "User shell profiles were mutated!"
fi

if [ "$FAILURES" -gt 0 ]; then
  printf '[FAIL] Tier 1 Utilities/Security/Logging/Storage Test Suite failed (%d/%d checks failed)\n' "$FAILURES" "$CHECKS" >&2
  exit 1
fi

printf '[SUCCESS] All %d behavioral checks passed across 40 components!\n' "$CHECKS"
exit 0
