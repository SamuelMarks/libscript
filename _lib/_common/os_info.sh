#!/bin/sh
# ## Overview
# Detects and exports essential operating system information. It reliably determines architecture (`ARCH`), OS variant (`TARGET_OS`), package manager (`PKG_MGR`), and init system (`INIT_SYS`) across diverse environments (Linux, macOS, Windows/Cygwin/MSYS, FreeBSD).
# ## Usage
# Source this file to populate standard OS-detection environment variables for cross-platform conditional logic.
set -feu
_oi_caller_this="${THIS_FILE:-}"; _oi_caller_dir="${SCRIPT_DIR:-}"
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
    if [ "${LIBSCRIPT_DEBUG:-0}" = '1' ]; then printf '[STOP]     processing "%s"\n' "${THIS_FILE}" >&2; fi
    [ -n "$_oi_caller_this" ] && THIS_FILE="$_oi_caller_this"
    [ -n "$_oi_caller_dir" ] && SCRIPT_DIR="$_oi_caller_dir"
    unset SCRIPT_NAME || true; if (return 0 2>/dev/null); then return; else exit 0; fi ;;
  *) if [ "${LIBSCRIPT_DEBUG:-0}" = '1' ]; then printf '[CONTINUE] processing "%s"\n' "${THIS_FILE}" >&2; fi ;;
esac
export STACK="${STACK:-}${THIS_FILE}"':'
SCRIPT_DIR=$(cd -- "$(dirname -- "${THIS_FILE}")" && pwd)
: "${LIBSCRIPT_ROOT_DIR:=$(d="$SCRIPT_DIR"; while [ ! -f "$d/libscript.sh" ]; do n="${d%/*}"; [ -z "$n" ] && n="/"; [ "$d" = "$n" ] && break; d="$n"; done; printf '%s\n' "$d")}"
if [ -z "${ARCH+x}" ]; then
  case "${LIBSCRIPT_TARGET_OS:-}" in
    msdos|dos|dos32)
      ARCH="${LIBSCRIPT_TARGET_ARCH:-i386}"
      export ARCH_ALT='dos32'
      export ARCH
      ;;
    *)
      ARCH="${LIBSCRIPT_TARGET_ARCH:-$(uname -m 2>/dev/null || printf 'x86_64')}"
      case "${ARCH}" in
        'aarch64') export ARCH_ALT='arm64' ;;
        *) export ARCH_ALT="${ARCH}" ;;
      esac
      export ARCH
      ;;
  esac
fi

if [ -z "${KERNEL_RELEASE+x}" ]; then
  KERNEL_RELEASE="$(uname -r 2>/dev/null || printf 'unknown')"
  export KERNEL_RELEASE
fi

if [ -z "${UNAME_A+x}" ]; then
  UNAME_A="$(uname -a 2>/dev/null || printf 'unknown')"
  export UNAME_A
fi

if [ -z "${UNAME+x}" ]; then
    if [ -n "${LIBSCRIPT_TARGET_OS:-}" ]; then
      case "${LIBSCRIPT_TARGET_OS}" in
        darwin|macos) UNAME='Darwin' ;;
        freebsd) UNAME='FreeBSD' ;;
        sunos|illumos|solaris) UNAME='SunOS' ;;
        reactos) UNAME='ReactOS' ;;
        windows) UNAME='Windows_NT' ;;
        msdos|dos|dos32) UNAME='MS-DOS' ;;
        *) UNAME="$(uname 2>/dev/null || printf 'Linux')" ;;
      esac
    else
      UNAME="$(uname 2>/dev/null || printf 'Linux')"
    fi
    UNAME_LOWER="$(printf '%s' "${UNAME}" | tr '[:upper:]' '[:lower:]')"
    export UNAME_LOWER
    case "${UNAME}" in
      'Darwin')
        export PKG_MGR='brew'
        export HOMEBREW_INSTALL="${HOMEBREW_INSTALL:-1}"
        TARGET_OS='darwin'
        TARGET_OS_NAME="$(sw_vers --productName 2>/dev/null || printf 'macOS')"
        export TARGET_OS_NAME
        ;;
      'Linux')
        _oi_os_rel="${LIBSCRIPT_OS_RELEASE_FILE:-/etc/os-release}"
        if [ -f "$_oi_os_rel" ]; then
          # shellcheck disable=SC1090,SC1091
          ID="$(. "$_oi_os_rel"; printf '%s' "${ID:-linux}")"
          # shellcheck disable=SC1090,SC1091
          ID_LIKE="$(. "$_oi_os_rel"; printf '%s' "${ID_LIKE-}")"
        else
          ID='linux'
          ID_LIKE=''
        fi
        unset _oi_os_rel || true
        case "${ID}" in
          'alpine') export PKG_MGR='apk' ;;
          'arch'|'manjaro'|'endeavouros') export PKG_MGR='pacman' ;;
          'debian'|'ubuntu'|'linuxmint'|'pop') export PKG_MGR='apt-get' ;;
          'opensuse'*|'sles') export PKG_MGR='zypper' ;;
          'void') export PKG_MGR='xbps-install' ;;
          'gentoo') export PKG_MGR='emerge' ;;
          'solus') export PKG_MGR='eopkg' ;;
          'rhel'|'rocky'|'rockylinux'|'almalinux'|'centos'|'fedora'|'amzn'|'ol') export PKG_MGR='dnf' ;;
          *)
            case "${ID_LIKE}" in
              *'arch'*) export PKG_MGR='pacman' ;;
              *'debian'*|*'ubuntu'*) export PKG_MGR='apt-get' ;;
              *'rhel'*|*'fedora'*|*'centos'*) export PKG_MGR='dnf' ;;
              *'suse'*) export PKG_MGR='zypper' ;;
              *'void'*) export PKG_MGR='xbps-install' ;;
              *'gentoo'*) export PKG_MGR='emerge' ;;
              *) ;;
            esac
          ;;
        esac

        TARGET_OS="${ID:-linux}"
        case "${PKG_MGR:-}" in
          'apk') TARGET_OS='alpine' ;;
          'apt-get')
            TARGET_OS='debian'
            export DEBIAN_FRONTEND='noninteractive' ;;
          'dnf'|'yum') TARGET_OS='rhel' ;;
          'pacman') TARGET_OS='arch' ;;
          'zypper') TARGET_OS='opensuse' ;;
          'xbps-install') TARGET_OS='void' ;;
          'emerge') TARGET_OS='gentoo' ;;
          'eopkg') TARGET_OS='solus' ;;
          *)
            >&2 printf 'Unimplemented, package manager for %s\n' "${TARGET_OS}"
            exit 3
            ;;
        esac
        ;;

      'CYGWIN_NT'*)
        export PKG_MGR='apt-cyg'
        TARGET_OS='cygwin'
        ;;
      'MINGW'* | 'MSYS'*)
        export PKG_MGR='pacman'
        TARGET_OS='mingw'
        ;;
      'Windows_NT')
        export PKG_MGR="${LIBSCRIPT_WINDOWS_PKG_MGR:-winget}"
        TARGET_OS='windows'
        ;;
      'MS-DOS'|'DOS'*|'FreeDOS'*|'DJGPP'*)
        export PKG_MGR="${LIBSCRIPT_PKG_MGR:-libscript}"
        export IS_MSDOS='1'
        export TARGET_OS_FLAVOR='msdos'
        export ARCH_ALT='dos32'
        TARGET_OS='msdos'
        ;;
      'ReactOS')
        export PKG_MGR="${LIBSCRIPT_REACTOS_PKG_MGR:-rapps}"
        export IS_REACTOS='1'
        export TARGET_OS_FLAVOR='reactos'
        TARGET_OS='reactos'
        ;;
      'FreeBSD')
        export PKG_MGR='pkg'
        TARGET_OS='freebsd' ;;
      'SunOS'|'illumos'|'Solaris')
        export PKG_MGR='pkg'
        TARGET_OS='sunos' ;;
      *)
        >&2 printf 'Unimplemented for %s\n' "${UNAME}"
        exit 3
        ;;
    esac
    export UNAME
    export TARGET_OS
fi

if [ -z "${UNAME_LOWER+x}" ]; then
  UNAME_LOWER="$(printf '%s' "${UNAME}" | tr '[:upper:]' '[:lower:]')"
  export UNAME_LOWER
fi

# ## _fallback
# Determines the init system by inspecting /proc/1/comm when standard service probes do not match.
_fallback() {
  possible="$(cat -- '/proc/1/comm')"
  if [ "${possible}" = 'systemd' ]; then
    export INIT_SYS='systemd'
    return
  fi
  case "$(stat -- "$(command -v "${possible}")" | awk 'NR==1{ print $NF }')" in
    # case "$(stat -- '/sbin/init' | awk 'NR==1{ print $NF }')" in
    'busybox'|*'/busybox')
      # https://en.wikipedia.org/wiki/BusyBox
      export INIT_SYS='busybox' ;;
    *'/systemd')
      # https://en.wikipedia.org/wiki/Systemd
      export INIT_SYS='systemd' ;;
    *)
      >&2 printf 'Unable to determine init system\n'
      return 2 ;;
  esac
}

if [ -z "${INIT_SYS+x}" ]; then
  if [ "${UNAME}" = 'Darwin' ]; then
    # https://en.wikipedia.org/wiki/Launchd
    export INIT_SYS='launchd'
  elif [ "${UNAME}" = 'Linux' ] && [ -f '/sbin/openrc-run' ]; then
    # https://en.wikipedia.org/wiki/OpenRC
    export INIT_SYS='openrc'
  else
    case "${UNAME}" in
        'Linux')
          if [ ! -f '/sbin/init' ]; then
            comm_name="$(cat -- '/proc/1/comm' 2>/dev/null || true)"
            comm_path="$(command -v "${comm_name}" 2>/dev/null || true)"
            if [ -n "${comm_path}" ]; then
              proc_comm="$(stat -- "${comm_path}" 2>/dev/null | awk 'NR==1{ print $NF }' || true)"
            else
              proc_comm="${comm_name}"
            fi
            case "${proc_comm}" in
                *'/bin/sh'|'dash'|'bash')
                  >&2 printf 'No init system setup\n'
                  export INIT_SYS='none' ;;
                *)
                  >&2 printf 'Unable to determine init system out of "%s"\n' "${proc_comm}"
                  export INIT_SYS='none' ;;
            esac
          elif [ -f '/etc/inittab' ]; then
            case "$(grep -F '::sysinit:' '/etc/inittab' | awk -F':/' '{print "/" $2}' | awk '{print $1}')" in
              '/sbin/openrc'|*'/openrc')
                # https://en.wikipedia.org/wiki/OpenRC
                export INIT_SYS='openrc' ;;
              *)
                _fallback
            esac
          else
            _fallback
          fi
          ;;

      'CYGWIN_NT'*)
        export INIT_SYS='windows-scm'
        ;;
      'MINGW'* | 'MSYS'*)
        export INIT_SYS='windows-scm'
        ;;
      'Windows_NT')
        export INIT_SYS='windows-scm'
        ;;
      'MS-DOS'|'DOS'*|'FreeDOS'*|'DJGPP'*)
        export INIT_SYS='none'
        ;;
      'ReactOS')
        export INIT_SYS='nt-scm'
        ;;
      'FreeBSD')
          if [ -d '/etc/inittab' ]; then
            export INIT_SYS='systemv_init'
          elif [ -f '/sbin/init' ]; then
            export INIT_SYS='bsd_init'
          else
            export INIT_SYS='bsd_init'
          fi
          ;;
      'SunOS'|'illumos'|'Solaris')
          if command -v svcadm >/dev/null 2>&1; then
            export INIT_SYS='smf'
          else
            export INIT_SYS='none'
          fi
          ;;
        *)
          >&2 printf 'TODO: *BSD, minix, SunOS, illumos, &etc.\n'
          export INIT_SYS='none' ;;
    esac
  fi
fi

STACK="${STACK%"${THIS_FILE}":}"
export STACK
[ -n "${_oi_caller_dir:-}" ] && SCRIPT_DIR="$_oi_caller_dir"
[ -n "${_oi_caller_this:-}" ] && THIS_FILE="$_oi_caller_this"
unset SCRIPT_NAME _oi_caller_this _oi_caller_dir || true
