@echo off
:: # ch5_jumpbox_to_targets.cmd
::
:: ## Overview
:: Automates Ch5 of Kubernetes the Hard Way.
::
:: ## Usage
:: Executes the steps for Ch5.

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
for /f "tokens=3" %%a in ('type "%MACHINES_TXT%" ^| findstr "node-"') do (
  set NODES=!NODES! %%a
)
if "!NODES!"=="" set NODES=node-0 node-1
for /f "tokens=1,3" %%i in ('type "%MACHINES_TXT%" ^| findstr "server"' ) do if "%%j"=="server" set SERVER_IP=%%i
if "!SERVER_IP!"=="" set SERVER_IP=192.168.56.10
for %%H in (%NODES%) do (
  ssh root@%%H "mkdir -p /var/lib/kubelet/"
  scp "%LIBSCRIPT_DATA_DIR%\ca.crt" root@%%H:/var/lib/kubelet/
  scp "%LIBSCRIPT_DATA_DIR%\%%H.crt" root@%%H:/var/lib/kubelet/kubelet.crt
  scp "%LIBSCRIPT_DATA_DIR%\%%H.key" root@%%H:/var/lib/kubelet/kubelet.key
)

for %%H in (%NODES%) do (
  kubectl config set-cluster %DIR%\\kubernetes-the-hard-way --certificate-authority="%LIBSCRIPT_DATA_DIR%\ca.crt" --embed-certs=true --server=https://!SERVER_IP!:6443 --kubeconfig="%LIBSCRIPT_DATA_DIR%\%%H.kubeconfig"
  kubectl config set-credentials system:node:%%H --client-certificate="%LIBSCRIPT_DATA_DIR%\%%H.crt" --client-key="%LIBSCRIPT_DATA_DIR%\%%H.key" --embed-certs=true --kubeconfig="%LIBSCRIPT_DATA_DIR%\%%H.kubeconfig"
  kubectl config set-context default --cluster=%DIR%\\kubernetes-the-hard-way --user=system:node:%%H --kubeconfig="%LIBSCRIPT_DATA_DIR%\%%H.kubeconfig"
  kubectl config use-context default --kubeconfig="%LIBSCRIPT_DATA_DIR%\%%H.kubeconfig"
)

kubectl config set-cluster %DIR%\\kubernetes-the-hard-way --certificate-authority="%LIBSCRIPT_DATA_DIR%\ca.crt" --embed-certs=true --server=https://!SERVER_IP!:6443 --kubeconfig="%LIBSCRIPT_DATA_DIR%\kube-proxy.kubeconfig"
kubectl config set-credentials system:kube-proxy --client-certificate="%LIBSCRIPT_DATA_DIR%\kube-proxy.crt" --client-key="%LIBSCRIPT_DATA_DIR%\kube-proxy.key" --embed-certs=true --kubeconfig="%LIBSCRIPT_DATA_DIR%\kube-proxy.kubeconfig"
kubectl config set-context default --cluster=%DIR%\\kubernetes-the-hard-way --user=system:kube-proxy --kubeconfig="%LIBSCRIPT_DATA_DIR%\kube-proxy.kubeconfig"
kubectl config use-context default --kubeconfig="%LIBSCRIPT_DATA_DIR%\kube-proxy.kubeconfig"

kubectl config set-cluster %DIR%\\kubernetes-the-hard-way --certificate-authority="%LIBSCRIPT_DATA_DIR%\ca.crt" --embed-certs=true --server=https://!SERVER_IP!:6443 --kubeconfig="%LIBSCRIPT_DATA_DIR%\kube-controller-manager.kubeconfig"
kubectl config set-credentials system:kube-controller-manager --client-certificate="%LIBSCRIPT_DATA_DIR%\kube-controller-manager.crt" --client-key="%LIBSCRIPT_DATA_DIR%\kube-controller-manager.key" --embed-certs=true --kubeconfig="%LIBSCRIPT_DATA_DIR%\kube-controller-manager.kubeconfig"
kubectl config set-context default --cluster=%DIR%\\kubernetes-the-hard-way --user=system:kube-controller-manager --kubeconfig="%LIBSCRIPT_DATA_DIR%\kube-controller-manager.kubeconfig"
kubectl config use-context default --kubeconfig="%LIBSCRIPT_DATA_DIR%\kube-controller-manager.kubeconfig"

kubectl config set-cluster %DIR%\\kubernetes-the-hard-way --certificate-authority="%LIBSCRIPT_DATA_DIR%\ca.crt" --embed-certs=true --server=https://!SERVER_IP!:6443 --kubeconfig="%LIBSCRIPT_DATA_DIR%\kube-scheduler.kubeconfig"
kubectl config set-credentials system:kube-scheduler --client-certificate="%LIBSCRIPT_DATA_DIR%\kube-scheduler.crt" --client-key="%LIBSCRIPT_DATA_DIR%\kube-scheduler.key" --embed-certs=true --kubeconfig="%LIBSCRIPT_DATA_DIR%\kube-scheduler.kubeconfig"
kubectl config set-context default --cluster=%DIR%\\kubernetes-the-hard-way --user=system:kube-scheduler --kubeconfig="%LIBSCRIPT_DATA_DIR%\kube-scheduler.kubeconfig"
kubectl config use-context default --kubeconfig="%LIBSCRIPT_DATA_DIR%\kube-scheduler.kubeconfig"

kubectl config set-cluster %DIR%\\kubernetes-the-hard-way --certificate-authority="%LIBSCRIPT_DATA_DIR%\ca.crt" --embed-certs=true --server=https://127.0.0.1:6443 --kubeconfig="%LIBSCRIPT_DATA_DIR%\admin.kubeconfig"
kubectl config set-credentials admin --client-certificate="%LIBSCRIPT_DATA_DIR%\admin.crt" --client-key="%LIBSCRIPT_DATA_DIR%\admin.key" --embed-certs=true --kubeconfig="%LIBSCRIPT_DATA_DIR%\admin.kubeconfig"
kubectl config set-context default --cluster=%DIR%\\kubernetes-the-hard-way --user=admin --kubeconfig="%LIBSCRIPT_DATA_DIR%\admin.kubeconfig"
kubectl config use-context default --kubeconfig="%LIBSCRIPT_DATA_DIR%\admin.kubeconfig"

for %%H in (%NODES%) do (
  ssh root@%%H "mkdir -p /var/lib/kube-proxy /var/lib/kubelet"
  scp "%LIBSCRIPT_DATA_DIR%\kube-proxy.kubeconfig" root@%%H:/var/lib/kube-proxy/kubeconfig
  scp "%LIBSCRIPT_DATA_DIR%\%%H.kubeconfig" root@%%H:/var/lib/kubelet/kubeconfig
)

scp "%LIBSCRIPT_DATA_DIR%\admin.kubeconfig" "%LIBSCRIPT_DATA_DIR%\kube-controller-manager.kubeconfig" "%LIBSCRIPT_DATA_DIR%\kube-scheduler.kubeconfig" root@server:~/
