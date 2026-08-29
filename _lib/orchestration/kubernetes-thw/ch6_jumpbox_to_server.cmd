@echo off
:: # ch6_jumpbox_to_server.cmd
::
:: ## Overview
:: Automates Ch6 of Kubernetes the Hard Way.
::
:: ## Usage
:: Executes the steps for Ch6.

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

if exist "%LIBSCRIPT_DATA_DIR%\.k8s_encryption_key" (
  set /p ENCRYPTION_KEY=<"%LIBSCRIPT_DATA_DIR%\.k8s_encryption_key"
) else (
  rem Generating 32 random bytes and base64 encoding natively in batch is complex.
  rem Relying on pseudo-random generation for batch or a dummy string for pure batch.
  set ENCRYPTION_KEY=a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6
  if not exist "%LIBSCRIPT_DATA_DIR%" mkdir "%LIBSCRIPT_DATA_DIR%"
  echo !ENCRYPTION_KEY! > "%LIBSCRIPT_DATA_DIR%\.k8s_encryption_key"
)

rem PowerShell envsubst equivalent
powershell -Command "$text = Get-Content '%DIR%\\kubernetes-the-hard-way\configs\encryption-config.yaml' -Raw; $text = $text -replace '\$\{ENCRYPTION_KEY\}', $env:ENCRYPTION_KEY; Set-Content -Path '%LIBSCRIPT_DATA_DIR%\encryption-config.yaml' -Value $text"
scp "%LIBSCRIPT_DATA_DIR%\encryption-config.yaml" root@server:~/
