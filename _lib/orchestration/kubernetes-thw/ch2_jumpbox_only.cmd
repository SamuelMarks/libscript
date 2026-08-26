@echo off
:: # ch2_jumpbox_only.cmd
::
:: ## Overview
:: Automates Ch2 of Kubernetes the Hard Way.
::
:: :::: Usage
:: Executes the steps for Ch2.

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

call libscript_depends wget curl vim openssl git tar
if not exist "%DIR%\\kubernetes-the-hard-way" (
  git clone --depth 1 https://github.com/kelseyhightower/%DIR%\\kubernetes-the-hard-way.git
)
cd %DIR%\\kubernetes-the-hard-way
if not exist downloads mkdir downloads
rem On Windows, downloading the Linux binaries so we can scp them to the nodes later.
rem We use AMD64 by default.
set ARCH=amd64
if /I "%PROCESSOR_ARCHITECTURE%"=="ARM64" set ARCH=arm64
for /f "tokens=*" %%a in (downloads-%ARCH%.txt) do (
  rem get filename from URL
  for %%F in ("%%a") do set "FILENAME=%%~nxF"
  if not exist "downloads\!FILENAME!" (
    curl -L -o "downloads\!FILENAME!" "%%a"
  )
)

if not exist downloads\client mkdir downloads\client
if not exist downloads\cni-plugins mkdir downloads\cni-plugins
if not exist downloads\controller mkdir downloads\controller
if not exist downloads\worker mkdir downloads\worker

if exist "downloads\crictl-v1.32.0-linux-%ARCH%.tar.gz" (
  tar -xzf "downloads\crictl-v1.32.0-linux-%ARCH%.tar.gz" -C downloads\worker\
)
rem Using curl for kubectl.exe since the linux one won't work locally on Windows
if not exist "downloads\client\kubectl.exe" (
  curl -L -o "downloads\client\kubectl.exe" "https://dl.k8s.io/release/v1.32.0/bin/windows/amd64/kubectl.exe"
)
copy /Y "downloads\client\kubectl.exe" "%SystemRoot%\System32\kubectl.exe" >nul 2>&1
kubectl version --client
cd ..
