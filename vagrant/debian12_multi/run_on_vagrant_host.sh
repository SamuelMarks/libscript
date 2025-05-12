#!/bin/sh

set -feu
if [ "${BASH_SOURCE-}" ] || [ "${ZSH_VERSION-}" ]; then
  # shellcheck disable=SC3040
  set -o pipefail
fi

mkdir vagrant_ssh
chmod 700 vagrant_ssh
ssh-keygen -N "" -t 'rsa' -b '4096' -C 'vagrant ex/internal ssh keys' -f 'vagrant_ssh/id_rsa'
