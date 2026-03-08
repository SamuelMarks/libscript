#!/bin/sh
# shellcheck disable=SC3054,SC3040,SC2296,SC2128,SC2039,SC2016,SC1090,SC1091,SC2034,SC2018,SC2019,SC2221,SC2222,SC2129,SC2209,SC2089,SC2090,SC2086,SC2154,SC2044,SC2181,SC2038,SC2155,SC2046,SC2002,SC1003,SC2295,SC2145



set -feu
if [ "${SCRIPT_NAME-}" ]; then
  this_file="${SCRIPT_NAME}"
elif [ "${BASH_SOURCE-}" ]; then
  this_file="${BASH_SOURCE}"

elif [ "${ZSH_VERSION-}" ]; then
  this_file="${0}"

else
  this_file="${0}"
fi

case "${STACK+x}" in
  *':'"${this_file}"':'*)
    printf '[STOP]     processing "%s"\n' "${this_file}"
    if (return 0 2>/dev/null); then return; else exit 0; fi ;;
  *) printf '[CONTINUE] processing "%s"\n' "${this_file}" ;;
esac
export STACK="${STACK:-}${this_file}"':'

_PKG_MGR_DIR=$(CDPATH='' cd -- "$(dirname -- "${this_file}")" && pwd)

LIBSCRIPT_ROOT_DIR="${LIBSCRIPT_ROOT_DIR:-$(d="${_PKG_MGR_DIR}"; while [ ! -f "${d}"'/ROOT' ]; do d="$(dirname -- "${d}")"; done; printf '%s' "${d}")}"

#DIR="$( dirname -- "$( readlink -nf -- "${0}" )")"

for lib in '_lib/_common/os_info.sh' '_lib/_common/priv.sh' '_lib/_common/pkg_mapper.sh'; do
  SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}"'/'"${lib}"
  export SCRIPT_NAME
  # shellcheck disable=SC1090
# shellcheck disable=SC1090,SC1091,SC2034
  . "${SCRIPT_NAME}"
done

PKG_MGR_UPDATE_REGISTRY="${PKG_MGR_UPDATE_REGISTRY:-1}"
export PKG_MGR_UPDATE_REGISTRY

cmd_avail() {
  command -v -- "${1}" >/dev/null 2>&1
}

detect_pkg_mgr() {
  if cmd_avail apt-get; then
    PKG_MGR='apt-get' # Debian, Ubuntu, and other derivatives
  elif cmd_avail apk; then
    PKG_MGR='apk' # Alpine Linux and derivatives
  elif cmd_avail dnf; then
    PKG_MGR='dnf'  # Red Hat and derivatives (preferred over `yum`)
  elif cmd_avail yum; then
    PKG_MGR='yum'  # Red Hat and derivatives
  elif cmd_avail pacman; then
    PKG_MGR='pacman'  # MSYS2
  elif cmd_avail zypper; then
    PKG_MGR='zypper' # OpenSUSE
  elif cmd_avail emerge; then
    PKG_MGR='emerge'  # Gentoo
  elif cmd_avail pkg; then
    PKG_MGR='pkg'  # FreeBSD
  elif cmd_avail port; then
    PKG_MGR='port'  # MacPorts
  elif cmd_avail brew; then
    PKG_MGR='brew'  # macOS and (rarely) Linux
  elif cmd_avail swupd; then
    PKG_MGR='swupd'  # Clear Linux
  elif cmd_avail xbps-install; then
    PKG_MGR='xbps'  # Void Linux
  elif cmd_avail eopkg; then
    PKG_MGR='eopkg'  # Solus
  else
    if [ "${TARGET_OS:-$(uname -s | tr '[:upper:]' '[:lower:]')}" = "darwin" ]; then
      if [ -f "${LIBSCRIPT_ROOT_DIR}/_lib/package-managers/brew/setup.sh" ]; then
        "${LIBSCRIPT_ROOT_DIR}/_lib/package-managers/brew/setup.sh"
        if cmd_avail brew; then PKG_MGR='brew'; export PKG_MGR; return; fi
      fi
    elif [ "${TARGET_OS:-$(uname -s | tr '[:upper:]' '[:lower:]')}" = "windows" ] || [ -n "${COMSPEC:-}" ]; then
      if [ -f "${LIBSCRIPT_ROOT_DIR}/_lib/package-managers/winget/setup.cmd" ]; then
        "${LIBSCRIPT_ROOT_DIR}/_lib/package-managers/winget/setup.cmd"
        if cmd_avail winget; then PKG_MGR='winget'; export PKG_MGR; return; fi
      fi
    else
      if [ -f "${LIBSCRIPT_ROOT_DIR}/_lib/package-managers/pkgx/setup.sh" ]; then
        "${LIBSCRIPT_ROOT_DIR}/_lib/package-managers/pkgx/setup.sh"
        if cmd_avail pkgx; then PKG_MGR='pkgx'; export PKG_MGR; return; fi
      fi
    fi
    >&2 printf 'Error: No supported package manager found\n'
    exit 1
  fi
  export PKG_MGR
}

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
      >&2 printf 'Error: is_installed function not implemented for %s\n' "${PKG_MGR}"
      exit 1 ;;
  esac
}

depends() {
  pkgs_to_install=''
  for pkg in "$@"; do
    mapped_pkgs="$(map_package "${pkg}")" || {
      >&2 printf 'Warning: Package "%s" not available via package manager "%s"\n' "${pkg}" "${PKG_MGR}"
      return 1
    }
    for mapped_pkg in ${mapped_pkgs}; do
      # >&2 printf 'Checking if package is installed (%s): %s\n' "${PKG_MGR}" "${mapped_pkg}"
      if ! is_installed "${mapped_pkg}"; then
        pkgs_to_install="${pkgs_to_install:+"${pkgs_to_install}" }${mapped_pkg}"
      fi
    done
  done
  if [ -n "${pkgs_to_install}" ]; then
    # >&2 printf 'Installing packages (%s): %s\n' "${PKG_MGR}" "${pkgs_to_install}"
    case "${PKG_MGR}" in
      'apt-get')
        export DEBIAN_FRONTEND='noninteractive'
        if [ "${PKG_MGR_UPDATE_REGISTRY}" -eq 1 ]; then
          priv  apt-get update -qq
        fi
                priv  apt-get install -y    ${pkgs_to_install} ;;
      'apk')    priv  apk add --no-cache    ${pkgs_to_install} ;;
      'brew')         brew install          ${pkgs_to_install} ;;
      'dnf')    priv  dnf install -y        ${pkgs_to_install} ;;
      'emerge') priv  emerge --quiet        ${pkgs_to_install} ;;
      'eopkg')  priv  eopkg install -y      ${pkgs_to_install} ;;
      'pacman') priv  pacman -S --noconfirm ${pkgs_to_install} ;;
      'pkg')    priv  pkg install -y        ${pkgs_to_install} ;;
      'port')   priv  port install          ${pkgs_to_install} ;;
      'swupd')  priv  swupd bundle-add      ${pkgs_to_install} ;;
      'xbps')   priv  xbps-install -Sy      ${pkgs_to_install} ;;
      'yum')    priv  yum install -y        ${pkgs_to_install} ;;
      'zypper') priv  zypper install -y     ${pkgs_to_install} ;;
      *)
        >&2 printf 'Error: depends function not implemented for %s\n' "${PKG_MGR}"
        exit 1
        ;;
    esac
  fi
}

if [ "${PKG_MGR-}" ]; then
  detect_pkg_mgr
fi

# Caching downloader hook
libscript_fetch() {
  url="$1"
  dest="${2:-}"
  expected_checksum="${3:-}"
  # Optional: allow override of download dir or fallback to global cache dir
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
  # Sometimes urls end in text/scripts without nice extensions. This is basic caching.
cache_file="$dl_dir/$filename"

  if [ -f "$cache_file" ]; then
    >&2 printf '[CACHED] %s\n' "$url"
  else
    >&2 printf '[DOWNLOADING] %s\n' "$url"
    if ! command -v curl >/dev/null 2>&1 && ! command -v wget >/dev/null 2>&1; then
      if [ -f "${LIBSCRIPT_ROOT_DIR}/_lib/utilities/curl/setup.sh" ]; then
        "${LIBSCRIPT_ROOT_DIR}/_lib/utilities/curl/setup.sh"
      elif [ -f "${LIBSCRIPT_ROOT_DIR}/_lib/utilities/wget/setup.sh" ]; then
        "${LIBSCRIPT_ROOT_DIR}/_lib/utilities/wget/setup.sh"
      fi
    fi

    if command -v curl >/dev/null 2>&1; then
      curl -#L "$url" -o "$cache_file"
    elif command -v wget >/dev/null 2>&1; then
      wget -q --show-progress -O "$cache_file" "$url"
    else
      >&2 printf 'Error: curl or wget required.\n'
      return 1
    fi

    # Check filesize > 0
  fsize=0
    if command -v wc >/dev/null 2>&1; then
      fsize=$(wc -c < "$cache_file" | tr -d ' ')
    elif command -v stat >/dev/null 2>&1; then
      # BSD/macOS stat vs GNU stat
      fsize=$(stat -c%s "$cache_file" 2>/dev/null || stat -f%z "$cache_file" 2>/dev/null || echo "1")
    fi
    if [ "$fsize" = "0" ]; then
      >&2 printf 'Error: Downloaded file %s is empty.\n' "$cache_file"
      rm -f "$cache_file"
      return 1
    fi
  fi

  # Checksum validation
  if [ -n "$expected_checksum" ]; then
  actual_checksum=""
    if command -v sha256sum >/dev/null 2>&1; then
      actual_checksum=$(sha256sum "$cache_file" | awk '{print $1}')
    elif command -v shasum >/dev/null 2>&1; then
      actual_checksum=$(shasum -a 256 "$cache_file" | awk '{print $1}')
    else
      >&2 printf 'Warning: sha256sum/shasum not found, skipping checksum validation.\n'
    fi
    if [ -n "$actual_checksum" ] && [ "$actual_checksum" != "$expected_checksum" ]; then
      >&2 printf 'Error: Checksum mismatch for %s. Expected: %s, Got: %s\n' "$cache_file" "$expected_checksum" "$actual_checksum"
      rm -f "$cache_file"
      return 1
    fi
  fi
  
  if [ -n "$dest" ]; then
    cp "$cache_file" "$dest"
  fi
}


libscript_download() {
  url="$1"
  out_file="$2"
  provided_checksum="${3:-}"
  
  if [ -z "$out_file" ]; then out_file="$(basename "$url")"; fi
  
  # Ensure LIBSCRIPT_CHECKSUM_DB is defined
  checksum_db="${LIBSCRIPT_ROOT_DIR}/checksums.txt"
  
  expected_checksum="$provided_checksum"
  if [ -z "$expected_checksum" ] && [ -f "$checksum_db" ]; then
    # try to find the checksum
    expected_checksum="$(grep -F "$url" "$checksum_db" | head -n 1 | awk '{print $2}')"
  fi
  
  # if --export-aria2-downloads is set, just write to it and return
  if [ -n "${LIBSCRIPT_ARIA2_EXPORT_FILE:-}" ]; then
    printf "%s\n" "$url" >> "$LIBSCRIPT_ARIA2_EXPORT_FILE"
    printf "  out=%s\n" "$(basename "$out_file")" >> "$LIBSCRIPT_ARIA2_EXPORT_FILE"
    if [ -n "$expected_checksum" ]; then
      printf "  checksum=sha-256=%s\n" "${expected_checksum#sha-256=}" >> "$LIBSCRIPT_ARIA2_EXPORT_FILE"
    fi
    return 0
  fi
  
  download_success=0

  # 1. aria2c
  if [ "$download_success" -eq 0 ] && command -v aria2c >/dev/null 2>&1; then
    # aria2c can fail if directory exists but is a file, handle normally
    if aria2c -d "$(dirname "$out_file")" -o "$(basename "$out_file")" --allow-overwrite=true "$url"; then
      download_success=1
    fi
  fi

  # 2. curl
  if [ "$download_success" -eq 0 ] && ! command -v curl >/dev/null 2>&1 && ! command -v wget >/dev/null 2>&1; then
    if [ -f "${LIBSCRIPT_ROOT_DIR}/_lib/utilities/curl/setup.sh" ]; then
      "${LIBSCRIPT_ROOT_DIR}/_lib/utilities/curl/setup.sh"
    elif [ -f "${LIBSCRIPT_ROOT_DIR}/_lib/utilities/wget/setup.sh" ]; then
      "${LIBSCRIPT_ROOT_DIR}/_lib/utilities/wget/setup.sh"
    fi
  fi

  if [ "$download_success" -eq 0 ] && command -v curl >/dev/null 2>&1; then
    if curl -fL -o "$out_file" "$url"; then
      download_success=1
    fi
  fi

  # 3. wget
  if [ "$download_success" -eq 0 ] && command -v wget >/dev/null 2>&1; then
    if wget -O "$out_file" "$url"; then
      download_success=1
    fi
  fi

  # 4. nc (netcat) fallback for HTTP (does not support HTTPS natively without OpenSSL, but we try)
  if [ "$download_success" -eq 0 ] && command -v nc >/dev/null 2>&1; then
  host="${url#*://}"
  path="/${host#*/}"
    host="${host%%/*}"
    if echo "$url" | grep -q "^http://"; then
      printf "GET %s HTTP/1.0\r\nHost: %s\r\nConnection: close\r\n\r\n" "$path" "$host" | nc "$host" 80 > "${out_file}.tmp"
      # safely strip headers
      {
        while IFS= read -r line; do
          line="$(echo "$line" | tr -d '\r\n')"
          [ -z "$line" ] && break
        done
        cat
      } < "${out_file}.tmp" > "$out_file"
      rm -f "${out_file}.tmp"
      download_success=1
    fi
  fi

  # 5. /dev/tcp native bash fallback
  if [ "$download_success" -eq 0 ]; then
  host="${url#*://}"
  path="/${host#*/}"
    host="${host%%/*}"
    if echo "$url" | grep -q "^http://"; then
      # shellcheck disable=SC3025
      if exec 3<>/dev/tcp/"$host"/80 2>/dev/null; then
        printf "GET %s HTTP/1.0\r\nHost: %s\r\nConnection: close\r\n\r\n" "$path" "$host" >&3
        {
          while IFS= read -r line <&3; do
            line="$(echo "$line" | tr -d '\r\n')"
            [ -z "$line" ] && break
          done
          cat <&3
        } > "$out_file"
        exec 3<&-
        download_success=1
      fi
    fi
  fi

  if [ "$download_success" -eq 0 ]; then
    echo "Error: Failed to download $url via aria2c, curl, wget, nc, or /dev/tcp." >&2
    return 1
  fi
  
  # Checksum handling
  # Compute sha256
  actual_checksum=""
  if command -v sha256sum >/dev/null 2>&1; then
    actual_checksum="$(sha256sum "$out_file" | awk '{print $1}')"
  elif command -v shasum >/dev/null 2>&1; then
    actual_checksum="$(shasum -a 256 "$out_file" | awk '{print $1}')"
  fi
  
  if [ -n "$actual_checksum" ]; then
  stripped_expected="${expected_checksum#sha-256=}"
    if [ -n "$stripped_expected" ] && [ "$stripped_expected" != "SKIP" ]; then
      if [ "$actual_checksum" != "$stripped_expected" ]; then
        echo "Error: checksum mismatch for $url" >&2
        echo "Expected: $stripped_expected" >&2
        echo "Actual:   $actual_checksum" >&2
        return 1
      fi
    else
      # Not found, add it if not prevented
      if [ "${LIBSCRIPT_NEVER_REFRESH_CHECKSUM_DB:-0}" != "1" ]; then
        echo "$url $actual_checksum" >> "$checksum_db"
      fi
    fi
  fi
}

libscript_process_aria2_file() {
list_file="$1"
  if [ ! -f "$list_file" ]; then
    echo "Error: File not found: $list_file" >&2
    return 1
  fi

  url=""
  out=""
  checksum=""

  process_entry() {
    if [ -n "$url" ]; then
      echo "Processing $url ..."
      libscript_download "$url" "$out" "$checksum"
    fi
    url=""
    out=""
    checksum=""
  }

  while IFS= read -r line || [ -n "$line" ]; do
    # skip empty lines safely
    [ -z "$(echo "$line" | tr -d '[:space:]')" ] && continue
    
    if echo "$line" | grep -q '^[[:space:]]'; then
opt
      opt="$(echo "$line" | sed 's/^[[:space:]]*//')"
      if echo "$opt" | grep -q '^out='; then
        out="${opt#out=}"
      elif echo "$opt" | grep -q '^checksum='; then
        checksum="${opt#checksum=}"
      fi
    else
      process_entry
      url="$line"
    fi
  done < "$list_file"
  process_entry
}
