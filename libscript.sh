#!/bin/sh
set -e

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)

show_help() {
  echo "LibScript Global CLI"
  echo "===================="
  echo ""
  echo "Usage: $0 [COMMAND] [ARGS...]"
  echo ""
  echo "Commands:"
  echo "  list                        List all available components"
  echo "  search <query>              Search available components by name or description"
  echo "  <component> [OPTIONS...]    Invoke the CLI for a specific component"
  echo ""
  echo "Options:"
  echo "  --help, -h, /?              Show this extensive help text"
  echo ""
  echo "Examples:"
  echo "  $0 list"
  echo "  $0 search ruby"
  echo "  $0 ruby --help"
  echo "  $0 postgres --help"
  echo ""
  echo "You can specify components by their short name (e.g., 'ruby' instead of '_lib/_toolchain/ruby')."
  echo "If there are multiple matches, it will ask you to be more specific."
  echo ""
}

find_components() {
  find "$SCRIPT_DIR" -name "cli.sh" | while read -r cli_script; do
    dir=$(dirname "$cli_script")
    if [ -f "$dir/vars.schema.json" ]; then
      rel_dir="${dir#$SCRIPT_DIR/}"
      if [ "$rel_dir" != "$dir" ]; then
        echo "$rel_dir"
      fi
    fi
  done
}

get_desc() {
  schema="$SCRIPT_DIR/$1/vars.schema.json"
  if command -v jq >/dev/null 2>&1; then
    jq -r '
      def aliases: [ .properties[]? | select(.versionAliases) | .versionAliases[] ] | unique | join(", ");
      if .description then
        if (aliases | length > 0) then .description + " [version aliases: " + aliases + "]" else .description end
      else "" end
    ' "$schema" 2>/dev/null || true
  fi
}

while [ $# -gt 0 ]; do
  case "$1" in
    --cache-dir=*)
      export LIBSCRIPT_CACHE_DIR="${1#*=}"
      shift
      ;;
    --prefix=*)
      export PREFIX="${1#*=}"
      shift
      ;;
    *)
      break
      ;;
  esac
done
cmd="$1"
if [ -z "$cmd" ] || [ "$cmd" = "--help" ] || [ "$cmd" = "-h" ] || [ "$cmd" = "/?" ]; then
  show_help
  exit 0
fi

shift || true

if [ "$cmd" = "list" ]; then
  echo "Available components:"
  find_components | sort | while read -r comp; do
    desc=$(get_desc "$comp")
    if [ -n "$desc" ]; then
      printf "  %-40s - %s\n" "$comp" "$desc"
    else
      printf "  %s\n" "$comp"
    fi
  done
  exit 0
fi

if [ "$cmd" = "search" ]; then
  query="$1"
  if [ -z "$query" ]; then
    echo "Error: please provide a search query."
    exit 1
  fi
  echo "Searching for '$query'..."
  find_components | sort | while read -r comp; do
    desc=$(get_desc "$comp")
    if echo "$comp $desc" | grep -i "$query" >/dev/null 2>&1; then
      if [ -n "$desc" ]; then
        printf "  %-40s - %s\n" "$comp" "$desc"
      else
        printf "  %s\n" "$comp"
      fi
    fi
  done
  exit 0
fi

target=""
if [ -f "$SCRIPT_DIR/$cmd/cli.sh" ]; then
  target="$SCRIPT_DIR/$cmd"
else
  matches=$(find_components | grep -i "$cmd" || true)
  count=$(echo "$matches" | grep -c . || true)
  if [ "$count" -eq 0 ]; then
    echo "Error: Unknown component '$cmd'."
    exit 1
  elif [ "$count" -eq 1 ]; then
    target="$SCRIPT_DIR/$matches"
  else
    exact_match=$(echo "$matches" | grep "/$cmd$" || true)
    exact_count=$(echo "$exact_match" | grep -c . || true)
    if [ "$exact_count" -eq 1 ]; then
      target="$SCRIPT_DIR/$exact_match"
    else
      echo "Error: Component '$cmd' is ambiguous. Matches:"
      echo "$matches" | sed 's/^/  /'
      exit 1
    fi
  fi
fi

if [ -x "$target/cli.sh" ]; then
  exec "$target/cli.sh" "$@"
elif [ -f "$target/cli.sh" ]; then
  exec sh "$target/cli.sh" "$@"
else
  echo "Error: Local CLI not found in $target"
  exit 1
fi
