@echo off
:: # setup_generic.cmd
:: ## Overview
:: Windows setup for gcp
::
:: ## Usage
:: Managed by libscript. Provides download, install, ls, ls-remote, use capabilities.
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

if "%ACTION%"=="" set ACTION=install
if "%GCP_VERSION%"=="" set GCP_VERSION=latest

if "%LIBSCRIPT_HOME%"=="" (
    set "LIBSCRIPT_HOME=%USERPROFILE%\.libscript"
)
if "%DOWNLOAD_DIR%"=="" (
    set "DOWNLOAD_DIR=%TEMP%\libscript_downloads"
)

:: Resolve install method
if "%GCP_INSTALL_METHOD%"=="" (
    if not "%LIBSCRIPT_DEFAULT_INSTALL_METHOD%"=="" (
        set "GCP_INSTALL_METHOD=%LIBSCRIPT_DEFAULT_INSTALL_METHOD%"
    ) else (
        set "GCP_INSTALL_METHOD=libscript_native"
    )
)

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
if /i "%ACTION%"=="group" goto :action_group
if /i "%ACTION%"=="project" goto :action_group
if /i "%ACTION%"=="network" goto :action_network
if /i "%ACTION%"=="firewall" goto :action_firewall
if /i "%ACTION%"=="storage" goto :action_storage
if /i "%ACTION%"=="dns" goto :action_dns
if /i "%ACTION%"=="auth" goto :action_auth
if /i "%ACTION%"=="location" goto :action_location
if /i "%ACTION%"=="node" goto :action_node
if /i "%~1"=="group" goto :action_group
if /i "%~1"=="project" goto :action_group
if /i "%~1"=="network" goto :action_network
if /i "%~1"=="firewall" goto :action_firewall
if /i "%~1"=="storage" goto :action_storage
if /i "%~1"=="dns" goto :action_dns
if /i "%~1"=="auth" goto :action_auth
if /i "%~1"=="location" goto :action_location
if /i "%~1"=="node" goto :action_node
goto :action_install

:: ## action_ls
:: Lists all locally installed versions of the component under LIBSCRIPT_HOME.
:action_ls
if "%GCP_INSTALL_METHOD%"=="system" ( echo System package manager does not support ls directly here. & exit /b 0 )
if exist "%LIBSCRIPT_HOME%\gcp" ( dir /b "%LIBSCRIPT_HOME%\gcp" )
exit /b 0

:: ## action_ls_remote
:: Lists upstream release versions available for download.
:action_ls_remote
if "%GCP_INSTALL_METHOD%"=="system" ( echo System package manager does not support ls-remote directly here. & exit /b 0 )
if not "%GCP_RELEASES_URL%"=="" (
    call "!LIBSCRIPT_ROOT_DIR!\_lib\_common\pkg_mgr.cmd" :libscript_fetch_stdout "%GCP_RELEASES_URL%"
) else (
    git ls-remote --tags "https://github.com/priyankavergadia/GCPSketchnote" 2^>nul ^| findstr /R "[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*"
)
exit /b 0

:: ## action_use
:: Activates the specified component version by updating the active symlink or junction.
:action_use
if "%GCP_INSTALL_METHOD%"=="system" ( echo Cannot 'use' specific version with system package manager. & exit /b 0 )

if "%GCP_VERSION%"=="latest" (set "EXACT_VERSION=%GCP_VERSION%"
) else if "%GCP_VERSION%"=="lts" (set "EXACT_VERSION=%GCP_VERSION%"
) else (
    set "EXACT_VERSION=%GCP_VERSION%"
)
if "%EXACT_VERSION%"=="" set "EXACT_VERSION=%GCP_VERSION%"

set "TARGET_DIR=%LIBSCRIPT_HOME%\gcp\%EXACT_VERSION%"
set "ALIAS_DIR=%LIBSCRIPT_HOME%\gcp\%GCP_VERSION%"

if not "%TARGET_DIR%"=="%ALIAS_DIR%" (
    if exist "%ALIAS_DIR%" (
        dir /al "%ALIAS_DIR%" >nul 2>&1
        if not errorlevel 1 rmdir "%ALIAS_DIR%" >nul 2>&1
    )
    if not exist "%ALIAS_DIR%" mklink /J "%ALIAS_DIR%" "%TARGET_DIR%" >nul 2>&1
)
exit /b 0

:: ## action_download
:: Downloads the component release archive into the local offline cache directory.
:action_download
if "%GCP_INSTALL_METHOD%"=="libscript_native" (
    echo Downloading gcp %GCP_VERSION% to %DOWNLOAD_DIR%\gcp...
    if not exist "%DOWNLOAD_DIR%\gcp" mkdir "%DOWNLOAD_DIR%\gcp"
    if not "%GCP_DOWNLOAD_URL%"=="" (
        call "!LIBSCRIPT_ROOT_DIR!\_lib\_common\pkg_mgr.cmd" :libscript_download "%GCP_DOWNLOAD_URL%" "%DOWNLOAD_DIR%\gcp\gcp-%GCP_VERSION%.zip"
    ) else (
        echo GCP_DOWNLOAD_URL is not defined. Skipping.
    )
)
exit /b 0

:: ## action_install
:: Installs and configures the requested version of the component.
:action_install
if "%GCP_INSTALL_METHOD%"=="system" (
    call "!LIBSCRIPT_ROOT_DIR!\_lib\_common\pkg_mgr.cmd" :libscript_depends gcp
    exit /b !errorlevel!
)

set "TARGET_DIR=%LIBSCRIPT_HOME%\gcp\%GCP_VERSION%"
if not exist "%TARGET_DIR%\bin" (
    echo Installing gcp %GCP_VERSION% natively to %TARGET_DIR%...
    if not exist "%TARGET_DIR%\bin" mkdir "%TARGET_DIR%\bin"
    if exist "%DOWNLOAD_DIR%\gcp\gcp-%GCP_VERSION%.zip" (
        echo Extracting from cache...
        tar -xf "%DOWNLOAD_DIR%\gcp\gcp-%GCP_VERSION%.zip" -C "%TARGET_DIR%"
    ) else if exist "%DOWNLOAD_DIR%\gcp\gcp-%GCP_VERSION%.tar.gz" (
        echo Extracting from cache...
        tar -xf "%DOWNLOAD_DIR%\gcp\gcp-%GCP_VERSION%.tar.gz" -C "%TARGET_DIR%"
    ) else if not "%GCP_DOWNLOAD_URL%"=="" (
        echo Downloading and extracting...
        call "!LIBSCRIPT_ROOT_DIR!\_lib\_common\pkg_mgr.cmd" :libscript_download "%GCP_DOWNLOAD_URL%" "%TEMP%\gcp.zip"
        tar -xf "%TEMP%\gcp.zip" -C "%TARGET_DIR%"
    ) else (
        echo No download URL or cache available for gcp.
        exit /b 1
    )
) else (
    echo gcp %GCP_VERSION% is already installed.
)
set "ALIAS_DIR=%LIBSCRIPT_HOME%\gcp\%GCP_VERSION%"
if not "%TARGET_DIR%"=="%ALIAS_DIR%" (
    if exist "%ALIAS_DIR%" (
        dir /al "%ALIAS_DIR%" >nul 2>&1
        if not errorlevel 1 rmdir "%ALIAS_DIR%" >nul 2>&1
    )
    if not exist "%ALIAS_DIR%" mklink /J "%ALIAS_DIR%" "%TARGET_DIR%" >nul 2>&1
)
exit /b 0

:: ## action_service
:: Routes service daemon control actions (start, stop, restart, status) to the common handler.
:action_service
:: ## action_install_service
:: Registers and configures the component as a persistent system service.
:action_install_service
:: ## action_uninstall_service
:: Stops and removes the registered system service for the component.
:action_uninstall_service
set "STACK="
call "!LIBSCRIPT_ROOT_DIR!\_lib\_common\setup_base.cmd" :libscript_handle_generic_action "gcp" "%ACTION%" "%GCP_VERSION%" "%GCP_INSTALL_METHOD%" "" "" "" "\"%LIBSCRIPT_HOME%\gcp\%GCP_VERSION%\\bin\\gcp.exe\"" "%LIBSCRIPT_HOME%\gcp\%GCP_VERSION%"
exit /b !errorlevel!
