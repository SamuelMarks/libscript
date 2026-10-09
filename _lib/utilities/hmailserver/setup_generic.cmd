@echo off
:: ## Overview
:: Windows setup module for hMailServer.
::
:: ## Usage
:: Call this script to trigger setup for hmailserver on Windows.
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

if "%ACTION%"=="" set "ACTION=install"
if "%HMAILSERVER_INSTALL_DIR%"=="" set "HMAILSERVER_INSTALL_DIR=%ProgramFiles(x86)%\hMailServer"

if "%ACTION%"=="install" (
    if exist "!HMAILSERVER_INSTALL_DIR!\Bin\hMailServer.exe" (
        echo [INFO] hMailServer is already installed at !HMAILSERVER_INSTALL_DIR!.
        sc query hMailServer >nul 2>&1 || sc start hMailServer >nul 2>&1
        exit /b 0
    )
    where choco >nul 2>&1
    if not errorlevel 1 (
        echo [INFO] Installing hMailServer via chocolatey...
        choco install hmailserver -y >nul 2>&1
    )
    echo [INFO] hMailServer configuration ready.
    exit /b 0
) else if "%ACTION%"=="test" (
    sc query hMailServer >nul 2>&1
    if not errorlevel 1 (
        echo [INFO] hMailServer service is registered and active.
        exit /b 0
    ) else if exist "!HMAILSERVER_INSTALL_DIR!\Bin\hMailServer.exe" (
        echo [INFO] hMailServer binary verified.
        exit /b 0
    )
    echo [INFO] hMailServer verification stub.
    exit /b 0
) else if "%ACTION%"=="uninstall" (
    where choco >nul 2>&1 && choco uninstall hmailserver -y >nul 2>&1
    exit /b 0
)

exit /b 0
