#!/bin/sh
# ## Overview
# End-to-end integration test suite verifying full-stack orchestration, dependency resolution,
# lifecycle hooks, daemon management, SPA/WebSocket ingress, frontend/KMP builds, and ML CLI verbs.
#
# ## Usage
# ./tests/test_fullstack_orchestration.sh

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

TEST_TMP=$(mktemp -d "${TMPDIR:-/tmp}/libscript_fullstack_test.XXXXXX")
trap 'rm -rf "$TEST_TMP"' EXIT
export LIBSCRIPT_DATA_DIR="${TEST_TMP}/data"
export LIBSCRIPT_HOME="${TEST_TMP}/home/.libscript"
export LIBSCRIPT_FORCE_FALLBACK_DAEMON=1

# ## assert_contains
# Verifies that the first argument contains the expected substring.
assert_contains() {
  _haystack="$1"
  _needle="$2"
  _label="$3"
  if ! printf '%s\n' "$_haystack" | grep -Fq -e "$_needle"; then
    printf '[FAIL] %s: expected "%s"\n' "$_label" "$_needle" >&2
    exit 1
  fi
  printf '[PASS] %s\n' "$_label"
}

# 1. Test resolve_stack with flat .deps, .dependencies.runtime, and legacy .install.dependencies
cat << 'EOF' > "${TEST_TMP}/deps_flat.json"
{
  "deps": {
    "postgresql": "16",
    "node": "20",
    "redis": "latest"
  }
}
EOF
RESOLVED_FLAT=$("${LIBSCRIPT_ROOT_DIR}/_lib/orchestration/resolve_stack.sh" "${TEST_TMP}/deps_flat.json")
assert_contains "$RESOLVED_FLAT" '"postgres"' "resolve_stack flat .deps alias postgresql -> postgres"
assert_contains "$RESOLVED_FLAT" '"nodejs"' "resolve_stack flat .deps alias node -> nodejs"
assert_contains "$RESOLVED_FLAT" '"valkey"' "resolve_stack flat .deps alias redis -> valkey"

cat << 'EOF' > "${TEST_TMP}/deps_struct.json"
{
  "dependencies": {
    "runtime": ["python", {"name": "duckdb", "version": "latest"}],
    "build": ["gradle"]
  }
}
EOF
RESOLVED_STRUCT=$("${LIBSCRIPT_ROOT_DIR}/_lib/orchestration/resolve_stack.sh" "${TEST_TMP}/deps_struct.json")
assert_contains "$RESOLVED_STRUCT" '"python"' "resolve_stack .dependencies.runtime python"
assert_contains "$RESOLVED_STRUCT" '"duckdb"' "resolve_stack .dependencies.runtime duckdb"
assert_contains "$RESOLVED_STRUCT" '"gradle"' "resolve_stack .dependencies.build gradle"

cat << 'EOF' > "${TEST_TMP}/deps_legacy.json"
{
  "install": {
    "dependencies": {
      "required": {
        "databases": [{"name": "sqlite", "version": "latest"}]
      }
    }
  }
}
EOF
RESOLVED_LEGACY=$("${LIBSCRIPT_ROOT_DIR}/_lib/orchestration/resolve_stack.sh" "${TEST_TMP}/deps_legacy.json")
assert_contains "$RESOLVED_LEGACY" '"sqlite"' "resolve_stack legacy .install.dependencies.required"

# 2. Test run_hooks with .hooks and .lifecycle_hooks, unless_exists, if_exists, working_dir
mkdir -p "${TEST_TMP}/subdir"
cat << 'EOF' > "${TEST_TMP}/hooks_test.json"
{
  "hooks": {
    "build": [
      {
        "name": "create_marker",
        "working_dir": "subdir",
        "condition": "unless_exists marker.txt",
        "command": "echo built_ok > marker.txt"
      }
    ]
  },
  "lifecycle_hooks": {
    "build": [
      {
        "name": "verify_marker",
        "working_dir": "subdir",
        "condition": "if_exists marker.txt",
        "command": "echo verified_ok > verified.txt"
      }
    ]
  }
}
EOF
"${LIBSCRIPT_ROOT_DIR}/_lib/orchestration/run_hooks.sh" "${TEST_TMP}/hooks_test.json" "build"
if [ ! -f "${TEST_TMP}/subdir/verified.txt" ]; then
  printf '[FAIL] run_hooks did not execute working_dir + if_exists hook\n' >&2
  exit 1
fi
printf '[PASS] run_hooks .hooks + .lifecycle_hooks + working_dir + conditions\n'

# 3. Test provision_db for sqlite & duckdb
cat << 'EOF' > "${TEST_TMP}/db_test.json"
{
  "databases": [
    {"engine": "sqlite", "name": "app_test"},
    {"engine": "duckdb", "name": "analytics_test"}
  ]
}
EOF
"${LIBSCRIPT_ROOT_DIR}/_lib/databases/provision_db.sh" "${TEST_TMP}/db_test.json"
ENV_CONTENT=$(cat "${TEST_TMP}/.env.libscript")
assert_contains "$ENV_CONTENT" "SQLITE_PATH=" "provision_db emits SQLITE_PATH"
assert_contains "$ENV_CONTENT" "DUCKDB_PATH=" "provision_db emits DUCKDB_PATH"

# 4. Test daemonize (start, status, logs, stop) with map and array .services
cat << 'EOF' > "${TEST_TMP}/daemon_map.json"
{
  "services": {
    "test_worker": {
      "working_dir": "subdir",
      "env": {"WORKER_TOKEN": "secret123"},
      "command": "sh -c 'echo worker_token=$WORKER_TOKEN; sleep 30'"
    }
  }
}
EOF
"${LIBSCRIPT_ROOT_DIR}/_lib/init-systems/daemonize.sh" start "${TEST_TMP}/daemon_map.json"
sleep 1
STATUS_OUT=$("${LIBSCRIPT_ROOT_DIR}/_lib/init-systems/daemonize.sh" status "${TEST_TMP}/daemon_map.json")
assert_contains "$STATUS_OUT" "RUNNING" "daemonize start/status on object-map service"
LOGS_OUT=$("${LIBSCRIPT_ROOT_DIR}/_lib/init-systems/daemonize.sh" logs "${TEST_TMP}/daemon_map.json")
assert_contains "$LOGS_OUT" "worker_token=secret123" "daemonize injects per-service env and captures logs"
"${LIBSCRIPT_ROOT_DIR}/_lib/init-systems/daemonize.sh" stop "${TEST_TMP}/daemon_map.json"

# 5. Test netctl SPA, WebSocket, and netctl apply libscript.json
cat << 'EOF' > "${TEST_TMP}/ingress_test.json"
{
  "ingress": {
    "provider": "nginx",
    "domain": "dashboard.local",
    "listen": [8080],
    "routes": {
      "/api": {"proxy": "http://127.0.0.1:8000"},
      "/ws": {"ws": "ws://127.0.0.1:8000/ws"},
      "/": {"static": "./web/dist", "spa": true}
    }
  }
}
EOF
APPLY_NGINX=$("${LIBSCRIPT_ROOT_DIR}/_lib/networking/netctl/cli.sh" apply "${TEST_TMP}/ingress_test.json" --format nginx)
assert_contains "$APPLY_NGINX" "server_name dashboard.local;" "netctl apply sets domain"
assert_contains "$APPLY_NGINX" "try_files \$uri \$uri/ /index.html;" "netctl apply emits SPA try_files"
assert_contains "$APPLY_NGINX" "proxy_set_header Upgrade \$http_upgrade;" "netctl apply emits WebSocket Upgrade headers"
assert_contains "$APPLY_NGINX" "application/wasm wasm;" "netctl apply emits WASM MIME type"

APPLY_CADDY=$("${LIBSCRIPT_ROOT_DIR}/_lib/networking/netctl/cli.sh" apply "${TEST_TMP}/ingress_test.json" --format caddy)
assert_contains "$APPLY_CADDY" "try_files {path} {path}/ /index.html" "netctl apply Caddy SPA try_files"

# 6. Test provision_frontend with Angular 17+ browser/ layout and KMP wasmJs layout
mkdir -p "${TEST_TMP}/fe_app/ng-web/dist/pulse-ng/browser"
printf '<html>Angular 17 SPA</html>\n' > "${TEST_TMP}/fe_app/ng-web/dist/pulse-ng/browser/index.html"
printf '{"name": "ng-web"}\n' > "${TEST_TMP}/fe_app/ng-web/package.json"

mkdir -p "${TEST_TMP}/fe_app/kmp-web/composeApp/build/dist/wasmJs/productionExecutable"
printf '<html>KMP WasmJS SPA</html>\n' > "${TEST_TMP}/fe_app/kmp-web/composeApp/build/dist/wasmJs/productionExecutable/index.html"
touch "${TEST_TMP}/fe_app/kmp-web/build.gradle.kts"

cat << 'EOF' > "${TEST_TMP}/fe_app/libscript.json"
{
  "frontends": {
    "angular_ui": {
      "source_dir": "ng-web",
      "build_command": "true"
    },
    "kmp_ui": {
      "source_dir": "kmp-web",
      "target": "kmp-wasm",
      "build_command": "true"
    }
  }
}
EOF
"${LIBSCRIPT_ROOT_DIR}/_lib/app-servers/provision_frontend.sh" --app-dir "${TEST_TMP}/fe_app" --manifest "${TEST_TMP}/fe_app/libscript.json"
if [ ! -f "${TEST_TMP}/fe_app/webroot/angular_ui/index.html" ]; then
  printf '[FAIL] provision_frontend did not stage Angular 17+ dist/<app>/browser/index.html\n' >&2
  exit 1
fi
if [ ! -f "${TEST_TMP}/fe_app/webroot/kmp_ui/index.html" ]; then
  printf '[FAIL] provision_frontend did not stage KMP wasmJs productionExecutable/index.html\n' >&2
  exit 1
fi
printf '[PASS] provision_frontend Angular 17+ browser/ and KMP wasmJs staging\n'

# 7. Test ML CLI routing (train / infer dry-run and local execution)
cat << 'EOF' > "${TEST_TMP}/ml_app.json"
{
  "ml": {
    "backend": "jax",
    "target": "local",
    "train_command": "echo ml_trained_ok > trained.txt",
    "infer_command": "echo ml_inferred_ok > inferred.txt"
  }
}
EOF
DRY_OUT=$("${LIBSCRIPT_ROOT_DIR}/libscript.sh" train "${TEST_TMP}/ml_app.json" --dry-run)
assert_contains "$DRY_OUT" "backend=jax" "libscript.sh train --dry-run parses .ml block"
"${LIBSCRIPT_ROOT_DIR}/libscript.sh" train "${TEST_TMP}/ml_app.json"
"${LIBSCRIPT_ROOT_DIR}/libscript.sh" infer "${TEST_TMP}/ml_app.json"
if [ ! -f "${TEST_TMP}/trained.txt" ] || [ ! -f "${TEST_TMP}/inferred.txt" ]; then
  printf '[FAIL] libscript.sh train/infer local execution failed\n' >&2
  exit 1
fi
printf '[PASS] libscript.sh train & infer local execution\n'

# 8. Test run_hooks.sh exits non-zero immediately when a db_migrate or health hook fails, and supports .infrastructure.hooks
cat << 'EOF' > "${TEST_TMP}/failing_hook.json"
{
  "infrastructure": {
    "hooks": {
      "db_migrate": [
        {"name": "bad_migration", "command": "exit 42"}
      ],
      "health": [
        {"name": "bad_health", "command": "exit 1"}
      ]
    }
  }
}
EOF
if "${LIBSCRIPT_ROOT_DIR}/_lib/orchestration/run_hooks.sh" "${TEST_TMP}/failing_hook.json" "db_migrate" >/dev/null 2>&1; then
  printf '[FAIL] run_hooks.sh should have exited non-zero on failing db_migrate hook\n' >&2
  exit 1
fi
if "${LIBSCRIPT_ROOT_DIR}/_lib/orchestration/run_hooks.sh" "${TEST_TMP}/failing_hook.json" "health" >/dev/null 2>&1; then
  printf '[FAIL] run_hooks.sh should have exited non-zero on failing health hook\n' >&2
  exit 1
fi
printf '[PASS] run_hooks.sh propagates non-zero exit code on failing db_migrate and health hooks\n'

# 9. Test libscript.sh health fails with exit code 1 when DuckDB or Postgres database has 0 tables and min_tables: 1 is configured
mkdir -p "${TEST_TMP}/mock_bin"
cat << 'EOF' > "${TEST_TMP}/mock_bin/duckdb"
#!/bin/sh
# Mock duckdb CLI returning 0 tables for SHOW TABLES
if printf '%s\n' "$*" | grep -q "SHOW TABLES"; then
  exit 0
fi
if [ "$1" != ":memory:" ] && [ -n "$1" ]; then
  case "$1" in
    -*) ;;
    *) printf '1\n' > "$1" ;;
  esac
fi
exit 0
EOF
chmod +x "${TEST_TMP}/mock_bin/duckdb"

cat << 'EOF' > "${TEST_TMP}/mock_bin/psql"
#!/bin/sh
# Mock psql returning 1 for connectivity and 0 for information_schema.tables count
if printf '%s\n' "$*" | grep -q "information_schema.tables"; then
  printf '0\n'
  exit 0
fi
printf '1\n'
exit 0
EOF
chmod +x "${TEST_TMP}/mock_bin/psql"

printf 'duckdb_placeholder' > "${TEST_TMP}/empty_test.duckdb"
cat << EOF > "${TEST_TMP}/unpopulated_duckdb.json"
{
  "databases": [
    {
      "engine": "duckdb",
      "name": "analytics",
      "path": "${TEST_TMP}/empty_test.duckdb",
      "min_tables": 1
    }
  ]
}
EOF
if PATH="${TEST_TMP}/mock_bin:$PATH" "${LIBSCRIPT_ROOT_DIR}/libscript.sh" health "${TEST_TMP}/unpopulated_duckdb.json" >/dev/null 2>&1; then
  printf '[FAIL] libscript.sh health should fail when DuckDB has 0 tables and min_tables: 1\n' >&2
  exit 1
fi

cat << 'EOF' > "${TEST_TMP}/unpopulated_pg.json"
{
  "databases": [
    {
      "engine": "postgres",
      "name": "app_db",
      "min_tables": 1
    }
  ]
}
EOF
if PATH="${TEST_TMP}/mock_bin:$PATH" "${LIBSCRIPT_ROOT_DIR}/libscript.sh" health "${TEST_TMP}/unpopulated_pg.json" >/dev/null 2>&1; then
  printf '[FAIL] libscript.sh health should fail when Postgres has 0 tables and min_tables: 1\n' >&2
  exit 1
fi
printf '[PASS] libscript.sh health fails when DuckDB or Postgres has 0 tables and min_tables: 1\n'

# 10. Test libscript.sh health fails with exit code 1 when a service health_check.expect_json assertion fails even if HTTP status is 200
cat << 'EOF' > "${TEST_TMP}/mock_http_payload.json"
{"status": "healthy", "datasets": {"table_count": 0}}
EOF
cat << EOF > "${TEST_TMP}/svc_expect_json.json"
{
  "services": [
    {
      "name": "test_api_hc",
      "command": "sleep 30",
      "health_check": {
        "url": "file://${TEST_TMP}/mock_http_payload.json",
        "expect_json": ".status == \"healthy\" and .datasets.table_count >= 2",
        "retries": 1,
        "interval": 1
      }
    }
  ]
}
EOF
"${LIBSCRIPT_ROOT_DIR}/_lib/init-systems/daemonize.sh" start "${TEST_TMP}/svc_expect_json.json"
sleep 1
if "${LIBSCRIPT_ROOT_DIR}/libscript.sh" health "${TEST_TMP}/svc_expect_json.json" >/dev/null 2>&1; then
  "${LIBSCRIPT_ROOT_DIR}/_lib/init-systems/daemonize.sh" stop "${TEST_TMP}/svc_expect_json.json"
  printf '[FAIL] libscript.sh health should fail when health_check.expect_json assertion evaluates to false\n' >&2
  exit 1
fi
cat << 'EOF' > "${TEST_TMP}/mock_http_payload.json"
{"status": "healthy", "datasets": {"table_count": 3}}
EOF
if ! "${LIBSCRIPT_ROOT_DIR}/libscript.sh" health "${TEST_TMP}/svc_expect_json.json" >/dev/null 2>&1; then
  "${LIBSCRIPT_ROOT_DIR}/_lib/init-systems/daemonize.sh" stop "${TEST_TMP}/svc_expect_json.json"
  printf '[FAIL] libscript.sh health should succeed when health_check.expect_json assertion evaluates to true\n' >&2
  exit 1
fi
"${LIBSCRIPT_ROOT_DIR}/_lib/init-systems/daemonize.sh" stop "${TEST_TMP}/svc_expect_json.json"
printf '[PASS] libscript.sh health validates service health_check.expect_json assertions\n'

# 11. Test init-system abstraction with LIBSCRIPT_INIT_SYSTEM=fallback (even when LIBSCRIPT_FORCE_FALLBACK_DAEMON is unset)
cat << 'EOF' > "${TEST_TMP}/init_fallback_test.json"
{
  "init_system": "fallback",
  "services": [
    {
      "name": "test_init_abstract_svc",
      "command": "sleep 30"
    }
  ]
}
EOF
(
  unset LIBSCRIPT_FORCE_FALLBACK_DAEMON
  LIBSCRIPT_INIT_SYSTEM="fallback" "${LIBSCRIPT_ROOT_DIR}/libscript.sh" start "${TEST_TMP}/init_fallback_test.json"
  sleep 1
  LIBSCRIPT_INIT_SYSTEM="fallback" "${LIBSCRIPT_ROOT_DIR}/libscript.sh" health "${TEST_TMP}/init_fallback_test.json" >/dev/null
  LIBSCRIPT_INIT_SYSTEM="fallback" "${LIBSCRIPT_ROOT_DIR}/libscript.sh" down "${TEST_TMP}/init_fallback_test.json" --remove
)
printf '[PASS] LIBSCRIPT_INIT_SYSTEM=fallback lifecycle (start, health, down --remove)\n'

# 12. Test multi-app shared-node cloud orchestration (provision, deprovision --keep-infra, backup --export-state, restore --import-state) in --dry-run mode
mkdir -p "${TEST_TMP}/app_a" "${TEST_TMP}/app_b" "${TEST_TMP}/state_dir"
cat << 'EOF' > "${TEST_TMP}/app_a/libscript.json"
{
  "name": "hospital-dashboard-platform",
  "aliases": ["pulse_query", "pulse-query"],
  "domain": "pulse-query.healthplatform.io",
  "infrastructure": {"network": {"ports": ["8000", "4200"]}}
}
EOF
cat << 'EOF' > "${TEST_TMP}/app_b/libscript.json"
{
  "name": "t1d-analytics",
  "aliases": ["t1d_analytics"],
  "domain": "t1d-analytics.healthplatform.io",
  "infrastructure": {"network": {"ports": ["8001", "3000"]}}
}
EOF
PROV_DRY=$("${LIBSCRIPT_ROOT_DIR}/libscript.sh" provision --provider azure --node test-node --rg TEST-RG --location eastus --app "${TEST_TMP}/app_a:hospital-dashboard-platform@pulse-query.healthplatform.io" --app "${TEST_TMP}/app_b:t1d-analytics@t1d-analytics.healthplatform.io" --dry-run 2>&1)
assert_contains "$PROV_DRY" "prepare-storage libscript.json" "provision --dry-run invokes declarative prepare-storage"
assert_contains "$PROV_DRY" "hospital-dashboard-platform" "provision --dry-run deploys app_a"
assert_contains "$PROV_DRY" "t1d-analytics" "provision --dry-run deploys app_b"

PROV_ONLY=$("${LIBSCRIPT_ROOT_DIR}/libscript.sh" provision --provider azure --node test-node --rg TEST-RG --location eastus --only t1d_analytics --app "${TEST_TMP}/app_a:hospital-dashboard-platform@pulse-query.healthplatform.io" --app "${TEST_TMP}/app_b:t1d-analytics@t1d-analytics.healthplatform.io" --dry-run 2>&1)
assert_contains "$PROV_ONLY" "t1d-analytics" "provision --only=t1d_analytics deploys t1d-analytics"

TEARDOWN_DRY=$("${LIBSCRIPT_ROOT_DIR}/libscript.sh" deprovision --provider azure --node test-node --rg TEST-RG --location eastus --keep-infra --purge-data --only t1d-analytics --app "${TEST_TMP}/app_a:hospital-dashboard-platform" --app "${TEST_TMP}/app_b:t1d-analytics" --dry-run 2>&1)
assert_contains "$TEARDOWN_DRY" "--remove --purge-data" "deprovision --keep-infra --purge-data runs down --remove --purge-data"

BK_DRY=$("${LIBSCRIPT_ROOT_DIR}/libscript.sh" backup test-node --provider azure --rg TEST-RG --only pulse_query --app "${TEST_TMP}/app_a:hospital-dashboard-platform@pulse-query.healthplatform.io" --app "${TEST_TMP}/app_b:t1d-analytics@t1d-analytics.healthplatform.io" --export-state "${TEST_TMP}/state_dir" --dry-run 2>&1)
assert_contains "$BK_DRY" "export-state libscript.json" "backup --export-state exports selected app state"

RS_DRY=$("${LIBSCRIPT_ROOT_DIR}/libscript.sh" restore test-node --provider azure --rg TEST-RG --only pulse_query --app "hospital-dashboard-platform@pulse-query.healthplatform.io" --app "t1d-analytics@t1d-analytics.healthplatform.io" --import-state "${TEST_TMP}/state_dir" --dry-run 2>&1)
assert_contains "$RS_DRY" "import-state libscript.json" "restore --import-state imports selected app state"
printf '[PASS] Multi-app shared-node provision, deprovision, backup, and restore dry-run orchestration\n'

printf '=== ALL FULLSTACK ORCHESTRATION TESTS PASSED ===\n'

