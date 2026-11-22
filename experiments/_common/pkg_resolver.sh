#!/bin/sh
# ## Overview
# Cross-OS package artifact resolver (`Step 1`) fetching from GitHub Releases or building anew via LibScript packagers.
# ## Usage
# ./experiments/_common/pkg_resolver.sh <infer-format|sha256|resolve> [args...]
set -feu
_pr_caller_this="${THIS_FILE:-}"; _pr_caller_dir="${SCRIPT_DIR:-}"
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
    if [ -n "$_pr_caller_this" ]; then THIS_FILE="$_pr_caller_this"; fi; if [ -n "$_pr_caller_dir" ]; then SCRIPT_DIR="$_pr_caller_dir"; fi
    unset SCRIPT_NAME || true; if (return 0 2>/dev/null); then return; else exit 0; fi ;;
  *) printf '[CONTINUE] processing "%s"\n' "${THIS_FILE}" >&2 ;;
esac
export STACK="${STACK:-}${THIS_FILE}"':'
SCRIPT_DIR=$(cd -- "$(dirname -- "${THIS_FILE}")" && pwd)
: "${LIBSCRIPT_ROOT_DIR:=$(d="$SCRIPT_DIR"; while [ ! -f "$d/libscript.sh" ]; do n="${d%/*}"; [ -z "$n" ] && n="/"; [ "$d" = "$n" ] && break; d="$n"; done; printf '%s\n' "$d")}"

for _pr_lib in 'engine/common/os_info.sh' 'engine/common/pkg_mgr.sh'; do
  SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/${_pr_lib}"
  export SCRIPT_NAME
  # shellcheck disable=SC1090,SC1091
  . "$SCRIPT_NAME"
done
unset SCRIPT_NAME || true

# ## pr_compute_sha256
# Computes the SHA-256 hex digest of a file using portable POSIX utilities.
pr_compute_sha256() {
  _pr_file="${1:?file required}"
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$_pr_file" | awk '{print $1}'
  elif command -v shasum >/dev/null 2>&1; then
    shasum -a 256 "$_pr_file" | awk '{print $1}'
  elif command -v openssl >/dev/null 2>&1; then
    openssl dgst -sha256 "$_pr_file" | awk '{print $NF}'
  else
    wc -c < "$_pr_file" | tr -d ' '
  fi
}

# ## pr_infer_format_for_os
# Maps a target guest OS slug to its native default installer format or validates an explicit format.
pr_infer_format_for_os() {
  _pr_os="${1:-windows-11}"
  _pr_fmt="${2:-auto}"
  case "$_pr_fmt" in
    msi|exe|deb|rpm|pkg|dmg)
      printf '%s\n' "$_pr_fmt"
      return 0
      ;;
    auto|'')
      case "$_pr_os" in
        windows*|win*) printf '%s\n' 'msi' ;;
        debian*|ubuntu*) printf '%s\n' 'deb' ;;
        rocky*|alma*|rhel*|fedora*|centos*) printf '%s\n' 'rpm' ;;
        macos*|darwin*) printf '%s\n' 'pkg' ;;
        *) printf '%s\n' 'deb' ;;
      esac
      return 0
      ;;
    *)
      printf '[ERROR] Unsupported package format: %s\n' "$_pr_fmt" >&2
      return 1
      ;;
  esac
}

# ## pr_resolve_from_github_release
# Fetches a release asset matching the stack and package format from GitHub Releases into cache idempotently.
pr_resolve_from_github_release() {
  _pr_suite="${1:?suite-id required}"
  _pr_manifest="${2:?packaging.json required}"
  _pr_fmt="${3:?format required}"
  _pr_repo="${4:-SamuelMarks/libscript}"
  _pr_tag="${5:-latest}"
  _pr_pattern="${6:-}"
  _pr_force="${7:-0}"

  _pr_app=$(jq -r '.name // "app"' "$_pr_manifest")
  if [ -z "$_pr_pattern" ]; then
    _pr_pattern="(?i)${_pr_app}.*\\.${_pr_fmt}$"
  fi

  _pr_cache_dir="${LIBSCRIPT_CACHE_DIR:-${LIBSCRIPT_ROOT_DIR}/cache}/experiments/${_pr_suite}/${_pr_tag}/${_pr_fmt}"
  mkdir -p "$_pr_cache_dir"

  if [ "$_pr_force" != '1' ]; then
    set +f
    for _pr_existing in "${_pr_cache_dir}"/*."${_pr_fmt}"; do
      if [ -f "$_pr_existing" ] && [ -s "$_pr_existing" ]; then
        printf '[SKIP] Reusing cached GitHub Release artifact: %s\n' "$_pr_existing" >&2
        set -f
        printf '%s\n' "$_pr_existing"
        return 0
      fi
    done
    set -f
  fi

  if [ "${LIBSCRIPT_MOCK_GITHUB_RELEASE_FILE:-}" != '' ] && [ -f "${LIBSCRIPT_MOCK_GITHUB_RELEASE_FILE}" ]; then
    _pr_dest="${_pr_cache_dir}/${_pr_app}-mock.${_pr_fmt}"
    cp "${LIBSCRIPT_MOCK_GITHUB_RELEASE_FILE}" "$_pr_dest"
    pr_compute_sha256 "$_pr_dest" > "${_pr_dest}.sha256"
    printf '%s\n' "$_pr_dest"
    return 0
  fi

  if [ "$_pr_tag" = 'latest' ]; then
    _pr_api="https://api.github.com/repos/${_pr_repo}/releases/latest"
  else
    _pr_api="https://api.github.com/repos/${_pr_repo}/releases/tags/${_pr_tag}"
  fi

  if [ -n "${GITHUB_TOKEN:-}" ] && [ -z "${LIBSCRIPT_DOWNLOAD_AUTH_HEADER:-}" ]; then
    LIBSCRIPT_DOWNLOAD_AUTH_HEADER="Authorization: Bearer ${GITHUB_TOKEN}"
    export LIBSCRIPT_DOWNLOAD_AUTH_HEADER
  fi

  _pr_rel_json=$(libscript_fetch_stdout "$_pr_api")
  _pr_asset_url=$(printf '%s' "$_pr_rel_json" | jq -r --arg pat "$_pr_pattern" --arg ext ".${_pr_fmt}" '
    ([.assets[]? | select(.name | test($pat))] + [.assets[]? | select(.name | endswith($ext))])
    | .[0].browser_download_url // empty
  ')
  _pr_asset_name=$(printf '%s' "$_pr_rel_json" | jq -r --arg pat "$_pr_pattern" --arg ext ".${_pr_fmt}" '
    ([.assets[]? | select(.name | test($pat))] + [.assets[]? | select(.name | endswith($ext))])
    | .[0].name // empty
  ')

  if [ -z "$_pr_asset_url" ] || [ -z "$_pr_asset_name" ]; then
    printf '[ERROR] No .%s release asset matching "%s" found in %s (%s)\n' "$_pr_fmt" "$_pr_pattern" "$_pr_repo" "$_pr_tag" >&2
    return 1
  fi

  _pr_dest="${_pr_cache_dir}/${_pr_asset_name}"
  libscript_download "$_pr_asset_url" "$_pr_dest" >&2
  if [ ! -s "$_pr_dest" ]; then
    printf '[ERROR] Downloaded artifact is empty: %s\n' "$_pr_dest" >&2
    return 1
  fi
  pr_compute_sha256 "$_pr_dest" > "${_pr_dest}.sha256"
  printf '%s\n' "$_pr_dest"
}

# ## pr_build_anew_on_host
# Builds the target package format anew on the host using LibScript's packaging entrypoints with idempotent stamp checks.
pr_build_anew_on_host() {
  _pr_suite="${1:?suite-id required}"
  _pr_manifest="${2:?packaging.json required}"
  _pr_os="${3:?target-os required}"
  _pr_fmt="${4:?format required}"
  _pr_variant="${5:-offline}"
  _pr_force="${6:-0}"

  _pr_app=$(jq -r '.name // "app"' "$_pr_manifest")
  _pr_title=$(jq -r '.title // .name // "LibScript App"' "$_pr_manifest")
  _pr_ver=$(jq -r '.version // "1.0.0.0"' "$_pr_manifest")
  _pr_pub=$(jq -r '.publisher // "LibScript"' "$_pr_manifest")
  _pr_upg=$(jq -r '.upgrade_code // "00000000-0000-0000-0000-000000000000"' "$_pr_manifest")

  _pr_out_dir="${LIBSCRIPT_ROOT_DIR}/build/experiments/${_pr_suite}/packages/${_pr_os}/${_pr_fmt}"
  mkdir -p "$_pr_out_dir"
  _pr_out_stem="${_pr_out_dir}/${_pr_app}-${_pr_ver}-${_pr_variant}"
  _pr_out_pkg="${_pr_out_stem}.${_pr_fmt}"
  _pr_stamp="${_pr_out_pkg}.stamp"
  _pr_git_sha=$(git -C "$LIBSCRIPT_ROOT_DIR" rev-parse HEAD 2>/dev/null || printf 'local')
  _pr_man_sha=$(pr_compute_sha256 "$_pr_manifest")
  _pr_key="${_pr_git_sha}:${_pr_man_sha}:${_pr_variant}"

  if [ "$_pr_force" != '1' ] && [ -s "$_pr_out_pkg" ] && [ -f "$_pr_stamp" ] && [ "$(cat "$_pr_stamp")" = "$_pr_key" ]; then
    printf '[SKIP] Reusing up-to-date host-built %s package: %s\n' "$_pr_fmt" "$_pr_out_pkg" >&2
    printf '%s\n' "$_pr_out_pkg"
    return 0
  fi

  if [ "${LIBSCRIPT_MOCK_ARTIFACT_BUILD:-0}" = '1' ]; then
    printf 'MOCK_PACKAGE:%s:%s:%s\n' "$_pr_app" "$_pr_fmt" "$_pr_ver" > "$_pr_out_pkg"
    printf '%s\n' "$_pr_key" > "$_pr_stamp"
    pr_compute_sha256 "$_pr_out_pkg" > "${_pr_out_pkg}.sha256"
    printf '%s\n' "$_pr_out_pkg"
    return 0
  fi

  case "$_pr_fmt" in
    msi)
      if [ "$_pr_app" = 'openedx' ] && [ -f "${LIBSCRIPT_ROOT_DIR}/synthesis/msi/build.sh" ]; then
        STACK='' sh "${LIBSCRIPT_ROOT_DIR}/synthesis/msi/build.sh" "--${_pr_variant}" --out-dir "$_pr_out_dir" >&2
        set +f
        for _pr_built in "${_pr_out_dir}"/*.msi; do
          if [ -f "$_pr_built" ] && [ "$_pr_built" != "$_pr_out_pkg" ]; then
            cp "$_pr_built" "$_pr_out_pkg"
            break
          fi
        done
        set -f
      else
        STACK='' "${LIBSCRIPT_ROOT_DIR}/libscript.sh" package_as msi \
          --app-name "$_pr_title" \
          --app-version "$_pr_ver" \
          --app-publisher "$_pr_pub" \
          --upgrade-code "$_pr_upg" \
          --out-file "$_pr_out_stem" \
          "$_pr_app" latest >&2
        if [ -f "${_pr_out_stem}.wxs" ] && [ ! -f "$_pr_out_pkg" ] && command -v wixl >/dev/null 2>&1; then
          wixl -o "$_pr_out_pkg" "${_pr_out_stem}.wxs" >&2
        fi
      fi
      ;;
    exe)
      STACK='' "${LIBSCRIPT_ROOT_DIR}/libscript.sh" package_as nsis \
        --app-name "$_pr_title" \
        --app-version "$_pr_ver" \
        --app-publisher "$_pr_pub" \
        --out-file "$_pr_out_stem" \
        "$_pr_app" latest >&2
      if [ -f "${_pr_out_stem}.nsi" ] && [ ! -f "$_pr_out_pkg" ] && command -v makensis >/dev/null 2>&1; then
        makensis -D OUT_FILE="$_pr_out_pkg" "${_pr_out_stem}.nsi" >&2
      fi
      ;;
    deb|rpm)
      _pr_gen="${_pr_out_dir}/build_${_pr_fmt}.gen.sh"
      STACK='' "${LIBSCRIPT_ROOT_DIR}/libscript.sh" package_as "$_pr_fmt" \
        --app-name "$_pr_title" \
        --app-version "$_pr_ver" \
        --app-publisher "$_pr_pub" \
        "$_pr_app" latest > "$_pr_gen"
      OUT_DIR="$_pr_out_dir" sh "$_pr_gen" >&2
      set +f
      for _pr_built in "${_pr_out_dir}"/*."${_pr_fmt}"; do
        if [ -f "$_pr_built" ] && [ "$_pr_built" != "$_pr_out_pkg" ]; then
          cp "$_pr_built" "$_pr_out_pkg"
          break
        fi
      done
      set -f
      ;;
    pkg|dmg)
      STACK='' "${LIBSCRIPT_ROOT_DIR}/libscript.sh" package_as "$_pr_fmt" \
        --app-name "$_pr_title" \
        --app-version "$_pr_ver" \
        --app-publisher "$_pr_pub" \
        --out-file "$_pr_out_stem" \
        "$_pr_app" latest >&2
      ;;
    *)
      printf '[ERROR] Unsupported host build format: %s\n' "$_pr_fmt" >&2
      return 1
      ;;
  esac

  if [ ! -s "$_pr_out_pkg" ]; then
    printf '[ERROR] Host package build did not produce expected non-empty artifact: %s\n' "$_pr_out_pkg" >&2
    return 1
  fi
  printf '%s\n' "$_pr_key" > "$_pr_stamp"
  pr_compute_sha256 "$_pr_out_pkg" > "${_pr_out_pkg}.sha256"
  printf '%s\n' "$_pr_out_pkg"
}

# ## pr_resolve_artifact
# Main Step 1 router resolving the requested package format via `github-release` or `build`.
pr_resolve_artifact() {
  _pr_suite="${1:?suite-id required}"
  _pr_manifest="${2:?packaging.json required}"
  _pr_os="${3:-windows-11}"
  _pr_fmt_in="${4:-auto}"
  _pr_source="${5:-github-release}"
  _pr_repo="${6:-SamuelMarks/libscript}"
  _pr_tag="${7:-latest}"
  _pr_pattern="${8:-}"
  _pr_variant="${9:-offline}"
  _pr_force="${10:-0}"

  _pr_fmt=$(pr_infer_format_for_os "$_pr_os" "$_pr_fmt_in")
  case "$_pr_source" in
    github-release)
      pr_resolve_from_github_release "$_pr_suite" "$_pr_manifest" "$_pr_fmt" "$_pr_repo" "$_pr_tag" "$_pr_pattern" "$_pr_force"
      ;;
    build)
      pr_build_anew_on_host "$_pr_suite" "$_pr_manifest" "$_pr_os" "$_pr_fmt" "$_pr_variant" "$_pr_force"
      ;;
    *)
      printf '[ERROR] Unsupported package source "%s" (expected github-release or build)\n' "$_pr_source" >&2
      return 1
      ;;
  esac
}

# ## pr_cli_main
# CLI router when `pkg_resolver.sh` is executed directly rather than sourced.
pr_cli_main() {
  _pr_act="${1:-}"
  shift 2>/dev/null || true
  case "$_pr_act" in
    infer-format) pr_infer_format_for_os "$@" ;;
    sha256) pr_compute_sha256 "$@" ;;
    resolve) pr_resolve_artifact "$@" ;;
    --help|-h|'')
      printf '%s\n' 'Usage: pkg_resolver.sh <infer-format|sha256|resolve> [args...]'
      ;;
    *)
      printf '[ERROR] Unknown pkg_resolver action: %s\n' "$_pr_act" >&2
      return 1
      ;;
  esac
}

if (return 0 2>/dev/null); then
  STACK="${STACK%"${THIS_FILE}":}"
  export STACK
  if [ -n "$_pr_caller_this" ]; then THIS_FILE="$_pr_caller_this"; fi
  if [ -n "$_pr_caller_dir" ]; then SCRIPT_DIR="$_pr_caller_dir"; fi
  unset _pr_caller_this _pr_caller_dir || true
else
  pr_cli_main "$@"
fi
