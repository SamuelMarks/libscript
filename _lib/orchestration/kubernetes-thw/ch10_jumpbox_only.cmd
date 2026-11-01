@echo off
:: # ch10_jumpbox_only.cmd
::
:: ## Overview
:: Automates Ch10 of Kubernetes the Hard Way.
::
:: ## Usage
:: Executes the steps for Ch10.

setlocal EnableDelayedExpansion

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
    set "d=%SCRIPT_DIR%"
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

cd %DIR%\kubernetes-the-hard-way

for /f "tokens=1" %%a in ('findstr /c:"server" "%DIR%\kubernetes-the-hard-way\machines.txt"') do set KUBERNETES_PUBLIC_ADDRESS=%%a

curl --cacert "%LIBSCRIPT_DATA_DIR%\ca.crt" https://%KUBERNETES_PUBLIC_ADDRESS%:6443/version || true
kubectl config set-cluster kubernetes-the-hard-way --certificate-authority="%LIBSCRIPT_DATA_DIR%\ca.crt" --embed-certs=true --server=https://%KUBERNETES_PUBLIC_ADDRESS%:6443
kubectl config set-credentials admin --client-certificate="%LIBSCRIPT_DATA_DIR%\admin.crt" --client-key="%LIBSCRIPT_DATA_DIR%\admin.key"
kubectl config set-context %DIR%\\kubernetes-the-hard-way --cluster=%DIR%\\kubernetes-the-hard-way --user=admin
kubectl config use-context %DIR%\\kubernetes-the-hard-way
kubectl version || true
kubectl get nodes || true
cd ..
