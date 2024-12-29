#!/bin/sh

realpath -- "${0}"
set -x
guard='H_'"$(realpath -- "${0}" | sed 's/[^a-zA-Z0-9_]/_/g')"
if env | grep -qF "${guard}"'=1'; then return ; fi
export "${guard}"=1
if [ -n "${ZSH_VERSION}" ] || [ -n "${BASH_VERSION}" ]; then
  set -xeuo pipefail
fi

SCRIPT_ROOT_DIR="${SCRIPT_ROOT_DIR:-$( dirname -- "$( dirname -- "$( dirname -- "${0}" )" )" )}"

# shellcheck disable=SC1091
. "${SCRIPT_ROOT_DIR}"'/conf.env.sh'
# shellcheck disable=SC1091
. "${SCRIPT_ROOT_DIR}"'/_lib/_os/_apt/apt.sh'

get_priv

apt_depends curl gnupg2 ca-certificates lsb-release debian-archive-keyring
[ -f '/usr/share/keyrings/nginx-archive-keyring.gpg' ] || \
  curl https://nginx.org/keys/nginx_signing.key | gpg --dearmor \
    | "${PRIV}" tee /usr/share/keyrings/nginx-archive-keyring.gpg >/dev/null
[ -f '/etc/apt/sources.list.d/nginx.list' ] || \
  echo "deb [signed-by=/usr/share/keyrings/nginx-archive-keyring.gpg] \
  http://nginx.org/packages/debian $(lsb_release -cs) nginx" \
    | "${PRIV}" tee /etc/apt/sources.list.d/nginx.list
[ -f '/etc/apt/preferences.d/99nginx' ] || \
  echo -e "Package: *\nPin: origin nginx.org\nPin: release o=nginx\nPin-Priority: 900\n" \
    | "${PRIV}" tee /etc/apt/preferences.d/99nginx && \
  "${PRIV}" apt update -qq

apt_depends nginx
