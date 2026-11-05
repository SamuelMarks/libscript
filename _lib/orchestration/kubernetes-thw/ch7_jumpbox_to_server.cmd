@echo off
:: # ch7_jumpbox_to_server.cmd
:: ## Overview
:: Automates Ch7 of Kubernetes the Hard Way.
:: ## Usage
:: Executes the steps for Ch7. setlocal EnableDelayedExpansion

set "THIS_FILE=%~f0"

if defined STACK (
    echo "!STACK!" | findstr /I /C:":!THIS_FILE!:" >nul 2>&1
    if not errorlevel 1 (
        echo [STOP] processing "!THIS_FILE!" >&2
        exit /b 0
    )
)
set "STACK=%STACK%:!THIS_FILE!:"

set "SCRIPT_DIR=%~dp0"
if "%SCRIPT_DIR:~-1%"=="\" set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"

if not defined LIBSCRIPT_ROOT_DIR (
    set "d=!SCRIPT_DIR!"
    call :find_root
)
goto :root_found

:: ## find_root
:: Ascends the directory tree looking for ROOT or libscript.cmd.
:find_root
if exist "!d!\libscript.cmd" (
    set "LIBSCRIPT_ROOT_DIR=!d!"
    exit /b 0
)
if exist "!d!\ROOT" (
    set "LIBSCRIPT_ROOT_DIR=!d!"
    exit /b 0
)
for %%P in ("!d!") do set "parent=%%~dpP"
set "d=!parent:~0,-1!"
if "!d!"=="" (
    echo Error: Could not find LIBSCRIPT_ROOT_DIR 1>&2
    exit /b 1
)
goto :find_root

:: ## root_found
:: Continues execution once LIBSCRIPT_ROOT_DIR is verified.
:root_found
set "DIR=!SCRIPT_DIR!"

scp "%DIR%\\kubernetes-the-hard-way\downloads\controller\etcd" "%DIR%\\kubernetes-the-hard-way\downloads\client\etcdctl" "%DIR%\\kubernetes-the-hard-way\units\etcd.service" root@server:~/
ssh root@server "mv -f etcd etcdctl /usr/local/bin/ || true; mkdir -p /etc/etcd /var/lib/etcd; chmod 700 /var/lib/etcd; cp -f ca.crt kube-api-server.key kube-api-server.crt /etc/etcd/; mv -f etcd.service /etc/systemd/system/; if [ -f $HOME/libscript/_lib/_common/service.sh ]; then SCRIPT_NAME=$HOME/libscript/_lib/_common/service.sh . $HOME/libscript/_lib/_common/service.sh; libscript_service daemon-reload etcd || true; libscript_service enable etcd || true; libscript_service start etcd || true; fi; etcdctl member list || true"
