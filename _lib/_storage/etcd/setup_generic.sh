#!/bin/sh

set -feu
# shellcheck disable=SC2296,SC3028,SC3040,SC3054
if [ "${SCRIPT_NAME-}" ]; then
  this_file="${SCRIPT_NAME}"
  elif [ "${BASH_SOURCE-}" ]; then
  this_file="${BASH_SOURCE[0]}"
  set -o pipefail
elif [ "${ZSH_VERSION-}" ]; then
  this_file="${(%):-%x}"
  set -o pipefail
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

DIR=$(CDPATH='' cd -- "$(dirname -- "${this_file}")" && pwd)

LIBSCRIPT_ROOT_DIR="${LIBSCRIPT_ROOT_DIR:-$(d="${DIR}"; while [ ! -f "${d}"'/ROOT' ]; do d="$(dirname -- "${d}")"; done; printf '%s' "${d}")}"
export LIBSCRIPT_ROOT_DIR

SCRIPT_NAME="${DIR}"'/env.sh'
export SCRIPT_NAME
# shellcheck disable=SC1090
. "${SCRIPT_NAME}"

for lib in '_lib/_common/os_info.sh' '_lib/_common/priv.sh' 'env.sh'; do
  SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}"'/'"${lib}"
  export SCRIPT_NAME
  # shellcheck disable=SC1090
  . "${SCRIPT_NAME}"
done

DOWNLOAD_URL='https://storage.googleapis.com/etcd'

uname_lower="$(printf '%s' "${UNAME}" | tr '[:upper:]' '[:lower:]')"
name='etcd-'"${ETCD_VERSION}"'-'"${uname_lower}"'-'"${ARCH_ALT}"
archive="${name}"
is_tar=1
case "${uname_lower}" in
  'darwin'|'windows')
    is_tar=0;
    archive="${archive}"'.zip' ;;
  *) archive="${archive}"'.tar.gz' ;;
esac

rm -rf -- '/tmp/'"${archive}" '/tmp/etcd-download-test'
mkdir -p -- '/tmp/etcd-download-test'
curl -Lo '/tmp/'"${archive}" -- "${DOWNLOAD_URL}"'/'"${ETCD_VERSION}"'/'"${archive}"
if [ "${is_tar}" -eq 1 ]; then
  tar xzvf '/tmp/'"${archive}" -C '/tmp/etcd-download-test' --strip-components=1
else
  unzip -d '/tmp' -- '/tmp/'"${archive}"
  d='/tmp/'"${name}"
  set +f
  mv -- "${d}"'/'* '/tmp/etcd-download-test'
  set -f
  rm -r -- "${d}"
fi
rm -f -- '/tmp/'"${archive}"
set +f
if [ -d '/opt/etcd' ]; then
  priv rm -rf -- '/opt/etcd'
fi
priv mkdir -p -- '/opt/etcd'
priv mv -- '/tmp/etcd-download-test/'* '/opt/etcd'
set -f
rm -r -- '/tmp/etcd-download-test'

case "${INIT_SYS}" in
  'systemd')
    service_name='etcd'
    name_file="$(mktemp)"
    trap 'rm -f -- "${name_file}"' EXIT HUP INT QUIT TERM
#         ENV='Environment="ETCD_ADVERTISE_CLIENT_URLS=http://%(public_ipv4)s:%(ADVERT_PORT)s"
#Environment="ETCD_DISCOVERY=%(etcd_discovery)s"
#Environment="ETCD_INITIAL_ADVERTISE_PEER_URLS=http://%(public_ipv4)s:%(PEER_PORT)s"
#Environment="ETCD_LISTEN_CLIENT_URLS=http://0.0.0.0:%(ADVERT_PORT)s,http://0.0.0.0:%(ADDITIONAL_LISTEN_PORT)s"
#Environment="ETCD_LISTEN_PEER_URLS=http://0.0.0.0:%(PEER_PORT)s"
#Environment="ETCD_NAME=%(node_name)s"
#Environment="ETCD_DATADIR=%(data_dir)s"' \
    env -i DESCRIPTION="${service_name}"' '"${ETCD_VERSION}"' server' \
         WORKING_DIR='/tmp' \
         ENV='Environment="ETCD_DATADIR=/tmp/etcd_data"
Environment="ETCD_NAME='"${service_name}"'_'"${ETCD_VERSION}"'"' \
         EXEC_START='/opt/etcd/etcd' \
         "$(which envsubst)" < "${LIBSCRIPT_ROOT_DIR}"'/_lib/_daemon/systemd/simple.service' > "${name_file}"
    priv install -m 0644 -o 'root' -- "${name_file}" '/etc/systemd/system/'"${service_name}"'.service'
    priv systemctl daemon-reload
    priv systemctl reload-or-restart -- "${service_name}"
    ;;
  *) >&2 printf 'TODO: %s\n' "${INIT_SYS}" ; exit 3 ;;
esac
priv '/opt/etcd/etcd' --version
