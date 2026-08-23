#!/bin/sh
# ## Overview
# Provides a unified interface for managing service states (start, stop, restart).
# 
# ## Usage
# Execute this script to perform lifecycle actions on background services.


set -feu
# shellcheck disable=SC2296,SC3028,SC3040,SC3054
if [ "${SCRIPT_NAME-}" ]; then
  THIS_FILE="${SCRIPT_NAME}"
elif [ "${BASH_SOURCE-}" ]; then
  eval 'THIS_FILE="${BASH_SOURCE[0]}"'
  eval 'set -o pipefail'
elif [ "${ZSH_VERSION-}" ]; then
  eval 'THIS_FILE="${(%):-%x}"'
  eval 'set -o pipefail'
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
if [ "$CMD" = "start" ] || [ "$CMD" = "stop" ] || [ "$CMD" = "status" ] || [ "$CMD" = "health" ] || [ "$CMD" = "logs" ] || [ "$CMD" = "restart" ] || [ "$CMD" = "up" ] || [ "$CMD" = "down" ]; then
  action="$CMD"
  if [ "$action" = "up" ]; then action="start"; fi
  if [ "$action" = "down" ]; then action="stop"; fi

  perform_health_check() {
    _pkg="$1"
    _ver="$2"
    
    # Perform specific runtime checks
    case "$_pkg" in
        postgres)
            "${LIBSCRIPT_ROOT_DIR:-.}/libscript.sh" "$_pkg" "health" "$_pkg" "$_ver" || true
            su - postgres -c "psql -c 'SELECT 1;'" || true
            ;;
        mariadb|mysql)
            "${LIBSCRIPT_ROOT_DIR:-.}/libscript.sh" "$_pkg" "health" "$_pkg" "$_ver" || true
            mysql -u root -e 'SELECT 1;' || true
            ;;
        mongodb)
            "${LIBSCRIPT_ROOT_DIR:-.}/libscript.sh" "$_pkg" "health" "$_pkg" "$_ver" || true
            mongosh --eval 'db.runCommand({ ping: 1 })' || mongo --eval 'db.runCommand({ ping: 1 })' || true
            ;;
        etcd)
            "${LIBSCRIPT_ROOT_DIR:-.}/libscript.sh" "$_pkg" "health" "$_pkg" "$_ver" || true
            etcdctl version || true
            ;;
        duckdb) duckdb -c 'SELECT 1;' || true ;;
        sqlite) sqlite3 :memory: 'SELECT 1;' || true ;;
        python) python3 -c 'print("hello world!")' || true ;;
        ruby) ruby -e 'puts "hello world!"' || true ;;
        nodejs) node -e 'console.log("hello world!")' || true ;;
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
        xpk) xpk --version || true ;;
        *)
          # Delegate to component core health checks first (e.g., systemd/openrc/sc checks)
          "${LIBSCRIPT_ROOT_DIR:-.}/libscript.sh" "$_pkg" "health" "$_pkg" "$_ver" || true
          if command -v "$_pkg" >/dev/null 2>&1; then
            "$_pkg" --version || true
          fi
          ;;
    esac
  }

  follow_logs=0
  skip_hooks=0
  new_args=""
  for arg in "$@"; do
    if [ "$arg" = "-f" ] || [ "$arg" = "--follow" ]; then
      follow_logs=1
    elif [ "$arg" = "--no-hooks" ]; then
      skip_hooks=1
    else
      new_args="$new_args \"$arg\""
    fi
  done
  eval "set -- $new_args"

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
    if [ "$skip_hooks" -eq 0 ]; then
      if [ "$action" = "start" ] || [ "$action" = "up" ]; then
        "${LIBSCRIPT_ROOT_DIR:-.}/_lib/orchestration/run_hooks.sh" "$json_file" "build"
        "${LIBSCRIPT_ROOT_DIR:-.}/_lib/orchestration/run_hooks.sh" "$json_file" "pre_start"
      fi
    fi

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
          else
            "${LIBSCRIPT_ROOT_DIR:-.}/libscript.sh" "$pkg" "$action" "$pkg" "$ver" &
          fi
        fi
      done < "$json_file.tmpdeps"
      rm -f "$json_file.tmpdeps"
    fi

    if [ "$action" = "start" ] || [ "$action" = "up" ]; then
      "${LIBSCRIPT_ROOT_DIR:-.}/_lib/init-systems/daemonize.sh" "$action" "$json_file"
    elif [ "$action" = "stop" ] || [ "$action" = "down" ]; then
      "${LIBSCRIPT_ROOT_DIR:-.}/_lib/init-systems/daemonize.sh" "$action" "$json_file"
    elif [ "$action" = "status" ]; then
      "${LIBSCRIPT_ROOT_DIR:-.}/_lib/init-systems/daemonize.sh" "$action" "$json_file"
    elif [ "$action" = "restart" ]; then
      "${LIBSCRIPT_ROOT_DIR:-.}/_lib/init-systems/daemonize.sh" "stop" "$json_file"
      "${LIBSCRIPT_ROOT_DIR:-.}/_lib/init-systems/daemonize.sh" "start" "$json_file"
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
