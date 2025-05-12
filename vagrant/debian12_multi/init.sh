#!/bin/sh

set -feu
if [ "${BASH_SOURCE-}" ] || [ "${ZSH_VERSION-}" ]; then
  # shellcheck disable=SC3040
  set -o pipefail
fi

printf '%s\n%s\n%s\n' \
    'LANG='"'"'C.UTF-8'"'"'' \
    'LC_ALL='"'"'C.UTF-8'"'"'' \
    'LIBSCRIPT_ROOT_DIR='"'"'/opt/repos/libscript'"'" >> /etc/environment
set +f
# shellcheck disable=SC3031
printf '%s\n%s\n' \
    'export LANG='"'"'C.UTF-8'"'"'' \
    'export LC_ALL='"'"'C.UTF-8'"'"'' >> ~/.bashrc
set -f
printf '%s\n' 'C.UTF-8 UTF-8' >> /etc/locale.gen
printf '%s\n' 'LANG='"'"'C.UTF-8'"'" >> /etc/locale.conf
apt-get -qq update
export DEBIAN_FRONTEND='noninteractive'
apt-get -qq install -y apt-utils curl dc gettext-base jq rsync libarchive-zip-perl pandoc
if test "$(hostname)" = 'master'; then
  mkdir vagrant_ssh
  chmod 700 vagrant_ssh
  ssh-keygen -N "" -t 'rsa' -b '4096' -C 'vagrant internal ssh keys' -f 'vagrant_ssh/id_rsa'
  [ -d /home/vagrant/.ssh ] || mkdir /home/vagrant/.ssh
  chmod 700 /home/vagrant/.ssh
  for i in $(dc -e '0 1 '"${NODE_COUNT}"'  stsisb[pli+dlt>a]salblax'); do
    # shellcheck disable=SC2003
    last_oct="$(expr "${i}" + 10)"
    #printf '%s\t%s\n' 'node'"${i}" '10.0.0.'"${last_oct}" >> /etc/hosts
    printf 'node%s\n' "${i}" >> /tmp/hosts.txt

    printf '\nHost node%d
      HostName 10.0.0.%d
      StrictHostKeyChecking no
      UserKnownHostsFile /dev/null
      IdentityFile /home/vagrant/.ssh/id_rsa\n' "${i}" "${last_oct}" >> ~/.ssh/config
  done
  cp /tmp/hosts.txt vagrant_ssh/
else
  [ -d /home/vagrant/.ssh ] || mkdir /home/vagrant/.ssh
  chmod 700 /home/vagrant/.ssh
  for i in $(dc -e '0 1 '"${NODE_COUNT}"'  stsisb[pli+dlt>a]salblax'); do
      # shellcheck disable=SC2003
      last_oct="$(expr "${i}" + 10)"

      printf '\nHost node%d
  HostName 10.0.0.%d
  StrictHostKeyChecking no
  UserKnownHostsFile /dev/null
  IdentityFile /home/vagrant/.ssh/id_rsa\n' "${i}" "${last_oct}" >> /home/vagrant/.ssh/config
  done
  printf '\nHost master
  HostName 10.0.0.10
  StrictHostKeyChecking no
  UserKnownHostsFile /dev/null
  IdentityFile /home/vagrant/.ssh/id_rsa\n' >> /home/vagrant/.ssh/config
fi
