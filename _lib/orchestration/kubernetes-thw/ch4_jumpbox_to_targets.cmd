@echo off
:: # ch4_jumpbox_to_targets.cmd
::
:: ## Overview
:: Automates Ch4 of Kubernetes the Hard Way.
::
:: :::: Usage
:: Executes the steps for Ch4.

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

call libscript_depends openssl

set CA_CONF=%DIR%\\kubernetes-the-hard-way\ca.conf
if not exist "%CA_CONF%" (
  echo Error: %CA_CONF% not found
  exit /b 1
)

set MACHINES_TXT=%DIR%\\kubernetes-the-hard-way\machines.txt
if not exist "%MACHINES_TXT%" (
  echo Error: %MACHINES_TXT% not found
  exit /b 1
)

set NODES=
for /f "tokens=3" %%a in ('type "%MACHINES_TXT%" ^| findstr "node-"') do (
  set NODES=!NODES! %%a
)
if "!NODES!"=="" set NODES=node-0 node-1
for %%i in (%NODES%) do (
  findstr /c:"[%%i]" "%CA_CONF%" >nul
  if errorlevel 1 (
    echo.>>"%CA_CONF%"
    echo [%%i]>>"%CA_CONF%"
    echo distinguished_name = %%i_distinguished_name>>"%CA_CONF%"
    echo prompt             = no>>"%CA_CONF%"
    echo req_extensions     = %%i_req_extensions>>"%CA_CONF%"
    echo.>>"%CA_CONF%"
    echo [%%i_req_extensions]>>"%CA_CONF%"
    echo basicConstraints     = CA:FALSE>>"%CA_CONF%"
    echo extendedKeyUsage     = clientAuth, serverAuth>>"%CA_CONF%"
    echo keyUsage             = critical, digitalSignature, keyEncipherment>>"%CA_CONF%"
    echo nsCertType           = client>>"%CA_CONF%"
    echo nsComment            = "%%i Certificate">>"%CA_CONF%"
    echo subjectAltName       = DNS:%%i, IP:127.0.0.1>>"%CA_CONF%"
    echo subjectKeyIdentifier = hash>>"%CA_CONF%"
    echo.>>"%CA_CONF%"
    echo [%%i_distinguished_name]>>"%CA_CONF%"
    echo CN = system:node:%%i>>"%CA_CONF%"
    echo O  = system:nodes>>"%CA_CONF%"
    echo C  = US>>"%CA_CONF%"
    echo ST = Washington>>"%CA_CONF%"
    echo L  = Seattle>>"%CA_CONF%"
  )
)

if not exist "%LIBSCRIPT_DATA_DIR%\ca.key" (
  openssl genrsa -out "%LIBSCRIPT_DATA_DIR%\ca.key" 4096
  openssl req -x509 -new -sha512 -noenc -key "%LIBSCRIPT_DATA_DIR%\ca.key" -days 3653 -config "%CA_CONF%" -out "%LIBSCRIPT_DATA_DIR%\ca.crt"
)

set CERTS=%NODES% admin kube-proxy kube-scheduler kube-controller-manager kube-api-server service-accounts
for %%i in (%CERTS%) do (
  if not exist "%LIBSCRIPT_DATA_DIR%\%%i.key" (
    openssl genrsa -out "%LIBSCRIPT_DATA_DIR%\%%i.key" 4096
    openssl req -new -key "%LIBSCRIPT_DATA_DIR%\%%i.key" -sha256 -config "%CA_CONF%" -section "%%i" -out "%LIBSCRIPT_DATA_DIR%\%%i.csr"
    openssl x509 -req -days 3653 -in "%LIBSCRIPT_DATA_DIR%\%%i.csr" -copy_extensions copyall -sha256 -CA "%LIBSCRIPT_DATA_DIR%\ca.crt" -CAkey "%LIBSCRIPT_DATA_DIR%\ca.key" -CAcreateserial -out "%LIBSCRIPT_DATA_DIR%\%%i.crt"
  )
)

scp "%LIBSCRIPT_DATA_DIR%\ca.key" "%LIBSCRIPT_DATA_DIR%\ca.crt" "%LIBSCRIPT_DATA_DIR%\kube-api-server.key" "%LIBSCRIPT_DATA_DIR%\kube-api-server.crt" "%LIBSCRIPT_DATA_DIR%\service-accounts.key" "%LIBSCRIPT_DATA_DIR%\service-accounts.crt" root@server:~/

for %%i in (%NODES%) do (
  scp "%LIBSCRIPT_DATA_DIR%\ca.crt" "%LIBSCRIPT_DATA_DIR%\%%i.key" "%LIBSCRIPT_DATA_DIR%\%%i.crt" root@%%i:~/
)
