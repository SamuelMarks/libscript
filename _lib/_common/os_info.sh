#!/bin/sh

if [ -n "${BASH_VERSION}" ]; then
  # shellcheck disable=SC3028 disable=SC3054
  this_file="${BASH_SOURCE[0]}"
  # shellcheck disable=SC3040
  set -xeuo pipefail
elif [ -n "${ZSH_VERSION}" ]; then
  # shellcheck disable=SC2296
  this_file="${(%):-%x}"
  # shellcheck disable=SC3040
  set -xeuo pipefail
else
  this_file="${0}"
  printf 'argv[%d] = "%s"\n' "0" "${0}";
  printf 'argv[%d] = "%s"\n' "1" "${1}";
  printf 'argv[%d] = "%s"\n' "2" "${2}";
fi

guard='H_'"$(realpath -- "${this_file}" | sed 's/[^a-zA-Z0-9_]/_/g')"

if env | grep -qF "${guard}"'=1'; then return ; fi
export "${guard}"=1

if [ "${ZSH_VERSION+x}" ] || [ "${BASH_VERSION+x}" ]; then
  # shellcheck disable=SC3040
  set -xeuo pipefail
fi

if [ -z ${UNAME+s} ]; then
    UNAME="$(uname)"
    case "${UNAME}" in
    'Darwin')
        export PKG_MGR='brew'
        export HOMEBREW_INSTALL="${HOMEBREW_INSTALL:-1}"
        export NGINX_SERVERS_ROOT='/opt/homebrew/etc/nginx/servers'
        [ -f '/opt/homebrew/bin/brew' ] || /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        TARGET_OS="$(sw_vers --productName)"
        ;;
    'Linux')
        ID="$(. /etc/os-release; printf '%s' "${ID}")"
        ID_LIKE="$(. /etc/os-release; printf '%s' "${ID_LIKE}")"
        export NGINX_SERVERS_ROOT='/etc/nginx/conf.d/sites-available'
        case "${ID}" in
        'alpine') export PKG_MGR='apk' ;;
        'debian') export PKG_MGR='apt-get' ;;
        'rhel') export PKG_MGR='dnf' ;;
        *)
            case "${ID_LIKE}" in
            *debian*) export PKG_MGR='apt-get' ;;
            *rhel*) export PKG_MGR='dnf' ;;
            *) ;;
            esac
        ;;
        esac

        case "${PKG_MGR}" in
        'apk')
            TARGET_OS='alpine'
            ;;
        'apt-get')
            TARGET_OS='debian'
            export DEBIAN_FRONTEND='noninteractive' ;;
        'dnf')
            TARGET_OS='rhel'
            ;;
        *)
            >&2 printf 'Unimplemented, package manager for %s\n' "${TARGET_OS}"
            exit 3
            ;;
        esac
        ;;
    *)
        >&2 printf 'Unimplemented for %s\n' "${UNAME}"
        exit 3
        ;;
    esac
    export UNAME
    export TARGET_OS
fi
