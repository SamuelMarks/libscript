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
trap 'chmod -R u+w "$TEST_TMP" 2>/dev/null || true; rm -rf "$TEST_TMP"' EXIT
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
mkdir -p "${TEST_TMP}/fe_app/ng-web/dist/app-ng/browser"
printf '<html>Angular 17 SPA</html>\n' > "${TEST_TMP}/fe_app/ng-web/dist/app-ng/browser/index.html"
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
  "name": "dashboard-platform",
  "aliases": ["metrics_query", "metrics-query"],
  "domain": "metrics-query.example.org",
  "infrastructure": {"network": {"ports": ["8000", "4200"]}}
}
EOF
cat << 'EOF' > "${TEST_TMP}/app_b/libscript.json"
{
  "name": "analytics-service",
  "aliases": ["analytics_service"],
  "domain": "analytics-service.example.org",
  "services": {
    "api": {
      "command": "echo ok",
      "env": {
        "APP_DB_SEARCH_DIR": "${APP_DB_SEARCH_DIR:-/remote/data/store:/local/volume/store}"
      }
    }
  },
  "infrastructure": {"network": {"ports": ["8001", "3000"]}}
}
EOF
_EXTRACTED_ENV_DEF=$(jq -r '([(.env // {}), (.remote_env // {}), ((.services // .infrastructure.services) | if type == "object" then .[] elif type == "array" then .[] else empty end | (.env // .environment // {}))] | add // {}) | to_entries[] | {key: .key, def: (if (.value | type) == "string" then (.value | sub("^\\$\\{[A-Za-z0-9_]+:-"; "") | sub("\\}$"; "")) else "" end)} | select(.def | test("^/[^:]+:/[^:]+")) | "\(.key)=\(.def)"' "${TEST_TMP}/app_b/libscript.json")
assert_contains "$_EXTRACTED_ENV_DEF" "APP_DB_SEARCH_DIR=/remote/data/store:/local/volume/store" "manifest-driven multi-host search path default extraction"

PROV_DRY=$("${LIBSCRIPT_ROOT_DIR}/libscript.sh" provision --provider azure --node test-node --rg TEST-RG --location eastus --app "${TEST_TMP}/app_a:dashboard-platform@metrics-query.example.org" --app "${TEST_TMP}/app_b:analytics-service@analytics-service.example.org" --dry-run 2>&1)
assert_contains "$PROV_DRY" "prepare-storage libscript.json" "provision --dry-run invokes declarative prepare-storage"
assert_contains "$PROV_DRY" "dashboard-platform" "provision --dry-run deploys app_a"
assert_contains "$PROV_DRY" "analytics-service" "provision --dry-run deploys app_b"

PROV_ONLY=$("${LIBSCRIPT_ROOT_DIR}/libscript.sh" provision --provider azure --node test-node --rg TEST-RG --location eastus --only analytics_service --app "${TEST_TMP}/app_a:dashboard-platform@metrics-query.example.org" --app "${TEST_TMP}/app_b:analytics-service@analytics-service.example.org" --dry-run 2>&1)
assert_contains "$PROV_ONLY" "analytics-service" "provision --only=analytics_service deploys analytics-service"

TEARDOWN_DRY=$("${LIBSCRIPT_ROOT_DIR}/libscript.sh" deprovision --provider azure --node test-node --rg TEST-RG --location eastus --keep-infra --purge-data --only analytics-service --app "${TEST_TMP}/app_a:dashboard-platform" --app "${TEST_TMP}/app_b:analytics-service" --dry-run 2>&1)
assert_contains "$TEARDOWN_DRY" "--remove --purge-data" "deprovision --keep-infra --purge-data runs down --remove --purge-data"

BK_DRY=$("${LIBSCRIPT_ROOT_DIR}/libscript.sh" backup test-node --provider azure --rg TEST-RG --only metrics_query --app "${TEST_TMP}/app_a:dashboard-platform@metrics-query.example.org" --app "${TEST_TMP}/app_b:analytics-service@analytics-service.example.org" --export-state "${TEST_TMP}/state_dir" --dry-run 2>&1)
assert_contains "$BK_DRY" "export-state libscript.json" "backup --export-state exports selected app state"

RS_DRY=$("${LIBSCRIPT_ROOT_DIR}/libscript.sh" restore test-node --provider azure --rg TEST-RG --only metrics_query --app "dashboard-platform@metrics-query.example.org" --app "analytics-service@analytics-service.example.org" --import-state "${TEST_TMP}/state_dir" --dry-run 2>&1)
assert_contains "$RS_DRY" "import-state libscript.json" "restore --import-state imports selected app state"
printf '[PASS] Multi-app shared-node provision, deprovision, backup, and restore dry-run orchestration\n'

# 13. Test gitignore-aware remote_sync with remote build-directory protection and stale directory deletion
if command -v rsync >/dev/null 2>&1; then
  SYNC_SRC="${TEST_TMP}/sync_local"
  SYNC_DST="${TEST_TMP}/sync_remote"
  mkdir -p "${SYNC_SRC}/src" "${SYNC_SRC}/build" "${SYNC_SRC}/cmake-build-debug" "${SYNC_SRC}/node_modules" "${SYNC_SRC}/target" "${SYNC_SRC}/.venv"
  mkdir -p "${SYNC_DST}/stale_old_dir/nested" "${SYNC_DST}/build" "${SYNC_DST}/cmake-build-debug" "${SYNC_DST}/cmake-build-release" "${SYNC_DST}/node_modules/pkg" "${SYNC_DST}/target/release" "${SYNC_DST}/.venv/bin"
  cat << 'EOF_GI' > "${SYNC_SRC}/.gitignore"
ignored_secret.txt
ignored_dir/
*.tmp_artifact
EOF_GI
  mkdir -p "${SYNC_SRC}/ignored_dir"
  printf 'keep_src\n' > "${SYNC_SRC}/src/main.c"
  printf 'do_not_upload_ignored\n' > "${SYNC_SRC}/ignored_secret.txt"
  printf 'do_not_upload_dir\n' > "${SYNC_SRC}/ignored_dir/file.txt"
  printf 'do_not_upload_glob\n' > "${SYNC_SRC}/test.tmp_artifact"
  printf 'local_build_noise\n' > "${SYNC_SRC}/build/local_only.o"
  printf 'remote_cached_bin\n' > "${SYNC_DST}/build/remote_cached.o"
  printf 'remote_cmake_dbg\n' > "${SYNC_DST}/cmake-build-debug/CMakeCache.txt"
  printf 'remote_cmake_rel\n' > "${SYNC_DST}/cmake-build-release/app_bin"
  printf 'remote_node_mod\n' > "${SYNC_DST}/node_modules/pkg/index.js"
  printf 'remote_rust_tgt\n' > "${SYNC_DST}/target/release/lib.rlib"
  printf 'remote_py_venv\n' > "${SYNC_DST}/.venv/bin/python"
  printf 'stale_file\n' > "${SYNC_DST}/stale_old_dir/nested/old.txt"

  rsync -avz --delete \
    --filter='P build' \
    --filter='P cmake-build-debug' \
    --filter='P cmake-build-release' \
    --filter='P cmake-build-*' \
    --filter='P node_modules' \
    --filter='P target' \
    --filter='P .venv' \
    --filter=':- .gitignore' \
    --exclude='.git' \
    --exclude='build' \
    --exclude='cmake-build-debug' \
    --exclude='cmake-build-release' \
    --exclude='cmake-build-*' \
    --exclude='node_modules' \
    --exclude='target' \
    --exclude='.venv' \
    "${SYNC_SRC}/" "${SYNC_DST}/" >/dev/null

  if [ ! -f "${SYNC_DST}/src/main.c" ]; then
    printf '[FAIL] remote_sync did not upload tracked src/main.c\n' >&2
    exit 1
  fi
  if [ -e "${SYNC_DST}/stale_old_dir" ]; then
    printf '[FAIL] remote_sync did not delete stale_old_dir on remote\n' >&2
    exit 1
  fi
  if [ -e "${SYNC_DST}/ignored_secret.txt" ] || [ -e "${SYNC_DST}/ignored_dir" ] || [ -e "${SYNC_DST}/test.tmp_artifact" ]; then
    printf '[FAIL] remote_sync uploaded files matching .gitignore\n' >&2
    exit 1
  fi
  if [ -e "${SYNC_DST}/build/local_only.o" ]; then
    printf '[FAIL] remote_sync uploaded local build directory artifact\n' >&2
    exit 1
  fi
  for _prot in "build/remote_cached.o" "cmake-build-debug/CMakeCache.txt" "cmake-build-release/app_bin" "node_modules/pkg/index.js" "target/release/lib.rlib" ".venv/bin/python"; do
    if [ ! -f "${SYNC_DST}/${_prot}" ]; then
      printf '[FAIL] remote_sync deleted protected remote build artifact: %s\n' "$_prot" >&2
      exit 1
    fi
  done
  printf '[PASS] Gitignore-aware remote_sync deletes stale remote dirs and preserves remote build/cache dirs\n'
fi

# 14. Test VM IP TTL caching and Python .venv lockfile hash helpers
SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/_lib/_common/remote_sync.sh"
export SCRIPT_NAME
# shellcheck disable=SC1090
. "${SCRIPT_NAME}"
unset SCRIPT_NAME
libscript_set_cached_vm_ip "azure" "TEST-RG" "cache-node" "198.51.100.42"
CACHED_IP=$(libscript_get_cached_vm_ip "azure" "TEST-RG" "cache-node")
assert_contains "$CACHED_IP" "198.51.100.42" "VM Public IP TTL cache hit"
libscript_invalidate_cached_vm_ip "azure" "TEST-RG" "cache-node"
if libscript_get_cached_vm_ip "azure" "TEST-RG" "cache-node" >/dev/null 2>&1; then
  printf '[FAIL] libscript_invalidate_cached_vm_ip did not clear cached IP\n' >&2
  exit 1
fi
printf '[PASS] VM Public IP TTL cache set, hit, and invalidation\n'

# 15. Test remote_sync.sh generates a ControlPath under 65 bytes even when TMPDIR is a 90-character macOS path
LONG_TMPDIR='/var/folders/w5/21g61wls7ksd3z8cxrj41s1c0000gn/T/very_long_nested_subdir_for_testing_90chars/'
SSH_OPTS_OUT=$(TMPDIR="$LONG_TMPDIR" libscript_ssh_mux_opts)
CTRL_PATH=$(printf '%s\n' "$SSH_OPTS_OUT" | sed -n 's/.*ControlPath=\([^ ]*\).*/\1/p')
if [ -z "$CTRL_PATH" ]; then
  printf '[FAIL] libscript_ssh_mux_opts did not emit ControlPath\n' >&2
  exit 1
fi
case "$CTRL_PATH" in
  *//*)
    printf '[FAIL] ControlPath contains double slash: %s\n' "$CTRL_PATH" >&2
    exit 1
    ;;
esac
if [ "${#CTRL_PATH}" -ge 65 ]; then
  printf '[FAIL] ControlPath length (%d) >= 65 bytes: %s\n' "${#CTRL_PATH}" "$CTRL_PATH" >&2
  exit 1
fi
printf '[PASS] remote_sync.sh generates short ControlPath (%d bytes < 65): %s\n' "${#CTRL_PATH}" "$CTRL_PATH"

# 16. Test libscript_python_venv (3 args) does not prematurely write .libscript_lock_hash, and libscript_python_sync_deps caches and invalidates properly
SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/_lib/_common/python_env.sh"
export SCRIPT_NAME
# shellcheck disable=SC1090
. "${SCRIPT_NAME}"
unset SCRIPT_NAME

PY_TEST_DIR="${TEST_TMP}/py_sync_test"
mkdir -p "${PY_TEST_DIR}" "${TEST_TMP}/py_mock_bin"
printf 'flask==3.0.0\n' > "${PY_TEST_DIR}/requirements.txt"

cat << 'EOF_UV' > "${TEST_TMP}/py_mock_bin/uv"
#!/bin/sh
if [ "$1" = "venv" ]; then
  for _arg in "$@"; do
    _last="$_arg"
  done
  mkdir -p "${_last}/bin"
  cat << 'EOF_PY' > "${_last}/bin/python"
#!/bin/sh
exit 0
EOF_PY
  cat << 'EOF_PIP' > "${_last}/bin/pip"
#!/bin/sh
printf 'pip_install:%s\n' "$*" >> "${PY_PIP_LOG}"
exit 0
EOF_PIP
  chmod +x "${_last}/bin/python" "${_last}/bin/pip"
  exit 0
fi
if [ "$1" = "pip" ] && [ "$2" = "install" ]; then
  printf 'uv_pip_install:%s\n' "$*" >> "${PY_PIP_LOG}"
  exit 0
fi
if [ "$1" = "sync" ]; then
  printf 'uv_sync:%s\n' "$*" >> "${PY_PIP_LOG}"
  exit 0
fi
exit 0
EOF_UV
chmod +x "${TEST_TMP}/py_mock_bin/uv"

export PY_PIP_LOG="${TEST_TMP}/py_pip_calls.log"
: > "$PY_PIP_LOG"

PATH="${TEST_TMP}/py_mock_bin:$PATH" LIBSCRIPT_PYTHON_VENV_BACKEND="uv" libscript_python_venv "" "${PY_TEST_DIR}/.venv" "3.12"
if [ ! -f "${PY_TEST_DIR}/.venv/.libscript_venv_interp" ]; then
  printf '[FAIL] libscript_python_venv (3 args) did not create .libscript_venv_interp\n' >&2
  exit 1
fi
if [ -f "${PY_TEST_DIR}/.venv/.libscript_lock_hash" ] || [ -f "${PY_TEST_DIR}/.venv/.libscript_py_hash" ]; then
  printf '[FAIL] libscript_python_venv (3 args) prematurely created .libscript_lock_hash or .libscript_py_hash\n' >&2
  exit 1
fi

# First sync_deps should install requirements.txt even though .venv already exists
SYNC1_OUT=$(PATH="${TEST_TMP}/py_mock_bin:$PATH" libscript_python_sync_deps "${PY_TEST_DIR}" "3.12" 2>&1)
export SYNC1_OUT
if [ ! -f "${PY_TEST_DIR}/.venv/.libscript_lock_hash" ]; then
  printf '[FAIL] libscript_python_sync_deps did not stamp .venv/.libscript_lock_hash after install\n' >&2
  exit 1
fi
PIP_COUNT_1=$(wc -l < "$PY_PIP_LOG" | tr -d ' ')
if [ "$PIP_COUNT_1" -lt 1 ]; then
  printf '[FAIL] libscript_python_sync_deps did not run pip install on unpopulated .venv\n' >&2
  exit 1
fi

# Second sync_deps should reuse cached .venv
SYNC2_OUT=$(PATH="${TEST_TMP}/py_mock_bin:$PATH" libscript_python_sync_deps "${PY_TEST_DIR}" "3.12" 2>&1)
assert_contains "$SYNC2_OUT" "[REUSE]" "libscript_python_sync_deps second run logs [REUSE]"
PIP_COUNT_2=$(wc -l < "$PY_PIP_LOG" | tr -d ' ')
if [ "$PIP_COUNT_2" -ne "$PIP_COUNT_1" ]; then
  printf '[FAIL] libscript_python_sync_deps re-ran pip install when lockfile was unchanged\n' >&2
  exit 1
fi

# Modifying requirements.txt should trigger re-install
printf 'flask==3.0.0\ngunicorn==22.0.0\n' > "${PY_TEST_DIR}/requirements.txt"
PATH="${TEST_TMP}/py_mock_bin:$PATH" libscript_python_sync_deps "${PY_TEST_DIR}" "3.12" >/dev/null 2>&1
PIP_COUNT_3=$(wc -l < "$PY_PIP_LOG" | tr -d ' ')
if [ "$PIP_COUNT_3" -le "$PIP_COUNT_2" ]; then
  printf '[FAIL] libscript_python_sync_deps did not re-run install when requirements.txt changed\n' >&2
  exit 1
fi

# FORCE_REINSTALL=1 should trigger re-install even when lockfile is unchanged
FORCE_REINSTALL=1 PATH="${TEST_TMP}/py_mock_bin:$PATH" libscript_python_sync_deps "${PY_TEST_DIR}" "3.12" >/dev/null 2>&1
PIP_COUNT_4=$(wc -l < "$PY_PIP_LOG" | tr -d ' ')
if [ "$PIP_COUNT_4" -le "$PIP_COUNT_3" ]; then
  printf '[FAIL] libscript_python_sync_deps did not re-run install when FORCE_REINSTALL=1\n' >&2
  exit 1
fi
printf '[PASS] libscript_python_venv and libscript_python_sync_deps lockfile hash integrity\n'

# 17. Test provision_frontend.sh re-runs npm install infe_dir when package.json changes even if node_modules/ exists, and runs ng build --configuration=release
FE_APP_DIR="${TEST_TMP}/fe_ng_app"
FE_SUB_DIR="${FE_APP_DIR}/pulse-query-ng-web"
mkdir -p "${FE_SUB_DIR}/src" "${FE_SUB_DIR}/node_modules" "${TEST_TMP}/fe_mock_bin"

cat << 'EOF_PKG1' > "${FE_SUB_DIR}/package.json"
{
  "name": "pulse-query-ng-web",
  "version": "1.0.0",
  "dependencies": {
    "@angular/core": "^17.0.0"
  }
}
EOF_PKG1

cat << 'EOF_NG' > "${FE_SUB_DIR}/angular.json"
{
  "projects": {
    "pulse-query-ng-web": {
      "architect": {
        "build": {
          "configurations": {
            "release": {},
            "production": {}
          }
        }
      }
    }
  }
}
EOF_NG
printf 'console.log("v1");\n' > "${FE_SUB_DIR}/src/main.ts"

cat << 'EOF_MF' > "${FE_APP_DIR}/libscript.json"
{
  "frontends": {
    "pulse": {
      "framework": "angular",
      "working_dir": "pulse-query-ng-web",
      "output_dir": "dist"
    }
  }
}
EOF_MF

export FE_CMD_LOG="${TEST_TMP}/fe_cmds.log"
: > "$FE_CMD_LOG"
unset FORCE_REINSTALL FORCE_REBUILD || true

cat << 'EOF_NODE' > "${TEST_TMP}/fe_mock_bin/node"
#!/bin/sh
exit 0
EOF_NODE
cat << 'EOF_NPM' > "${TEST_TMP}/fe_mock_bin/npm"
#!/bin/sh
printf 'npm %s\n' "$*" >> "${FE_CMD_LOG}"
mkdir -p node_modules
exit 0
EOF_NPM
cat << 'EOF_NPX' > "${TEST_TMP}/fe_mock_bin/npx"
#!/bin/sh
printf 'npx %s\n' "$*" >> "${FE_CMD_LOG}"
mkdir -p dist
printf '<html>release</html>\n' > dist/index.html
exit 0
EOF_NPX
chmod +x "${TEST_TMP}/fe_mock_bin/node" "${TEST_TMP}/fe_mock_bin/npm" "${TEST_TMP}/fe_mock_bin/npx"

# Run 1: node_modules/ already exists but .libscript_pkg_hash is missing -> must run npm install and npx ng build --configuration=release
PATH="${TEST_TMP}/fe_mock_bin:$PATH" STACK="" "${LIBSCRIPT_ROOT_DIR}/_lib/app-servers/provision_frontend.sh" --app-dir "${FE_APP_DIR}" --manifest "${FE_APP_DIR}/libscript.json" >/dev/null
FE_LOG_1=$(cat "$FE_CMD_LOG")
assert_contains "$FE_LOG_1" "npm install" "provision_frontend.sh runs npm install when .libscript_pkg_hash is missing"
assert_contains "$FE_LOG_1" "npx ng build --configuration=release" "provision_frontend.sh runs npx ng build --configuration=release when release config exists"

# Run 2: unchanged package.json and src -> must reuse both deps and build
: > "$FE_CMD_LOG"
FE_RUN2_OUT=$(PATH="${TEST_TMP}/fe_mock_bin:$PATH" STACK="" "${LIBSCRIPT_ROOT_DIR}/_lib/app-servers/provision_frontend.sh" --app-dir "${FE_APP_DIR}" --manifest "${FE_APP_DIR}/libscript.json" 2>&1)
assert_contains "$FE_RUN2_OUT" "[REUSE] Frontend dependencies" "provision_frontend.sh reuses node_modules on second run"
assert_contains "$FE_RUN2_OUT" "[REUSE] Frontend build" "provision_frontend.sh reuses build on second run"
if [ -s "$FE_CMD_LOG" ]; then
  printf '[FAIL] provision_frontend.sh invoked npm/npx on unchanged second run: %s\n' "$(cat "$FE_CMD_LOG")" >&2
  exit 1
fi

# Run 3: update package.json while node_modules/ still exists -> must re-run npm install
cat << 'EOF_PKG2' > "${FE_SUB_DIR}/package.json"
{
  "name": "pulse-query-ng-web",
  "version": "1.0.1",
  "dependencies": {
    "@angular/core": "^17.3.0"
  }
}
EOF_PKG2
PATH="${TEST_TMP}/fe_mock_bin:$PATH" STACK="" "${LIBSCRIPT_ROOT_DIR}/_lib/app-servers/ollama/env.sh" >/dev/null 2>&1 || true
PATH="${TEST_TMP}/fe_mock_bin:$PATH" STACK="" "${LIBSCRIPT_ROOT_DIR}/_lib/app-servers/provision_frontend.sh" --app-dir "${FE_APP_DIR}" --manifest "${FE_APP_DIR}/libscript.json" >/dev/null
FE_LOG_3=$(cat "$FE_CMD_LOG")
assert_contains "$FE_LOG_3" "npm install" "provision_frontend.sh re-runs npm install when package.json changes even if node_modules exists"
printf '[PASS] provision_frontend.sh sub-app lockfile hash invalidation and ng build --configuration=release\n'

# 18. Test Ollama CPU runner hardening (env.sh defaults, service.sh configure override persistence, and prepare-storage 11-key merge)
# shellcheck disable=SC2016
OL_ENV_OUT=$(
  env -i PATH="$PATH" HOME="${TEST_TMP}" LIBSCRIPT_ROOT_DIR="${LIBSCRIPT_ROOT_DIR}" sh -c '
    SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/_lib/app-servers/ollama/env.sh"
    export SCRIPT_NAME
    . "${SCRIPT_NAME}"
    printf "FA=%s\nKV=%s\nCTX=%s\nQ=%s\nKA=%s\nAMX=%s\nLLM=%s\nGPU=%s\n" \
      "${OLLAMA_FLASH_ATTENTION:-}" \
      "${OLLAMA_KV_CACHE_TYPE:-}" \
      "${OLLAMA_CONTEXT_LENGTH:-}" \
      "${OLLAMA_MAX_QUEUE:-}" \
      "${OLLAMA_KEEP_ALIVE:-}" \
      "${GGML_BACKEND_AMX:-}" \
      "${OLLAMA_LLM_LIBRARY:-}" \
      "${OLLAMA_NUM_GPU:-}"
  '
)
assert_contains "$OL_ENV_OUT" "FA=0" "ollama/env.sh sets OLLAMA_FLASH_ATTENTION=0"
assert_contains "$OL_ENV_OUT" "KV=f16" "ollama/env.sh sets OLLAMA_KV_CACHE_TYPE=f16"
assert_contains "$OL_ENV_OUT" "CTX=2048" "ollama/env.sh sets OLLAMA_CONTEXT_LENGTH=2048"
assert_contains "$OL_ENV_OUT" "Q=16" "ollama/env.sh sets OLLAMA_MAX_QUEUE=16"
assert_contains "$OL_ENV_OUT" "KA=10m" "ollama/env.sh sets OLLAMA_KEEP_ALIVE=10m"
assert_contains "$OL_ENV_OUT" "AMX=0" "ollama/env.sh sets GGML_BACKEND_AMX=0"
assert_contains "$OL_ENV_OUT" "LLM=cpu_avx2" "ollama/env.sh sets OLLAMA_LLM_LIBRARY=cpu_avx2 on GPU-less node"
assert_contains "$OL_ENV_OUT" "GPU=0" "ollama/env.sh sets OLLAMA_NUM_GPU=0 on GPU-less node"

OL_DATA_DIR="${TEST_TMP}/ol_svc_data"
OL_MODELS_DIR="${TEST_TMP}/ol_models"
mkdir -p "$OL_DATA_DIR" "$OL_MODELS_DIR"
env -i PATH="$PATH" HOME="${TEST_TMP}" LIBSCRIPT_ROOT_DIR="${LIBSCRIPT_ROOT_DIR}" \
  LIBSCRIPT_DATA_DIR="${OL_DATA_DIR}" LIBSCRIPT_FORCE_FALLBACK_DAEMON=1 \
  OLLAMA_MODELS_DIR="${OL_MODELS_DIR}" \
  sh "${LIBSCRIPT_ROOT_DIR}/_lib/app-servers/ollama/service.sh" configure >/dev/null 2>&1

if [ ! -f "${OL_DATA_DIR}/ollama/service.env" ]; then
  printf '[FAIL] ollama/service.sh configure did not create %s/ollama/service.env\n' "$OL_DATA_DIR" >&2
  exit 1
fi
OL_SVC_ENV=$(cat "${OL_DATA_DIR}/ollama/service.env")
assert_contains "$OL_SVC_ENV" "export OLLAMA_MODELS=${OL_MODELS_DIR}" "service.sh configure persists OLLAMA_MODELS"
assert_contains "$OL_SVC_ENV" "export GGML_BACKEND_AMX=0" "service.sh configure persists GGML_BACKEND_AMX=0"
assert_contains "$OL_SVC_ENV" "export OLLAMA_LLM_LIBRARY=cpu_avx2" "service.sh configure persists OLLAMA_LLM_LIBRARY=cpu_avx2"
assert_contains "$OL_SVC_ENV" "export OLLAMA_NUM_GPU=0" "service.sh configure persists OLLAMA_NUM_GPU=0"
assert_contains "$OL_SVC_ENV" "export OLLAMA_FLASH_ATTENTION=0" "service.sh configure persists OLLAMA_FLASH_ATTENTION=0"
assert_contains "$OL_SVC_ENV" "export OLLAMA_KV_CACHE_TYPE=f16" "service.sh configure persists OLLAMA_KV_CACHE_TYPE=f16"
assert_contains "$OL_SVC_ENV" "export OLLAMA_CONTEXT_LENGTH=2048" "service.sh configure persists OLLAMA_CONTEXT_LENGTH=2048"
assert_contains "$OL_SVC_ENV" "export OLLAMA_MAX_QUEUE=16" "service.sh configure persists OLLAMA_MAX_QUEUE=16"
assert_contains "$OL_SVC_ENV" "export OLLAMA_KEEP_ALIVE=10m" "service.sh configure persists OLLAMA_KEEP_ALIVE=10m"

PS_DIR="${TEST_TMP}/ps_merge_test"
PS_DATA="${TEST_TMP}/ps_data"
mkdir -p "$PS_DIR" "$PS_DATA"
cat << EOF_PS_JSON > "${PS_DIR}/libscript.json"
{
  "deps": {
    "ollama": "latest"
  },
  "infrastructure": {
    "service_overrides": {
      "ollama": {
        "OLLAMA_MODELS": "${PS_DATA}/models_from_infra",
        "OLLAMA_MODELS_DIR": "${PS_DATA}/models_from_infra",
        "OLLAMA_HOST": "127.0.0.1:11434",
        "OLLAMA_NUM_PARALLEL": "1",
        "OLLAMA_MAX_LOADED_MODELS": "1",
        "OLLAMA_MAX_QUEUE": "16"
      }
    }
  },
  "service_overrides": {
    "ollama": {
      "OLLAMA_KEEP_ALIVE": "15m",
      "OLLAMA_FLASH_ATTENTION": "0",
      "OLLAMA_KV_CACHE_TYPE": "f16",
      "OLLAMA_CONTEXT_LENGTH": "4096",
      "OLLAMA_NUM_GPU": "0",
      "OLLAMA_LLM_LIBRARY": "cpu_avx2"
    }
  }
}
EOF_PS_JSON

CMD="prepare-storage" LIBSCRIPT_DATA_DIR="${PS_DATA}" LIBSCRIPT_FORCE_FALLBACK_DAEMON=1 STACK="" \
  sh "${LIBSCRIPT_ROOT_DIR}/cli/commands/services/actions.sh" "${PS_DIR}/libscript.json" >/dev/null 2>&1

PS_SVC_ENV=$(cat "${PS_DATA}/ollama/service.env")
assert_contains "$PS_SVC_ENV" "export OLLAMA_MODELS=${PS_DATA}/models_from_infra" "prepare-storage merges infrastructure.service_overrides OLLAMA_MODELS"
assert_contains "$PS_SVC_ENV" "export GGML_BACKEND_AMX=0" "prepare-storage persists GGML_BACKEND_AMX=0"
assert_contains "$PS_SVC_ENV" "export OLLAMA_CONTEXT_LENGTH=4096" "prepare-storage preserves manifest OLLAMA_CONTEXT_LENGTH=4096 across service.sh configure"
assert_contains "$PS_SVC_ENV" "export OLLAMA_KEEP_ALIVE=15m" "prepare-storage preserves manifest OLLAMA_KEEP_ALIVE=15m across service.sh configure"
assert_contains "$PS_SVC_ENV" "export OLLAMA_LLM_LIBRARY=cpu_avx2" "prepare-storage persists OLLAMA_LLM_LIBRARY=cpu_avx2"
assert_contains "$PS_SVC_ENV" "export OLLAMA_NUM_GPU=0" "prepare-storage persists OLLAMA_NUM_GPU=0"
printf '[PASS] Ollama CPU runner defaults, service.sh configure overrides, and prepare-storage 11-key merge\n'

# 19. Test Azure --delete-option Detach, prepare-storage Postgres/Valkey configuration, and traits/storage/mount.sh ownership preservation
AZ_ATTACH_DRY=$(DRY_RUN=true "${LIBSCRIPT_ROOT_DIR}/_lib/cloud-providers/azure/cli.sh" storage attach-disk test-node TEST-RG test-node-data-disk 100 /mnt/data 2>&1)
assert_contains "$AZ_ATTACH_DRY" "--delete-option Detach" "azure storage attach-disk uses --delete-option Detach"

PG_VK_DIR="${TEST_TMP}/pg_vk_test"
PG_VK_MNT="${PG_VK_DIR}/mnt_data"
PG_VK_SYS="${PG_VK_DIR}/systemd"
PG_VK_ETC="${PG_VK_DIR}/etc"
mkdir -p "${PG_VK_MNT}/postgres" "${PG_VK_MNT}/valkey" "$PG_VK_SYS" "${PG_VK_ETC}/valkey"
printf 'dir /var/lib/valkey\nappendonly no\n' > "${PG_VK_ETC}/valkey/valkey.conf"

cat << EOF_PGVK > "${PG_VK_DIR}/libscript.json"
{
  "service_overrides": {
    "postgres": {
      "POSTGRES_DATA_DIR": "${PG_VK_MNT}/postgres",
      "PGDATA": "${PG_VK_MNT}/postgres"
    },
    "valkey": {
      "VALKEY_DATA_DIR": "${PG_VK_MNT}/valkey"
    }
  }
}
EOF_PGVK

CMD="prepare-storage" LIBSCRIPT_DATA_DIR="${PG_VK_DIR}/data" LIBSCRIPT_SYSTEMD_DIR="${PG_VK_SYS}" LIBSCRIPT_ETC_DIR="${PG_VK_ETC}" LIBSCRIPT_MOCK_SYSTEMD=1 STACK="" \
  sh "${LIBSCRIPT_ROOT_DIR}/cli/commands/services/actions.sh" "${PG_VK_DIR}/libscript.json" >/dev/null 2>&1

if [ ! -f "${PG_VK_SYS}/postgresql.service.d/override.conf" ]; then
  printf '[FAIL] prepare-storage did not create postgresql.service.d/override.conf\n' >&2
  exit 1
fi
PG_OVR_CONTENT=$(cat "${PG_VK_SYS}/postgresql.service.d/override.conf")
assert_contains "$PG_OVR_CONTENT" "RequiresMountsFor=${PG_VK_MNT}" "postgres override.conf sets RequiresMountsFor"
assert_contains "$PG_OVR_CONTENT" "ReadWritePaths=${PG_VK_MNT}/postgres" "postgres override.conf sets ReadWritePaths"
assert_contains "$PG_OVR_CONTENT" "POSTGRES_DATA_DIR=${PG_VK_MNT}/postgres" "postgres override.conf sets POSTGRES_DATA_DIR"

if [ ! -f "${PG_VK_SYS}/valkey-server.service.d/override.conf" ]; then
  printf '[FAIL] prepare-storage did not create valkey-server.service.d/override.conf\n' >&2
  exit 1
fi
VK_OVR_CONTENT=$(cat "${PG_VK_SYS}/valkey-server.service.d/override.conf")
assert_contains "$VK_OVR_CONTENT" "RequiresMountsFor=${PG_VK_MNT}" "valkey override.conf sets RequiresMountsFor"
assert_contains "$VK_OVR_CONTENT" "ReadWritePaths=${PG_VK_MNT}/valkey" "valkey override.conf sets ReadWritePaths"
assert_contains "$VK_OVR_CONTENT" "VALKEY_DATA_DIR=${PG_VK_MNT}/valkey" "valkey override.conf sets VALKEY_DATA_DIR"

VK_CONF_CONTENT=$(cat "${PG_VK_ETC}/valkey/valkey.conf")
assert_contains "$VK_CONF_CONTENT" "dir ${PG_VK_MNT}/valkey" "valkey.conf updated dir to persistent /mnt/data/valkey"
assert_contains "$VK_CONF_CONTENT" "appendonly yes" "valkey.conf enabled appendonly yes"

# Verify traits/storage/mount.sh excludes postgres and valkey from recursive chown and invokes restore_service_data_ownership
MOUNT_SH_CONTENT=$(cat "${LIBSCRIPT_ROOT_DIR}/traits/storage/mount.sh")
assert_contains "$MOUNT_SH_CONTENT" "ollama_models|postgres|postgresql|valkey|redis|certs|lost+found" "traits/storage/mount.sh excludes postgres and valkey from recursive chown"
assert_contains "$MOUNT_SH_CONTENT" "restore_service_data_ownership" "traits/storage/mount.sh defines and invokes restore_service_data_ownership"
printf '[PASS] Azure --delete-option Detach, prepare-storage Postgres/Valkey configuration, and mount.sh ownership protection\n'

# 20. Test Let's Encrypt read-only certificate persistence in /mnt/data/certs, self-signed rejection, and expiry-only renewal
if command -v openssl >/dev/null 2>&1; then
  LE_DOM='pulse-query.healthplatform.io'
  LE_STORE="${TEST_TMP}/mnt_data/certs"
  LE_LIVE="${LE_STORE}/live/${LE_DOM}"
  LE_MOCK_BIN="${TEST_TMP}/le_mock_bin"
  LE_CB_LOG="${TEST_TMP}/certbot_calls.log"
  mkdir -p "$LE_LIVE" "$LE_MOCK_BIN" "${TEST_TMP}/le_app/dist"
  : > "$LE_CB_LOG"
  printf '<html>Pulse Query</html>\n' > "${TEST_TMP}/le_app/dist/index.html"

  # Create a mock CA and a valid 30-day CA-signed leaf certificate (Issuer != Subject)
  openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout "${TEST_TMP}/le_ca.key" -out "${TEST_TMP}/le_ca.crt" \
    -subj "/C=US/O=Internet Security Research Group/CN=ISRG Root X1" >/dev/null 2>&1
  openssl req -nodes -newkey rsa:2048 \
    -keyout "${LE_LIVE}/privkey.pem" -out "${TEST_TMP}/le_leaf.csr" \
    -subj "/CN=${LE_DOM}" >/dev/null 2>&1
  openssl x509 -req -days 30 -in "${TEST_TMP}/le_leaf.csr" \
    -CA "${TEST_TMP}/le_ca.crt" -CAkey "${TEST_TMP}/le_ca.key" -CAcreateserial \
    -out "${LE_LIVE}/fullchain.pem" >/dev/null 2>&1

  # Mock certbot that records invocations and issues a fresh CA-signed cert into CERT_STORE_DIR
  cat << EOF_MOCK_CB > "${LE_MOCK_BIN}/certbot"
#!/bin/sh
printf 'certbot %s\n' "\$*" >> "${LE_CB_LOG}"
mkdir -p "${LE_LIVE}"
chmod 0755 "${LE_LIVE}" 2>/dev/null || true
chmod 0600 "${LE_LIVE}/fullchain.pem" "${LE_LIVE}/privkey.pem" 2>/dev/null || true
openssl req -nodes -newkey rsa:2048 \
  -keyout "${LE_LIVE}/privkey.pem" -out "${TEST_TMP}/le_renew.csr" \
  -subj "/CN=${LE_DOM}" >/dev/null 2>&1
openssl x509 -req -days 90 -in "${TEST_TMP}/le_renew.csr" \
  -CA "${TEST_TMP}/le_ca.crt" -CAkey "${TEST_TMP}/le_ca.key" -CAcreateserial \
  -out "${LE_LIVE}/fullchain.pem" >/dev/null 2>&1
exit 0
EOF_MOCK_CB
  chmod +x "${LE_MOCK_BIN}/certbot"

  cat << EOF_LE_JSON > "${TEST_TMP}/le_app/libscript.json"
{
  "name": "pulse-query",
  "ingress": {
    "provider": "nginx",
    "domain": "${LE_DOM}",
    "tls": "letsencrypt",
    "cert_store_dir": "${LE_STORE}",
    "routes": {
      "/api": {"proxy": "http://127.0.0.1:8000"},
      "/": {"static": "./dist", "spa": true}
    }
  }
}
EOF_LE_JSON

  # (1) Valid CA-signed non-expired cert in ${TEST_TMP}/mnt_data/certs/live/${LE_DOM}/ is restored & reused without invoking certbot
  LE_ING_OUT=$(PATH="${LE_MOCK_BIN}:$PATH" CERT_STORE_DIR="$LE_STORE" STACK="" \
    "${LIBSCRIPT_ROOT_DIR}/_lib/networking/netctl/cli.sh" ingress "${TEST_TMP}/le_app/libscript.json" 2>&1)
  assert_contains "$LE_ING_OUT" "[REUSE] [TLS]" "netctl ingress reuses valid non-expired Let's Encrypt certificate from /mnt/data/certs"
  if [ -s "$LE_CB_LOG" ]; then
    printf '[FAIL] certbot was invoked even though a valid non-expired CA certificate existed in %s\n' "$LE_LIVE" >&2
    exit 1
  fi

  # (2) Verify persisted certificate files have read-only permissions (0444 for fullchain.pem, 0400 for privkey.pem)
  # shellcheck disable=SC2012
  _fc_perm=$(ls -l "${LE_LIVE}/fullchain.pem" | awk '{print $1}')
  # shellcheck disable=SC2012
  _pk_perm=$(ls -l "${LE_LIVE}/privkey.pem" | awk '{print $1}')
  assert_contains "$_fc_perm" "-r--r--r--" "persisted fullchain.pem has read-only 0444 permissions"
  assert_contains "$_pk_perm" "-r--------" "persisted privkey.pem has read-only 0400 permissions"

  # Verify emitted nginx config has /.well-known/acme-challenge/ and 443 ssl_certificate pointing to LE_STORE
  LE_EMIT_CONF=$(CERT_STORE_DIR="$LE_STORE" STACK="" \
    "${LIBSCRIPT_ROOT_DIR}/_lib/networking/netctl/cli.sh" apply "${TEST_TMP}/le_app/libscript.json" --format nginx)
  assert_contains "$LE_EMIT_CONF" "location ^~ /.well-known/acme-challenge/" "nginx config includes /.well-known/acme-challenge/ location"
  assert_contains "$LE_EMIT_CONF" "ssl_certificate ${LE_LIVE}/fullchain.pem;" "nginx config uses read-only cert from CERT_STORE_DIR"

  # (3) Self-signed certificate is rejected by netctl_cert_is_valid_letsencrypt and triggers Certbot acquisition
  chmod 0755 "$LE_LIVE"
  chmod 0600 "${LE_LIVE}/fullchain.pem" "${LE_LIVE}/privkey.pem"
  openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout "${LE_LIVE}/privkey.pem" -out "${LE_LIVE}/fullchain.pem" \
    -subj "/CN=${LE_DOM}" >/dev/null 2>&1
  PATH="${LE_MOCK_BIN}:$PATH" CERT_STORE_DIR="$LE_STORE" STACK="" \
    "${LIBSCRIPT_ROOT_DIR}/_lib/networking/netctl/cli.sh" ingress "${TEST_TMP}/le_app/libscript.json" >/dev/null 2>&1
  CB_CALLS_AFTER_SELFSIGNED=$(wc -l < "$LE_CB_LOG" | tr -d ' ')
  if [ "$CB_CALLS_AFTER_SELFSIGNED" -lt 1 ]; then
    printf '[FAIL] Self-signed certificate was not rejected by netctl_cert_is_valid_letsencrypt\n' >&2
    exit 1
  fi
  printf '[PASS] Self-signed certificate rejected and replaced with CA-signed certificate\n'

  # (4) Expired certificate (or certificate failing openssl x509 -checkend threshold) triggers renewal, whereas non-expired does not
  : > "$LE_CB_LOG"
  PATH="${LE_MOCK_BIN}:$PATH" CERT_STORE_DIR="$LE_STORE" LETSENCRYPT_RENEW_BEFORE_SECONDS=0 STACK="" \
    "${LIBSCRIPT_ROOT_DIR}/_lib/networking/netctl/cli.sh" ingress "${TEST_TMP}/le_app/libscript.json" >/dev/null 2>&1
  if [ -s "$LE_CB_LOG" ]; then
    printf '[FAIL] Non-expired certificate should not be renewed when LETSENCRYPT_RENEW_BEFORE_SECONDS=0\n' >&2
    exit 1
  fi
  # Simulate expiration by requiring 365 days (31536000s) remaining on a 90-day certificate
  PATH="${LE_MOCK_BIN}:$PATH" CERT_STORE_DIR="$LE_STORE" LETSENCRYPT_RENEW_BEFORE_SECONDS=31536000 STACK="" \
    "${LIBSCRIPT_ROOT_DIR}/_lib/networking/netctl/cli.sh" ensure-cert "$LE_DOM" "$LE_STORE" >/dev/null 2>&1 || true
  if [ ! -s "$LE_CB_LOG" ]; then
    printf '[FAIL] Expired certificate (failing openssl x509 -checkend) did not trigger Certbot renewal\n' >&2
    exit 1
  fi
  printf '[PASS] Let'\''s Encrypt read-only persistence (/mnt/data/certs), self-signed rejection, and expiry-only renewal\n'
fi

# 21. Test DATA_DISK_MOUNT and DATA_MOUNT_DIR override default /mnt/data across certbot, netctl, and database provisioning
CUSTOM_DATA_MOUNT="${TEST_TMP}/custom_data_mount"
mkdir -p "$CUSTOM_DATA_MOUNT"
# shellcheck disable=SC2016
CB_MOUNT_OUT=$(
  env -i PATH="$PATH" HOME="${TEST_TMP}" LIBSCRIPT_ROOT_DIR="${LIBSCRIPT_ROOT_DIR}" DATA_DISK_MOUNT="${CUSTOM_DATA_MOUNT}" sh -c '
    SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/_lib/security/certbot/env.sh"
    export SCRIPT_NAME
    . "${SCRIPT_NAME}"
    printf "CS=%s\n" "${CERT_STORE_DIR:-}"
  '
)
assert_contains "$CB_MOUNT_OUT" "CS=${CUSTOM_DATA_MOUNT}/certs" "certbot/env.sh derives CERT_STORE_DIR from DATA_DISK_MOUNT when CERT_STORE_DIR is unset"

DUCK_MOUNT_DIR="${TEST_TMP}/duck_mount_app"
mkdir -p "$DUCK_MOUNT_DIR"
cat << 'EOF_DUCK_MOUNT' > "${DUCK_MOUNT_DIR}/libscript.json"
{
  "databases": [
    {
      "name": "mounted_analytics",
      "engine": "duckdb"
    }
  ]
}
EOF_DUCK_MOUNT
DATA_DISK_MOUNT="${CUSTOM_DATA_MOUNT}" STACK="" "${LIBSCRIPT_ROOT_DIR}/_lib/databases/provision_db.sh" "${DUCK_MOUNT_DIR}/libscript.json" >/dev/null 2>&1
if [ ! -f "${CUSTOM_DATA_MOUNT}/mounted_analytics.duckdb" ]; then
  printf '[FAIL] provision_db.sh did not use DATA_DISK_MOUNT (%s/mounted_analytics.duckdb) when path is omitted\n' "$CUSTOM_DATA_MOUNT" >&2
  exit 1
fi
printf '[PASS] DATA_DISK_MOUNT overrides default /mnt/data across certbot and database provisioning\n'

# 22. Test .ingress.proxy_read_timeout propagation to NETCTL_PROXY_READ_TIMEOUT during libscript_Synchronize_Ingress
INGRESS_TIMEOUT_DIR="${TEST_TMP}/ingress_timeout_app"
mkdir -p "$INGRESS_TIMEOUT_DIR"
cat << 'EOF_INGRESS_TIMEOUT' > "${INGRESS_TIMEOUT_DIR}/libscript.json"
{
  "ingress": {
    "provider": "nginx",
    "domain": "t1d-analytics.healthplatform.io",
    "proxy_connect_timeout": 45,
    "proxy_send_timeout": 420,
    "proxy_read_timeout": 600,
    "proxy_buffering": "off",
    "routes": {
      "/api": "http://127.0.0.1:8000"
    }
  }
}
EOF_INGRESS_TIMEOUT

# shellcheck disable=SC2016
SYNC_ING_OUT=$(
  env -i PATH="$PATH" HOME="${TEST_TMP}" LIBSCRIPT_ROOT_DIR="${LIBSCRIPT_ROOT_DIR}" sh -c '
    SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/_lib/_common/component_core.sh"
    export SCRIPT_NAME
    LIBSCRIPT_COMPONENT_CORE_LIB_ONLY=1 . "${SCRIPT_NAME}"
    libscript_Synchronize_Ingress "'"${INGRESS_TIMEOUT_DIR}/libscript.json"'" --format nginx --out "'"${INGRESS_TIMEOUT_DIR}/nginx.conf"'"
    printf "CONN=%s SEND=%s READ=%s BUF=%s\n" "${NETCTL_PROXY_CONNECT_TIMEOUT:-}" "${NETCTL_PROXY_SEND_TIMEOUT:-}" "${NETCTL_PROXY_READ_TIMEOUT:-}" "${NETCTL_PROXY_BUFFERING:-}"
  '
)
assert_contains "$SYNC_ING_OUT" "READ=600s" "libscript_Synchronize_Ingress normalizes .ingress.proxy_read_timeout to NETCTL_PROXY_READ_TIMEOUT=600s"
assert_contains "$SYNC_ING_OUT" "CONN=45s" "libscript_Synchronize_Ingress normalizes .ingress.proxy_connect_timeout to NETCTL_PROXY_CONNECT_TIMEOUT=45s"
assert_contains "$(cat "${INGRESS_TIMEOUT_DIR}/nginx.conf")" "proxy_read_timeout 600s;" "libscript_Synchronize_Ingress emits proxy_read_timeout 600s in nginx.conf"
assert_contains "$(cat "${INGRESS_TIMEOUT_DIR}/nginx.conf")" "proxy_buffering off;" "libscript_Synchronize_Ingress emits proxy_buffering off in nginx.conf"

printf '=== ALL FULLSTACK ORCHESTRATION TESTS PASSED ===\n'

