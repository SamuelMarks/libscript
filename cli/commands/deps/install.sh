#!/bin/sh
# ## Overview
# Resolves and installs dependencies required by libscript components.
# 
# ## Usage
# Execute this script to fetch and setup required dependencies.


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
if [ "$CMD" = "install-deps" ]; then
  json_file="libscript.json"
  force_reinstall=0
  force_rebuild=0
  for _id_arg in "$@"; do
    case "$_id_arg" in
      --force-reinstall) force_reinstall=1 ;;
      --force-rebuild) force_rebuild=1 ;;
      -*) ;;
      *) json_file="$_id_arg" ;;
    esac
  done
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

  if [ -z "${LIBSCRIPT_SECRETS:-}" ]; then
    json_secrets=$(jq -r 'if .secrets then .secrets else empty end' "$json_file" 2>/dev/null)
    if [ "$json_secrets" != "null" ] && [ -n "$json_secrets" ]; then
      export LIBSCRIPT_SECRETS="$json_secrets"
    else
      export LIBSCRIPT_SECRETS="${LIBSCRIPT_ROOT_DIR:-$SCRIPT_DIR}/secrets"
    fi
  fi

  if [ -f "${LIBSCRIPT_ROOT_DIR:-.}/_lib/_common/env_printer.sh" ]; then
    SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR:-.}/_lib/_common/env_printer.sh"
    # shellcheck disable=SC1090,SC1091
    . "${LIBSCRIPT_ROOT_DIR:-.}/_lib/_common/env_printer.sh"
    unset SCRIPT_NAME || true
    libscript_hydrate_manifest_env "$json_file" || true
  fi

    _manifest_dir=$(cd -- "$(dirname -- "$json_file")" && pwd)
  if [ "$force_reinstall" -eq 1 ]; then
    printf '[INFO] --force-reinstall: cleaning .venv and node_modules in %s...\n' "$_manifest_dir"
    for _clean_dir in "$_manifest_dir" "$_manifest_dir"/*; do
      [ -d "$_clean_dir" ] || continue
      rm -rf "${_clean_dir}/.venv" "${_clean_dir}/node_modules"
    done
  fi
  if [ "$force_rebuild" -eq 1 ]; then
    printf '[INFO] --force-rebuild: cleaning dist, build, and .angular caches in %s...\n' "$_manifest_dir"
    for _clean_dir in "$_manifest_dir" "$_manifest_dir"/*; do
      [ -d "$_clean_dir" ] || continue
      rm -rf "${_clean_dir}/dist" "${_clean_dir}/build" "${_clean_dir}/.angular"
    done
  fi

  _data_disks=$(jq -r '(.infrastructure.node.data_disks // [])[]? | "\(.mount_path // "/mnt/data") \(.fstype // "ext4")"' "$json_file" 2>/dev/null || true)
  if [ -n "$_data_disks" ] && [ -x "${LIBSCRIPT_ROOT_DIR:-.}/traits/storage/mount.sh" ]; then
    printf '%s\n' "$_data_disks" | while read -r _dd_mp _dd_fs; do
      [ -n "$_dd_mp" ] || continue
      case "$_dd_mp" in
        **) _dd_mp="${DATA_DISK_MOUNT:-${DATA_MOUNT_DIR:-/mnt/data}}" ;;
      esac
      "${LIBSCRIPT_ROOT_DIR:-.}/traits/storage/mount.sh" --auto-data-disk "$_dd_mp" "${_dd_fs:-ext4}" || true
    done
  fi

  "${LIBSCRIPT_ROOT_DIR:-.}/_lib/orchestration/run_hooks.sh" "$json_file" "pre_install" 

  unset SCRIPT_NAME || true
  deps=$("${LIBSCRIPT_ROOT_DIR:-.}/_lib/orchestration/resolve_stack.sh" "$json_file" 2>/dev/null | jq -r '.selected[] | "\(.name) \(.version // "latest") \(.override // "")"' 2>/dev/null || true)
  if [ -z "$deps" ]; then
    printf '%s\n' "No dependencies found in $json_file."
  else
    # Parallel Download Phase
    printf '%s\n' "Downloading dependencies in parallel..."
    printf '%s\n' "$deps" | while read -r pkg ver override; do
      if [ -n "$pkg" ]; then
        if [ "$ver" = "null" ]; then ver="latest"; fi
        if [ -z "$override" ] || [ "$override" = "null" ]; then
          "${LIBSCRIPT_ROOT_DIR:-.}/libscript.sh" download "$pkg" "$ver" &
        fi
      fi
    done
    wait

    # Serial Install Phase
    printf '%s\n' "Installing dependencies sequentially..."
    printf '%s\n' "$deps" | while read -r pkg ver override; do
      if [ -n "$pkg" ]; then
        if [ "$ver" = "null" ]; then ver="latest"; fi
        if [ -n "$override" ] && [ "$override" != "null" ]; then
          printf '%s\n' "Skipping installation of $pkg (override provided: $override)"
        else
          printf '%s\n' "Installing $pkg $ver..."
          "${LIBSCRIPT_ROOT_DIR:-.}/libscript.sh" install "$pkg" "$ver"
        fi
      fi
    done

    # Export resolved component env.sh paths into current execution environment
    tmp_deps_env=$(mktemp 2>/dev/null || printf '%s' "/tmp/libscript_deps_env.$$")
    printf '%s\n' "$deps" > "$tmp_deps_env"
    while read -r pkg ver _override; do
      if [ -n "$pkg" ]; then
        if [ "$ver" = "null" ] || [ -z "$ver" ]; then ver="latest"; fi
        _pkg_up=$(printf '%s' "$pkg" | tr '[:lower:]-' '[:upper:]_')
        export "${_pkg_up}_VERSION=${ver}"
        for _cat_name in $(ls -1 "${LIBSCRIPT_ROOT_DIR:-.}/_lib" 2>/dev/null || true); do
          _cat_dir="${LIBSCRIPT_ROOT_DIR:-.}/_lib/${_cat_name}"
          if [ -f "${_cat_dir}/${pkg}/env.sh" ]; then
            STACK=""
            SCRIPT_NAME="${_cat_dir}/${pkg}/env.sh"
            # shellcheck disable=SC1090
            . "${SCRIPT_NAME}" || true
          fi
        done
      fi
    done < "$tmp_deps_env"
    unset SCRIPT_NAME || true
    rm -f "$tmp_deps_env"

    # Persist resolved PATH idempotently into .env.libscript alongside manifest
    _manifest_dir=$(cd -- "$(dirname -- "$json_file")" && pwd)
    _env_out="${_manifest_dir}/.env.libscript"
    touch "$_env_out"
    grep -v "^PATH=" "$_env_out" > "${_env_out}.tmp" 2>/dev/null || true
    printf 'PATH="%s"\n' "$PATH" >> "${_env_out}.tmp"
    mv "${_env_out}.tmp" "$_env_out"
    chmod 0644 "$_env_out" 2>/dev/null || true
  fi

  # Ensure project Python virtual environments exist and are usable by the service user before running install hooks & DB provisioning
  _manifest_dir=$(cd -- "$(dirname -- "$json_file")" && pwd)
  _py_ver=$(jq -r '(.deps.python // .dependencies.python // (.dependencies.runtime[]? | select(.name=="python") | .version) // "3.12")' "$json_file" 2>/dev/null | head -n 1 || printf '3.12')
  [ -z "$_py_ver" ] || [ "$_py_ver" = "null" ] && _py_ver="3.12"
  _target_user="${SERVICE_USER:-${REMOTE_USER:-${SUDO_USER:-}}}"
  _target_home="${REMOTE_HOME:-}"
  if [ -n "$_target_user" ] && [ -z "$_target_home" ] && [ -d "/home/${_target_user}" ]; then
    _target_home="/home/${_target_user}"
  fi
  if [ -n "$_target_home" ] && [ -d "$_target_home" ]; then
    export UV_PYTHON_INSTALL_DIR="${_target_home}/.local/share/uv/python"
    export UV_CACHE_DIR="${_target_home}/.cache/uv"
  fi
  if [ -f "${LIBSCRIPT_ROOT_DIR:-.}/_lib/_common/python_env.sh" ]; then
    SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR:-.}/_lib/_common/python_env.sh"
    # shellcheck disable=SC1090,SC1091
    . "${LIBSCRIPT_ROOT_DIR:-.}/_lib/_common/python_env.sh"
    unset SCRIPT_NAME || true
  fi
  for _py_proj in "$_manifest_dir" "$_manifest_dir"/*; do
    [ -d "$_py_proj" ] || continue
    if [ -f "${_py_proj}/pyproject.toml" ] || [ -f "${_py_proj}/requirements.txt" ]; then
      # If .venv/bin/python points into /root/... (inaccessible to non-root service user), recreate it cleanly
      if [ -L "${_py_proj}/.venv/bin/python" ] || [ -L "${_py_proj}/.venv/bin/python3" ]; then
        _py_target=$(readlink -f "${_py_proj}/.venv/bin/python3" 2>/dev/null || readlink "${_py_proj}/.venv/bin/python3" 2>/dev/null || true)
        case "$_py_target" in
          /root/*)
            if [ -n "$_target_user" ] && [ "$_target_user" != "root" ]; then
              rm -rf "${_py_proj}/.venv"
            fi
            ;;
        esac
      fi
      if [ ! -x "${_py_proj}/.venv/bin/python" ]; then
        if command -v uv >/dev/null 2>&1; then
          HOME="${_target_home:-${HOME:-/root}}" LIBSCRIPT_PYTHON_VENV_BACKEND=uv libscript_python_venv "${_py_proj}/.venv" "$_py_ver" 2>/dev/null || true
          (cd "$_py_proj" && HOME="${_target_home:-${HOME:-/root}}" uv sync --python "$_py_ver" 2>/dev/null || HOME="${_target_home:-${HOME:-/root}}" uv sync 2>/dev/null || true)
        elif type libscript_python_venv >/dev/null 2>&1; then
          libscript_python_venv "${_py_proj}/.venv" "$_py_ver" 2>/dev/null || true
        fi
      fi
      if [ -n "$_target_user" ] && id "$_target_user" >/dev/null 2>&1 && [ -d "${_py_proj}/.venv" ]; then
        chown -R "${_target_user}:${SERVICE_GROUP:-${REMOTE_GROUP:-$_target_user}}" "${_py_proj}/.venv" "${_target_home:-/home/$_target_user}/.local" "${_target_home:-/home/$_target_user}/.cache" 2>/dev/null || true
      fi
    fi
  done

  "${LIBSCRIPT_ROOT_DIR:-.}/_lib/orchestration/run_hooks.sh" "$json_file" "install"

  if [ -f "${LIBSCRIPT_ROOT_DIR:-.}/_lib/databases/provision_db.sh" ]; then
    "${LIBSCRIPT_ROOT_DIR:-.}/_lib/databases/provision_db.sh" "$json_file"
  fi

  "${LIBSCRIPT_ROOT_DIR:-.}/_lib/orchestration/run_hooks.sh" "$json_file" "post_install"
  "${LIBSCRIPT_ROOT_DIR:-.}/_lib/orchestration/run_hooks.sh" "$json_file" "db_migrate"
  exit 0
fi
