#!/bin/sh
# ## Overview
# Provides an abstraction layer over native system package managers.
# It defines `libscript_depends` for resolving and installing system dependencies,
# and `libscript_download` for robust file fetching with caching, checksum validation,
# and signature verification.
# 
# ## Usage
# Source this file to interact consistently with system-level package management
# and to safely fetch remote artifacts.


set -feu
# shellcheck disable=SC2296,SC3028,SC3040,SC3054
if [ "${SCRIPT_NAME-}" ]; then
  THIS_FILE="${SCRIPT_NAME}"
elif [ "${BASH_SOURCE-}" ]; then
  eval 'THIS_FILE="${BASH_SOURCE[0]}"'
  eval 'set -o pipefail'
elif [ "${ZSH_VERSION-}" ]; then
  eval 'THIS_FILE="${(%):-%x}"'
  eval 'set -o pipefail'
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

# Source logging
. "${LIBSCRIPT_ROOT_DIR}/_lib/_common/log.sh"

#DIR="$( dirname -- "$( readlink -nf -- "${0}" )")"

for LIB in "_lib/_common/os_info.sh" "_lib/_common/priv.sh" "_lib/_common/pkg_mapper.sh"; do
  SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}"'/'"${LIB}"
  export SCRIPT_NAME
  # shellcheck disable=SC1090,SC1091
  . "${SCRIPT_NAME}"
done

PKG_MGR_UPDATE_REGISTRY="${PKG_MGR_UPDATE_REGISTRY:-1}"
export PKG_MGR_UPDATE_REGISTRY

# ## libscript_resolve_install_method
# Executes libscript_resolve_install_method functionality.
libscript_resolve_install_method() {
  comp_method_var="${1}_INSTALL_METHOD"
  eval "requested=\${${comp_method_var}:-\${LIBSCRIPT_DEFAULT_INSTALL_METHOD:-}}"

  chain="libscript_native mise asdf pkgx vfox system"
  check_chain=""
  
  if [ -n "$requested" ]; then
    # Start chain from the requested method
    found=0
    for m in $chain; do
      if [ "$m" = "$requested" ]; then found=1; fi
      if [ "$found" = "1" ]; then
        check_chain="${check_chain:+$check_chain }$m"
      fi
    done
    # If requested method is not in our known chain, just check it directly then fallback to full chain
    if [ "$found" = "0" ]; then
      check_chain="$requested $chain"
    fi
  else
    check_chain="$chain"
  fi

  for m in $check_chain; do
    if [ "$m" = "libscript_native" ] || [ "$m" = "system" ]; then
      printf '%s\n' "$m"
      return 0
    fi
    if libscript_cmd_avail "$m"; then
      printf '%s\n' "$m"
      return 0
    fi
  done
  
  printf '%s\n' "system"
  return 0
}

# ## libscript_cmd_avail
# Executes libscript_cmd_avail functionality.
libscript_cmd_avail() {
  command -v -- "${1}" >/dev/null 2>&1
}

# ## detect_pkg_mgr
# Executes detect_pkg_mgr functionality.
detect_pkg_mgr() {
  if libscript_cmd_avail apt-get; then
    PKG_MGR='apt-get' # Debian, Ubuntu, and other derivatives
  elif libscript_cmd_avail apk; then
    PKG_MGR='apk' # Alpine Linux and derivatives
  elif libscript_cmd_avail dnf; then
    PKG_MGR='dnf'  # Red Hat and derivatives (preferred over `yum`)
  elif libscript_cmd_avail yum; then
    PKG_MGR='yum'  # Red Hat and derivatives
  elif libscript_cmd_avail pacman; then
    PKG_MGR='pacman'  # MSYS2
  elif libscript_cmd_avail zypper; then
    PKG_MGR='zypper' # OpenSUSE
  elif libscript_cmd_avail emerge; then
    PKG_MGR='emerge'  # Gentoo
  elif libscript_cmd_avail pkg; then
    PKG_MGR='pkg'  # FreeBSD
  elif libscript_cmd_avail port; then
    PKG_MGR='port'  # MacPorts
  elif libscript_cmd_avail brew; then
    PKG_MGR='brew'  # macOS and (rarely) Linux
  elif libscript_cmd_avail swupd; then
    PKG_MGR='swupd'  # Clear Linux
  elif libscript_cmd_avail xbps-install; then
    PKG_MGR='xbps'  # Void Linux
  elif libscript_cmd_avail eopkg; then
    PKG_MGR='eopkg'  # Solus
  else
    if [ "${TARGET_OS:-$(uname -s | tr '[:upper:]' '[:lower:]')}" = "darwin" ]; then
      if [ -f "${LIBSCRIPT_ROOT_DIR}/_lib/package-managers/brew/setup.sh" ]; then
        "${LIBSCRIPT_ROOT_DIR}/_lib/package-managers/brew/setup.sh"
        if libscript_cmd_avail brew; then PKG_MGR='brew'; export PKG_MGR; return; fi
      fi
    elif [ "${TARGET_OS:-$(uname -s | tr '[:upper:]' '[:lower:]')}" = "windows" ] || [ -n "${COMSPEC:-}" ]; then
      if [ -f "${LIBSCRIPT_ROOT_DIR}/_lib/package-managers/winget/setup.cmd" ]; then
        "${LIBSCRIPT_ROOT_DIR}/_lib/package-managers/winget/setup.cmd"
        if libscript_cmd_avail winget; then PKG_MGR='winget'; export PKG_MGR; return; fi
      fi
    else
      if [ -f "${LIBSCRIPT_ROOT_DIR}/_lib/package-managers/pkgx/setup.sh" ]; then
        "${LIBSCRIPT_ROOT_DIR}/_lib/package-managers/pkgx/setup.sh"
        if libscript_cmd_avail pkgx; then PKG_MGR='pkgx'; export PKG_MGR; return; fi
      fi
    fi
    log_error 'No supported package manager found'
    exit 1
  fi
  export PKG_MGR
}

# ## is_installed
# Executes is_installed functionality.
is_installed() {
  pkg="${1}"
  case "${PKG_MGR}" in
    'apk')                apk info -e "${pkg}" >/dev/null 2>&1 ;;
    'apt-get')            dpkg-query -W -f='${Status}\n' "${pkg}" 2>/dev/null | grep -q 'install ok installed' ;;
    'brew')               brew list --formula "${pkg}" >/dev/null 2>&1 ;;
    'dnf'|'yum'|'zypper') rpm -q "${pkg}" >/dev/null 2>&1 ;;
    'emerge')             eix -I "${pkg}" >/dev/null 2>&1 ;;
    'eopkg')              eopkg list-installed | grep -q '^'"${pkg}"'[[:space:]]' ;;
    'pacman')             pacman -Q "${pkg}" >/dev/null 2>&1 ;;
    'pkg')                pkg info -e "${pkg}" ;;
    'port')               port installed "${pkg}" | grep -q 'active' ;;
    'swupd')              swupd bundle-list | grep -qx "${pkg}" ;;
    'xbps')               xbps-query -Rs '^'"${pkg}"'$' | grep -q '\[installed\]' ;;
    *)
      log_error "is_installed function not implemented for ${PKG_MGR}"
      exit 1 ;;
  esac
}

# ## libscript_depends
# Executes libscript_depends functionality.
libscript_depends() {
  if [ "${LIBSCRIPT_SKIP_SYSTEM_DEPS:-0}" = "1" ]; then
    log_info "Skipping system dependencies due to LIBSCRIPT_SKIP_SYSTEM_DEPS=1"
    return 0
  fi
  pkgs_to_install=''
  for pkg in "$@"; do
    mapped_pkgs="$(map_package "${pkg}")" || {
      log_warn "Package \"${pkg}\" not available via package manager \"${PKG_MGR}\""
      return 1
    }
    for mapped_pkg in ${mapped_pkgs}; do
      # log_info "Checking if package is installed (${PKG_MGR}): ${mapped_pkg}"
      if ! is_installed "${mapped_pkg}"; then
        pkgs_to_install="${pkgs_to_install:+"${pkgs_to_install}" }${mapped_pkg}"
      fi
    done
  done
  if [ -n "${pkgs_to_install}" ]; then
    # log_info "Installing packages (${PKG_MGR}): "${pkgs_to_install}""
    _lockdir="${TMPDIR:-/tmp}/libscript_pkg_mgr_lock"
    _lock_timeout=600
    _lock_count=0
    while ! mkdir "$_lockdir" 2>/dev/null; do
      _lock_count=$((_lock_count + 1))
      if [ "$_lock_count" -gt "$_lock_timeout" ]; then
        log_error "Could not acquire package manager lock after ${_lock_timeout}s"
        return 1
      fi
      sleep 1
    done
    
    # Run in a subshell so if it exits early due to set -e, we can still remove the lock
    (
      _install_failed=0
      case "${PKG_MGR}" in
        'apt-get')
          export DEBIAN_FRONTEND='noninteractive'
          if [ "${PKG_MGR_UPDATE_REGISTRY}" -eq 1 ]; then
            priv  apt-get -o Dpkg::Lock::Timeout=120 update -qq || true
          fi
                  priv  apt-get -o Dpkg::Lock::Timeout=120 install -y    ${pkgs_to_install} || _install_failed=1 ;;
        'apk')    priv  apk add --no-cache    ${pkgs_to_install} || _install_failed=1 ;;
        'brew')         brew install          ${pkgs_to_install} || _install_failed=1 ;;
        'dnf')    priv  dnf install -y        ${pkgs_to_install} || _install_failed=1 ;;
        'emerge') priv  emerge --quiet        ${pkgs_to_install} || _install_failed=1 ;;
        'eopkg')  priv  eopkg install -y      ${pkgs_to_install} || _install_failed=1 ;;
        'pacman') priv  pacman -S --noconfirm ${pkgs_to_install} || _install_failed=1 ;;
        'pkg')    priv  pkg install -y        ${pkgs_to_install} || _install_failed=1 ;;
        'port')   priv  port install          ${pkgs_to_install} || _install_failed=1 ;;
        'swupd')  priv  swupd bundle-add      ${pkgs_to_install} || _install_failed=1 ;;
        'xbps')   priv  xbps-install -Sy      ${pkgs_to_install} || _install_failed=1 ;;
        'yum')    priv  yum install -y        ${pkgs_to_install} || _install_failed=1 ;;
        'zypper') priv  zypper install -y     ${pkgs_to_install} || _install_failed=1 ;;
        *)
          log_error "libscript_depends function not implemented for ${PKG_MGR}"
          exit 1
          ;;
      esac
      exit "$_install_failed"
    )
    _install_failed=$?

    rmdir "$_lockdir" 2>/dev/null || true
    if [ "$_install_failed" -ne 0 ]; then
      return 1
    fi
  fi
}

if [ "${PKG_MGR-}" ]; then
  detect_pkg_mgr
fi

# Unified Caching Downloader
libscript_download() {
  export url="${1:-}"
  dest="${2:-}"
  provided_checksum="${3:-}"

  if [ -z "$url" ]; then
    printf 'Error: URL required for libscript_download\n' >&2
    return 1
  fi

  if [ -z "$dest" ]; then dest="$(basename "$url")"; fi

  # 1. Checksum Resolution
  checksum_db="${LIBSCRIPT_ROOT_DIR}/_lib/checksums.txt"
  expected_checksum="$provided_checksum"
  checksum_from_db=0

  if [ -z "$expected_checksum" ] && [ -f "$checksum_db" ]; then
    db_match="$(grep -F "$url" "$checksum_db" | head -n 1 | awk '{print $2}' || true)"
    if [ -n "$db_match" ]; then
        expected_checksum="$db_match"
        checksum_from_db=1
    fi
  fi

  # Dynamic Checksum Fetching
  if [ -z "$expected_checksum" ] && [ -f "${LIBSCRIPT_ROOT_DIR}/_lib/_common/fetch_checksum.sh" ]; then
      fetched_checksum="$("${LIBSCRIPT_ROOT_DIR}/_lib/_common/fetch_checksum.sh" "$url" || true)"
      if [ -n "$fetched_checksum" ]; then
          expected_checksum="sha-256=$fetched_checksum"
          log_info "Fetched checksum dynamically: $fetched_checksum"
      else
          log_info "Warning: No checksum provided or found in DB/dynamically for $url"
      fi
  fi

  # 2. Aria2 Export Mode
  if [ -n "${LIBSCRIPT_ARIA2_EXPORT_FILE:-}" ]; then
    if [ ! -f "$LIBSCRIPT_ARIA2_EXPORT_FILE" ] || ! grep -F -x -q "$url" "$LIBSCRIPT_ARIA2_EXPORT_FILE"; then
      printf "%s\n" "$url" >> "$LIBSCRIPT_ARIA2_EXPORT_FILE"
      printf "  out=%s\n" "$(basename "$dest")" >> "$LIBSCRIPT_ARIA2_EXPORT_FILE"
      if [ -n "$expected_checksum" ]; then
        printf "  checksum=sha-256=%s\n" "${expected_checksum#sha-256=}" >> "$LIBSCRIPT_ARIA2_EXPORT_FILE"
      fi
    fi
    return 0
  fi

  # 3. Cache Path Resolution
  dl_dir="${DOWNLOAD_DIR:-}"
  cache_dir="${LIBSCRIPT_CACHE_DIR:-$LIBSCRIPT_ROOT_DIR/cache/downloads}"

  if [ -z "$dl_dir" ]; then
      dl_dir="$cache_dir"
      if [ -n "${PACKAGE_NAME:-}" ]; then
        dl_dir="$dl_dir/$PACKAGE_NAME"
      else
        dl_dir="$dl_dir/unknown"
      fi
  fi

  mkdir -p -- "$dl_dir"
  filename="$(basename "$url")"
  cache_file="$dl_dir/$filename"

  # 4. Cache Check & Download
  download_needed=1
  if [ -f "$cache_file" ]; then
    log_info "[CACHED] ${url}"
    download_needed=0
  fi

  if [ "$download_needed" -eq 1 ]; then
    log_info "[DOWNLOADING] ${url}"

    # Ensure tools are available
    if ! command -v aria2c >/dev/null 2>&1 && ! command -v curl >/dev/null 2>&1 && ! command -v wget >/dev/null 2>&1; then
        [ -f "${LIBSCRIPT_ROOT_DIR}/_lib/utilities/curl/setup.sh" ] && "${LIBSCRIPT_ROOT_DIR}/_lib/utilities/curl/setup.sh"
    fi

    download_success=0

    # Strategy A: aria2c
    if [ "$download_success" -eq 0 ] && command -v aria2c >/dev/null 2>&1; then
      if aria2c -d "$dl_dir" -o "$filename" --allow-overwrite=true "$url"; then download_success=1; fi
    fi

    # Strategy B: curl
    if [ "$download_success" -eq 0 ] && command -v curl >/dev/null 2>&1; then
      if curl -#fL -o "$cache_file" "$url"; then download_success=1; fi
    fi

    # Strategy C: wget
    if [ "$download_success" -eq 0 ] && command -v wget >/dev/null 2>&1; then
      if wget -q --show-progress -O "$cache_file" "$url"; then download_success=1; fi
    fi

    # Strategy D: nc/tcp fallbacks (HTTP only)
    if [ "$download_success" -eq 0 ] && printf '%s\n' "$url" | grep -q "^http://"; then
        host="${url#*://}"; path="/${host#*/}"; host="${host%%/*}"
        if command -v nc >/dev/null 2>&1; then
          printf "GET %s HTTP/1.0\r\nHost: %s\r\nConnection: close\r\n\r\n" "$path" "$host" | nc "$host" 80 > "${cache_file}.tmp"
          { while IFS= read -r line; do line="$(printf '%s\n' "$line" | tr -d '\r\n')"; [ -z "$line" ] && break; done; cat; } < "${cache_file}.tmp" > "$cache_file"
          rm -f "${cache_file}.tmp"
          download_success=1
        elif [ -e "/dev/tcp/$host/80" ]; then
          tcp_path="/dev/tcp/$host/80"
          if [ -e "$tcp_path" ]; then
            exec 3<>"$tcp_path"
            printf "GET %s HTTP/1.0\r\nHost: %s\r\nConnection: close\r\n\r\n" "$path" "$host" >&3
            { while IFS= read -r line <&3; do line="$(printf '%s\n' "$line" | tr -d '\r\n')"; [ -z "$line" ] && break; done; cat <&3; } > "$cache_file"
            exec 3<&-
            download_success=1
          fi
        fi
    fi

    if [ "$download_success" -eq 0 ]; then
      log_error "Failed to download ${url}"
      return 1
    fi

    # Verify size
    fsize=$(wc -c < "$cache_file" | tr -d ' ' 2>/dev/null || stat -c%s "$cache_file" 2>/dev/null || stat -f%z "$cache_file" 2>/dev/null || printf '%s\n' "1")
    if [ "$fsize" = "0" ]; then
      log_error "Downloaded file ${cache_file} is empty."
      rm -f "$cache_file"
      return 1
    fi
  fi

  # 5. Checksum Validation
  if [ -n "$expected_checksum" ] && [ "$expected_checksum" != "SKIP" ]; then
    actual_checksum=""
    clean_expected="${expected_checksum#sha-256=}"
    if command -v sha256sum >/dev/null 2>&1; then
      actual_checksum=$(sha256sum "$cache_file" | awk '{print $1}')
    elif command -v shasum >/dev/null 2>&1; then
      actual_checksum=$(shasum -a 256 "$cache_file" | awk '{print $1}')
    fi

    if [ -n "$actual_checksum" ]; then
      if [ "$actual_checksum" != "$clean_expected" ]; then
        log_error "Checksum mismatch for ${url}. Expected: ${clean_expected}, Got: ${actual_checksum}"
        rm -f "$cache_file"
        return 1
      fi
    fi
  elif [ -n "$cache_file" ] && [ "${LIBSCRIPT_NEVER_REFRESH_CHECKSUM_DB:-0}" != "1" ] && [ -f "$cache_file" ]; then
    # Auto-populate checksum DB if missing
    if command -v sha256sum >/dev/null 2>&1; then
        printf '%s\n' "$url $(sha256sum "$cache_file" | awk '{print $1}')" >> "$checksum_db"
    fi
  fi

  # Auto-populate DB with dynamically fetched checksum if we didn't have it in DB
  if [ "$checksum_from_db" -eq 0 ] && [ -n "$expected_checksum" ] && [ "$expected_checksum" != "SKIP" ]; then
    if [ "${LIBSCRIPT_DISABLE_CHECKSUM_TXT_UPDATE:-0}" != "1" ]; then
       log_info "Updating _lib/checksums.txt with fetched checksum for $url"
       printf '%s\n' "$url ${expected_checksum#sha-256=}" >> "$checksum_db"
    fi
  fi

  # Signature Verification
  if [ -f "${LIBSCRIPT_ROOT_DIR}/_lib/_common/verify_signature.sh" ]; then
      if ! "${LIBSCRIPT_ROOT_DIR}/_lib/_common/verify_signature.sh" "$cache_file" "$url"; then
          log_error "Signature verification failed for ${url}"
          rm -f "$cache_file"
          return 1
      fi
  fi

  # 6. Final Placement
  if [ -n "$dest" ] && [ "$dest" != "$cache_file" ]; then
    mkdir -p "$(dirname "$dest")"
    if ! [ "$cache_file" -ef "$dest" ]; then
      cp "$cache_file" "$dest"
    fi
  fi
}

# ## libscript_fetch
# Executes libscript_fetch functionality.
libscript_fetch() {
  libscript_download "$@"
}


# ## libscript_process_aria2_file
# Executes libscript_process_aria2_file functionality.
libscript_process_aria2_file() {
  list_file="${1:-}"
  if [ -z "$list_file" ] || [ ! -f "$list_file" ]; then
    log_error "File not found: ${list_file}"
    return 1
  fi

  export url=""
  out=""
  checksum=""

  process_entry() {
    if [ -n "$url" ]; then
      log_info "Processing $url ..."
      libscript_download "$url" "$out" "$checksum"
    fi
    export url=""
    out=""
    checksum=""
  }

  while IFS= read -r line || [ -n "$line" ]; do
    # skip empty lines safely
    [ -z "$(printf '%s\n' "$line" | tr -d '[:space:]')" ] && continue

    if printf '%s\n' "$line" | grep -q '^[[:space:]]'; then

      opt="$(printf '%s\n' "$line" | sed 's/^[[:space:]]*//')"
      if printf '%s\n' "$opt" | grep -q '^out='; then
        out="${opt#out=}"
      elif printf '%s\n' "$opt" | grep -q '^checksum='; then
        checksum="${opt#checksum=}"
      fi
    else
      process_entry
      export url="$line"
    fi
  done < "$list_file"
  process_entry
}
