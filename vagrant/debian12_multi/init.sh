#!/bin/sh
# shellcheck disable=SC2016,SC1090,SC1091,SC2034,SC2018,SC2019,SC2221,SC2222,SC2129,SC2209,SC2089,SC2090,SC2086,SC2154,SC2044,SC2181,SC2038,SC2155,SC2046,SC2002,SC1003,SC2295,SC2145



set -feu

printf '%s\n%s\n%s\n' \
    'LANG='"'"'C.UTF-8'"'"'' \
    'LC_ALL='"'"'C.UTF-8'"'"'' \
    'LIBSCRIPT_ROOT_DIR='"'"'/opt/repos/libscript'"'" >> /etc/environment
set +f
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
  sudo sed -i \
    -e 's/^#*PermitRootLogin.*/PermitRootLogin yes/' \
    -e 's/^#PubkeyAuthentication yes/PubkeyAuthentication yes/' \
    -e 's/^#PasswordAuthentication yes/PasswordAuthentication no/' \
    /etc/ssh/sshd_config
  printf '\nHost jump
  HostName 10.0.0.10
  User vagrant
  IdentityFile /home/vagrant/.ssh/id_rsa
  StrictHostKeyChecking no
  UserKnownHostsFile /dev/null

Host server
  HostName 10.0.0.11
  User vagrant
  IdentityFile /home/vagrant/.ssh/id_rsa
  StrictHostKeyChecking no
  UserKnownHostsFile /dev/null\n' >> /home/vagrant/.ssh/config
  for i in $(dc -e '1 1 '"${NODE_COUNT}"'  stsisb[pli+dlt>a]salblax'); do
      # shellcheck disable=SC2003
      last_oct="$(expr "${i}" + 11)"

      printf '\nHost node%d
  HostName 10.0.0.%d
  StrictHostKeyChecking no
  UserKnownHostsFile /dev/null
  IdentityFile /home/vagrant/.ssh/id_rsa\n' "${i}" "${last_oct}" >> /home/vagrant/.ssh/config
  done
fi
