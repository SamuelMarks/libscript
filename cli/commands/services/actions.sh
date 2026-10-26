#!/bin/sh
# ## Overview
# Provides a unified interface for managing service states (start, stop, restart,
# status, health, logs, down, uninstall-service, deprovision-db, export-state, import-state).
#
# ## Usage
# Execute this script to perform lifecycle actions on background services.

set -feu
if [ "${SCRIPT_NAME-}" ]; then
  THIS_FILE="${SCRIPT_NAME}"
elif [ "${BASH_SOURCE-}" ]; then
  THIS_FILE="${BASH_SOURCE}"
elif [ "${ZSH_VERSION-}" ]; then
  # libscript-allow-eval
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

if [ "$CMD" = "deprovision-db" ]; then
  json_file="${1:-libscript.json}"
  exec "${LIBSCRIPT_ROOT_DIR:-.}/_lib/databases/deprovision_db.sh" "$json_file"
elif [ "$CMD" = "export-state" ]; then
  json_file="${1:-libscript.json}"
  stage_dir="${2:-}"
  exec "${LIBSCRIPT_ROOT_DIR:-.}/_lib/databases/export_db.sh" "$json_file" "$stage_dir"
elif [ "$CMD" = "import-state" ]; then
  json_file="${1:-libscript.json}"
  stage_dir="${2:-}"
  exec "${LIBSCRIPT_ROOT_DIR:-.}/_lib/databases/import_db.sh" "$json_file" "$stage_dir"
elif [ "$CMD" = "prepare-storage" ]; then
  json_file="${1:-libscript.json}"
  if [ -f "$json_file" ] && command -v jq >/dev/null 2>&1; then
    if [ -f "${LIBSCRIPT_ROOT_DIR:-.}/_lib/_common/env_printer.sh" ]; then
      SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR:-.}/_lib/_common/env_printer.sh"
      # shellcheck disable=SC1090,SC1091
      . "${LIBSCRIPT_ROOT_DIR:-.}/_lib/_common/env_printer.sh"
      unset SCRIPT_NAME || true
      libscript_hydrate_manifest_env "$json_file" || true
    fi
    _ps_mounts=$(jq -r '(.infrastructure.node.data_disks // [])[]? | "\(.mount_path // "/mnt/data") \(.fstype // "ext4")"' "$json_file" 2>/dev/null || true)
    if [ -n "$_ps_mounts" ]; then
      printf '%s\n' "$_ps_mounts" | while read -r _mp _fs; do
        [ -n "$_mp" ] || continue
        if type libscript_expand_manifest_vars >/dev/null 2>&1; then
          _mp=$(libscript_expand_manifest_vars "$_mp")
        fi
        case "$_mp" in
          \$\{*) _mp="${DATA_DISK_MOUNT:-${DATA_MOUNT_DIR:-/mnt/data}}" ;;
        esac
        "${LIBSCRIPT_ROOT_DIR:-.}/traits/storage/mount.sh" --auto-data-disk "$_mp" "${_fs:-ext4}"
      done
    fi
    if [ -f "${LIBSCRIPT_ROOT_DIR:-.}/_lib/_common/service_install.sh" ]; then
      SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR:-.}/_lib/_common/service_install.sh"
      # shellcheck disable=SC1090,SC1091
      . "${LIBSCRIPT_ROOT_DIR:-.}/_lib/_common/service_install.sh"
      unset SCRIPT_NAME || true
    fi
    _ps_overrides=$(jq -r '(.service_overrides // {}) | to_entries[]? | "\(.key) \(.value | to_entries | map("\(.key)=\(.value)") | join(" "))"' "$json_file" 2>/dev/null || true)
    if [ -n "$_ps_overrides" ] && type libscript_service_override_env >/dev/null 2>&1; then
      printf '%s\n' "$_ps_overrides" | while read -r _ovr_svc _ovr_pairs; do
        [ -n "$_ovr_svc" ] && [ -n "$_ovr_pairs" ] || continue
        if type libscript_expand_manifest_vars >/dev/null 2>&1; then
          _ovr_pairs=$(libscript_expand_manifest_vars "$_ovr_pairs")
        fi
        # shellcheck disable=SC2086
        libscript_service_override_env "$_ovr_svc" $_ovr_pairs || true
      done
    fi
    _has_ollama=$(jq -r 'if (.deps.ollama != null) or (.dependencies.ollama != null) or ([.dependencies.runtime[]? | select(.name == "ollama")] | length > 0) then "1" else "0" end' "$json_file" 2>/dev/null || printf '0')
    if [ "$_has_ollama" = "1" ] || [ -n "${OLLAMA_MODELS:-}" ]; then
      _ol_models="${OLLAMA_MODELS:-${DATA_DISK_MOUNT:-${DATA_MOUNT_DIR:-/mnt/data}}/ollama_models}"
      if [ -x "${LIBSCRIPT_ROOT_DIR:-.}/_lib/app-servers/ollama/service.sh" ]; then
        OLLAMA_MODELS="$_ol_models" "${LIBSCRIPT_ROOT_DIR:-.}/_lib/app-servers/ollama/service.sh" configure || true
      fi
    fi
  fi
  exit 0
fi

if [ "$CMD" = "start" ] || [ "$CMD" = "stop" ] || [ "$CMD" = "status" ] || [ "$CMD" = "health" ] || [ "$CMD" = "logs" ] || [ "$CMD" = "restart" ] || [ "$CMD" = "up" ] || [ "$CMD" = "down" ] || [ "$CMD" = "uninstall-service" ]; then
  action="$CMD"
  if [ "$action" = "up" ]; then action="start"; fi
  if [ "$action" = "down" ]; then action="stop"; fi
  if [ "$action" = "uninstall-service" ]; then action="uninstall"; fi

  # ## perform_health_check
  # Executes runtime health checks for the given package and version.
  perform_health_check() {
    _pkg="$1"
    _ver="$2"

    case "$_pkg" in
        postgres)
            "${LIBSCRIPT_ROOT_DIR:-.}/libscript.sh" "$_pkg" "health" "$_pkg" "$_ver"
            if command -v pg_isready >/dev/null 2>&1; then
              pg_isready >/dev/null 2>&1
            elif command -v psql >/dev/null 2>&1; then
              psql -U postgres -c 'SELECT 1;' >/dev/null 2>&1 || su - postgres -c "psql -c 'SELECT 1;'" >/dev/null 2>&1
            fi
            ;;
        mariadb|mysql)
            "${LIBSCRIPT_ROOT_DIR:-.}/libscript.sh" "$_pkg" "health" "$_pkg" "$_ver"
            if command -v mysql >/dev/null 2>&1; then
              mysql -u root -e 'SELECT 1;' >/dev/null 2>&1
            fi
            ;;
        mongodb)
            "${LIBSCRIPT_ROOT_DIR:-.}/libscript.sh" "$_pkg" "health" "$_pkg" "$_ver"
            mongosh --eval 'db.runCommand({ ping: 1 })' >/dev/null 2>&1 || mongo --eval 'db.runCommand({ ping: 1 })' >/dev/null 2>&1
            ;;
        etcd)
            "${LIBSCRIPT_ROOT_DIR:-.}/libscript.sh" "$_pkg" "health" "$_pkg" "$_ver"
            etcdctl version >/dev/null 2>&1
            ;;
        valkey|redis)
            if command -v valkey-cli >/dev/null 2>&1 && valkey-cli ping 2>/dev/null | grep -qi "PONG"; then
              true
            elif command -v redis-cli >/dev/null 2>&1 && redis-cli ping 2>/dev/null | grep -qi "PONG"; then
              true
            else
              "${LIBSCRIPT_ROOT_DIR:-.}/libscript.sh" "$_pkg" "health" "$_pkg" "$_ver"
            fi
            ;;
        nginx|ollama)
            "${LIBSCRIPT_ROOT_DIR:-.}/libscript.sh" "$_pkg" "health" "$_pkg" "$_ver"
            ;;
        duckdb)
            if command -v duckdb >/dev/null 2>&1; then
              duckdb :memory: -c 'SELECT 1;' >/dev/null 2>&1 || true
            else
              "${LIBSCRIPT_ROOT_DIR:-.}/libscript.sh" "$_pkg" "health" "$_pkg" "$_ver"
            fi
            ;;
        sqlite) sqlite3 :memory: 'SELECT 1;' >/dev/null 2>&1 || true ;;
        python) python3 -c 'print("hello world!")' || true ;; # libscript-allow-interp
        ruby) ruby -e 'puts "hello world!"' || true ;; # libscript-allow-interp
        nodejs) node -e 'console.log("hello world!")' || true ;; # libscript-allow-interp
        java) java -version || true ;;
        csharp) dotnet --version || true ;;
        go) go version || true ;;
        rust) rustc --version || true ;;
        php) php -r 'echo "hello world!";' || true ;;
        elixir) elixir -e 'IO.puts("hello world!")' || true ;;
        swift) swift --version || true ;;
        zig) zig version || true ;;
        deno) deno --version || true ;;
        bun) bun --version || true ;;
        c|cc|cpp) gcc --version || clang --version || true ;;
        sh) sh --version || echo 'sh is present' || true ;;
        bazel) bazel --version || true ;;
        cmake) cmake --version || true ;;
        coursier) cs --version || true ;;
        gradle) gradle --version || true ;;
        huggingface-cli) huggingface-cli --version || true ;;
        just) just --version || true ;;
        maven) mvn --version || true ;;
        uv)
            if command -v uv >/dev/null 2>&1; then
              uv --version || true
            else
              "${LIBSCRIPT_ROOT_DIR:-.}/_lib/package-managers/uv/cli.sh" test >/dev/null 2>&1 || true
            fi
            ;;
        xpk) xpk --version || true ;;
        *)
          "${LIBSCRIPT_ROOT_DIR:-.}/libscript.sh" "$_pkg" "health" "$_pkg" "$_ver" || true
          if command -v "$_pkg" >/dev/null 2>&1; then
            "$_pkg" --version || true
          fi
          ;;
    esac
  }

  # ## normalize_service_data_ownership
  # Ensures data directories and DuckDB files are owned by the configured service user before daemon startup.
  normalize_service_data_ownership() {
    _nsd_json="$1"
    _nsd_dir=$(cd -- "$(dirname -- "$_nsd_json")" && pwd)
    if [ -f "${LIBSCRIPT_ROOT_DIR:-.}/_lib/_common/env_printer.sh" ]; then
      SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR:-.}/_lib/_common/env_printer.sh"
      # shellcheck disable=SC1090,SC1091
      . "${LIBSCRIPT_ROOT_DIR:-.}/_lib/_common/env_printer.sh"
      unset SCRIPT_NAME || true
      libscript_hydrate_manifest_env "$_nsd_json" || true
    fi
    _nsd_user=$(jq -r '((.services // .infrastructure.services) | if type == "object" then [to_entries[].value] elif type == "array" then . else [] end) | .[0].user // empty' "$_nsd_json" 2>/dev/null || true)
    if type libscript_expand_manifest_vars >/dev/null 2>&1; then
      _nsd_user=$(libscript_expand_manifest_vars "$_nsd_user")
    fi
    if [ -z "$_nsd_user" ]; then
      _nsd_user="${SERVICE_USER:-${REMOTE_USER:-${SUDO_USER:-}}}"
    fi
    if [ -n "$_nsd_user" ] && id "$_nsd_user" >/dev/null 2>&1; then
      _nsd_group="${SERVICE_GROUP:-${REMOTE_GROUP:-$_nsd_user}}"
      for _nsd_ef in "${_nsd_dir}/.env.libscript" "${_nsd_dir}/.env" "${_nsd_dir}/.env.secrets"; do
        if [ -f "$_nsd_ef" ]; then
          chown "${_nsd_user}:${_nsd_group}" "$_nsd_ef" 2>/dev/null || sudo -n chown "${_nsd_user}:${_nsd_group}" "$_nsd_ef" 2>/dev/null || true
          chmod 0644 "$_nsd_ef" 2>/dev/null || sudo -n chmod 0644 "$_nsd_ef" 2>/dev/null || true
        fi
      done
      for _nsd_target in "${DATA_DISK_MOUNT:-/mnt/data}" "${DATA_MOUNT_DIR:-/mnt/data}" "${TMP_DATA_DIR:-/tmp/data}" "${_nsd_dir}/data"; do
        if [ -n "$_nsd_target" ] && [ -d "$_nsd_target" ]; then
          chown -R "${_nsd_user}:${_nsd_group}" "$_nsd_target" 2>/dev/null || sudo -n chown -R "${_nsd_user}:${_nsd_group}" "$_nsd_target" 2>/dev/null || true
          chmod -R u+rwX,go+rX "$_nsd_target" 2>/dev/null || sudo -n chmod -R u+rwX,go+rX "$_nsd_target" 2>/dev/null || true
        fi
      done
    fi
  }

  # ## check_manifest_health_once
  # Runs database, daemon, and hook health checks once and returns 0 if all succeed.
  check_manifest_health_once() {
    _cmh_json="$1"
    shift
    if [ -f "${LIBSCRIPT_ROOT_DIR:-.}/_lib/databases/health_db.sh" ]; then
      if ! "${LIBSCRIPT_ROOT_DIR:-.}/_lib/databases/health_db.sh" "$_cmh_json" "$@"; then
        return 1
      fi
    fi
    if ! "${LIBSCRIPT_ROOT_DIR:-.}/_lib/init-systems/daemonize.sh" "health" "$_cmh_json" "$@"; then
      return 1
    fi
    if [ "$skip_hooks" -eq 0 ]; then
      if ! "${LIBSCRIPT_ROOT_DIR:-.}/_lib/orchestration/run_hooks.sh" "$_cmh_json" "health"; then
        return 1
      fi
    fi
    return 0
  }

  follow_logs=0
  skip_hooks=0
  remove_service=0
  purge_data=0
  remediate=0
  verify_ingress=0
  public_url=""
  _orig_argc=$#
  _arg_idx=0
  while [ "$_arg_idx" -lt "$_orig_argc" ]; do
    _cur_arg="$1"
    shift
    case "$_cur_arg" in
      -f|--follow) follow_logs=1 ;;
      --no-hooks) skip_hooks=1 ;;
      --remove|--uninstall) remove_service=1 ;;
      --purge-data) purge_data=1 ;;
      --remediate) remediate=1 ;;
      --verify-ingress) verify_ingress=1 ;;
      --public-url=*) public_url="${_cur_arg#*=}"; verify_ingress=1 ;;
      *) set -- "$@" "$_cur_arg" ;;
    esac
    _arg_idx=$((_arg_idx + 1))
  done

  if [ "$action" = "stop" ] && [ "$remove_service" -eq 1 ]; then
    action="uninstall"
  fi

  if [ $# -eq 0 ] || [ "$1" = "libscript.json" ] || [ "${1##*.}" = "json" ]; then
    json_file="${1:-libscript.json}"
    if [ ! -f "$json_file" ]; then
      printf '%s\n' "Error: $json_file not found." >&2
      exit 1
    fi
    if ! command -v jq >/dev/null 2>&1; then
      if [ -f "${LIBSCRIPT_ROOT_DIR:-.}/_lib/utilities/jq/setup.sh" ]; then
        "${LIBSCRIPT_ROOT_DIR:-.}/_lib/utilities/jq/setup.sh"
      fi
    fi
    if ! command -v jq >/dev/null 2>&1; then
      printf '%s\n' "Error: jq is required to parse $json_file." >&2
      exit 1
    fi

    if [ -f "${LIBSCRIPT_ROOT_DIR:-.}/_lib/_common/env_printer.sh" ]; then
      SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR:-.}/_lib/_common/env_printer.sh"
      # shellcheck disable=SC1090,SC1091
      . "${LIBSCRIPT_ROOT_DIR:-.}/_lib/_common/env_printer.sh"
      unset SCRIPT_NAME || true
      libscript_hydrate_manifest_env "$json_file" || true
    fi

    if [ "$skip_hooks" -eq 0 ]; then
      if [ "$action" = "start" ] || [ "$action" = "up" ]; then
        "${LIBSCRIPT_ROOT_DIR:-.}/_lib/orchestration/run_hooks.sh" "$json_file" "build"
      elif [ "$action" = "stop" ] || [ "$action" = "down" ] || [ "$action" = "uninstall" ]; then
        "${LIBSCRIPT_ROOT_DIR:-.}/_lib/orchestration/run_hooks.sh" "$json_file" "pre_stop" || true
      fi
    fi

    if [ "$action" != "uninstall" ]; then
      unset SCRIPT_NAME || true
      deps=$("${LIBSCRIPT_ROOT_DIR:-.}/_lib/orchestration/resolve_stack.sh" "$json_file" 2>/dev/null | jq -r '.selected[] | "\(.name) \(.version // "latest")"' 2>/dev/null || true)
      if [ -n "$deps" ]; then
        printf '%s\n' "$deps" > "$json_file.tmpdeps"
        while read -r pkg ver; do
          if [ -n "$pkg" ]; then
            if [ "$ver" = "null" ]; then ver="latest"; fi
            if [ "$action" = "logs" ] && [ "$follow_logs" = "1" ]; then
              "${LIBSCRIPT_ROOT_DIR:-.}/libscript.sh" "$pkg" "$action" "$pkg" "$ver" -f 2>&1 | awk -v prefix="$pkg" '{print "\033[36m" prefix " |\033[0m " $0; fflush()}' &
            elif [ "$action" = "health" ]; then
              printf '%s\n' "=== $pkg ==="
              perform_health_check "$pkg" "$ver"
            elif [ "$action" = "status" ] || [ "$action" = "logs" ]; then
              printf '%s\n' "=== $pkg ==="
              "${LIBSCRIPT_ROOT_DIR:-.}/libscript.sh" "$pkg" "$action" "$pkg" "$ver"
            elif [ "$action" = "start" ] || [ "$action" = "up" ]; then
              case "$pkg" in
                postgres|postgresql|mariadb|mysql|valkey|redis|mongodb|etcd)
                  "${LIBSCRIPT_ROOT_DIR:-.}/libscript.sh" "$pkg" "$action" "$pkg" "$ver"
                  ;;
                python|nodejs|uv|duckdb|sqlite|ruby|java|csharp|go|rust|php|elixir|swift|zig|deno|bun|c|cc|cpp|sh|bazel|cmake|coursier|gradle|huggingface-cli|just|maven|xpk)
                  ;;
                *)
                  "${LIBSCRIPT_ROOT_DIR:-.}/libscript.sh" "$pkg" "$action" "$pkg" "$ver" &
                  ;;
              esac
            else
              case "$pkg" in
                python|nodejs|uv|duckdb|sqlite|ruby|java|csharp|go|rust|php|elixir|swift|zig|deno|bun|c|cc|cpp|sh|bazel|cmake|coursier|gradle|huggingface-cli|just|maven|xpk)
                  ;;
                *)
                  "${LIBSCRIPT_ROOT_DIR:-.}/libscript.sh" "$pkg" "$action" "$pkg" "$ver" &
                  ;;
              esac
            fi
          fi
        done < "$json_file.tmpdeps"
        rm -f "$json_file.tmpdeps"
      fi
    fi

    if [ "$action" = "start" ] || [ "$action" = "up" ]; then
      if [ "$skip_hooks" -eq 0 ]; then
        "${LIBSCRIPT_ROOT_DIR:-.}/_lib/init-systems/daemonize.sh" "stop" "$json_file" >/dev/null 2>&1 || true
        if [ -f "${LIBSCRIPT_ROOT_DIR:-.}/_lib/databases/provision_db.sh" ]; then
          "${LIBSCRIPT_ROOT_DIR:-.}/_lib/databases/provision_db.sh" "$json_file"
        fi
        "${LIBSCRIPT_ROOT_DIR:-.}/_lib/orchestration/run_hooks.sh" "$json_file" "db_migrate"
        "${LIBSCRIPT_ROOT_DIR:-.}/_lib/orchestration/run_hooks.sh" "$json_file" "pre_start"
      fi
      normalize_service_data_ownership "$json_file"
      "${LIBSCRIPT_ROOT_DIR:-.}/_lib/init-systems/daemonize.sh" "$action" "$json_file"
      if jq -e '.ingress != null' "$json_file" >/dev/null 2>&1; then
        "${LIBSCRIPT_ROOT_DIR:-.}/_lib/networking/netctl/cli.sh" apply "$json_file" --reload || true
      fi
      if [ "$skip_hooks" -eq 0 ]; then
        "${LIBSCRIPT_ROOT_DIR:-.}/_lib/orchestration/run_hooks.sh" "$json_file" "post_start"
      fi
    elif [ "$action" = "stop" ] || [ "$action" = "down" ]; then
      "${LIBSCRIPT_ROOT_DIR:-.}/_lib/init-systems/daemonize.sh" "$action" "$json_file"
      if [ "$purge_data" -eq 1 ] && [ -f "${LIBSCRIPT_ROOT_DIR:-.}/_lib/databases/deprovision_db.sh" ]; then
        "${LIBSCRIPT_ROOT_DIR:-.}/_lib/databases/deprovision_db.sh" "$json_file"
      fi
      if [ "$skip_hooks" -eq 0 ]; then
        "${LIBSCRIPT_ROOT_DIR:-.}/_lib/orchestration/run_hooks.sh" "$json_file" "post_stop"
      fi
    elif [ "$action" = "uninstall" ]; then
      "${LIBSCRIPT_ROOT_DIR:-.}/_lib/init-systems/daemonize.sh" "uninstall" "$json_file"
      if jq -e '.ingress != null' "$json_file" >/dev/null 2>&1; then
        "${LIBSCRIPT_ROOT_DIR:-.}/_lib/networking/netctl/cli.sh" remove-ingress "$json_file" --reload || true
      fi
      if [ "$purge_data" -eq 1 ] && [ -f "${LIBSCRIPT_ROOT_DIR:-.}/_lib/databases/deprovision_db.sh" ]; then
        "${LIBSCRIPT_ROOT_DIR:-.}/_lib/databases/deprovision_db.sh" "$json_file"
      fi
      if [ "$skip_hooks" -eq 0 ]; then
        "${LIBSCRIPT_ROOT_DIR:-.}/_lib/orchestration/run_hooks.sh" "$json_file" "post_stop" || true
      fi
    elif [ "$action" = "health" ]; then
      set --
      [ "$verify_ingress" -eq 1 ] && set -- "$@" "--verify-ingress"
      [ -n "$public_url" ] && set -- "$@" "--public-url=${public_url}"
      if ! check_manifest_health_once "$json_file" "$@"; then
        if [ "$remediate" -eq 1 ]; then
          printf '[INFO] Health check failed for %s; running auto-remediation...\n' "$json_file"
          "${LIBSCRIPT_ROOT_DIR:-.}/_lib/init-systems/daemonize.sh" "stop" "$json_file" >/dev/null 2>&1 || true
          if [ -f "${LIBSCRIPT_ROOT_DIR:-.}/_lib/databases/provision_db.sh" ]; then
            LIBSCRIPT_FORCE_SEED=1 "${LIBSCRIPT_ROOT_DIR:-.}/_lib/databases/provision_db.sh" "$json_file"
          fi
          "${LIBSCRIPT_ROOT_DIR:-.}/_lib/orchestration/run_hooks.sh" "$json_file" "db_migrate" || true
          "${LIBSCRIPT_ROOT_DIR:-.}/_lib/orchestration/run_hooks.sh" "$json_file" "pre_start" || true
          normalize_service_data_ownership "$json_file"
          "${LIBSCRIPT_ROOT_DIR:-.}/_lib/init-systems/daemonize.sh" "start" "$json_file"
          if jq -e '.ingress != null' "$json_file" >/dev/null 2>&1; then
            "${LIBSCRIPT_ROOT_DIR:-.}/_lib/networking/netctl/cli.sh" apply "$json_file" --reload || true
          fi
          check_manifest_health_once "$json_file" "$@"
        else
          exit 1
        fi
      fi
    elif [ "$action" = "status" ] || [ "$action" = "logs" ]; then
      "${LIBSCRIPT_ROOT_DIR:-.}/_lib/init-systems/daemonize.sh" "$action" "$json_file"
    elif [ "$action" = "restart" ]; then
      "${LIBSCRIPT_ROOT_DIR:-.}/_lib/init-systems/daemonize.sh" "stop" "$json_file"
      normalize_service_data_ownership "$json_file"
      "${LIBSCRIPT_ROOT_DIR:-.}/_lib/init-systems/daemonize.sh" "start" "$json_file"
      if jq -e '.ingress != null' "$json_file" >/dev/null 2>&1; then
        "${LIBSCRIPT_ROOT_DIR:-.}/_lib/networking/netctl/cli.sh" apply "$json_file" --reload || true
      fi
    fi

    wait
    exit 0
  else
    for pkg in "$@"; do
      if [ "$action" = "logs" ] && [ "$follow_logs" = "1" ]; then
        "${LIBSCRIPT_ROOT_DIR:-.}/libscript.sh" "$pkg" "$action" "$pkg" "latest" -f 2>&1 | awk -v prefix="$pkg" '{print "\033[36m" prefix " |\033[0m " $0; fflush()}' &
      elif [ "$action" = "health" ]; then
        printf '%s\n' "=== $pkg ==="
        perform_health_check "$pkg" "latest"
      elif [ "$action" = "status" ] || [ "$action" = "logs" ]; then
        printf '%s\n' "=== $pkg ==="
        "${LIBSCRIPT_ROOT_DIR:-.}/libscript.sh" "$pkg" "$action" "$pkg" "latest"
      else
        "${LIBSCRIPT_ROOT_DIR:-.}/libscript.sh" "$pkg" "$action" "$pkg" "latest" &
      fi
    done
    wait
    exit 0
  fi
fi
