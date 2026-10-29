@echo off
:: # setup_generic.cmd
::
:: ## Overview
:: Generic Windows setup and installation script for NSSM (Non-Sucking Service Manager).
:: Downloads or provisions nssm.exe (Win64) for managing native Windows Services.
::
:: ## Usage
:: Called internally by setup.cmd / cli.cmd.

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
if "%SCRIPT_DIR:~-1%"=="\" set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"

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
if "%NSSM_VERSION%"=="" set "NSSM_VERSION=2.24"
if "%NSSM_VERSION%"=="latest" set "NSSM_VERSION=2.24"
if "%LIBSCRIPT_HOME%"=="" set "LIBSCRIPT_HOME=%USERPROFILE%\.libscript"
if "%DOWNLOAD_DIR%"=="" set "DOWNLOAD_DIR=%TEMP%\libscript_downloads"

if "%ACTION%"=="ls" goto :action_ls
if "%ACTION%"=="ls-remote" goto :action_ls_remote
if "%ACTION%"=="use" goto :action_use
if "%ACTION%"=="download" goto :action_download
if "%ACTION%"=="install" goto :action_install
if "%ACTION%"=="start" goto :action_service
if "%ACTION%"=="stop" goto :action_service
if "%ACTION%"=="restart" goto :action_service
if "%ACTION%"=="status" goto :action_service
if "%ACTION%"=="health" goto :action_service
if "%ACTION%"=="logs" goto :action_service
if "%ACTION%"=="up" goto :action_service
if "%ACTION%"=="down" goto :action_service
if "%ACTION%"=="install-service" goto :action_install_service
if "%ACTION%"=="uninstall-service" goto :action_uninstall_service
goto :action_install

:: ## action_ls
:: Lists locally installed versions of nssm under LIBSCRIPT_HOME.
:action_ls
if exist "%LIBSCRIPT_HOME%\nssm" dir /b "%LIBSCRIPT_HOME%\nssm"
exit /b 0

:: ## action_ls_remote
:: Lists available upstream versions of nssm.
:action_ls_remote
echo 2.24
echo 2.23
exit /b 0

:: ## action_use
:: Activates the specified nssm version alias.
:action_use
set "TARGET_DIR=%LIBSCRIPT_HOME%\nssm\%NSSM_VERSION%"
set "ALIAS_DIR=%LIBSCRIPT_HOME%\nssm\latest"
if not "%TARGET_DIR%"=="%ALIAS_DIR%" (
    if exist "%ALIAS_DIR%" rmdir "%ALIAS_DIR%" >nul 2>&1
    if not exist "%ALIAS_DIR%" mklink /J "%ALIAS_DIR%" "%TARGET_DIR%" >nul 2>&1
)
exit /b 0

:: ## action_download
:: Downloads the nssm Win64 release zip archive to the local cache directory.
:action_download
if not exist "%DOWNLOAD_DIR%\nssm" mkdir "%DOWNLOAD_DIR%\nssm"
set "DL_URL=%NSSM_DOWNLOAD_URL%"
if "%DL_URL%"=="" set "DL_URL=https://nssm.cc/release/nssm-2.24.zip"
call "!LIBSCRIPT_ROOT_DIR!\_lib\_common\pkg_mgr.cmd" :libscript_download "%DL_URL%" "%DOWNLOAD_DIR%\nssm\nssm-%NSSM_VERSION%.zip"
exit /b 0

:: ## action_install
:: Installs and configures the requested version of nssm on Windows.
:action_install
set "TARGET_DIR=%LIBSCRIPT_HOME%\nssm\%NSSM_VERSION%"
if not "%NSSM_INSTALL_DIR%"=="" set "TARGET_DIR=%NSSM_INSTALL_DIR%"

if exist "%TARGET_DIR%\bin\nssm.exe" (
    echo [INFO] nssm %NSSM_VERSION% is already installed at %TARGET_DIR%.
    exit /b 0
)

if "%NSSM_INSTALL_METHOD%"=="system" (
    call "!LIBSCRIPT_ROOT_DIR!\_lib\_common\pkg_mgr.cmd" :libscript_depends nssm
    where nssm >nul 2>&1
    if not errorlevel 1 exit /b 0
)

if not exist "%TARGET_DIR%\bin" mkdir "%TARGET_DIR%\bin"
set "DL_URL=%NSSM_DOWNLOAD_URL%"
if "%DL_URL%"=="" set "DL_URL=https://nssm.cc/release/nssm-2.24.zip"

if exist "%DOWNLOAD_DIR%\nssm\nssm-%NSSM_VERSION%.zip" (
    tar -xf "%DOWNLOAD_DIR%\nssm\nssm-%NSSM_VERSION%.zip" -C "%TARGET_DIR%"
) else (
    call "!LIBSCRIPT_ROOT_DIR!\_lib\_common\pkg_mgr.cmd" :libscript_download "%DL_URL%" "%TEMP%\nssm.zip"
    if exist "%TEMP%\nssm.zip" tar -xf "%TEMP%\nssm.zip" -C "%TARGET_DIR%"
)

if exist "%TARGET_DIR%\nssm-2.24\win64\nssm.exe" (
    copy /y "%TARGET_DIR%\nssm-2.24\win64\nssm.exe" "%TARGET_DIR%\bin\nssm.exe" >nul 2>&1
)

set "ALIAS_DIR=%LIBSCRIPT_HOME%\nssm\latest"
if not "%TARGET_DIR%"=="%ALIAS_DIR%" (
    if exist "%ALIAS_DIR%" rmdir "%ALIAS_DIR%" >nul 2>&1
    if not exist "%ALIAS_DIR%" mklink /J "%ALIAS_DIR%" "%TARGET_DIR%" >nul 2>&1
)
exit /b 0

:: ## action_service
:: Routes service daemon control actions to the common handler.
:action_service
:: ## action_install_service
:: Registers the component as a persistent system service.
:action_install_service
:: ## action_uninstall_service
:: Removes the registered system service for the component.
:action_uninstall_service
set "STACK="
call "!LIBSCRIPT_ROOT_DIR!\_lib\_common\setup_base.cmd" :libscript_handle_generic_action "nssm" "%ACTION%" "%NSSM_VERSION%" "libscript_native" "" "" "" "\"%LIBSCRIPT_HOME%\nssm\%NSSM_VERSION%\bin\nssm.exe\"" "%LIBSCRIPT_HOME%\nssm\%NSSM_VERSION%"
exit /b !errorlevel!
