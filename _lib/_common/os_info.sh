#!/bin/sh

realpath -- "${0}"
set -x
guard='H_'"$(realpath -- "${0}" | sed 's/[^a-zA-Z0-9_]/_/g')"
if env | grep -qF "${guard}"'=1'; then return ; fi
export "${guard}"=1

if [ -n "${ZSH_VERSION}" ] || [ -n "${BASH_VERSION}" ]; then
  set -xeuo pipefail
fi

if [ -z ${UNAME+x} ]; then
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
