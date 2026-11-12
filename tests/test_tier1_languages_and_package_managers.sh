#!/bin/sh
# ## Overview
# End-to-end behavioral test suite for the 20 Tier 1 Language version managers (`_lib/languages/*`)
# and 4 Tier 1 Package Manager recipes (`_lib/package-managers/*`) added in Sections 10.2 and 10.3.
#
# ## Usage
# ./tests/test_tier1_languages_and_package_managers.sh

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
# Builds a synthetic upstream-layout .tar.gz archive containing bin/<binary> for deterministic offline install tests.
build_mock_tarball() {
  _comp="$1"
  _bin="$2"
  _ver="$3"
  _out_tgz="$4"
  _stage="${TEST_WS}/stage_${_comp}_${_ver}"
  rm -rf "$_stage"
  mkdir -p "$_stage/${_comp}-${_ver}/bin"
  cat <<MOCK_EOF > "$_stage/${_comp}-${_ver}/bin/${_bin}"
#!/bin/sh
printf '%s mock version %s (%s)\n' "${_comp}" "${_ver}" "\$*"
exit 0
MOCK_EOF
  chmod +x "$_stage/${_comp}-${_ver}/bin/${_bin}"
  tar -czf "$_out_tgz" -C "$_stage" "${_comp}-${_ver}"
  rm -rf "$_stage"
}

# ## build_mock_nested_zip
# Builds a synthetic nested .zip archive (e.g., dart-sdk/bin/dart or v/v) to verify zip directory flattening and root binary linking.
build_mock_nested_zip() {
  _top_dir="$1"
  _rel_bin="$2"
  _comp="$3"
  _ver="$4"
  _out_zip="$5"
  _stage="${TEST_WS}/zip_stage_${_comp}_${_ver}"
  rm -rf "$_stage"
  _full_bin="${_stage}/${_top_dir}/${_rel_bin}"
  mkdir -p "$(dirname "$_full_bin")"
  cat <<MOCK_EOF > "$_full_bin"
#!/bin/sh
printf '%s zip-mock version %s (%s)\n' "${_comp}" "${_ver}" "\$*"
exit 0
MOCK_EOF
  chmod +x "$_full_bin"
  (cd "$_stage" && zip -qr "$_out_zip" "$_top_dir")
  rm -rf "$_stage"
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

  if [ "$_layout" = "zip-nested-bin" ]; then
    _arc_name="${_comp}-${_ver}.zip"
    build_mock_nested_zip "${_comp}-sdk" "bin/${_bin}" "$_comp" "$_ver" "${FAKE_DL_DIR}/${_comp}/${_arc_name}"
  elif [ "$_layout" = "zip-nested-root" ]; then
    _arc_name="${_comp}-${_ver}.zip"
    build_mock_nested_zip "${_comp}" "${_bin}" "$_comp" "$_ver" "${FAKE_DL_DIR}/${_comp}/${_arc_name}"
  else
    _arc_name="${_comp}-${_ver}.tar.gz"
    build_mock_tarball "$_comp" "$_bin" "$_ver" "${FAKE_DL_DIR}/${_comp}/${_arc_name}"
  fi

  _dl_url="https://example.invalid/${_comp}/${_arc_name}"

  if env \
    HOME="$FAKE_HOME" \
    LIBSCRIPT_HOME="$FAKE_LS_HOME" \
    DOWNLOAD_DIR="$FAKE_DL_DIR" \
    LIBSCRIPT_GLOBAL_INSTALL_METHOD="libscript_native" \
    "${_prefix}_INSTALL_METHOD=libscript_native" \
    "${_prefix}_DOWNLOAD_URL=${_dl_url}" \
    STACK="" \
    "${LIBSCRIPT_ROOT_DIR}/libscript.sh" install "$_comp" "$_ver" >/dev/null 2>&1; then
    if [ -x "${FAKE_LS_HOME}/${_comp}/${_ver}/bin/${_bin}" ]; then
      pass_check "${_cat}/${_comp}: initial offline install created executable bin/${_bin}"
    else
      fail_check "${_cat}/${_comp}: bin/${_bin} missing after install"
    fi
  else
    fail_check "${_cat}/${_comp}: initial offline install failed"
  fi

  _second_out=$(env \
    HOME="$FAKE_HOME" \
    LIBSCRIPT_HOME="$FAKE_LS_HOME" \
    DOWNLOAD_DIR="$FAKE_DL_DIR" \
    LIBSCRIPT_GLOBAL_INSTALL_METHOD="libscript_native" \
    "${_prefix}_INSTALL_METHOD=libscript_native" \
    "${_prefix}_DOWNLOAD_URL=${_dl_url}" \
    STACK="" \
    "${LIBSCRIPT_ROOT_DIR}/libscript.sh" install "$_comp" "$_ver" 2>&1 || true)

  case "$_second_out" in
    *"already installed"*)
      pass_check "${_cat}/${_comp}: 2x install exited idempotently ('already installed')"
      ;;
    *)
      fail_check "${_cat}/${_comp}: 2x install did not hit idempotent early exit"
      ;;
  esac

  if env \
    HOME="$FAKE_HOME" \
    LIBSCRIPT_HOME="$FAKE_LS_HOME" \
    "${_prefix}_VERSION=${_ver}" \
    STACK="" \
    "${LIBSCRIPT_ROOT_DIR}/_lib/${_cat}/${_comp}/test.sh" >/dev/null 2>&1; then
    pass_check "${_cat}/${_comp}: smoke test.sh succeeded"
  else
    fail_check "${_cat}/${_comp}: smoke test.sh failed"
  fi
}

printf '=== 1. Testing Offline Install, Nested Archive Extraction, 2x Idempotency & Smoke Tests ===\n'
verify_component_lifecycle "languages" "clojure" "clojure" "1.12.0.1488" "tar"
verify_component_lifecycle "languages" "crystal" "crystal" "1.15.1" "tar"
verify_component_lifecycle "languages" "dart" "dart" "3.6.1" "zip-nested-bin"
verify_component_lifecycle "languages" "erlang" "erl" "27.2" "tar"
verify_component_lifecycle "languages" "fortran" "gfortran" "14.2.0" "tar"
verify_component_lifecycle "languages" "gleam" "gleam" "1.7.0" "tar"
verify_component_lifecycle "languages" "groovy" "groovy" "4.0.24" "zip-nested-bin"
verify_component_lifecycle "languages" "haskell" "ghc" "9.10.1" "tar"
verify_component_lifecycle "languages" "lua" "lua" "5.4.7" "tar"
verify_component_lifecycle "languages" "nim" "nim" "2.2.2" "tar"
verify_component_lifecycle "languages" "ocaml" "ocaml" "5.2.1" "tar"
verify_component_lifecycle "languages" "odin" "odin" "dev-2025-01" "zip-nested-root"
verify_component_lifecycle "languages" "perl" "perl" "5.40.0" "tar"
verify_component_lifecycle "languages" "prolog" "swipl" "9.2.9" "tar"
verify_component_lifecycle "languages" "racket" "racket" "8.15" "tar"
verify_component_lifecycle "languages" "scala" "scala" "3.6.3" "tar"
verify_component_lifecycle "languages" "scheme" "guile" "10.1.0" "tar"
verify_component_lifecycle "languages" "tcl" "tclsh" "8.6.16" "tar"
verify_component_lifecycle "languages" "vala" "valac" "0.56.17" "tar"
verify_component_lifecycle "languages" "vlang" "v" "0.4.9" "zip-nested-root"

verify_component_lifecycle "package-managers" "maven-wrapper" "mvnw" "3.3.2" "zip-nested-root"
verify_component_lifecycle "package-managers" "pkgsrc" "pkgin" "2024Q4" "tar"
verify_component_lifecycle "package-managers" "port" "port" "2.10.5" "tar"
verify_component_lifecycle "package-managers" "yum" "yum" "4.9.0" "tar"

printf '=== 2. Testing Side-by-Side Multi-Version Coexistence & Switching (gleam 1.6.0 vs 1.7.0) ===\n'
verify_component_lifecycle "languages" "gleam" "gleam" "1.6.0" "tar"

_run_16=$(env HOME="$FAKE_HOME" LIBSCRIPT_HOME="$FAKE_LS_HOME" STACK="" \
  "${LIBSCRIPT_ROOT_DIR}/_lib/languages/gleam/cli.sh" run gleam 1.6.0 --version 2>&1)
_run_17=$(env HOME="$FAKE_HOME" LIBSCRIPT_HOME="$FAKE_LS_HOME" STACK="" \
  "${LIBSCRIPT_ROOT_DIR}/_lib/languages/gleam/cli.sh" run gleam 1.7.0 --version 2>&1)

case "$_run_16" in
  *"1.6.0"*) pass_check "gleam 1.6.0 executes side-by-side" ;;
  *) fail_check "gleam 1.6.0 side-by-side output mismatch: ${_run_16}" ;;
esac

case "$_run_17" in
  *"1.7.0"*) pass_check "gleam 1.7.0 executes side-by-side" ;;
  *) fail_check "gleam 1.7.0 side-by-side output mismatch: ${_run_17}" ;;
esac

for _fmt in sh cmd ps1 fish json; do
  _env_out=$(env HOME="$FAKE_HOME" LIBSCRIPT_HOME="$FAKE_LS_HOME" STACK="" \
    "${LIBSCRIPT_ROOT_DIR}/libscript.sh" env gleam 1.7.0 --format="$_fmt" 2>&1)
  case "$_env_out" in
    *"gleam/1.7.0/bin"*|*"gleam\\1.7.0\\bin"*)
      pass_check "env --format=${_fmt} emits isolated gleam 1.7.0 bin path"
      ;;
    *)
      fail_check "env --format=${_fmt} missing gleam 1.7.0 bin path: ${_env_out}"
      ;;
  esac
done

printf '=== 3. Testing Cross-Platform Package Mapper Resolution ===\n'
SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/_lib/_common/pkg_mapper.sh"
export SCRIPT_NAME
# shellcheck disable=SC1090
. "${SCRIPT_NAME}"

PKG_MGR='dnf'
export PKG_MGR
if [ "$(map_package fortran)" = 'gcc-gfortran' ]; then
  pass_check 'pkg_mapper maps fortran -> gcc-gfortran on dnf'
else
  fail_check 'pkg_mapper fortran dnf mismatch'
fi
PKG_MGR='apt-get'
export PKG_MGR
if [ "$(map_package scheme)" = 'guile-3.0' ]; then
  pass_check 'pkg_mapper maps scheme -> guile-3.0 on apt-get'
else
  fail_check 'pkg_mapper scheme apt-get mismatch'
fi
PKG_MGR='winget'
export PKG_MGR
if [ "$(map_package dart)" = 'Google.DartSDK' ]; then
  pass_check 'pkg_mapper maps dart -> Google.DartSDK on winget'
else
  fail_check 'pkg_mapper dart winget mismatch'
fi

printf '=== 4. Verifying Shell Profile Isolation ===\n'
if [ "$(cat "${FAKE_HOME}/.bashrc")" = "# sentinel-bashrc" ] && \
   [ "$(cat "${FAKE_HOME}/.profile")" = "# sentinel-profile" ] && \
   [ "$(cat "${FAKE_HOME}/.zshrc")" = "# sentinel-zshrc" ]; then
  pass_check "Zero mutation of ~/.bashrc, ~/.profile, and ~/.zshrc across all 24 components"
else
  fail_check "User shell profiles were mutated!"
fi

if [ "$FAILURES" -gt 0 ]; then
  printf '[FAIL] Tier 1 Languages & Package Managers Test Suite failed (%d/%d checks failed)\n' "$FAILURES" "$CHECKS" >&2
  exit 1
fi

printf '[SUCCESS] All %d behavioral checks passed across 24 components!\n' "$CHECKS"
exit 0
