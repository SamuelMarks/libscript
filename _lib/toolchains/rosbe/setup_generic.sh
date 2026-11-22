#!/bin/sh
# ## Overview
# Generic setup module for the ReactOS Build Environment (rosbe).
# Composes _lib/toolchains/cmake and _lib/toolchains/ninja and provisions isolated i386/amd64 MinGW wrappers.
#
# ## Usage
# ./_lib/toolchains/rosbe/setup_generic.sh

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

for LIB in "engine/common/pkg_mgr.sh" "engine/common/os_info.sh" "engine/common/versioning.sh"; do
  SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/${LIB}"
  export SCRIPT_NAME
  # shellcheck disable=SC1090
  . "${SCRIPT_NAME}"
done
unset SCRIPT_NAME || true

ROSBE_INSTALL_METHOD="$(libscript_resolve_install_method "ROSBE")"
ACTION="${ACTION:-install}"
VERSION="${ROSBE_VERSION:-${LIBSCRIPT_ROSBE_VERSION:-2.2.1}}"

# ## link_mingw_prefix
# Links host MinGW cross-compiler tools for a given triplet into an isolated RosBE target bin directory.
link_mingw_prefix() {
  _triplet="$1"
  _dest_bin="$2"
  mkdir -p "$_dest_bin"
  for _tool in gcc g++ as ld ar ranlib windres dlltool objcopy objdump strip nm; do
    _host_bin=$(command -v "${_triplet}-${_tool}" 2>/dev/null || true)
    if [ -n "$_host_bin" ]; then
      ln -sf "$_host_bin" "${_dest_bin}/${_triplet}-${_tool}"
    fi
  done
}

# ## install_rosbe_native
# Installs isolated RosBE environment and composes cmake + ninja dependencies idempotently.
install_rosbe_native() {
  _ver="$1"
  [ "$_ver" = 'latest' ] && _ver='2.2.1'
  _home="${LIBSCRIPT_HOME:-${HOME:-/root}/.libscript}"
  _inst_dir="${LIBSCRIPT_ROSBE_INSTALL_DIR:-${_home}/rosbe/${_ver}}"
  _stamp="${_inst_dir}/.stamp.rosbe"

  if [ -x "${_inst_dir}/bin/rosbe" ] && [ -f "$_stamp" ]; then
    log_info "[SKIP] rosbe ${_ver} is already installed at ${_inst_dir}."
    return 0
  fi

  if [ "${LIBSCRIPT_OFFLINE:-0}" != '1' ]; then
    if ! command -v cmake >/dev/null 2>&1; then
      STACK='' "${LIBSCRIPT_ROOT_DIR}/libscript.sh" install cmake latest || true
    fi
    if ! command -v ninja >/dev/null 2>&1; then
      STACK='' "${LIBSCRIPT_ROOT_DIR}/libscript.sh" install ninja latest || true
    fi
  fi

  mkdir -p "${_inst_dir}/bin" "${_inst_dir}/i386/bin" "${_inst_dir}/amd64/bin"

  _custom_url="${ROSBE_DOWNLOAD_URL:-${LIBSCRIPT_ROSBE_URL:-}}"
  if [ -n "$_custom_url" ] && [ "${LIBSCRIPT_OFFLINE:-0}" != '1' ]; then
    _arc="${DOWNLOAD_DIR:-${TMPDIR:-/tmp}/libscript_downloads}/rosbe/RosBE-${_ver}.tar.bz2"
    mkdir -p "$(dirname -- "$_arc")"
    if libscript_download "$_custom_url" "$_arc" 'SKIP'; then
      tar -xjf "$_arc" -C "$_inst_dir" --strip-components=1 2>/dev/null || tar -xf "$_arc" -C "$_inst_dir" 2>/dev/null || true
    fi
  fi

  link_mingw_prefix 'i686-w64-mingw32' "${_inst_dir}/i386/bin"
  link_mingw_prefix 'x86_64-w64-mingw32' "${_inst_dir}/amd64/bin"

  printf 'i686-w64-mingw32\n' > "${_inst_dir}/targets.list"
  cat <<WRAP_EOF > "${_inst_dir}/bin/rosbe"
#!/bin/sh
if [ "\${1:-}" = "--version" ] || [ "\${1:-}" = "-v" ]; then
  printf 'RosBE %s\n' "${_ver}"
  exit 0
fi
exec "${LIBSCRIPT_ROOT_DIR}/_lib/toolchains/rosbe/cli.sh" "\$@"
WRAP_EOF
  chmod +x "${_inst_dir}/bin/rosbe"

  mkdir -p "${_home}/bin"
  ln -sf "${_inst_dir}/bin/rosbe" "${_home}/bin/rosbe"
  date -u +"%Y-%m-%dT%H:%M:%SZ" > "${_stamp}.tmp"
  mv "${_stamp}.tmp" "$_stamp"
  log_info "Installed rosbe ${_ver} to ${_inst_dir}."
}

case "$ACTION" in
  ls|use)
    libscript_handle_generic_action 'rosbe' "$ACTION" "$VERSION" "$ROSBE_INSTALL_METHOD"
    ;;
  ls-remote)
    if [ -n "${ROSBE_RELEASES_URL:-}" ]; then
      libscript_fetch_stdout "${ROSBE_RELEASES_URL}" | grep -oE '[0-9]+\.[0-9]+(\.[0-9]+)?' | libscript_sort_versions | uniq || printf '2.2.1\n'
    else
      printf '2.2.0\n2.2.1\n'
    fi
    ;;
  download)
    _dl_url="${ROSBE_DOWNLOAD_URL:-${LIBSCRIPT_ROSBE_URL:-}}"
    if [ -n "$_dl_url" ] && [ "${LIBSCRIPT_OFFLINE:-0}" != '1' ]; then
      _dl_dest="${DOWNLOAD_DIR:-${TMPDIR:-/tmp}/libscript_downloads}/rosbe/RosBE-${VERSION}.tar.bz2"
      mkdir -p "$(dirname -- "$_dl_dest")"
      libscript_download "$_dl_url" "$_dl_dest" 'SKIP' || true
    fi
    ;;
  install)
    install_rosbe_native "$VERSION"
    ;;
  *)
    libscript_handle_generic_action 'rosbe' "$ACTION" "$VERSION" "$ROSBE_INSTALL_METHOD"
    ;;
esac
