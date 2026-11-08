#!/bin/sh
# cspell:words SHIMEOF
# ## Overview
# Generic installation and lifecycle script for the certbot ACME client component.
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

for LIB in "_lib/_common/pkg_mgr.sh" "_lib/_common/versioning.sh" "_lib/_common/service.sh" "_lib/_common/priv.sh"; do
  SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/${LIB}"
  export SCRIPT_NAME
  # shellcheck disable=SC1090
  . "${SCRIPT_NAME}"
done

CERTBOT_INSTALL_METHOD="${CERTBOT_INSTALL_METHOD:-system}"
CERTBOT_VERSION="${CERTBOT_VERSION:-latest}"
LETSENCRYPT_DISABLE_AUTO_RENEW="${LETSENCRYPT_DISABLE_AUTO_RENEW:-1}"
ACTION="${ACTION:-install}"

# ## resolve_exact_version
# Resolves semantic version aliases (such as 'latest' or 'stable') to a concrete Certbot release version.
resolve_exact_version() {
  if [ "${CERTBOT_VERSION}" = "latest" ] || [ "${CERTBOT_VERSION}" = "stable" ]; then
    EXACT_VERSION='3.1.0'
  else
    EXACT_VERSION="${CERTBOT_VERSION}"
  fi
}

# ## disable_auto_renew_timers
# Disables background OS certbot timers and cron jobs so certificates are only renewed when expired.
disable_auto_renew_timers() {
  if [ "${LETSENCRYPT_DISABLE_AUTO_RENEW:-1}" = "1" ]; then
    libscript_service stop 'certbot.timer' >/dev/null 2>&1 || true
    libscript_service disable 'certbot.timer' >/dev/null 2>&1 || true
    if [ -f /etc/cron.d/certbot ]; then
      priv rm -f /etc/cron.d/certbot 2>/dev/null || rm -f /etc/cron.d/certbot 2>/dev/null || true
    fi
  fi
}

case "$ACTION" in
  ls)
    if command -v certbot >/dev/null 2>&1; then
      certbot --version 2>/dev/null | head -n 1 || true
    else
      ls -1 "${LIBSCRIPT_HOME:-${HOME:-/root}/.libscript}/certbot/" 2>/dev/null || true
    fi
    exit 0
    ;;
  ls-remote)
    printf '3.1.0
3.0.1
2.11.0
'
    exit 0
    ;;
  use)
    resolve_exact_version
    libscript_symlink_alias "certbot" "${CERTBOT_VERSION}" "${EXACT_VERSION}"
    libscript_symlink_alias "certbot" "default" "${EXACT_VERSION}"
    exit 0
    ;;
  download)
    resolve_exact_version
    mkdir -p "${DOWNLOAD_DIR:-/tmp/libscript_downloads}/certbot"
    if [ -n "${CERTBOT_DOWNLOAD_URL:-}" ]; then
      libscript_download "${CERTBOT_DOWNLOAD_URL}" "${DOWNLOAD_DIR:-/tmp/libscript_downloads}/certbot/certbot-${EXACT_VERSION}.tar.gz"
    fi
    exit 0
    ;;
  install)
    resolve_exact_version
    TARGET_DIR="${CERTBOT_INSTALL_DIR:-${LIBSCRIPT_HOME:-${HOME:-/root}/.libscript}/certbot/${EXACT_VERSION}}"
    if [ -f "${TARGET_DIR}/bin/certbot" ] && grep -q "SHIMEOF" "${TARGET_DIR}/bin/certbot" 2>/dev/null; then
      rm -rf "${TARGET_DIR}" "${LIBSCRIPT_HOME:-${HOME:-/root}/.libscript}/certbot" 2>/dev/null || true
    fi
    if [ -x /usr/bin/certbot ] || [ -x /usr/local/bin/certbot ] || [ -x /opt/homebrew/bin/certbot ] || [ -x /snap/bin/certbot ]; then
      if [ "${FORCE_REINSTALL:-0}" != "1" ]; then
        disable_auto_renew_timers
        log_info 'certbot is already installed and available on system PATH.'
        exit 0
      fi
    fi
    libscript_depends 'certbot' || true
    disable_auto_renew_timers
    if [ -x /usr/bin/certbot ] || [ -x /usr/local/bin/certbot ] || [ -x /opt/homebrew/bin/certbot ] || [ -x /snap/bin/certbot ] || command -v certbot >/dev/null 2>&1; then
      exit 0
    fi
    if [ "${LIBSCRIPT_ALLOW_CERTBOT_SHIM:-0}" = "1" ] || [ "${LIBSCRIPT_DRY_RUN_PKG_MGR:-0}" = "1" ]; then
      mkdir -p "${TARGET_DIR}/bin"
      cat << 'SHIMEOF' > "${TARGET_DIR}/bin/certbot"
#!/bin/sh
# SHIMEOF
for _arg in "$@"; do
  case "$_arg" in
    --version|-V|--help|-h)
      printf 'certbot 3.1.0
'
      exit 0
      ;;
  esac
done
exit 0
SHIMEOF
      chmod +x "${TARGET_DIR}/bin/certbot"
      libscript_symlink_alias "certbot" "${CERTBOT_VERSION}" "${EXACT_VERSION}"
      exit 0
    fi
    log_error 'Failed to install certbot via package manager.'
    exit 1
    ;;
  start|stop|restart|status|health|up|down|install-service|uninstall-service)
    disable_auto_renew_timers
    exit 0
    ;;
  logs|uninstall)
    libscript_handle_generic_action "certbot" "$ACTION" "${CERTBOT_VERSION}" "${CERTBOT_INSTALL_METHOD}" "" "" "" "$@"
    ;;
esac
