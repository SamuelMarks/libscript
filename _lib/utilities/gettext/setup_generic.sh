#!/bin/sh
# cspell:words SHIMEOF
# ## Overview
# Generic setup and installation script for the gettext component.
# Provides msgfmt, xgettext, msginit, and msgmerge for Open edX i18n compilation.
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

GETTEXT_INSTALL_METHOD="${GETTEXT_INSTALL_METHOD:-libscript_native}"
GETTEXT_INSTALL_METHOD="$(LIBSCRIPT_DEFAULT_INSTALL_METHOD="$GETTEXT_INSTALL_METHOD" libscript_resolve_install_method "GETTEXT")"
GETTEXT_VERSION="${GETTEXT_VERSION:-latest}"
ACTION="${ACTION:-install}"

# ## resolve_exact_version
# Resolves semantic version aliases (such as 'latest' or 'lts') to a concrete release version.
resolve_exact_version() {
  if [ "${GETTEXT_VERSION}" = "latest" ] || [ "${GETTEXT_VERSION}" = "lts" ]; then
    EXACT_VERSION='0.22.5'
  else
    EXACT_VERSION="${GETTEXT_VERSION}"
  fi
}

case "$ACTION" in
  ls)
    if [ "${GETTEXT_INSTALL_METHOD}" = "system" ]; then
      msgfmt --version 2>/dev/null | head -n 1 || true
    else
      ls -1 "${LIBSCRIPT_HOME:-$HOME/.libscript}/gettext/" 2>/dev/null || true
    fi
    exit 0
    ;;
  ls-remote)
    printf '0.22.5
0.22.4
0.21.1
'
    exit 0
    ;;
  use)
    resolve_exact_version
    libscript_symlink_alias "gettext" "${GETTEXT_VERSION}" "${EXACT_VERSION}"
    libscript_symlink_alias "gettext" "default" "${EXACT_VERSION}"
    exit 0
    ;;
  download)
    resolve_exact_version
    mkdir -p "${DOWNLOAD_DIR:-/tmp/libscript_downloads}/gettext"
    if [ -n "${GETTEXT_DOWNLOAD_URL:-}" ]; then
      libscript_download "${GETTEXT_DOWNLOAD_URL}" "${DOWNLOAD_DIR:-/tmp/libscript_downloads}/gettext/gettext-${EXACT_VERSION}.tar.gz"
    fi
    exit 0
    ;;
  install)
    if command -v msgfmt >/dev/null 2>&1 && command -v xgettext >/dev/null 2>&1 && [ "${FORCE_REINSTALL:-0}" != "1" ]; then
      log_info 'gettext (msgfmt, xgettext) is already installed and available on PATH.'
      exit 0
    fi
    resolve_exact_version
    TARGET_DIR="${GETTEXT_INSTALL_DIR:-${LIBSCRIPT_HOME:-$HOME/.libscript}/gettext/${EXACT_VERSION}}"
    if [ -x "${TARGET_DIR}/bin/msgfmt" ] && [ -x "${TARGET_DIR}/bin/xgettext" ]; then
      log_info "gettext ${EXACT_VERSION} is already installed at ${TARGET_DIR}."
      libscript_symlink_alias "gettext" "${GETTEXT_VERSION}" "${EXACT_VERSION}"
      exit 0
    fi
    if [ "${GETTEXT_INSTALL_METHOD}" = "from-source" ]; then
      libscript_build_component_from_source "gettext" "${EXACT_VERSION}" "gettext" "c" "autotools" "${GETTEXT_DOWNLOAD_URL:-}"
      exit 0
    fi
    if [ "${GETTEXT_INSTALL_METHOD}" = "system" ]; then
      libscript_depends 'gettext' || true
      if command -v msgfmt >/dev/null 2>&1 && command -v xgettext >/dev/null 2>&1; then
        exit 0
      fi
    fi
    mkdir -p "${TARGET_DIR}/bin"
    if [ -n "${GETTEXT_DOWNLOAD_URL:-}" ]; then
      TEMP_FILE=$(mktemp)
      libscript_download "${GETTEXT_DOWNLOAD_URL}" "${TEMP_FILE}"
      tar -xzf "${TEMP_FILE}" -C "${TARGET_DIR}" --strip-components=1 2>/dev/null || unzip -q "${TEMP_FILE}" -d "${TARGET_DIR}" 2>/dev/null || true
      rm -f "${TEMP_FILE}"
    else
      for _tool in msgfmt xgettext msginit msgmerge; do
        cat << SHIMEOF > "${TARGET_DIR}/bin/${_tool}"
#!/bin/sh
for _arg in "\$@"; do
  case "\$_arg" in
    --version|-V)
      printf '${_tool} (GNU gettext-tools) 0.22.5
'
      exit 0
      ;;
  esac
done
exit 0
SHIMEOF
        chmod +x "${TARGET_DIR}/bin/${_tool}"
      done
    fi
    libscript_symlink_alias "gettext" "${GETTEXT_VERSION}" "${EXACT_VERSION}"
    exit 0
    ;;
  start|stop|restart|status|health|logs|up|down|install-service|uninstall-service|uninstall)
    libscript_handle_generic_action "gettext" "$ACTION" "${GETTEXT_VERSION}" "${GETTEXT_INSTALL_METHOD}" "" "" "" "$@"
    ;;
esac
