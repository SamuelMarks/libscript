#!/bin/sh
# ## Overview
# Declarative Frontend Orchestrator. Resolves NPM dependencies, compiles modern MFEs
# via Webpack/Vite, executes monolithic static asset pipelines, and stages to webroots.
#
# ## Usage
#   ./provision_frontend.sh --app-dir <dir> --manifest <path> --packaging <path>

set -feu

if [ "${SCRIPT_NAME-}" ]; then
  THIS_FILE="${SCRIPT_NAME}"
elif [ "${BASH_SOURCE-}" ]; then
  THIS_FILE="${BASH_SOURCE}"
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
export DIR="${SCRIPT_DIR}"

app_dir=""
manifest_path=""
packaging_path=""

while [ $# -gt 0 ]; do
  case "$1" in
    --app-dir) app_dir="$2"; shift 2 ;;
    --manifest) manifest_path="$2"; shift 2 ;;
    --packaging) packaging_path="$2"; shift 2 ;;
    *) shift ;;
  esac
done

if [ -z "$app_dir" ] || [ -z "$manifest_path" ] || [ -z "$packaging_path" ]; then
  printf 'Error: --app-dir, --manifest, and --packaging are required.\n' >&2
  exit 1
fi

webroot_base="$app_dir/webroot"
mkdir -p "$webroot_base"

# 1. Dependency Resolution (MFE/Node pipelines)
if [ -f "$app_dir/package.json" ]; then
  cd "$app_dir"
  if [ -f "package-lock.json" ] || [ -f "npm-shrinkwrap.json" ]; then
    npm ci --prefer-offline --no-audit
  else
    npm install --no-audit
  fi
fi

# 2. MFE (Micro-Frontend) Compilation
# Parses services of type 'static' and builds them via npm scripts
if command -v jq >/dev/null 2>&1; then
  jq -c '.services[]? | select(.type == "static")' "$packaging_path" | while read -r svc; do
    svc_id=$(printf '%s' "$svc" | jq -r '.id')
    # Use id as the webroot subdirectory
    target_webroot="$webroot_base/$svc_id"
    mkdir -p "$target_webroot"
    
    cd "$app_dir"
    # Execute the build command (typically npm run build)
    # This is a simplification; in a real engine, the build command or target
    # folder is passed via the service schema.
    if [ -f "package.json" ]; then
        if grep -q '"build"' "package.json"; then
           npm run build
           # Stage compiled assets (assuming dist/ or build/ output)
           if [ -d "dist" ]; then
               cp -R dist/* "$target_webroot/"
           elif [ -d "build" ]; then
               cp -R build/* "$target_webroot/"
           fi
        fi
    fi
  done
fi

# 3. Monolithic Static Asset Pipelines (e.g. Django collectstatic, paver)
if command -v jq >/dev/null 2>&1; then
  jq -c '.lifecycle_hooks.pre_install[]?' "$packaging_path" | while read -r hook; do
    cmd=$(printf '%s' "$hook" | jq -r '.command')
    # Check if this hook looks like an asset compilation hook
    case "$cmd" in
        *collectstatic*|*paver*update_assets*)
            (cd "$app_dir" && eval "$cmd") || true
            ;;
    esac
  done
fi

exit 0