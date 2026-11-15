#!/bin/sh
# ## Overview
# Generic setup script for gemma-tpu-suite installing isolated wrapper shims idempotently under LIBSCRIPT_HOME.
#
# ## Usage
# Invoked internally by _lib/toolchains/gemma-tpu-suite/setup.sh.
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

for _sg_lib in _lib/_common/log.sh _lib/_common/versioning.sh; do
  SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/${_sg_lib}"
  export SCRIPT_NAME
  # shellcheck disable=SC1090,SC1091
  . "${SCRIPT_NAME}"
done
unset SCRIPT_NAME _sg_lib || true

ACTION="${ACTION:-install}"
GEMMA_TPU_SUITE_VERSION="${GEMMA_TPU_SUITE_VERSION:-1.0.0}"
EXACT_VERSION="${GEMMA_TPU_SUITE_VERSION}"
if [ "${EXACT_VERSION}" = 'latest' ] || [ "${EXACT_VERSION}" = 'stable' ]; then
  EXACT_VERSION='1.0.0'
fi
HOME_BASE="${LIBSCRIPT_HOME:-${HOME:-/root}/.libscript}"
TARGET_DIR="${HOME_BASE}/gemma-tpu-suite/${EXACT_VERSION}"

# ## install_gemma_suite_shim
# Writes the isolated gemma-tpu-suite CLI shim idempotently.
install_gemma_suite_shim() {
  if [ -x "${TARGET_DIR}/bin/gemma-tpu-suite" ] && [ "${FORCE_REINSTALL:-0}" != '1' ]; then
    log_info "gemma-tpu-suite ${EXACT_VERSION} is already installed at ${TARGET_DIR}."
    return 0
  fi
  mkdir -p "${TARGET_DIR}/bin"
  cat <<EOF > "${TARGET_DIR}/bin/gemma-tpu-suite"
#!/bin/sh
set -feu
if [ "\${1:-}" = "--version" ] || [ "\${1:-}" = "-v" ]; then
  printf 'gemma-tpu-suite %s\n' '${EXACT_VERSION}'
  exit 0
fi
exec '${LIBSCRIPT_ROOT_DIR}/_lib/toolchains/gemma-tpu-suite/benchmark_experiments.sh' "\$@"
EOF
  chmod +x "${TARGET_DIR}/bin/gemma-tpu-suite"
  libscript_symlink_alias 'gemma-tpu-suite' "${GEMMA_TPU_SUITE_VERSION}" "${EXACT_VERSION}"
  libscript_symlink_alias 'gemma-tpu-suite' 'default' "${EXACT_VERSION}"
  log_info "Installed gemma-tpu-suite ${EXACT_VERSION} to ${TARGET_DIR}."
}

case "${ACTION}" in
  ls)
    if [ -d "${HOME_BASE}/gemma-tpu-suite" ]; then
      ls -1 "${HOME_BASE}/gemma-tpu-suite"
    fi
    ;;
  ls-remote)
    printf '%s\n' '1.0.0'
    ;;
  download)
    exit 0
    ;;
  use)
    install_gemma_suite_shim
    ;;
  install|*)
    install_gemma_suite_shim
    ;;
esac
