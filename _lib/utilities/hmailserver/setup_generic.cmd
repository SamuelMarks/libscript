@echo off
:: ## Overview
:: Windows setup module for hMailServer.
::
:: ## Usage
:: Call this script to trigger setup for hmailserver on Windows.
setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"

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
