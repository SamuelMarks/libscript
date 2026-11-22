#!/bin/sh
# ## Overview
# Generic setup module for ReactOS Applications Manager (rapps).
# Provisions an isolated rapps-db package catalog and cross-platform rapps CLI shim.
#
# ## Usage
# ./_lib/package-managers/rapps/setup_generic.sh

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

RAPPS_INSTALL_METHOD="$(libscript_resolve_install_method "RAPPS")"
ACTION="${ACTION:-install}"
VERSION="${RAPPS_VERSION:-${LIBSCRIPT_RAPPS_VERSION:-0.4.16}}"

# ## seed_builtin_rapps_db
# Writes curated baseline RAPPS .txt INI definitions for deterministic offline catalog resolution.
seed_builtin_rapps_db() {
  _db_dir="$1"
  mkdir -p "$_db_dir"
  cat <<'INI_EOF' > "${_db_dir}/7zip.txt"
[Section]
Name = 7-Zip
Version = 24.08
License = LGPL
Description = High-compression file archiver utility for Win32 and ReactOS.
Category = 12
URLDownload = https://www.7-zip.org/a/7z2408.exe
SHA256 = SKIP
Installer = exe
SilentParameters = /S

[Section.amd64]
URLDownload = https://www.7-zip.org/a/7z2408-x64.exe
SHA256 = SKIP
Installer = exe
SilentParameters = /S
INI_EOF

  cat <<'INI_EOF' > "${_db_dir}/sumatrapdf.txt"
[Section]
Name = SumatraPDF
Version = 3.5.2
License = GPLv3
Description = Lightweight PDF, eBook, and XPS reader for ReactOS.
Category = 6
URLDownload = https://www.sumatrapdfreader.org/dl/rel/3.5.2/SumatraPDF-3.5.2-install.exe
SHA256 = SKIP
Installer = exe
SilentParameters = -s

[Section.amd64]
URLDownload = https://www.sumatrapdfreader.org/dl/rel/3.5.2/SumatraPDF-3.5.2-64-install.exe
SHA256 = SKIP
Installer = exe
SilentParameters = -s
INI_EOF

  cat <<'INI_EOF' > "${_db_dir}/notepadpp.txt"
[Section]
Name = Notepad++
Version = 8.6.9
License = GPLv3
Description = Source code and text editor for Win32 and ReactOS.
Category = 7
URLDownload = https://github.com/notepad-plus-plus/notepad-plus-plus/releases/download/v8.6.9/npp.8.6.9.Installer.exe
SHA256 = SKIP
Installer = exe
SilentParameters = /S

[Section.amd64]
URLDownload = https://github.com/notepad-plus-plus/notepad-plus-plus/releases/download/v8.6.9/npp.8.6.9.Installer.x64.exe
SHA256 = SKIP
Installer = exe
SilentParameters = /S
INI_EOF

  cat <<'INI_EOF' > "${_db_dir}/vlc.txt"
[Section]
Name = VLC media player
Version = 3.0.21
License = GPLv2
Description = Cross-platform multimedia player and framework.
Category = 2
URLDownload = https://get.videolan.org/vlc/3.0.21/win32/vlc-3.0.21-win32.exe
SHA256 = SKIP
Installer = exe
SilentParameters = /S

[Section.amd64]
URLDownload = https://get.videolan.org/vlc/3.0.21/win64/vlc-3.0.21-win64.exe
SHA256 = SKIP
Installer = exe
SilentParameters = /S
INI_EOF

  cat <<'INI_EOF' > "${_db_dir}/git.txt"
[Section]
Name = Git for Windows / ReactOS
Version = 2.46.0
License = GPLv2
Description = Distributed version control system.
Category = 7
URLDownload = https://github.com/git-for-windows/git/releases/download/v2.46.0.windows.1/Git-2.46.0-32-bit.exe
SHA256 = SKIP
Installer = inno
SilentParameters = /VERYSILENT /SUPPRESSMSGBOXES /NORESTART

[Section.amd64]
URLDownload = https://github.com/git-for-windows/git/releases/download/v2.46.0.windows.1/Git-2.46.0-64-bit.exe
SHA256 = SKIP
Installer = inno
SilentParameters = /VERYSILENT /SUPPRESSMSGBOXES /NORESTART
INI_EOF
}

# ## install_rapps_native
# Stages isolated rapps catalog and wrapper binary idempotently.
install_rapps_native() {
  _ver="$1"
  [ "$_ver" = "latest" ] && _ver='0.4.16'
  _home="${LIBSCRIPT_HOME:-${HOME:-/root}/.libscript}"
  _inst_dir="${_home}/rapps/${_ver}"
  _stamp="${_inst_dir}/.stamp.rapps"

  if [ -x "${_inst_dir}/bin/rapps" ] && [ -f "$_stamp" ]; then
    log_info "[SKIP] rapps ${_ver} is already installed at ${_inst_dir}."
    return 0
  fi

  mkdir -p "${_inst_dir}/bin" "${_inst_dir}/db"
  seed_builtin_rapps_db "${_inst_dir}/db"

  _db_url="${RAPPS_DOWNLOAD_URL:-${LIBSCRIPT_RAPPS_DB_URL:-}}"
  if [ -n "$_db_url" ] && [ "${LIBSCRIPT_OFFLINE:-0}" != "1" ] && [ "${RAPPS_FETCH_UPSTREAM_DB:-0}" = "1" ]; then
    _arc="${DOWNLOAD_DIR:-${TMPDIR:-/tmp}/libscript_downloads}/rapps/rapps-db-${_ver}.tar.gz"
    mkdir -p "$(dirname -- "$_arc")"
    if libscript_download "$_db_url" "$_arc" "SKIP"; then
      tar -xzf "$_arc" -C "${_inst_dir}/db" --strip-components=1 2>/dev/null || true
    fi
  fi

  cat <<WRAP_EOF > "${_inst_dir}/bin/rapps"
#!/bin/sh
exec "${LIBSCRIPT_ROOT_DIR}/_lib/package-managers/rapps/cli.sh" "\$@"
WRAP_EOF
  chmod +x "${_inst_dir}/bin/rapps"

  mkdir -p "${_home}/bin"
  ln -sf "${_inst_dir}/bin/rapps" "${_home}/bin/rapps"
  date -u +"%Y-%m-%dT%H:%M:%SZ" > "${_stamp}.tmp"
  mv "${_stamp}.tmp" "$_stamp"
  log_info "Installed rapps ${_ver} to ${_inst_dir}."
}

case "$ACTION" in
  ls|use)
    libscript_handle_generic_action "rapps" "$ACTION" "$VERSION" "$RAPPS_INSTALL_METHOD"
    ;;
  ls-remote)
    if [ -n "${RAPPS_RELEASES_URL:-}" ]; then
      libscript_fetch_stdout "${RAPPS_RELEASES_URL}" | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | libscript_sort_versions | uniq || printf '0.4.16\n'
    else
      printf '0.4.15\n0.4.16\n'
    fi
    ;;
  download)
    _db_url="${RAPPS_DOWNLOAD_URL:-${LIBSCRIPT_RAPPS_DB_URL:-https://github.com/reactos/rapps-db/archive/refs/heads/master.tar.gz}}"
    _dl_dest="${DOWNLOAD_DIR:-${TMPDIR:-/tmp}/libscript_downloads}/rapps/rapps-db-${VERSION}.tar.gz"
    mkdir -p "$(dirname -- "$_dl_dest")"
    if [ "${LIBSCRIPT_OFFLINE:-0}" != "1" ]; then
      libscript_download "$_db_url" "$_dl_dest" "SKIP" || true
    fi
    ;;
  install)
    install_rapps_native "$VERSION"
    ;;
  *)
    libscript_handle_generic_action "rapps" "$ACTION" "$VERSION" "$RAPPS_INSTALL_METHOD"
    ;;
esac
