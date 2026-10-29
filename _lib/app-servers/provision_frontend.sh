#!/bin/sh
# ## Overview
# Declarative Frontend & Kotlin Multiplatform (KMP) Build Orchestrator with reuse-else-create caching.
# Resolves NPM/Gradle dependencies, builds Angular 17+, Vite/React/JS SPAs, MFEs, and KMP
# (jsBrowserDistribution, wasmJsBrowserDistribution, Compose Desktop, iOS) targets, and stages to webroots.
#
# ## Usage
#   ./provision_frontend.sh --app-dir <dir> --manifest <path> [--packaging <path>] [--force-rebuild] [--force-reinstall]

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
export DIR="${SCRIPT_DIR}"

app_dir=""
manifest_path=""
packaging_path=""

while [ $# -gt 0 ]; do
  case "$1" in
    --app-dir) app_dir="$2"; shift 2 ;;
    --manifest) manifest_path="$2"; shift 2 ;;
    --packaging) packaging_path="$2"; shift 2 ;;
    --force-rebuild) export FORCE_REBUILD=1; shift ;;
    --force-reinstall) export FORCE_REINSTALL=1; shift ;;
    *) shift ;;
  esac
done

if [ -z "$app_dir" ]; then
  printf '%s\n' 'Error: --app-dir is required.' >&2
  exit 1
fi

if [ -z "$packaging_path" ] && [ -n "$manifest_path" ]; then
  packaging_path="$manifest_path"
fi
if [ -z "$manifest_path" ] && [ -n "$packaging_path" ]; then
  manifest_path="$packaging_path"
fi
if [ -z "$packaging_path" ]; then
  printf '%s\n' 'Error: --manifest or --packaging is required.' >&2
  exit 1
fi

app_dir=$(cd -- "$app_dir" && pwd)
webroot_base="$app_dir/webroot"
mkdir -p "$webroot_base"

# ## compute_frontend_fingerprint
# Computes a deterministic checksum over package.json, lockfiles, and src/ for build cache validation.
compute_frontend_fingerprint() {
  _cff_dir="$1"
  (
    cd "$_cff_dir" 2>/dev/null || exit 0
    for _cff_f in package.json package-lock.json pnpm-lock.yaml yarn.lock angular.json vite.config.ts vite.config.js tsconfig.json; do
      if [ -f "$_cff_f" ]; then
        cksum "$_cff_f" 2>/dev/null || true
      fi
    done
    if [ -d "src" ]; then
      find src -type f -exec cksum {} + 2>/dev/null | sort || true
    fi
  ) | cksum | awk '{print $1"_"$2}'
}

# ## install_node_deps
# Installs npm/pnpm/yarn/bun dependencies in a target directory if package.json exists, reusing node_modules if lockfile hash matches.
install_node_deps() {
  _dir="$1"
  _custom_inst="${2:-}"
  if [ -f "$_dir/package.json" ]; then
    (
      cd "$_dir"
      if [ "${FORCE_REINSTALL:-0}" = "1" ]; then
        rm -rf "node_modules"
      fi
      _pkg_fp=$(cksum package.json package-lock.json pnpm-lock.yaml yarn.lock 2>/dev/null | cksum | awk '{print $1"_"$2}' || printf 'none')
      if [ "${FORCE_REINSTALL:-0}" != "1" ] && [ -d "node_modules" ] && [ -f "node_modules/.libscript_pkg_hash" ] && [ "$(cat node_modules/.libscript_pkg_hash 2>/dev/null || true)" = "$_pkg_fp" ]; then
        printf '[REUSE] Frontend dependencies in %s are up-to-date.\n' "$_dir"
        exit 0
      fi
      if [ -n "$_custom_inst" ] && [ "$_custom_inst" != "null" ]; then
        sh -c "$_custom_inst"
      elif [ -f "pnpm-lock.yaml" ] && command -v pnpm >/dev/null 2>&1; then
        pnpm install --frozen-lockfile || pnpm install
      elif [ -f "yarn.lock" ] && command -v yarn >/dev/null 2>&1; then
        yarn install --frozen-lockfile || yarn install
      elif [ -f "bun.lockb" ] && command -v bun >/dev/null 2>&1; then
        bun install
      elif [ -f "package-lock.json" ] || [ -f "npm-shrinkwrap.json" ]; then
        npm ci --prefer-offline --no-audit --no-fund || npm install --legacy-peer-deps --no-audit --no-fund
      else
        npm install --no-audit --no-fund
      fi
      if [ -d "node_modules" ]; then
        printf '%s\n' "$_pkg_fp" > "node_modules/.libscript_pkg_hash" 2>/dev/null || true
      fi
    )
  fi
}

# ## resolve_artifact_exists
# Checks whether the compiled frontend artifact or index.html exists on disk.
resolve_artifact_exists() {
  _rae_src="$1"
  _rae_app="$2"
  _rae_out="${3:-}"
  _rae_art="${4:-}"

  if [ -n "$_rae_art" ] && [ "$_rae_art" != "null" ]; then
    if [ -f "$_rae_src/$_rae_art" ] || [ -f "$_rae_app/$_rae_art" ] || [ -f "$_rae_art" ]; then
      return 0
    fi
    return 1
  fi

  if [ -n "$_rae_out" ] && [ "$_rae_out" != "null" ]; then
    if [ -f "$_rae_src/$_rae_out/index.html" ] || [ -f "$_rae_app/$_rae_out/index.html" ]; then
      return 0
    fi
  fi

  if [ -d "$_rae_src/dist" ]; then
    if [ -f "$_rae_src/dist/index.html" ]; then
      return 0
    fi
    for _ng_p in $(ls -1 "$_rae_src/dist" 2>/dev/null || true); do
      if [ -f "$_rae_src/dist/$_ng_p/browser/index.html" ] || [ -f "$_rae_src/dist/$_ng_p/index.html" ]; then
        return 0
      fi
    done
  fi
  return 1
}

# ## stage_compiled_assets
# Detects Angular 17+ browser/, KMP productionExecutable/, or standard dist/ and stages files to target_webroot.
stage_compiled_assets() {
  _src_dir="$1"
  _target_webroot="$2"
  _custom_out="${3:-}"
  mkdir -p "$_target_webroot"

  if [ -n "$_custom_out" ] && [ "$_custom_out" != "null" ]; then
    if [ -d "$_src_dir/$_custom_out" ]; then
      cp -R "$_src_dir/$_custom_out/." "$_target_webroot/" 2>/dev/null || true
      return 0
    elif [ -d "$app_dir/$_custom_out" ]; then
      cp -R "$app_dir/$_custom_out/." "$_target_webroot/" 2>/dev/null || true
      return 0
    fi
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
  _gradle_cmd='gradle'
  if [ -x "$_kmp_dir/gradlew" ]; then
    _gradle_cmd='./gradlew'
  elif [ -f "$_kmp_dir/gradlew" ]; then
    chmod +x "$_kmp_dir/gradlew"
    _gradle_cmd='./gradlew'
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
    printf '%s\n' "$FRONTEND_ENTRIES" | while IFS= read -r svc; do
      [ -n "$svc" ] || continue
      svc_id=$(printf '%s\n' "$svc" | jq -r '.id // .name // "default"')
      src_rel=$(printf '%s\n' "$svc" | jq -r '.source_dir // .working_dir // .cwd // "."')
      inst_cmd=$(printf '%s\n' "$svc" | jq -r '.install_command // empty')
      build_cmd=$(printf '%s\n' "$svc" | jq -r '.build_command // empty')
      out_dir=$(printf '%s\n' "$svc" | jq -r '.output_dir // .dist_dir // empty')
      art_chk=$(printf '%s\n' "$svc" | jq -r '.artifact_check // empty')
      stage_override=$(printf '%s\n' "$svc" | jq -r '.stage_dir // empty')
      framework=$(printf '%s\n' "$svc" | jq -r '(.framework // "") | ascii_downcase')
      kmp_target=$(printf '%s\n' "$svc" | jq -r '.target // empty')

      if [ -z "$src_rel" ] || [ "$src_rel" = "." ]; then
        src_dir="$app_dir"
      elif [ "${src_rel#/}" != "$src_rel" ]; then
        src_dir="$src_rel"
      else
        src_dir="$app_dir/$src_rel"
      fi

      if [ -n "$stage_override" ] && [ "$stage_override" != "null" ]; then
        if [ "${stage_override#/}" != "$stage_override" ]; then
          target_webroot="$stage_override"
        else
          target_webroot="$app_dir/$stage_override"
        fi
      else
        target_webroot="$webroot_base/$svc_id"
      fi
      mkdir -p "$target_webroot"

      if [ "${FORCE_REBUILD:-0}" = "1" ]; then
        rm -rf "$src_dir/dist" "$src_dir/build" "$src_dir/.angular" "$src_dir/.vite" "$src_dir/.libscript_build.sha256"
        _extra_cleans=$(printf '%s\n' "$svc" | jq -r '.clean_dirs[]? // empty' 2>/dev/null || true)
        if [ -n "$_extra_cleans" ]; then
          printf '%s\n' "$_extra_cleans" | while IFS= read -r _cd; do
            [ -n "$_cd" ] && rm -rf "${src_dir:?}/${_cd:?}"
          done
        fi
      fi

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
        if [ "$src_dir" != "$app_dir" ] || [ -n "$inst_cmd" ]; then
          install_node_deps "$src_dir" "$inst_cmd"
        fi
        _fe_fp=$(compute_frontend_fingerprint "$src_dir")
        if [ "${FORCE_REBUILD:-0}" != "1" ] && resolve_artifact_exists "$src_dir" "$app_dir" "$out_dir" "$art_chk" && { [ ! -f "${src_dir}/.libscript_build.sha256" ] || [ "$(cat "${src_dir}/.libscript_build.sha256" 2>/dev/null || true)" = "$_fe_fp" ]; }; then
          printf '[REUSE] Frontend build for '\''%s'\'' in '\''%s'\'' is up-to-date.\n' "$svc_id" "$src_dir"
          [ -f "${src_dir}/.libscript_build.sha256" ] || printf '%s\n' "$_fe_fp" > "${src_dir}/.libscript_build.sha256" 2>/dev/null || true
        else
          printf '[BUILD] Building frontend '\''%s'\'' (%s) in '\''%s'\''...\n' "$svc_id" "${framework:-spa}" "$src_dir"
          (
            cd "$src_dir"
            if [ -s "$_fe_env_file" ]; then
              # shellcheck disable=SC1090
              . "$_fe_env_file"
            fi
            if [ -n "$build_cmd" ]; then
              sh -c "$build_cmd"
            elif [ "$framework" = "angular" ] && [ -f "angular.json" ]; then
              npx ng build
            elif [ "$framework" = "vite" ]; then
              if grep -q '"build"' "package.json"; then
                npm run build
              else
                npx vite build
              fi
            elif grep -q '"build"' "package.json"; then
              npm run build
            fi
          )
          printf '%s\n' "$_fe_fp" > "${src_dir}/.libscript_build.sha256" 2>/dev/null || true
        fi
        stage_compiled_assets "$src_dir" "$target_webroot" "$out_dir"
      else
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
    cmd=$(printf '%s\n' "$hook" | jq -r '.command // empty')
    case "$cmd" in
      *collectstatic*|*paver*update_assets*)
        (cd "$app_dir" && sh -c "$cmd") || true
        ;;
    esac
  done
fi

exit 0
