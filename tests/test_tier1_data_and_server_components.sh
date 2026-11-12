#!/bin/sh
# ## Overview
# Behavioral test suite for the 46 Tier 1 Database, Cache, Search, Broker, Web, and App Server recipes (Sections 10.4-10.6).
#
# ## Usage
# ./tests/test_tier1_data_and_server_components.sh

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
# Builds a synthetic upstream-layout .tar.gz archive containing bin/<binary> (or sbin/<binary> or bin/<binary>.sh).
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

# ## build_mock_nested_zip
# Builds a synthetic nested .zip archive to verify zip directory flattening and binary linking.
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

  case "$_layout" in
    zip-nested-bin)
      _arc_name="${_comp}-${_ver}.zip"
      build_mock_nested_zip "${_comp}-dist" "bin/${_bin}" "$_comp" "$_ver" "${FAKE_DL_DIR}/${_comp}/${_arc_name}"
      ;;
    zip-nested-root)
      _arc_name="${_comp}-${_ver}.zip"
      build_mock_nested_zip "${_comp}" "${_bin}" "$_comp" "$_ver" "${FAKE_DL_DIR}/${_comp}/${_arc_name}"
      ;;
    tar-sbin)
      _arc_name="${_comp}-${_ver}.tar.gz"
      build_mock_tarball "$_comp" "sbin/${_bin}" "$_ver" "${FAKE_DL_DIR}/${_comp}/${_arc_name}"
      ;;
    tar-sh-launcher)
      _arc_name="${_comp}-${_ver}.tar.gz"
      build_mock_tarball "$_comp" "bin/${_bin}.sh" "$_ver" "${FAKE_DL_DIR}/${_comp}/${_arc_name}"
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

printf '=== 1. Testing Section 10.4 Tier 1 Databases (17 Components) ===\n'
verify_component_lifecycle "databases" "cassandra" "cassandra" "5.0.2" "tar"
verify_component_lifecycle "databases" "clickhouse" "clickhouse" "24.12.2.29" "tar"
verify_component_lifecycle "databases" "cockroachdb" "cockroach" "24.3.2" "tar"
verify_component_lifecycle "databases" "couchdb" "couchdb" "3.4.2" "tar"
verify_component_lifecycle "databases" "ferretdb" "ferretdb" "1.24.0" "tar"
verify_component_lifecycle "databases" "firebird" "isql-fb" "5.0.1" "tar"
verify_component_lifecycle "databases" "influxdb" "influxd" "2.7.11" "tar"
verify_component_lifecycle "databases" "lmdb" "mdb_stat" "0.9.33" "tar"
verify_component_lifecycle "databases" "mssql" "sqlcmd" "1.8.2" "tar"
verify_component_lifecycle "databases" "neo4j" "neo4j" "5.26.0" "tar"
verify_component_lifecycle "databases" "questdb" "questdb" "8.2.1" "tar-sh-launcher"
verify_component_lifecycle "databases" "rethinkdb" "rethinkdb" "2.4.4" "tar"
verify_component_lifecycle "databases" "rocksdb" "ldb" "9.10.0" "tar"
verify_component_lifecycle "databases" "scylladb" "scylla" "6.2.2" "tar-sbin"
verify_component_lifecycle "databases" "surrealdb" "surreal" "2.1.4" "tar"
verify_component_lifecycle "databases" "tidb" "tidb-server" "8.5.0" "tar"
verify_component_lifecycle "databases" "timescaledb" "timescaledb-tune" "2.17.2" "tar"

printf '=== 2. Testing Section 10.5 Tier 1 Caches, Search & Message Brokers (12 Components) ===\n'
verify_component_lifecycle "caches" "dragonfly" "dragonfly" "1.26.0" "tar"
verify_component_lifecycle "caches" "hazelcast" "hz" "5.5.0" "tar"
verify_component_lifecycle "caches" "keydb" "keydb-server" "6.3.4" "tar"
verify_component_lifecycle "caches" "varnish" "varnishd" "7.6.1" "tar-sbin"
verify_component_lifecycle "search" "opensearch" "opensearch" "2.18.0" "tar"
verify_component_lifecycle "search" "solr" "solr" "9.7.0" "tar"
verify_component_lifecycle "search" "sonic" "sonic" "1.4.9" "tar"
verify_component_lifecycle "search" "typesense" "typesense-server" "27.1" "tar"
verify_component_lifecycle "message-brokers" "activemq" "activemq" "6.1.4" "tar"
verify_component_lifecycle "message-brokers" "pulsar" "pulsar" "4.0.1" "tar"
verify_component_lifecycle "message-brokers" "redpanda" "rpk" "24.3.2" "zip-nested-root"
verify_component_lifecycle "message-brokers" "zeromq" "curve_keygen" "4.3.5" "tar"

printf '=== 3. Testing Section 10.6 Tier 1 Web Servers & App Servers (17 Components) ===\n'
verify_component_lifecycle "web-servers" "apache" "apachectl" "2.4.62" "tar-sbin"
verify_component_lifecycle "web-servers" "envoy" "envoy" "1.32.3" "tar"
verify_component_lifecycle "web-servers" "haproxy" "haproxy" "3.1.2" "tar-sbin"
verify_component_lifecycle "web-servers" "openresty" "openresty" "1.27.1.1" "tar"
verify_component_lifecycle "web-servers" "tomcat" "catalina" "10.1.34" "tar-sh-launcher"
verify_component_lifecycle "web-servers" "traefik" "traefik" "3.2.3" "tar"
verify_component_lifecycle "app-servers" "glassfish" "asadmin" "7.0.21" "zip-nested-bin"
verify_component_lifecycle "app-servers" "jboss" "jboss-cli" "34.0.1.Final" "tar-sh-launcher"
verify_component_lifecycle "app-servers" "jetty" "jetty" "12.0.16" "tar"
verify_component_lifecycle "app-servers" "passenger" "passenger" "6.0.24" "tar"
verify_component_lifecycle "app-servers" "payara" "asadmin" "6.2024.12" "zip-nested-bin"
verify_component_lifecycle "app-servers" "php-fpm" "php-fpm" "8.4.2" "tar-sbin"
verify_component_lifecycle "app-servers" "pm2" "pm2" "5.4.3" "tar"
verify_component_lifecycle "app-servers" "puma" "puma" "6.5.0" "tar"
verify_component_lifecycle "app-servers" "triton" "tritonserver" "2.53.0" "tar"
verify_component_lifecycle "app-servers" "unicorn" "unicorn" "6.1.0" "tar"
verify_component_lifecycle "app-servers" "wildfly" "jboss-cli" "34.0.1.Final" "tar-sh-launcher"

printf '=== 4. Testing Side-by-Side Multi-Version Coexistence & Switching (surrealdb 2.1.3 vs 2.1.4) ===\n'
verify_component_lifecycle "databases" "surrealdb" "surreal" "2.1.3" "tar"

_run_213=$(env HOME="$FAKE_HOME" LIBSCRIPT_HOME="$FAKE_LS_HOME" STACK="" "${LIBSCRIPT_ROOT_DIR}/_lib/databases/surrealdb/cli.sh" run surrealdb 2.1.3 version 2>&1)
_run_214=$(env HOME="$FAKE_HOME" LIBSCRIPT_HOME="$FAKE_LS_HOME" STACK="" "${LIBSCRIPT_ROOT_DIR}/_lib/databases/surrealdb/cli.sh" run surrealdb 2.1.4 version 2>&1)

case "$_run_213" in
  *"2.1.3"*) pass_check "surrealdb 2.1.3 executes side-by-side" ;;
  *) fail_check "surrealdb 2.1.3 side-by-side output mismatch: ${_run_213}" ;;
esac

case "$_run_214" in
  *"2.1.4"*) pass_check "surrealdb 2.1.4 executes side-by-side" ;;
  *) fail_check "surrealdb 2.1.4 side-by-side output mismatch: ${_run_214}" ;;
esac

for _fmt in sh cmd ps1 fish json; do
  _env_out=$(env HOME="$FAKE_HOME" LIBSCRIPT_HOME="$FAKE_LS_HOME" STACK="" "${LIBSCRIPT_ROOT_DIR}/libscript.sh" env surrealdb 2.1.4 --format="$_fmt" 2>&1)
  case "$_env_out" in
    *"surrealdb/2.1.4/bin"*|*'surrealdb\2.1.4\bin'*)
      pass_check "env --format=${_fmt} emits isolated surrealdb 2.1.4 bin path"
      ;;
    *)
      fail_check "env --format=${_fmt} missing surrealdb 2.1.4 bin path: ${_env_out}"
      ;;
  esac
done

printf '=== 5. Testing Physical & Multi-Tenant Lifecycle Hooks ===\n'
if env HOME="$FAKE_HOME" LIBSCRIPT_HOME="$FAKE_LS_HOME" LIBSCRIPT_TARGET_SYSROOT="${TEST_WS}/sysroot" STACK="" "${LIBSCRIPT_ROOT_DIR}/_lib/databases/cockroachdb/hooks/configure.sh" >/dev/null 2>&1 && env HOME="$FAKE_HOME" LIBSCRIPT_HOME="$FAKE_LS_HOME" LIBSCRIPT_TARGET_SYSROOT="${TEST_WS}/sysroot" STACK="" "${LIBSCRIPT_ROOT_DIR}/_lib/databases/cockroachdb/hooks/provision_tenant.sh" --tenant=acme >/dev/null 2>&1; then
  pass_check "cockroachdb physical & logical hooks execute cleanly"
else
  fail_check "cockroachdb lifecycle hooks failed"
fi

printf '=== 6. Testing Cross-Platform Package Mapper Resolution ===\n'
SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/_lib/_common/pkg_mapper.sh"
export SCRIPT_NAME
# shellcheck disable=SC1090
. "${SCRIPT_NAME}"

PKG_MGR='dnf'
export PKG_MGR
if [ "$(map_package apache)" = 'httpd' ]; then
  pass_check 'pkg_mapper maps apache -> httpd on dnf'
else
  fail_check 'pkg_mapper apache dnf mismatch'
fi
PKG_MGR='pkg'
export PKG_MGR
if [ "$(map_package varnish)" = 'varnish7' ]; then
  pass_check 'pkg_mapper maps varnish -> varnish7 on FreeBSD pkg'
else
  fail_check 'pkg_mapper varnish pkg mismatch'
fi
PKG_MGR='apt-get'
export PKG_MGR
if [ "$(map_package zeromq)" = 'libzmq3-dev' ]; then
  pass_check 'pkg_mapper maps zeromq -> libzmq3-dev on apt-get'
else
  fail_check 'pkg_mapper zeromq apt-get mismatch'
fi

printf '=== 7. Verifying Shell Profile Isolation ===\n'
if [ "$(cat "${FAKE_HOME}/.bashrc")" = "# sentinel-bashrc" ] && [ "$(cat "${FAKE_HOME}/.profile")" = "# sentinel-profile" ] && [ "$(cat "${FAKE_HOME}/.zshrc")" = "# sentinel-zshrc" ]; then
  pass_check "Zero mutation of ~/.bashrc, ~/.profile, and ~/.zshrc across all 46 components"
else
  fail_check "User shell profiles were mutated!"
fi

if [ "$FAILURES" -gt 0 ]; then
  printf '[FAIL] Tier 1 Data & Server Components Test Suite failed (%d/%d checks failed)\n' "$FAILURES" "$CHECKS" >&2
  exit 1
fi

printf '[SUCCESS] All %d behavioral checks passed across 46 components!\n' "$CHECKS"
exit 0
