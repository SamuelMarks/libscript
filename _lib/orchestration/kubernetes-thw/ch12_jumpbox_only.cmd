@echo off
:: # ch12_jumpbox_only.cmd
::
:: ## Overview
:: Automates Ch12 of Kubernetes the Hard Way.
::
:: ## Usage
:: Executes the steps for Ch12.

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

cd %DIR%\\kubernetes-the-hard-way
kubectl create secret generic %DIR%\\kubernetes-the-hard-way --from-literal="mykey=mydata"
ssh root@server "etcdctl get /registry/secrets/default/%DIR%\\kubernetes-the-hard-way | hexdump -C"
kubectl create deployment nginx --image=nginx
kubectl rollout status deployment/nginx

for /f "tokens=*" %%a in ('kubectl get pod -l app^=nginx -o jsonpath^="{.items[0].metadata.name}"') do set POD_NAME=%%a
start /b kubectl port-forward "%POD_NAME%" 8080:80
timeout /t 5
curl -I http://127.0.0.1:8080
rem Taskkill won't trivially kill just this process without knowing PID, assuming test tear-down handles it.
kubectl logs "%POD_NAME%"
kubectl exec -ti "%POD_NAME%" -- nginx -v
cd ..
