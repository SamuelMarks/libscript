#!/bin/sh
# ## Overview
# Implements packaging logic for the 'docker' format.
# Generates Dockerfile with ADD layer caching in online mode or air-gapped COPY cache/ mode.
#
# ## Usage
# This script is called by the packaging system and should not be executed manually.
#   ./libscript.sh package-as docker [OPTIONS] [PKG] [VERSION] [URL]
#
# ## Parameters
# - `--offline`, `-o`: Generate completely air-gapped Dockerfile using pre-populated cache/
# - `--online`: Generate Dockerfile using ADD layer caching for remote dependencies
# - `--base`, `--base-image <image>`: Override base container image (default: debian:bookworm-slim)
# - `--layer`, `-l <layer>`: Filter components by architectural layer
# - `--artifact`, `-a <type>`: Target specific OS packaging artifact (deb, rpm, apk, txz, msi, exe)
# - `--cache-dir <dir>`: Override default LibScript cache directory

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

base_image="debian:bookworm-slim"
layer_filter=""
artifact_type=""
is_offline=0
if [ "${LIBSCRIPT_OFFLINE:-0}" = "1" ]; then
  is_offline=1
fi

tmp_args=$(mktemp)
tmp_env_add=$(mktemp)
tmp_add=$(mktemp)
tmp_run=$(mktemp)
trap 'rm -f "$tmp_args" "$tmp_env_add" "$tmp_add" "$tmp_run"' EXIT INT TERM

# ## parse_cli_args
# Separates flag options from positional arguments without using eval.
while [ $# -gt 0 ]; do
  case "$1" in
    --offline|-o)
      is_offline=1
      shift
      ;;
    --online)
      is_offline=0
      shift
      ;;
    --layer|-l)
      layer_filter="${2:-}"
      shift 2
      ;;
    --artifact|-a)
      artifact_type="${2:-}"
      if [ "$artifact_type" = "deb" ]; then
        base_image="debian:bookworm-slim"
      elif [ "$artifact_type" = "rpm" ]; then
        base_image="almalinux:9"
      elif [ "$artifact_type" = "apk" ]; then
        base_image="alpine:latest"
      elif [ "$artifact_type" = "txz" ]; then
        base_image="freebsd"
      elif [ "$artifact_type" = "msi" ] || [ "$artifact_type" = "exe" ]; then
        base_image="mcr.microsoft.com/windows/servercore:ltsc2022"
      fi
      shift 2
      ;;
    --base|--base-image)
      base_image="${2:-}"
      if [ "$base_image" = "debian" ]; then
        base_image="debian:bookworm-slim"
        layer_filter=""
      elif [ "$base_image" = "alpine" ]; then
        base_image="alpine:latest"
      fi
      shift 2
      ;;
    *)
      printf '%s
' "$1" >> "$tmp_args"
      shift
      ;;
  esac
done

if [ "$is_offline" -eq 1 ]; then
  if [ ! -d "cache" ] && [ ! -d "${LIBSCRIPT_CACHE_DIR:-}" ]; then
    printf '[WARN] Local cache directory not found. Run hydrate_offline_cache.sh prior to air-gapped build.
' >&2
  fi
fi

# Print Dockerfile Header
printf '%s\n' "FROM $base_image"
printf '%s\n' "ARG TARGETOS=linux"
printf '%s\n' "ARG TARGETARCH=amd64"
printf '%s\n' "ENV LC_ALL=C.UTF-8 LANG=C.UTF-8"
printf '%s\n' 'ENV LIBSCRIPT_ROOT_DIR="/opt/libscript"'
printf '%s\n' 'ENV LIBSCRIPT_BUILD_DIR="/opt/libscript_build"'
printf '%s\n' 'ENV LIBSCRIPT_DATA_DIR="/opt/libscript_data"'
printf '%s\n' 'ENV LIBSCRIPT_CACHE_DIR="/opt/libscript_cache"'

if [ "$is_offline" -eq 1 ]; then
  printf '%s\n' 'ENV LIBSCRIPT_OFFLINE="1"'
  printf '%s\n' 'ENV PIP_NO_INDEX="1"'
  printf '%s\n' 'ENV PIP_FIND_LINKS="/opt/libscript_cache/wheels"'
  printf '%s\n' 'ENV npm_config_offline="true"'
  printf '%s\n' 'ENV npm_config_prefer_offline="true"'
  printf '%s\n' 'ENV npm_config_cache="/opt/libscript_cache/npm"'
  printf '%s\n' 'COPY cache/ /opt/libscript_cache/'
fi

# Collect positional arguments
first_target=""
if [ -s "$tmp_args" ]; then
  first_target=$(head -n 1 "$tmp_args")
fi

# Inspect manifest or offline_bundle for online ADD layer caching
bundle_file=""
if [ -n "$first_target" ]; then
  if [ -f "$first_target/offline_bundle.json" ]; then
    bundle_file="$first_target/offline_bundle.json"
  elif [ -f "$first_target/manifest.json" ]; then
    bundle_file="$first_target/manifest.json"
  elif [ -f "${LIBSCRIPT_ROOT_DIR}/stacks/cms/${first_target}/offline_bundle.json" ]; then
    bundle_file="${LIBSCRIPT_ROOT_DIR}/stacks/cms/${first_target}/offline_bundle.json"
  elif [ -f "${LIBSCRIPT_ROOT_DIR}/stacks/cms/${first_target}/manifest.json" ]; then
    bundle_file="${LIBSCRIPT_ROOT_DIR}/stacks/cms/${first_target}/manifest.json"
  fi
fi

if [ "$is_offline" -ne 1 ] && [ -n "$bundle_file" ] && command -v jq >/dev/null 2>&1; then
  # Extract runtimes
  jq -r '.runtimes[]? | "\(.extract_dir // "runtimes") \(.filename) \(.url)"' "$bundle_file" 2>/dev/null | while read -r _dir _fn _url; do
    if [ -n "$_url" ] && [ "$_url" != "null" ]; then
      printf 'ADD %s /opt/libscript_cache/%s/%s
' "$_url" "$_dir" "$_fn" >> "$tmp_add"
    fi
  done
  # Extract databases
  jq -r '.databases[]? | "\(.extract_dir // "databases") \(.filename) \(.url)"' "$bundle_file" 2>/dev/null | while read -r _dir _fn _url; do
    if [ -n "$_url" ] && [ "$_url" != "null" ]; then
      printf 'ADD %s /opt/libscript_cache/%s/%s
' "$_url" "$_dir" "$_fn" >> "$tmp_add"
    fi
  done
  # Extract wheels
  jq -r '.wheels.packages[]? | "\("wheels") \(.filename) \(.url)"' "$bundle_file" 2>/dev/null | while read -r _dir _fn _url; do
    if [ -n "$_url" ] && [ "$_url" != "null" ]; then
      printf 'ADD %s /opt/libscript_cache/%s/%s
' "$_url" "$_dir" "$_fn" >> "$tmp_add"
    fi
  done
  # Extract codebase
  jq -r 'if .codebase.archive_url then "codebase \(.codebase.archive_filename) \(.codebase.archive_url)" else empty end' "$bundle_file" 2>/dev/null | while read -r _dir _fn _url; do
    if [ -n "$_url" ] && [ "$_url" != "null" ]; then
      printf 'ADD %s /opt/libscript_cache/%s/%s
' "$_url" "$_dir" "$_fn" >> "$tmp_add"
    fi
  done
fi

deps_list=""
if [ -s "$tmp_args" ]; then
  # Read positional tokens
  cur_pkg=""
  cur_ver=""
  cur_override=""
  while read -r token; do
    [ -z "$token" ] && continue
    if [ -z "$cur_pkg" ]; then
      cur_pkg="$token"
    elif [ -z "$cur_ver" ]; then
      case "$token" in
        http://*|https://*)
          cur_ver="latest"
          cur_override="$token"
          deps_list="${deps_list}cli ${cur_pkg} ${cur_ver} ${cur_override}
"
          cur_pkg=""
          cur_ver=""
          cur_override=""
          ;;
        *)
          cur_ver="$token"
          ;;
      esac
    else
      case "$token" in
        http://*|https://*)
          cur_override="$token"
          deps_list="${deps_list}cli ${cur_pkg} ${cur_ver} ${cur_override}
"
          cur_pkg=""
          cur_ver=""
          cur_override=""
          ;;
        *)
          deps_list="${deps_list}cli ${cur_pkg} ${cur_ver} ${cur_override}
"
          cur_pkg="$token"
          cur_ver=""
          cur_override=""
          ;;
      esac
    fi
  done < "$tmp_args"

  if [ -n "$cur_pkg" ]; then
    if [ -z "$cur_ver" ]; then cur_ver="latest"; fi
    deps_list="${deps_list}cli ${cur_pkg} ${cur_ver} ${cur_override}
"
  fi
elif [ -f "libscript.json" ] && command -v jq >/dev/null 2>&1; then
  deps_list=$("${LIBSCRIPT_ROOT_DIR:-.}/_lib/orchestration/resolve_stack.sh" "libscript.json" 2>/dev/null | jq -r '.selected[] | "\(.layer // "deps") \(.name) \(.version // "latest") \(.override // "")"' 2>/dev/null || true)
fi

# Process dependencies and emit instructions without eval
if [ -n "$deps_list" ]; then
  printf '%b
' "$deps_list" | while read -r _layer pkg ver override; do
    [ -z "$pkg" ] && continue
    if [ -n "$layer_filter" ] && [ "$_layer" != "cli" ] && [ "$_layer" != "$layer_filter" ] && [ "${_layer}s" != "$layer_filter" ]; then
      continue
    fi

    pkg_clean=$(basename "$pkg")
    pkg_up=$(printf '%s' "$pkg_clean" | tr '[:lower:]' '[:upper:]' | tr '-' '_')
    [ "$ver" = "null" ] || [ -z "$ver" ] && ver="latest"

    printf 'ENV %s_VERSION="%s"
' "$pkg_up" "$ver" >> "$tmp_env_add"

    if [ -n "$override" ] && [ "$override" != "null" ]; then
      filename=$(basename "${override%%\?*}")
      if [ "$is_offline" -ne 1 ]; then
        printf 'ENV %s_URL="%s"
' "$pkg_up" "$override" >> "$tmp_env_add"
        printf 'ADD ${%s_URL} /opt/libscript_cache/%s/%s
' "$pkg_up" "$pkg_clean" "$filename" >> "$tmp_add"
      fi
    fi

    if [ "$artifact_type" = "deb" ]; then
      printf 'RUN dpkg -s %s >/dev/null 2>&1 || (apt-get update && apt-get install -y /opt/libscript/*-%s_*.deb)
' "$pkg_clean" "$pkg_clean" >> "$tmp_run"
    elif [ "$artifact_type" = "rpm" ]; then
      printf 'RUN rpm -q %s >/dev/null 2>&1 || dnf install -y /opt/libscript/*-%s-*.rpm
' "$pkg_clean" "$pkg_clean" >> "$tmp_run"
    elif [ "$artifact_type" = "apk" ]; then
      printf 'RUN apk info -e %s >/dev/null 2>&1 || apk add --allow-untrusted /opt/libscript/*-%s-*.apk
' "$pkg_clean" "$pkg_clean" >> "$tmp_run"
    elif [ "$artifact_type" = "txz" ]; then
      printf 'RUN pkg install -y /opt/libscript/*-%s*.txz /opt/libscript/*-%s*.pkg || true
' "$pkg_clean" "$pkg_clean" >> "$tmp_run"
    elif [ "$artifact_type" = "msi" ]; then
      printf 'RUN for %%I in (C:\opt\libscript\*-%s-*.msi) do msiexec /i "%%I" /qn /norestart
' "$pkg_clean" >> "$tmp_run"
    elif [ "$artifact_type" = "exe" ]; then
      printf 'RUN for %%I in (C:\opt\libscript\*-%s-*.exe) do "%%I" /SILENT /VERYSILENT
' "$pkg_clean" >> "$tmp_run"
    else
      if [ "$is_offline" -eq 1 ]; then
        printf 'RUN ./libscript.sh install %s ${%s_VERSION} --offline
' "$pkg" "$pkg_up" >> "$tmp_run"
      else
        printf 'RUN ./libscript.sh install %s ${%s_VERSION}
' "$pkg" "$pkg_up" >> "$tmp_run"
      fi
    fi

    if [ -f "${LIBSCRIPT_ROOT_DIR}/libscript.sh" ]; then
      PREFIX="/opt/libscript/installed/$pkg_clean" "${LIBSCRIPT_ROOT_DIR}/libscript.sh" env "$pkg_clean" "$ver" --format=docker 2>/dev/null | grep -vE '^(ENV STACK=|ENV SCRIPT_NAME=)' >> "$tmp_run" || true
    fi
  done
else
  if [ "$is_offline" -eq 1 ]; then
    printf '%s
' "RUN ./install_gen.sh --offline" >> "$tmp_run"
  else
    printf '%s
' "RUN ./install_gen.sh" >> "$tmp_run"
  fi
fi

if [ -s "$tmp_env_add" ]; then
  cat "$tmp_env_add"
fi
if [ -s "$tmp_add" ]; then
  cat "$tmp_add"
fi

printf '%s
' "COPY . /opt/libscript"
printf '%s
' "WORKDIR /opt/libscript"

if [ -s "$tmp_run" ]; then
  cat "$tmp_run"
fi

exit 0
