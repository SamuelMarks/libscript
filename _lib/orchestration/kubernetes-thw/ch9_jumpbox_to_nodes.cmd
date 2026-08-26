@echo off
:: # ch9_jumpbox_to_nodes.cmd
::
:: ## Overview
:: Automates Ch9 of Kubernetes the Hard Way.
::
:: :::: Usage
:: Executes the steps for Ch9.

setlocal EnableDelayedExpansion

set "THIS_FILE=%~f0"
set "SCRIPT_DIR=%~dp0"
if "%SCRIPT_DIR:~-1%"=="\" set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"

:: Traverse up to find libscript.cmd
set "d=%SCRIPT_DIR%"
:find_root
if exist "%d%\libscript.cmd" (
    set "LIBSCRIPT_ROOT_DIR=%d%"
    goto root_found
)
for %%a in ("%d%") do set "parent=%%~dpa"
if "%parent:~-1%"=="\" set "parent=%parent:~0,-1%"
if "%d%"=="%parent%" (
    set "LIBSCRIPT_ROOT_DIR=%SCRIPT_DIR%"
    goto root_found
)
set "d=%parent%"
goto find_root
:root_found
set "DIR=%SCRIPT_DIR%"

set MACHINES_TXT=%DIR%\\kubernetes-the-hard-way\machines.txt
set NODES=
for /f "tokens=3,4" %%a in ('type "%MACHINES_TXT%" ^| findstr "node-"') do (
  set NODES=!NODES! %%a
  set SUBNET_%%a=%%b
)
if "!NODES!"=="" (
  set NODES=node-0 node-1
  set SUBNET_node-0=10.200.0.0/24
  set SUBNET_node-1=10.200.1.0/24
)

for %%H in (%NODES%) do (
  set "SUBNET=!SUBNET_%%H!"
  powershell -Command "$text = Get-Content '%DIR%\\kubernetes-the-hard-way\configs\10-bridge.conf' -Raw; $text = $text -replace 'SUBNET', $env:SUBNET; Set-Content -Path '%DIR%\\kubernetes-the-hard-way\10-bridge-%%H.conf' -Value $text"
  powershell -Command "$text = Get-Content '%DIR%\\kubernetes-the-hard-way\configs\kubelet-config.yaml' -Raw; $text = $text -replace 'SUBNET', $env:SUBNET; Set-Content -Path '%DIR%\\kubernetes-the-hard-way\kubelet-config-%%H.yaml' -Value $text"
  scp "%DIR%\\kubernetes-the-hard-way\10-bridge-%%H.conf" "%DIR%\\kubernetes-the-hard-way\kubelet-config-%%H.yaml" root@%%H:~/
  ssh root@%%H "mv -f 10-bridge-%%H.conf 10-bridge.conf && mv -f kubelet-config-%%H.yaml kubelet-config.yaml"
)

for %%H in (%NODES%) do (
  ssh root@%%H "mkdir -p ~/cni-plugins"
  scp %DIR%\\kubernetes-the-hard-way\downloads\worker\* %DIR%\\kubernetes-the-hard-way\downloads\client\kubectl %DIR%\\kubernetes-the-hard-way\configs\99-loopback.conf %DIR%\\kubernetes-the-hard-way\configs\containerd-config.toml %DIR%\\kubernetes-the-hard-way\configs\kube-proxy-config.yaml %DIR%\\kubernetes-the-hard-way\units\containerd.service %DIR%\\kubernetes-the-hard-way\units\kubelet.service %DIR%\\kubernetes-the-hard-way\units\kube-proxy.service root@%%H:~/
  scp %DIR%\\kubernetes-the-hard-way\downloads\cni-plugins\* root@%%H:~/cni-plugins/
)

for %%H in (%NODES%) do (
  ssh root@%%H "apt-get update; apt-get -y install socat conntrack ipset kmod; if swapon --show | grep -q 'NAME'; then swapoff -a; fi; mkdir -p /etc/cni/net.d /opt/cni/bin /var/lib/kubelet /var/lib/kube-proxy /var/lib/kubernetes /var/run/kubernetes; mv -f crictl kube-proxy kubelet runc /usr/local/bin/ || true; mv -f containerd containerd-shim-runc-v2 containerd-stress /bin/ || true; cp -rf cni-plugins/* /opt/cni/bin/ || true; mv -f 10-bridge.conf 99-loopback.conf /etc/cni/net.d/ || true; modprobe br-netfilter || true; if ! grep -q 'br-netfilter' /etc/modules-load.d/modules.conf; then echo 'br-netfilter' >> /etc/modules-load.d/modules.conf; fi; echo 'net.bridge.bridge-nf-call-iptables = 1' > /etc/sysctl.d/kubernetes.conf; echo 'net.bridge.bridge-nf-call-ip6tables = 1' >> /etc/sysctl.d/kubernetes.conf; sysctl -p /etc/sysctl.d/kubernetes.conf || true; mkdir -p /etc/containerd/; mv -f containerd-config.toml /etc/containerd/config.toml || true; mv -f containerd.service /etc/systemd/system/ || true; mv -f kubelet-config.yaml /var/lib/kubelet/ || true; mv -f kubelet.service /etc/systemd/system/ || true; mv -f kube-proxy-config.yaml /var/lib/kube-proxy/ || true; mv -f kube-proxy.service /etc/systemd/system/ || true; systemctl daemon-reload; systemctl enable containerd kubelet kube-proxy; systemctl start containerd kubelet kube-proxy"
)

ssh root@server "kubectl get nodes --kubeconfig admin.kubeconfig" || true
