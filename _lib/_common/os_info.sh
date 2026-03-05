#!/bin/sh
# shellcheck disable=SC2016,SC1090,SC1091,SC2034,SC2018,SC2019,SC2221,SC2222,SC2129,SC2209,SC2089,SC2090,SC2086,SC2154,SC2044,SC2181,SC2038,SC2155,SC2046,SC2002,SC1003,SC2295,SC2145



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

if [ -z ${ARCH+x} ]; then
  ARCH="$(uname -m)"
  case "${ARCH}" in
    'aarch64') export ARCH_ALT='arm64' ;;
    *) export ARCH_ALT="${ARCH}" ;;
  esac
  export ARCH
fi

if [ -z ${UNAME+x} ]; then
    UNAME="$(uname)"
    UNAME_LOWER="$(printf '%s' "${UNAME}" | tr '[:upper:]' '[:lower:]')"
    export UNAME_LOWER
    case "${UNAME}" in
      'Darwin')
        export PKG_MGR='brew'
        export HOMEBREW_INSTALL="${HOMEBREW_INSTALL:-1}"
        export NGINX_SERVERS_ROOT='/opt/homebrew/etc/nginx/servers'
        if [ ! -f '/opt/homebrew/bin/brew' ] && [ ! -f '/usr/local/bin/brew' ]; then
          NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        fi
        TARGET_OS="$(sw_vers --productName)"
        ;;
      'Linux')
        # shellcheck disable=SC1091
        ID="$(. /etc/os-release; printf '%s' "${ID}")"
        # shellcheck disable=SC1091
        ID_LIKE="$(. /etc/os-release; printf '%s' "${ID_LIKE-}")"
        export NGINX_SERVERS_ROOT='/etc/nginx/conf.d/sites-available'
        case "${ID}" in
          'alpine') export PKG_MGR='apk' ;;
          'arch') export PKG_MGR='pacman' ;;
          'debian') export PKG_MGR='apt-get' ;;
          'opensuse') export PKG_MGR='zypper' ;;
          'rhel') export PKG_MGR='dnf' ;;
          *)
            case "${ID_LIKE}" in
              'arch') export PKG_MGR='pacman' ;;
              *'debian'*) export PKG_MGR='apt-get' ;;
              *'rhel'*) export PKG_MGR='dnf' ;;
              *'suse'*) export PKG_MGR='zypper' ;;
              *) ;;
            esac
          ;;
        esac

        case "${PKG_MGR}" in
          'apk') TARGET_OS='alpine' ;;
          'apt-get')
            TARGET_OS='debian'
            export DEBIAN_FRONTEND='noninteractive' ;;
          'dnf') TARGET_OS='rhel' ;;
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
      'FreeBSD')
        export PKG_MGR='pkg'
        TARGET_OS='freebsd' ;;
      *)
        >&2 printf 'Unimplemented for %s\n' "${UNAME}"
        exit 3
        ;;
    esac
    printf 'UNAME="%s"; TARGET_OS="%s"\n' "${UNAME}" "${TARGET_OS}"
    export UNAME
    export TARGET_OS
fi

if [ -z "${UNAME+x}" ]; then
  UNAME="$(uname)"
fi

_fallback() {
  possible="$(cat -- '/proc/1/comm')"
  if [ "${possible}" = 'systemd' ]; then
    export INIT_SYS='systemd'
    return
  fi
  case "$(stat -- "$(which -- "${possible}")" | awk 'NR==1{ print $NF }')" in
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
  if [ -f '/bin/launchctl' ]; then
    # https://en.wikipedia.org/wiki/Launchd
    export INIT_SYS='launchd'
  elif [ -f '/sbin/openrc-run' ]; then
    # https://en.wikipedia.org/wiki/OpenRC
    export INIT_SYS='openrc'
  else
    case "${UNAME}" in
        'Linux')
          if [ ! -f '/sbin/init' ]; then
            comm_name="$(cat -- '/proc/1/comm' 2>/dev/null || true)"
            comm_path="$(which -- "${comm_name}" 2>/dev/null || true)"
            if [ -n "${comm_path}" ]; then
              proc_comm="$(stat -- "${comm_path}" 2>/dev/null | awk 'NR==1{ print $NF }' || true)"
            else
              proc_comm="${comm_name}"
            fi
            case "${proc_comm}" in
               *'/bin/bash'|'dash'|'bash')
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
      'FreeBSD')
          if [ -d '/etc/inittab' ]; then
            export INIT_SYS='systemv_init'
          elif [ -f '/sbib/init' ]; then
            export INIT_SYS='bsd_init'
          fi
          ;;
        *)
          >&2 printf 'TODO: *BSD, minix, SunOS, illumos, &etc.\n'
          export INIT_SYS='none' ;;
    esac
  fi
fi
