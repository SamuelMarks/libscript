#!/bin/sh
# ## Overview
# Test suite for the kubernetes-thw component via Vagrant.
#
# ## Usage
# Execute this script to perform a component-specific test.

set -feu
if [ "${SCRIPT_NAME-}" ]; then
  THIS_FILE="${SCRIPT_NAME}"
elif [ "${BASH_SOURCE-}" ]; then
  eval 'THIS_FILE="${BASH_SOURCE[0]}"'
  eval 'set -o pipefail'
elif [ "${ZSH_VERSION-}" ]; then
  eval 'THIS_FILE="${(%):-%x}"'
  eval 'set -o pipefail'
else
  THIS_FILE="${0}"
fi

SCRIPT_DIR=$(cd -- "$(dirname -- "${THIS_FILE}")" && pwd)
: "${LIBSCRIPT_ROOT_DIR:=$(d="$SCRIPT_DIR"; while [ ! -f "$d/libscript.sh" ]; do n="${d%/*}"; [ -z "$n" ] && n="/"; [ "$d" = "$n" ] && break; d="$n"; done; printf '%s\n' "$d")}"

export VAGRANT_N="${VAGRANT_N:-3}"
export VAGRANT_IMAGE_DIR="${VAGRANT_IMAGE_DIR:-k8s-thw-debian}"

# 1. Bring up vagrant machines
(
  cd "${LIBSCRIPT_ROOT_DIR}/vagrant" || exit 1
  sh up_multiple.sh
)

# 2. Wait for ssh
for i in $(dc -e '0 1 '"${VAGRANT_N}"' stsisb[pli+dlt>a]salblax'); do
  (
    cd "${LIBSCRIPT_ROOT_DIR}/vagrant/${VAGRANT_IMAGE_DIR}" || exit 1
    while ! vagrant ssh "${VAGRANT_IMAGE_DIR}${i}" -c "echo up" -- -n >/dev/null 2>&1; do
      sleep 2
    done
  )
done

# 3. Generate machines.txt
mkdir -p "${SCRIPT_DIR}/kubernetes-the-hard-way"
export MACHINES_TXT="${SCRIPT_DIR}/kubernetes-the-hard-way/machines.txt"
rm -f "${MACHINES_TXT}"

for i in $(dc -e '0 1 '"${VAGRANT_N}"' stsisb[pli+dlt>a]salblax'); do
  if [ "$i" -eq 0 ]; then
    HOST="server"
    SUBNET=""
  else
    HOST="node-$((i-1))"
    SUBNET="10.200.$((i-1)).0/24"
  fi
  
  if [ "$VAGRANT_IMAGE_DIR" = "k8s-thw-alpine" ]; then
    IP="192.168.56.$((10+i))"
  else
    IP="192.168.56.$((20+i))"
  fi
  
  FQDN="${HOST}.kubernetes.local"
  printf '%s %s %s %s\n' "$IP" "$FQDN" "$HOST" "$SUBNET" >> "${MACHINES_TXT}"
done

# 4. Generate SSH config for Jumpbox (local runner)
if [ ! -d ~/.ssh ]; then
  mkdir -p ~/.ssh
  chmod 700 ~/.ssh
fi

if [ ! -f ~/.ssh/id_rsa ]; then
  ssh-keygen -t rsa -N "" -f ~/.ssh/id_rsa
fi

while read -r IP FQDN HOST SUBNET; do
  if [ "$HOST" = "server" ]; then
    MACH_IDX=0
  else
    MACH_IDX=$(( $(echo "$HOST" | cut -d'-' -f2) + 1 ))
  fi
  # Extract HostName, Port, and IdentityFile from Vagrant
  (
    cd "${LIBSCRIPT_ROOT_DIR}/vagrant/${VAGRANT_IMAGE_DIR}" || exit 1
    vagrant ssh-config "${VAGRANT_IMAGE_DIR}${MACH_IDX}" > /tmp/vssh_${MACH_IDX}
  )
  V_HOST=$(awk '/HostName/ {print $2}' /tmp/vssh_${MACH_IDX})
  V_PORT=$(awk '/Port/ {print $2}' /tmp/vssh_${MACH_IDX})
  KEY_PATH=$(awk '/IdentityFile/ {print $2}' /tmp/vssh_${MACH_IDX} | head -n 1)
  
  ssh-keygen -R "[$V_HOST]:$V_PORT" 2>/dev/null || true
  ssh-keygen -R "$V_HOST" 2>/dev/null || true
  ssh-keyscan -p "$V_PORT" -H "$V_HOST" >> ~/.ssh/known_hosts 2>/dev/null || true
  
  sed -i.bak "/^Host $HOST$/,/^$/d" ~/.ssh/config 2>/dev/null || true
  printf 'Host %s\n  HostName %s\n  Port %s\n  User root\n  IdentityFile %s\n  StrictHostKeyChecking no\n\n' "$HOST" "$V_HOST" "$V_PORT" "$KEY_PATH" >> ~/.ssh/config
  
  # Ensure root access is allowed by injecting the newly created public key (if Vagrant hasn't setup root ssh key auth)
  # Vagrant usually maps 'vagrant' user. Let's make sure 'root' has the key.
  (
    cd "${LIBSCRIPT_ROOT_DIR}/vagrant/${VAGRANT_IMAGE_DIR}" || exit 1
    vagrant ssh "${VAGRANT_IMAGE_DIR}${MACH_IDX}" -c "sudo mkdir -p /root/.ssh && sudo cp /home/vagrant/.ssh/authorized_keys /root/.ssh/authorized_keys && sudo chown -R root:root /root/.ssh" < /dev/null
    
    # Inject hosts from machines.txt
    vagrant ssh "${VAGRANT_IMAGE_DIR}${MACH_IDX}" -c "sudo sh -c 'grep -v \"\.kubernetes\.local\" /etc/hosts > /tmp/hosts.tmp && mv /tmp/hosts.tmp /etc/hosts && cat << \EOF >> /etc/hosts
192.168.56.10 server.kubernetes.local server
192.168.56.11 node-0.kubernetes.local node-0
192.168.56.12 node-1.kubernetes.local node-1
192.168.56.20 server.kubernetes.local server
192.168.56.21 node-0.kubernetes.local node-0
192.168.56.22 node-1.kubernetes.local node-1
EOF'" < /dev/null

    # Inject systemctl shim for Alpine
    if [ "$VAGRANT_IMAGE_DIR" = "k8s-thw-alpine" ]; then
      vagrant ssh "${VAGRANT_IMAGE_DIR}${MACH_IDX}" -c "sudo sh -c 'cat << \EOF > /usr/local/bin/systemctl
#!/bin/sh
CMD=\$1
if [ \"\$CMD\" = \"daemon-reload\" ] || [ \"\$CMD\" = \"enable\" ]; then exit 0; fi
if [ \"\$CMD\" = \"start\" ]; then
    mkdir -p /etc/systemd/system
    shift
    for SVC in \"\$@\"; do
        SVC=\${SVC%.service}
        awk -v svc=\"\$SVC\" '\''
        BEGIN { in_exec = 0; cmd = \"\" }
        /^ExecStart=/ { in_exec = 1; sub(/^ExecStart=/, \"\"); }
        in_exec {
            line = \$0;
            if (line ~ /\\\\$/) { sub(/\\\\$/, \"\", line); cmd = cmd \" \" line; }
            else { cmd = cmd \" \" line; in_exec = 0; print \"nohup \" cmd \" > /var/log/\" svc \".log 2>&1 &\" }
        }
        '\'' \"/etc/systemd/system/\${SVC}.service\" > \"/tmp/start_\${SVC}.sh\"
        sh \"/tmp/start_\${SVC}.sh\"
    done
    exit 0
fi
EOF
chmod +x /usr/local/bin/systemctl'" < /dev/null
    fi
  )
done < "${MACHINES_TXT}"

# 5. Execute Chapters
cd "${SCRIPT_DIR}" || exit 1

# Setup SSH tunnel for kube-apiserver access from jumpbox
ssh -f -N -L 6443:127.0.0.1:6443 root@server

for chap in \
  ch2_jumpbox_only.sh \
  ch4_jumpbox_to_targets.sh \
  ch5_jumpbox_to_targets.sh \
  ch6_jumpbox_to_server.sh \
  ch7_jumpbox_to_server.sh \
  ch8_jumpbox_to_server.sh \
  ch9_jumpbox_to_nodes.sh \
  ch10_jumpbox_only.sh \
  ch11_jumpbox_to_nodes.sh \
  ch12_jumpbox_only.sh; do
  
  # We can't rely on kubernetes-the-hard-way ca.conf if we didn't generate it.
  # ch2 clones the repo. Let's run it.
  if echo "$VAGRANT_IMAGE_DIR" | grep -q "alpine"; then
    for host in server node-0 node-1; do
      scp "${SCRIPT_DIR}/alpine-systemctl.sh" root@${host}:/usr/local/bin/systemctl
      ssh root@${host} "chmod +x /usr/local/bin/systemctl; mkdir -p /etc/systemd/system"
    done
  fi
  
  sh "$chap"
done

# Cleanup SSH tunnel
pkill -f "ssh -f -N -L 6443:127.0.0.1:6443 root@server" || true

# 6. Verify Cluster is green!
ssh root@server "kubectl get nodes --kubeconfig admin.kubeconfig"
if ! ssh root@server "kubectl get nodes --kubeconfig admin.kubeconfig" | grep -qi ready; then
  echo "Kubernetes nodes are not ready!"
  exit 1
fi
echo "Kubernetes is fully green!"
