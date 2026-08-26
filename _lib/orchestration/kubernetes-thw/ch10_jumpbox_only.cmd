@echo off
:: # ch10_jumpbox_only.cmd
::
:: ## Overview
:: Automates Ch10 of Kubernetes the Hard Way.
::
:: :::: Usage
:: Executes the steps for Ch10.

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
