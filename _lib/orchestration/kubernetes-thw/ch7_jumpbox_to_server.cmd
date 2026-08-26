@echo off
:: # ch7_jumpbox_to_server.cmd
::
:: ## Overview
:: Automates Ch7 of Kubernetes the Hard Way.
::
:: :::: Usage
:: Executes the steps for Ch7.

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

scp "%DIR%\\kubernetes-the-hard-way\downloads\controller\etcd" "%DIR%\\kubernetes-the-hard-way\downloads\client\etcdctl" "%DIR%\\kubernetes-the-hard-way\units\etcd.service" root@server:~/
ssh root@server "mv -f etcd etcdctl /usr/local/bin/ || true; mkdir -p /etc/etcd /var/lib/etcd; chmod 700 /var/lib/etcd; cp -f ca.crt kube-api-server.key kube-api-server.crt /etc/etcd/; mv -f etcd.service /etc/systemd/system/; systemctl daemon-reload; systemctl enable etcd; systemctl start etcd; etcdctl member list || true"
