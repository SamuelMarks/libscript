@echo off
:: # run_msi.cmd
::
:: ## Overview
:: Launches Windows Installer (.msi) packages via msiexec.exe.
:: Defaults to OpenEdX-Setup.msi if no package path is specified.
::
:: ## Usage
:: run_msi.cmd [path_to_msi]

setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"

set "SCRIPT_DIR=%~dp0"
if "%SCRIPT_DIR:~-1%"=="\" set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"

set "MSI_FILE=%~1"
if "%MSI_FILE%"=="" (
  if exist "%SCRIPT_DIR%\OpenEdX-Setup.msi" (
    set "MSI_FILE=%SCRIPT_DIR%\OpenEdX-Setup.msi"
  ) else if exist "C:\libscript\OpenEdX-Setup.msi" (
    set "MSI_FILE=C:\libscript\OpenEdX-Setup.msi"
  ) else (
    echo [ERROR] No MSI installer package found. Please specify the path to the .msi file. >&2
    exit /b 1
  )
)

start "" msiexec.exe /i "%MSI_FILE%"
exit /b %ERRORLEVEL%
