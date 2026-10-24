#!/bin/sh
# ## Overview
# Declarative Frontend & Kotlin Multiplatform (KMP) Build Orchestrator.
# Resolves NPM/Gradle dependencies, builds Angular 17+, Vite/React/JS SPAs, MFEs, and KMP
# (jsBrowserDistribution, wasmJsBrowserDistribution, Compose Desktop, iOS) targets, and stages to webroots.
#
# ## Usage
#   ./provision_frontend.sh --app-dir <dir> --manifest <path> --packaging <path>

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
    printf '[STOP]     processing "%s"
' "${THIS_FILE}" >&2
    if (return 0 2>/dev/null); then return; else exit 0; fi ;;
  *) printf '[CONTINUE] processing "%s"
' "${THIS_FILE}" >&2 ;;
esac
export STACK="${STACK:-}${THIS_FILE}"':'
SCRIPT_DIR=$(cd -- "$(dirname -- "${THIS_FILE}")" && pwd)
: "${LIBSCRIPT_ROOT_DIR:=$(d="$SCRIPT_DIR"; while [ ! -f "$d/libscript.sh" ]; do n="${d%/*}"; [ -z "$n" ] && n="/"; [ "$d" = "$n" ] && break; d="$n"; done; printf '%s
' "$d")}"
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

if [ -z "$app_dir" ]; then
  printf 'Error: --app-dir is required.
' >&2
  exit 1
fi

if [ -z "$packaging_path" ] && [ -n "$manifest_path" ]; then
  packaging_path="$manifest_path"
fi
if [ -z "$manifest_path" ] && [ -n "$packaging_path" ]; then
  manifest_path="$packaging_path"
fi
if [ -z "$packaging_path" ]; then
  printf 'Error: --manifest or --packaging is required.
' >&2
  exit 1
fi

app_dir=$(cd -- "$app_dir" && pwd)
webroot_base="$app_dir/webroot"
mkdir -p "$webroot_base"

# ## install_node_deps
# Installs npm/pnpm/yarn/bun dependencies in a target directory if package.json exists.
install_node_deps() {
  _dir="$1"
  if [ -f "$_dir/package.json" ]; then
    (
      cd "$_dir"
      if [ -f "pnpm-lock.yaml" ] && command -v pnpm >/dev/null 2>&1; then
        pnpm install --frozen-lockfile || pnpm install
      elif [ -f "yarn.lock" ] && command -v yarn >/dev/null 2>&1; then
        yarn install --frozen-lockfile || yarn install
      elif [ -f "bun.lockb" ] && command -v bun >/dev/null 2>&1; then
        bun install
      elif [ -f "package-lock.json" ] || [ -f "npm-shrinkwrap.json" ]; then
        npm ci --prefer-offline --no-audit
      else
        npm install --no-audit
      fi
    )
  fi
}

# ## stage_compiled_assets
# Detects Angular 17+ browser/, KMP productionExecutable/, or standard dist/ and stages files to target_webroot.
stage_compiled_assets() {
  _src_dir="$1"
  _target_webroot="$2"
  _custom_out="${3:-}"
  mkdir -p "$_target_webroot"

  if [ -n "$_custom_out" ] && [ "$_custom_out" != "null" ] && [ -d "$_src_dir/$_custom_out" ]; then
    cp -R "$_src_dir/$_custom_out/." "$_target_webroot/" 2>/dev/null || true
    return 0
  fi

  # Check Angular 17+ dist/<project>/browser/index.html layout and classic dist/<project>/index.html
  if [ -d "$_src_dir/dist" ]; then
    for _ng_proj in $(ls -1 "$_src_dir/dist" 2>/dev/null || true); do
      if [ -f "$_src_dir/dist/$_ng_proj/browser/index.html" ]; then
        cp -R "$_src_dir/dist/$_ng_proj/browser/." "$_target_webroot/"
        return 0
      elif [ -f "$_src_dir/dist/$_ng_proj/index.html" ]; then
        cp -R "$_src_dir/dist/$_ng_proj/." "$_target_webroot/"
        return 0
      fi
    done
  fi

  # Check Kotlin Multiplatform (KMP) WasmJS or JS productionExecutable output
  if [ -d "$_src_dir/composeApp/build/dist/wasmJs/productionExecutable" ]; then
    cp -R "$_src_dir/composeApp/build/dist/wasmJs/productionExecutable/." "$_target_webroot/"
    return 0
  fi
  if [ -d "$_src_dir/composeApp/build/dist/js/productionExecutable" ]; then
    cp -R "$_src_dir/composeApp/build/dist/js/productionExecutable/." "$_target_webroot/"
    return 0
  fi
  if [ -d "$_src_dir/build/dist/wasmJs/productionExecutable" ]; then
    cp -R "$_src_dir/build/dist/wasmJs/productionExecutable/." "$_target_webroot/"
    return 0
  fi
  if [ -d "$_src_dir/build/dist/js/productionExecutable" ]; then
    cp -R "$_src_dir/build/dist/js/productionExecutable/." "$_target_webroot/"
    return 0
  fi

  # Standard Vite / React / Vue / Webpack dist/ or build/
  if [ -d "$_src_dir/dist" ]; then
    cp -R "$_src_dir/dist/." "$_target_webroot/" 2>/dev/null || true
  elif [ -d "$_src_dir/build" ] && [ -f "$_src_dir/build/index.html" ]; then
    cp -R "$_src_dir/build/." "$_target_webroot/" 2>/dev/null || true
  fi
}

# ## run_kmp_gradle_build
# Executes Kotlin Multiplatform (KMP) Gradle tasks for Web (JS/WasmJS), Desktop JVM, or iOS.
run_kmp_gradle_build() {
  _kmp_dir="$1"
  _kmp_target="${2:-kmp-js}"
  _gradle_cmd="gradle"
  if [ -x "$_kmp_dir/gradlew" ]; then
    _gradle_cmd="./gradlew"
  elif [ -f "$_kmp_dir/gradlew" ]; then
    chmod +x "$_kmp_dir/gradlew"
    _gradle_cmd="./gradlew"
  fi

  (
    cd "$_kmp_dir"
    case "$_kmp_target" in
      kmp-wasm|wasm|wasmjs|wasmJs)
        "$_gradle_cmd" :composeApp:wasmJsBrowserDistribution
        ;;
      kmp-js|js)
        "$_gradle_cmd" :composeApp:jsBrowserDistribution
        ;;
      kmp-desktop|desktop|jvm)
        "$_gradle_cmd" :composeApp:packageDistributionForCurrentOS
        ;;
      kmp-ios|ios)
        if [ "$(uname -s | tr '[:upper:]' '[:lower:]')" = "darwin" ]; then
          "$_gradle_cmd" :composeApp:linkReleaseFrameworkIosArm64
        fi
        ;;
      *)
        "$_gradle_cmd" :composeApp:jsBrowserDistribution
        ;;
    esac
  )
}

# 1. Root-level dependency resolution if package.json is in app_dir
install_node_deps "$app_dir"

# 2. Frontend / MFE / KMP Compilation
if command -v jq >/dev/null 2>&1 && [ -f "$packaging_path" ]; then
  FRONTEND_ENTRIES=$(jq -c '
    (
      [ (.services | if type == "array" then .[] elif type == "object" then to_entries[] | (.value + {id: (.value.id // .key)}) else empty end) | select(.type == "static" or .type == "spa" or .type == "frontend" or .type == "kmp" or .framework != null or .target != null) ] +
      [ (.frontends | if type == "array" then .[] elif type == "object" then to_entries[] | (.value + {id: (.value.id // .key)}) else empty end) ]
    )[]?
  ' "$packaging_path" 2>/dev/null || true)

  if [ -n "$FRONTEND_ENTRIES" ]; then
    printf '%s
' "$FRONTEND_ENTRIES" | while IFS= read -r svc; do
      [ -n "$svc" ] || continue
      svc_id=$(printf '%s
' "$svc" | jq -r '.id // .name // "default"')
      src_rel=$(printf '%s
' "$svc" | jq -r '.source_dir // .working_dir // .cwd // "."')
      build_cmd=$(printf '%s
' "$svc" | jq -r '.build_command // empty')
      out_dir=$(printf '%s
' "$svc" | jq -r '.output_dir // .dist_dir // empty')
      kmp_target=$(printf '%s
' "$svc" | jq -r '.target // empty')

      if [ -z "$src_rel" ] || [ "$src_rel" = "." ]; then
        src_dir="$app_dir"
      elif [ "${src_rel#/}" != "$src_rel" ]; then
        src_dir="$src_rel"
      else
        src_dir="$app_dir/$src_rel"
      fi

      target_webroot="$webroot_base/$svc_id"
      mkdir -p "$target_webroot"

      # Export per-frontend build environment variables in subshell via temporary file
      _fe_env_file=$(mktemp "${TMPDIR:-/tmp}/libscript_fe_env.XXXXXX")
      printf '%s\n' "$svc" | jq -r '.env // {} | to_entries[]? | "export \(.key)=\(.value | @sh)"' > "$_fe_env_file" 2>/dev/null || true

      if [ -f "$src_dir/build.gradle.kts" ] || [ -f "$src_dir/build.gradle" ] || [ -n "$kmp_target" ]; then
        if [ -n "$build_cmd" ]; then
          (
            cd "$src_dir"
            if [ -s "$_fe_env_file" ]; then
              # shellcheck disable=SC1090
              . "$_fe_env_file"
            fi
            sh -c "$build_cmd"
          )
        else
          run_kmp_gradle_build "$src_dir" "${kmp_target:-kmp-js}"
        fi
        stage_compiled_assets "$src_dir" "$target_webroot" "$out_dir"
      elif [ -f "$src_dir/package.json" ]; then
        if [ "$src_dir" != "$app_dir" ]; then
          install_node_deps "$src_dir"
        fi
        (
          cd "$src_dir"
          if [ -s "$_fe_env_file" ]; then
            # shellcheck disable=SC1090
            . "$_fe_env_file"
          fi
          if [ -n "$build_cmd" ]; then
            sh -c "$build_cmd"
          elif grep -q '"build"' "package.json"; then
            npm run build
          fi
        )
        stage_compiled_assets "$src_dir" "$target_webroot" "$out_dir"
      fi
      rm -f "$_fe_env_file"
    done
  fi
fi

# 3. Monolithic Static Asset Pipelines (e.g. Django collectstatic, paver)
if command -v jq >/dev/null 2>&1 && [ -f "$packaging_path" ]; then
  jq -c '((.lifecycle_hooks.pre_install // []) + (.hooks.pre_install // []))[]?' "$packaging_path" 2>/dev/null | while IFS= read -r hook; do
    [ -n "$hook" ] || continue
    cmd=$(printf '%s
' "$hook" | jq -r '.command // empty')
    case "$cmd" in
      *collectstatic*|*paver*update_assets*)
        (cd "$app_dir" && sh -c "$cmd") || true
        ;;
    esac
  done
fi

exit 0
