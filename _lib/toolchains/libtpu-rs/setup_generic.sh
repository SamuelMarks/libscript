#!/bin/sh
# ## Overview
# Generic setup script for `libtpu-rs` enforcing SIGPLAN `RULE-6` pinned release profiles (both full and slim feature-gated shared libraries) and provisioning an isolated `jax`/`jaxlib` virtual environment via `python_env.sh`.
#
# ## Usage
# Called internally by `_lib/toolchains/libtpu-rs/setup.sh`.

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

for _ltr_lib in '_lib/_common/pkg_mgr.sh' '_lib/_common/versioning.sh' '_lib/_common/python_env.sh' '_lib/_common/experiment_harness.sh'; do
  SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/${_ltr_lib}"
  export SCRIPT_NAME
  # shellcheck disable=SC1090,SC1091
  . "${SCRIPT_NAME}"
done
unset SCRIPT_NAME _ltr_lib || true

LIBTPU_RS_INSTALL_METHOD="${LIBTPU_RS_INSTALL_METHOD:-${LIBSCRIPT_GLOBAL_INSTALL_METHOD:-from-source}}"
ACTION="${ACTION:-install}"
VERSION="${LIBTPU_RS_VERSION:-0.0.52}"
LIBTPU_RS_CARGO_PROFILE="${LIBTPU_RS_CARGO_PROFILE:-opt3-lto-thin-cgu1}"
LIBTPU_RS_SLIM_FEATURES="${LIBTPU_RS_SLIM_FEATURES:---no-default-features}"
LIBTPU_RS_JAX_VERSION="${LIBTPU_RS_JAX_VERSION:-0.4.38}"

# ## resolve_exact_version
# Resolves dynamic version aliases for `libtpu-rs`.
resolve_exact_version() {
  if [ "${VERSION}" = "latest" ] || [ "${VERSION}" = "lts" ]; then
    EXACT_VERSION='0.0.52'
  else
    EXACT_VERSION="${VERSION}"
  fi
}

# ## resolve_repo_dir
# Resolves the local `libtpu-rs` source checkout or clones `LIBTPU_RS_GIT_URL` idempotently.
resolve_repo_dir() {
  if [ -n "${LIBTPU_RS_REPO_DIR:-}" ] && [ -d "${LIBTPU_RS_REPO_DIR}" ]; then
    printf '%s\n' "${LIBTPU_RS_REPO_DIR}"
    return 0
  fi
  if [ -d "${LIBSCRIPT_ROOT_DIR}/../libtpu-rs" ]; then
    (cd -- "${LIBSCRIPT_ROOT_DIR}/../libtpu-rs" && pwd)
    return 0
  fi
  if [ -n "${LIBTPU_RS_GIT_URL:-}" ]; then
    _clone_dst="${LIBSCRIPT_CACHE_DIR:-$LIBSCRIPT_ROOT_DIR/cache}/src/libtpu-rs"
    if [ ! -d "${_clone_dst}/.git" ]; then
      mkdir -p "$(dirname -- "${_clone_dst}")"
      git clone --depth 1 "${LIBTPU_RS_GIT_URL}" "${_clone_dst}"
    fi
    printf '%s\n' "${_clone_dst}"
    return 0
  fi
  return 1
}

case "$ACTION" in
  ls)
    if [ -d "${LIBSCRIPT_HOME:-${HOME:-/root}/.libscript}/libtpu-rs" ]; then
      ls -1 "${LIBSCRIPT_HOME:-${HOME:-/root}/.libscript}/libtpu-rs"
    fi
    ;;
  ls-remote)
    printf '0.0.52\n'
    ;;
  use)
    resolve_exact_version
    TARGET_DIR="${LIBSCRIPT_HOME:-${HOME:-/root}/.libscript}/libtpu-rs/${EXACT_VERSION}"
    if [ ! -d "${TARGET_DIR}" ]; then
      ACTION='install' "$0"
    fi
    libscript_symlink_alias 'libtpu-rs' "${VERSION}" "${EXACT_VERSION}"
    libscript_symlink_alias 'libtpu-rs' 'default' "${EXACT_VERSION}"
    ;;
  download)
    resolve_repo_dir >/dev/null || true
    ;;
  install)
    resolve_exact_version
    TARGET_DIR="${LIBSCRIPT_HOME:-${HOME:-/root}/.libscript}/libtpu-rs/${EXACT_VERSION}"
    if [ -x "${TARGET_DIR}/bin/libtpu-rs-env" ] && [ "${FORCE_REINSTALL:-0}" != "1" ]; then
      printf '[INFO] libtpu-rs %s is already installed at %s.\n' "${EXACT_VERSION}" "${TARGET_DIR}"
      libscript_symlink_alias 'libtpu-rs' "${VERSION}" "${EXACT_VERSION}"
      libscript_symlink_alias 'libtpu-rs' 'default' "${EXACT_VERSION}"
      exit 0
    fi

    mkdir -p "${TARGET_DIR}/bin" "${TARGET_DIR}/lib"
    libscript_exp_pin_cargo_release "${LIBTPU_RS_CARGO_PROFILE}" "${TARGET_DIR}/cargo_profile.json"

    _so_ext='so'
    if [ "${UNAME:-}" = "Darwin" ]; then
      _so_ext='dylib'
    fi

    if _src_repo=$(resolve_repo_dir 2>/dev/null) && [ -f "${_src_repo}/Cargo.toml" ]; then
      if ! command -v cargo >/dev/null 2>&1; then
        "${LIBSCRIPT_ROOT_DIR}/libscript.sh" install rust latest
      fi
      (
        cd -- "${_src_repo}"
        cargo build --release -p libtpu-c-api
      )
      _built_lib="${_src_repo}/target/release/libtpu_c_api.${_so_ext}"
      if [ -f "${_built_lib}" ]; then
        cp -f "${_built_lib}" "${TARGET_DIR}/lib/libtpu_c_api.unstripped.${_so_ext}"
        libscript_exp_strip_shared_lib "${_built_lib}" "${TARGET_DIR}/lib/libtpu_c_api.${_so_ext}"
      fi
      if [ -n "${LIBTPU_RS_SLIM_FEATURES}" ]; then
        (
          cd -- "${_src_repo}"
          # shellcheck disable=SC2086
          cargo build --release -p libtpu-c-api --target-dir "${_src_repo}/target/release-slim" ${LIBTPU_RS_SLIM_FEATURES} || true
        )
        _slim_lib="${_src_repo}/target/release-slim/release/libtpu_c_api.${_so_ext}"
        if [ -f "${_slim_lib}" ]; then
          cp -f "${_slim_lib}" "${TARGET_DIR}/lib/libtpu_c_api_slim.unstripped.${_so_ext}"
          libscript_exp_strip_shared_lib "${_slim_lib}" "${TARGET_DIR}/lib/libtpu_c_api_slim.${_so_ext}"
        fi
      fi
    fi

    _req_file="${TARGET_DIR}/jax_requirements.txt"
    printf 'jax==%s\njaxlib==%s\n' "${LIBTPU_RS_JAX_VERSION}" "${LIBTPU_RS_JAX_VERSION}" > "${_req_file}"
    if [ "${LIBSCRIPT_OFFLINE:-0}" != "1" ]; then
      libscript_python_venv "${TARGET_DIR}/venv" '' "${_req_file}" || log_warn 'Deferred optional jax/jaxlib installation in venv.'
    fi

    cat <<EOF > "${TARGET_DIR}/bin/libtpu-rs-env.tmp"
#!/bin/sh
printf 'libtpu-rs %s (%s)\n' '${EXACT_VERSION}' '${TARGET_DIR}'
EOF
    mv -f "${TARGET_DIR}/bin/libtpu-rs-env.tmp" "${TARGET_DIR}/bin/libtpu-rs-env"
    chmod +x "${TARGET_DIR}/bin/libtpu-rs-env"
    libscript_symlink_alias 'libtpu-rs' "${VERSION}" "${EXACT_VERSION}"
    libscript_symlink_alias 'libtpu-rs' 'default' "${EXACT_VERSION}"
    ;;
  start|stop|restart|status|health|logs|up|down|install-service|uninstall-service|uninstall)
    libscript_handle_generic_action 'libtpu-rs' "$ACTION" "$VERSION" "${LIBTPU_RS_INSTALL_METHOD}" "" "" "" "$@"
    ;;
esac
