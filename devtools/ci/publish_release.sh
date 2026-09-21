#!/bin/sh
# ## Overview
# Publishes built release packages, installer artifacts, and cryptographic
# checksums to GitHub Releases via the GitHub CLI in an idempotent manner.
#
# ## Usage
# ./devtools/ci/publish_release.sh --tag <tag> [--dist-dir <dir>] [--title <title>] [--draft] [--prerelease]

set -eu

if [ "${SCRIPT_NAME-}" ]; then
  THIS_FILE="${SCRIPT_NAME}"
elif [ "${BASH_SOURCE-}" ]; then
  THIS_FILE="${BASH_SOURCE}"
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

# ## show_help
# Displays usage instructions and supported CLI parameters.
show_help() {
  printf '%s
' "Usage: $(basename "$THIS_FILE") --tag <tag> [OPTIONS]"
  printf '%s
' "Publishes installer artifacts and checksums to GitHub Releases."
  printf '
'
  printf '%s
' "Options:"
  printf '%s
' "  --tag <tag>         Release tag name (required, e.g. v1.0.0)."
  printf '%s
' "  --dist-dir <dir>    Directory containing built release assets (default: dist)."
  printf '%s
' "  --title <title>     Release title (default: matches tag name)."
  printf '%s
' "  --draft             Publish release as a draft."
  printf '%s
' "  --prerelease        Publish release as a pre-release."
  printf '%s
' "  --help, -h, /?, -?  Show this help message."
}

TAG=""
DIST_DIR="dist"
TITLE=""
IS_DRAFT="false"
IS_PRERELEASE="false"

while [ $# -gt 0 ]; do
  case "$1" in
    --tag)
      TAG="${2:-}"
      shift 2 || true
      ;;
    --dist-dir)
      DIST_DIR="${2:-}"
      shift 2 || true
      ;;
    --title)
      TITLE="${2:-}"
      shift 2 || true
      ;;
    --draft)
      IS_DRAFT="true"
      shift
      ;;
    --prerelease)
      IS_PRERELEASE="true"
      shift
      ;;
    --help|-h|/\?|-\?)
      show_help
      exit 0
      ;;
    *)
      printf '[ERROR] Unknown argument: %s
' "$1" >&2
      show_help >&2
      exit 1
      ;;
  esac
done

if [ -z "$TAG" ]; then
  printf '[ERROR] Missing required parameter: --tag <tag>
' >&2
  show_help >&2
  exit 1
fi

if [ -z "$TITLE" ]; then
  TITLE="$TAG"
fi

if [ ! -d "$DIST_DIR" ]; then
  printf '[ERROR] Distribution directory not found: %s
' "$DIST_DIR" >&2
  exit 1
fi

# ## generate_sums
# Generates consolidated SHA256SUMS.txt inside the distribution directory if needed.
generate_sums() {
  _dir="$1"
  if [ -d "$_dir" ]; then
    _tmp_sums="${_dir}/.SHA256SUMS.tmp.$$"
    rm -f "$_tmp_sums"
    for _f in "$_dir"/*; do
      [ -f "$_f" ] || continue
      _fname="${_f##*/}"
      case "$_fname" in
        SHA256SUMS.txt|*.sha256|.*) continue ;;
      esac
      if command -v sha256sum >/dev/null 2>&1; then
        (cd "$_dir" && sha256sum "$_fname") >> "$_tmp_sums" 2>/dev/null || true
      elif command -v shasum >/dev/null 2>&1; then
        (cd "$_dir" && shasum -a 256 "$_fname") >> "$_tmp_sums" 2>/dev/null || true
      elif command -v openssl >/dev/null 2>&1; then
        _h=$(openssl dgst -sha256 "$_f" 2>/dev/null | awk '{print $NF}')
        if [ -n "$_h" ]; then
          printf '%s  %s
' "$_h" "$_fname" >> "$_tmp_sums"
        fi
      fi
    done
    if [ -s "$_tmp_sums" ]; then
      mv -f "$_tmp_sums" "$_dir/SHA256SUMS.txt"
    else
      rm -f "$_tmp_sums"
      if [ -f "$_dir/SHA256SUMS.txt" ] && [ ! -s "$_dir/SHA256SUMS.txt" ]; then
        rm -f "$_dir/SHA256SUMS.txt"
      fi
    fi
  fi
}

# ## upload_or_create_release
# Creates a new GitHub Release or attaches assets to an existing release idempotently.
upload_or_create_release() {
  _tag="$1"
  _title="$2"
  _dir="$3"
  _draft="$4"
  _pre="$5"

  printf '[INFO] Publishing release assets for tag "%s" from "%s"...
' "$_tag" "$_dir"

  # Collect all non-empty files from $_dir into positional parameters
  set --
  for _f in "$_dir"/*; do
    if [ -f "$_f" ] && [ -s "$_f" ]; then
      set -- "$@" "$_f"
    elif [ -f "$_f" ] && [ ! -s "$_f" ]; then
      printf '[WARN] Skipping empty asset file (0 bytes): %s
' "$_f" >&2
    fi
  done

  if [ $# -eq 0 ]; then
    printf '[ERROR] No valid non-empty assets found in "%s" to publish.
' "$_dir" >&2
    return 1
  fi

  if gh release view "$_tag" >/dev/null 2>&1; then
    printf '[INFO] Release "%s" already exists. Uploading assets with clobber...
' "$_tag"
    gh release upload "$_tag" "$@" --clobber
  else
    printf '[INFO] Creating new release "%s"...
' "$_tag"
    if [ "$_draft" = "true" ] && [ "$_pre" = "true" ]; then
      gh release create "$_tag" --title "$_title" --generate-notes --draft --prerelease "$@"
    elif [ "$_draft" = "true" ]; then
      gh release create "$_tag" --title "$_title" --generate-notes --draft "$@"
    elif [ "$_pre" = "true" ]; then
      gh release create "$_tag" --title "$_title" --generate-notes --prerelease "$@"
    else
      gh release create "$_tag" --title "$_title" --generate-notes "$@"
    fi
  fi

  printf '[SUCCESS] Release assets successfully published for %s
' "$_tag"
}

generate_sums "$DIST_DIR"
upload_or_create_release "$TAG" "$TITLE" "$DIST_DIR" "$IS_DRAFT" "$IS_PRERELEASE"

exit 0
