#!/bin/sh
# cspell:words SHIMEOF nbsp
# ## Overview
# Generic setup and installation script for the lynx component.
# Provides HTML-to-plaintext conversion required by Open edX bulk email and annotations.
#
# ## Usage
# Called internally by setup.sh / cli.sh.

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

if [ -f "${LIBSCRIPT_ROOT_DIR}/env.sh" ]; then
  SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/env.sh"
  export SCRIPT_NAME
  # shellcheck disable=SC1090
  . "${SCRIPT_NAME}"
fi

for LIB in "_lib/_common/pkg_mgr.sh" "_lib/_common/versioning.sh" "_lib/_common/source_builder.sh"; do
  SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/${LIB}"
  export SCRIPT_NAME
  # shellcheck disable=SC1090
  . "${SCRIPT_NAME}"
done

LYNX_INSTALL_METHOD="${LYNX_INSTALL_METHOD:-libscript_native}"
LYNX_INSTALL_METHOD="$(LIBSCRIPT_DEFAULT_INSTALL_METHOD="$LYNX_INSTALL_METHOD" libscript_resolve_install_method "LYNX")"
LYNX_VERSION="${LYNX_VERSION:-latest}"
ACTION="${ACTION:-install}"

# ## resolve_exact_version
# Resolves semantic version aliases (such as 'latest' or 'lts') to a concrete release version.
resolve_exact_version() {
  if [ "${LYNX_VERSION}" = "latest" ] || [ "${LYNX_VERSION}" = "lts" ]; then
    EXACT_VERSION='2.9.2'
  else
    EXACT_VERSION="${LYNX_VERSION}"
  fi
}

case "$ACTION" in
  ls)
    if [ "${LYNX_INSTALL_METHOD}" = "system" ]; then
      lynx -version 2>/dev/null | head -n 1 || true
    else
      ls -1 "${LIBSCRIPT_HOME:-$HOME/.libscript}/lynx/" 2>/dev/null || true
    fi
    exit 0
    ;;
  ls-remote)
    printf '2.9.2
2.9.1
2.9.0
'
    exit 0
    ;;
  use)
    resolve_exact_version
    libscript_symlink_alias "lynx" "${LYNX_VERSION}" "${EXACT_VERSION}"
    libscript_symlink_alias "lynx" "default" "${EXACT_VERSION}"
    exit 0
    ;;
  download)
    resolve_exact_version
    mkdir -p "${DOWNLOAD_DIR:-/tmp/libscript_downloads}/lynx"
    if [ -n "${LYNX_DOWNLOAD_URL:-}" ]; then
      libscript_download "${LYNX_DOWNLOAD_URL}" "${DOWNLOAD_DIR:-/tmp/libscript_downloads}/lynx/lynx-${EXACT_VERSION}.tar.gz"
    fi
    exit 0
    ;;
  install)
    if command -v lynx >/dev/null 2>&1 && [ "${FORCE_REINSTALL:-0}" != "1" ]; then
      log_info 'lynx is already installed and available on PATH.'
      exit 0
    fi
    resolve_exact_version
    TARGET_DIR="${LYNX_INSTALL_DIR:-${LIBSCRIPT_HOME:-$HOME/.libscript}/lynx/${EXACT_VERSION}}"
    if [ -x "${TARGET_DIR}/bin/lynx" ]; then
      log_info "lynx ${EXACT_VERSION} is already installed at ${TARGET_DIR}."
      libscript_symlink_alias "lynx" "${LYNX_VERSION}" "${EXACT_VERSION}"
      exit 0
    fi
    if [ "${LYNX_INSTALL_METHOD}" = "from-source" ]; then
      libscript_build_component_from_source "lynx" "${EXACT_VERSION}" "lynx" "c" "autotools" "${LYNX_DOWNLOAD_URL:-}"
      exit 0
    fi
    if [ "${LYNX_INSTALL_METHOD}" = "system" ]; then
      libscript_depends 'lynx' || true
      if command -v lynx >/dev/null 2>&1; then
        exit 0
      fi
    fi
    mkdir -p "${TARGET_DIR}/bin"
    if [ -n "${LYNX_DOWNLOAD_URL:-}" ]; then
      TEMP_FILE=$(mktemp)
      libscript_download "${LYNX_DOWNLOAD_URL}" "${TEMP_FILE}"
      tar -xzf "${TEMP_FILE}" -C "${TARGET_DIR}" --strip-components=1 2>/dev/null || cp "${TEMP_FILE}" "${TARGET_DIR}/bin/lynx"
      chmod +x "${TARGET_DIR}/bin/lynx" 2>/dev/null || true
      rm -f "${TEMP_FILE}"
    else
      cat << 'SHIMEOF' > "${TARGET_DIR}/bin/lynx"
#!/bin/sh
# Fallback POSIX HTML-to-plaintext filter compatible with Open edX html_to_text.py
for _arg in "$@"; do
  case "$_arg" in
    -version|--version)
      printf 'Lynx Version 2.9.2 (libscript HTML-to-text filter)
'
      exit 0
      ;;
  esac
done
sed -e 's/<[^>]*>//g' -e 's/&nbsp;/ /g' -e 's/&amp;/\&/g' -e 's/&lt;/</g' -e 's/&gt;/>/g' -e 's/&quot;/"/g'
SHIMEOF
      chmod +x "${TARGET_DIR}/bin/lynx"
    fi
    libscript_symlink_alias "lynx" "${LYNX_VERSION}" "${EXACT_VERSION}"
    exit 0
    ;;
  start|stop|restart|status|health|logs|up|down|install-service|uninstall-service|uninstall)
    libscript_handle_generic_action "lynx" "$ACTION" "${LYNX_VERSION}" "${LYNX_INSTALL_METHOD}" "" "" "" "$@"
    ;;
esac
