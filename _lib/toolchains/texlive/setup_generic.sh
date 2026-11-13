#!/bin/sh
# ## Overview
# Generic setup script for the texlive component installing portable TeX Live (`install-tl`) with scholarly ACM/PGFPlots/Type-1 packages into an isolated prefix.
#
# ## Usage
# Called internally by `_lib/toolchains/texlive/setup.sh`.

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

SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/_lib/_common/pkg_mgr.sh"
export SCRIPT_NAME
# shellcheck disable=SC1090
. "${SCRIPT_NAME}"

SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/_lib/_common/versioning.sh"
export SCRIPT_NAME
# shellcheck disable=SC1090
. "${SCRIPT_NAME}"

TEXLIVE_INSTALL_METHOD="${TEXLIVE_INSTALL_METHOD:-${LIBSCRIPT_GLOBAL_INSTALL_METHOD:-libscript_native}}"
ACTION="${ACTION:-install}"
VERSION="${TEXLIVE_VERSION:-2025}"
TEXLIVE_SCHEME="${TEXLIVE_SCHEME:-scheme-basic}"
TEXLIVE_EXTRA_PACKAGES="${TEXLIVE_EXTRA_PACKAGES:-acmart pgfplots pgf booktabs microtype hyperref cm-super libertine}"

# ## resolve_exact_version
# Resolves dynamic version aliases for TeX Live into a concrete release year.
resolve_exact_version() {
  if [ "${VERSION}" = "latest" ] || [ "${VERSION}" = "lts" ]; then
    EXACT_VERSION='2025'
  else
    EXACT_VERSION="${VERSION}"
  fi
}

case "$ACTION" in
  ls)
    if [ "${TEXLIVE_INSTALL_METHOD}" = "libscript_native" ]; then
      if [ -d "${LIBSCRIPT_HOME:-${HOME:-/root}/.libscript}/texlive" ]; then
        ls -1 "${LIBSCRIPT_HOME:-${HOME:-/root}/.libscript}/texlive"
      fi
    elif command -v pdflatex >/dev/null 2>&1; then
      pdflatex --version | head -n 1 || true
    fi
    ;;
  ls-remote)
    RELEASES_URL="${TEXLIVE_RELEASES_URL:-https://tug.org/texlive/acquire-netinstall.html}"
    printf '[ls-remote] Querying TeX Live release metadata from %s...\n' "${RELEASES_URL}"
    libscript_fetch_stdout "${RELEASES_URL}" | head -n 20 || true
    ;;
  use)
    resolve_exact_version
    TARGET_DIR="${LIBSCRIPT_HOME:-${HOME:-/root}/.libscript}/texlive/${EXACT_VERSION}"
    if [ ! -d "${TARGET_DIR}" ]; then
      ACTION='install' "$0"
    fi
    libscript_symlink_alias 'texlive' "${VERSION}" "${EXACT_VERSION}"
    libscript_symlink_alias 'texlive' 'default' "${EXACT_VERSION}"
    ;;
  download)
    URL="${TEXLIVE_DOWNLOAD_URL:-https://mirror.ctan.org/systems/texlive/tlnet/install-tl-unx.tar.gz}"
    DL_DIR="${DOWNLOAD_DIR:-/tmp/libscript_downloads}/texlive"
    mkdir -p "${DL_DIR}"
    libscript_download "${URL}" "${DL_DIR}/install-tl-unx.tar.gz"
    ;;
  install)
    resolve_exact_version
    TARGET_DIR="${LIBSCRIPT_HOME:-${HOME:-/root}/.libscript}/texlive/${EXACT_VERSION}"
    if [ -x "${TARGET_DIR}/bin/pdflatex" ] && [ "${FORCE_REINSTALL:-0}" != "1" ]; then
      printf '[INFO] texlive %s is already installed at %s.\n' "${EXACT_VERSION}" "${TARGET_DIR}"
      libscript_symlink_alias 'texlive' "${VERSION}" "${EXACT_VERSION}"
      libscript_symlink_alias 'texlive' 'default' "${EXACT_VERSION}"
      exit 0
    fi
    if [ "${TEXLIVE_INSTALL_METHOD}" = "system" ]; then
      if command -v pdflatex >/dev/null 2>&1 && command -v bibtex >/dev/null 2>&1 && [ "${FORCE_REINSTALL:-0}" != "1" ]; then
        printf '[INFO] System texlive (pdflatex + bibtex) is already available on PATH.\n'
        exit 0
      fi
      libscript_depends 'texlive'
      exit 0
    fi
    URL="${TEXLIVE_DOWNLOAD_URL:-https://mirror.ctan.org/systems/texlive/tlnet/install-tl-unx.tar.gz}"
    TMP_DIR="${TMPDIR:-/tmp}/texlive-install-$$"
    mkdir -p "${TMP_DIR}" "${TARGET_DIR}/bin"
    PACKAGE_NAME='texlive' libscript_download "${URL}" "${TMP_DIR}/install-tl-unx.tar.gz"
    tar -xzf "${TMP_DIR}/install-tl-unx.tar.gz" -C "${TMP_DIR}" --strip-components=1
    cat <<EOF > "${TMP_DIR}/texlive.profile"
selected_scheme ${TEXLIVE_SCHEME}
TEXDIR ${TARGET_DIR}
TEXMFLOCAL ${TARGET_DIR}/texmf-local
TEXMFSYSCONFIG ${TARGET_DIR}/texmf-config
TEXMFSYSVAR ${TARGET_DIR}/texmf-var
TEXMFHOME ${TARGET_DIR}/texmf-home
instopt_adjustpath 0
instopt_adjustrepo 1
tlpdbopt_autobackup 0
tlpdbopt_install_docfiles 0
tlpdbopt_install_srcfiles 0
EOF
    "${TMP_DIR}/install-tl" --profile="${TMP_DIR}/texlive.profile"
    _plat_bin=$(find "${TARGET_DIR}/bin" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | head -n 1 || true)
    if [ -n "${_plat_bin}" ] && [ -x "${_plat_bin}/pdflatex" ]; then
      for _tool in pdflatex bibtex tlmgr kpsewhich latex; do
        if [ -x "${_plat_bin}/${_tool}" ]; then
          ln -sf "${_plat_bin}/${_tool}" "${TARGET_DIR}/bin/${_tool}"
        fi
      done
      if [ -x "${_plat_bin}/tlmgr" ] && [ -n "${TEXLIVE_EXTRA_PACKAGES}" ]; then
        # shellcheck disable=SC2086
        "${_plat_bin}/tlmgr" install ${TEXLIVE_EXTRA_PACKAGES} || true
      fi
    fi
    rm -rf "${TMP_DIR}"
    libscript_symlink_alias 'texlive' "${VERSION}" "${EXACT_VERSION}"
    libscript_symlink_alias 'texlive' 'default' "${EXACT_VERSION}"
    ;;
  start|stop|restart|status|health|logs|up|down|install-service|uninstall-service|uninstall)
    libscript_handle_generic_action 'texlive' "$ACTION" "$VERSION" "${TEXLIVE_INSTALL_METHOD}" "" "" "" "$@"
    ;;
esac
