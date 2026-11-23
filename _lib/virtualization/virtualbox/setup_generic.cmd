@echo off
:: # setup_generic.cmd
:: ## Overview
:: Generic setup and installation script for VirtualBox on Windows.
:: ## Usage
:: Call this script to install VirtualBox on Windows.

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
    set "d=!SCRIPT_DIR!"
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
if "%VIRTUALBOX_INSTALL_EXTPACK%"=="" set "VIRTUALBOX_INSTALL_EXTPACK=1"

if /i "%ACTION%"=="ls" goto :action_ls
if /i "%ACTION%"=="ls-remote" goto :action_ls_remote
if /i "%ACTION%"=="use" goto :action_use
if /i "%ACTION%"=="download" goto :action_download
if /i "%ACTION%"=="install" goto :action_install
if /i "%ACTION%"=="uninstall" goto :action_uninstall
exit /b 0

:: ## action_ls
:: Lists the installed VirtualBox version on Windows.
:action_ls
where VBoxManage >nul 2>&1
if not errorlevel 1 (
    VBoxManage --version
) else if exist "C:\Program Files\Oracle\VirtualBox\VBoxManage.exe" (
    "C:\Program Files\Oracle\VirtualBox\VBoxManage.exe" --version
) else (
    echo VirtualBox not installed.
)
exit /b 0

:: ## action_ls_remote
:: Lists supported upstream VirtualBox release tracks.
:action_ls_remote
echo 7.0
echo 7.1
exit /b 0

:: ## action_use
:: Selects VirtualBox version or triggers installation if missing.
:action_use
where VBoxManage >nul 2>&1
if errorlevel 1 (
    set "STACK="
    set "ACTION=install"
    call "!THIS_FILE!"
    exit /b !ERRORLEVEL!
)
exit /b 0

:: ## action_download
:: Pre-downloads the VirtualBox Extension Pack when VBoxManage version is known.
:action_download
if "%DOWNLOAD_DIR%"=="" set "DOWNLOAD_DIR=%TEMP%\libscript_downloads"
if not exist "%DOWNLOAD_DIR%\virtualbox" mkdir "%DOWNLOAD_DIR%\virtualbox"
echo [download] Prepared VirtualBox download cache at %DOWNLOAD_DIR%\virtualbox.
exit /b 0

:: ## action_install
:: Installs Oracle VirtualBox and optional Extension Pack on Windows.
:action_install
where VBoxManage >nul 2>&1
if "!errorlevel!" neq "0" (
    call "!LIBSCRIPT_ROOT_DIR!\engine\common\pkg_mgr.cmd" :libscript_depends virtualbox
) else (
    echo VirtualBox is already installed.
)
if "%VIRTUALBOX_INSTALL_EXTPACK%"=="1" (
    call "!LIBSCRIPT_ROOT_DIR!\engine\common\pkg_mgr.cmd" :libscript_depends Oracle.VirtualBoxExtensionPack 2>nul
)
exit /b 0

:: ## action_uninstall
:: Uninstalls Oracle VirtualBox via the active Windows package manager.
:action_uninstall
echo [INFO] Uninstalling VirtualBox...
call "!LIBSCRIPT_ROOT_DIR!\engine\common\pkg_mgr.cmd" :libscript_uninstall_pkg Oracle.VirtualBox 2>nul
call "!LIBSCRIPT_ROOT_DIR!\engine\common\pkg_mgr.cmd" :libscript_uninstall_pkg virtualbox 2>nul
exit /b 0
