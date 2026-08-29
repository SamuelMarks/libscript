@echo off
:: # ch8_jumpbox_to_server.cmd
::
:: ## Overview
:: Automates Ch8 of Kubernetes the Hard Way.
::
:: ## Usage
:: Executes the steps for Ch8.

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
set MACHINES_TXT=%DIR%\kubernetes-the-hard-way\machines.txt
for /f "tokens=1,3" %%i in ('type "%MACHINES_TXT%" ^| findstr "server"' ) do if "%%j"=="server" set SERVER_IP=%%i
if "!SERVER_IP!"=="" set SERVER_IP=192.168.56.10


scp "%DIR%\\kubernetes-the-hard-way\downloads\controller\kube-apiserver" "%DIR%\\kubernetes-the-hard-way\downloads\controller\kube-controller-manager" "%DIR%\\kubernetes-the-hard-way\downloads\controller\kube-scheduler" "%DIR%\\kubernetes-the-hard-way\downloads\client\kubectl" "%DIR%\\kubernetes-the-hard-way\units\kube-apiserver.service" "%DIR%\\kubernetes-the-hard-way\units\kube-controller-manager.service" "%DIR%\\kubernetes-the-hard-way\units\kube-scheduler.service" "%DIR%\\kubernetes-the-hard-way\configs\kube-scheduler.yaml" "%DIR%\\kubernetes-the-hard-way\configs\kube-apiserver-to-kubelet.yaml" root@server:~/
ssh root@server "mkdir -p /etc/kubernetes/config /var/lib/kubernetes/; mv -f kube-apiserver kube-controller-manager kube-scheduler kubectl /usr/local/bin/ || true; cp -f ca.crt ca.key kube-api-server.key kube-api-server.crt service-accounts.key service-accounts.crt encryption-config.yaml /var/lib/kubernetes/; mv -f kube-apiserver.service /etc/systemd/system/kube-apiserver.service || true; cp -f kube-controller-manager.kubeconfig /var/lib/kubernetes/ || true; mv -f kube-controller-manager.service /etc/systemd/system/ || true; cp -f kube-scheduler.kubeconfig /var/lib/kubernetes/ || true; mv -f kube-scheduler.yaml /etc/kubernetes/config/ || true; mv -f kube-scheduler.service /etc/systemd/system/ || true; systemctl daemon-reload; systemctl enable kube-apiserver kube-controller-manager kube-scheduler; systemctl start kube-apiserver kube-controller-manager kube-scheduler; sleep 10; kubectl cluster-info --kubeconfig admin.kubeconfig || true; kubectl apply -f kube-apiserver-to-kubelet.yaml --kubeconfig admin.kubeconfig || true"
curl --cacert "%LIBSCRIPT_DATA_DIR%\ca.crt" https://!SERVER_IP!:6443/version || true
