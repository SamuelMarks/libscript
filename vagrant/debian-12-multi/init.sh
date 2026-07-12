#!/bin/sh
# ## Overview
# Vagrant environment configuration and setup scripts.
# 
# ## Usage
# Execute this script within the context of Vagrant provisioning.


set -feu
# shellcheck disable=SC2296,SC3028,SC3040,SC3054
if [ "${SCRIPT_NAME-}" ]; then
  THIS_FILE="${SCRIPT_NAME}"
elif [ "${BASH_SOURCE-}" ]; then
  THIS_FILE="${BASH_SOURCE[0]}"
  set -o pipefail
elif [ "${ZSH_VERSION-}" ]; then
  THIS_FILE="${(%):-%x}"
  set -o pipefail
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
if ! grep -q "^LANG='C.UTF-8'" /etc/environment 2>/dev/null; then
  printf "%s\n" "LANG='C.UTF-8'" >> /etc/environment
fi
if ! grep -q "^LC_ALL='C.UTF-8'" /etc/environment 2>/dev/null; then
  printf "%s\n" "LC_ALL='C.UTF-8'" >> /etc/environment
fi
if ! grep -q "^LIBSCRIPT_ROOT_DIR=" /etc/environment 2>/dev/null; then
  printf "%s\n" "LIBSCRIPT_ROOT_DIR='/opt/repos/libscript'" >> /etc/environment
fi
set +f
if ! grep -q "export LC_ALL='C.UTF-8'" ~/.bashrc 2>/dev/null; then
  printf '%s\n%s\n' \
      'export LANG='"'"'C.UTF-8'"'"'' \
      'export LC_ALL='"'"'C.UTF-8'"'"'' >> ~/.bashrc
fi
set -feu
grep -q '^C.UTF-8 UTF-8' /etc/locale.gen 2>/dev/null || printf '%s\n' 'C.UTF-8 UTF-8' >> /etc/locale.gen
grep -q '^LANG=' /etc/locale.conf 2>/dev/null || printf '%s\n' 'LANG='"'"'C.UTF-8'"'" >> /etc/locale.conf
apt-get -qq update
export DEBIAN_FRONTEND='noninteractive'
apt-get -qq install -y apt-utils curl dc gettext-base jq rsync libarchive-zip-perl pandoc
if test "$(hostname)" = 'master'; then
  [ -d vagrant_ssh ] || mkdir vagrant_ssh
  chmod 700 vagrant_ssh
  [ -f vagrant_ssh/id_rsa ] || ssh-keygen -N "" -t 'rsa' -b '4096' -C 'vagrant internal ssh keys' -f 'vagrant_ssh/id_rsa'
  [ -d /home/vagrant/.ssh ] || mkdir /home/vagrant/.ssh
  chmod 700 /home/vagrant/.ssh
  rm -f /tmp/hosts.txt
  for i in $(dc -e '0 1 '"${NODE_COUNT}"'  stsisb[pli+dlt>a]salblax'); do
    # shellcheck disable=SC2003
    last_oct="$(expr "${i}" + 10)"
    printf 'node%s\n' "${i}" >> /tmp/hosts.txt

    if ! grep -q "Host node${i}" ~/.ssh/config 2>/dev/null; then
      printf '\nHost node%d\n      HostName 10.0.0.%d\n      StrictHostKeyChecking no\n      UserKnownHostsFile /dev/null\n      IdentityFile /home/vagrant/.ssh/id_rsa\n' "${i}" "${last_oct}" >> ~/.ssh/config
    fi
  done
  cp /tmp/hosts.txt vagrant_ssh/
else
  [ -d /home/vagrant/.ssh ] || mkdir /home/vagrant/.ssh
  chmod 700 /home/vagrant/.ssh
  sudo sed -i \
    -e 's/^#*PermitRootLogin.*/PermitRootLogin yes/' \
    -e 's/^#PubkeyAuthentication yes/PubkeyAuthentication yes/' \
    -e 's/^#PasswordAuthentication yes/PasswordAuthentication no/' \
    /etc/ssh/sshd_config
  if ! grep -q "Host jump" /home/vagrant/.ssh/config 2>/dev/null; then
    printf '\nHost jump\n  HostName 10.0.0.10\n  User vagrant\n  IdentityFile /home/vagrant/.ssh/id_rsa\n  StrictHostKeyChecking no\n  UserKnownHostsFile /dev/null\n\nHost server\n  HostName 10.0.0.11\n  User vagrant\n  IdentityFile /home/vagrant/.ssh/id_rsa\n  StrictHostKeyChecking no\n  UserKnownHostsFile /dev/null\n' >> /home/vagrant/.ssh/config
  fi
  for i in $(dc -e '1 1 '"${NODE_COUNT}"'  stsisb[pli+dlt>a]salblax'); do
      # shellcheck disable=SC2003
      last_oct="$(expr "${i}" + 11)"

      if ! grep -q "Host node${i}" /home/vagrant/.ssh/config 2>/dev/null; then
        printf '\nHost node%d\n  HostName 10.0.0.%d\n  StrictHostKeyChecking no\n  UserKnownHostsFile /dev/null\n  IdentityFile /home/vagrant/.ssh/id_rsa\n' "${i}" "${last_oct}" >> /home/vagrant/.ssh/config
      fi
  done
fi
