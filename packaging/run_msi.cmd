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

if defined STACK (
    echo !STACK! | findstr /C:":%THIS_FILE%:" >nul 2>&1
    if not errorlevel 1 (
        echo [STOP] processing "%THIS_FILE%" >&2
        exit /b 0
    )
)
set "STACK=%STACK%:%THIS_FILE%:"

set "SCRIPT_DIR=%~dp0"
if "%SCRIPT_DIR:~-1%"=="" set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"

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
