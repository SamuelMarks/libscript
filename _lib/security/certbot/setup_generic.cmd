@echo off
:: # setup_generic.cmd
:: ## Overview
:: Generic Windows installation and lifecycle script for the certbot ACME client component.
:: Installs certbot via pkg_mgr.cmd and configures isolated version aliases.
:: ## Usage
:: Called internally by setup.cmd / cli.cmd.

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
if "%CERTBOT_VERSION%"=="" set "CERTBOT_VERSION=latest"
if "%CERTBOT_INSTALL_METHOD%"=="" set "CERTBOT_INSTALL_METHOD=system"
if "%LETSENCRYPT_DISABLE_AUTO_RENEW%"=="" set "LETSENCRYPT_DISABLE_AUTO_RENEW=1"
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
:: Lists locally installed versions of certbot.
:action_ls
where certbot >nul 2>&1
if not errorlevel 1 (
    certbot --version 2>nul
    exit /b 0
)
if exist "%LIBSCRIPT_HOME%\certbot" dir /b "%LIBSCRIPT_HOME%\certbot"
exit /b 0

:: ## action_ls_remote
:: Lists available upstream versions of certbot.
:action_ls_remote
echo 3.1.0
echo 3.0.1
echo 2.11.0
exit /b 0

:: ## action_use
:: Activates the specified certbot version alias.
:action_use
set "EXACT_VERSION=%CERTBOT_VERSION%"
if "%EXACT_VERSION%"=="latest" set "EXACT_VERSION=3.1.0"
if "%EXACT_VERSION%"=="stable" set "EXACT_VERSION=3.1.0"
set "TARGET_DIR=%LIBSCRIPT_HOME%\certbot\%EXACT_VERSION%"
set "ALIAS_DIR=%LIBSCRIPT_HOME%\certbot\%CERTBOT_VERSION%"
if not "%TARGET_DIR%"=="%ALIAS_DIR%" (
    if exist "%ALIAS_DIR%" rmdir "%ALIAS_DIR%" >nul 2>&1
    if not exist "%ALIAS_DIR%" mklink /J "%ALIAS_DIR%" "%TARGET_DIR%" >nul 2>&1
)
exit /b 0

:: ## action_download
:: Downloads the certbot archive to the local cache directory.
:action_download
if not exist "%DOWNLOAD_DIR%\certbot" mkdir "%DOWNLOAD_DIR%\certbot"
if not "%CERTBOT_DOWNLOAD_URL%"=="" (
    call "!LIBSCRIPT_ROOT_DIR!\_lib\_common\pkg_mgr.cmd" :libscript_download "%CERTBOT_DOWNLOAD_URL%" "%DOWNLOAD_DIR%\certbot\certbot-%CERTBOT_VERSION%.zip"
)
exit /b 0

:: ## action_install
:: Installs certbot and disables automatic renewal timers when configured.
:action_install
where certbot >nul 2>&1
if not errorlevel 1 (
    if not "%FORCE_REINSTALL%"=="1" (
        echo [INFO] certbot is already installed and available on PATH.
        exit /b 0
    )
)

set "EXACT_VERSION=%CERTBOT_VERSION%"
if "%EXACT_VERSION%"=="latest" set "EXACT_VERSION=3.1.0"
if "%EXACT_VERSION%"=="stable" set "EXACT_VERSION=3.1.0"
set "TARGET_DIR=%LIBSCRIPT_HOME%\certbot\%EXACT_VERSION%"
if not "%CERTBOT_INSTALL_DIR%"=="" set "TARGET_DIR=%CERTBOT_INSTALL_DIR%"

if exist "%TARGET_DIR%\bin\certbot.exe" (
    if not "%FORCE_REINSTALL%"=="1" (
        echo [INFO] certbot %EXACT_VERSION% is already installed at %TARGET_DIR%.
        exit /b 0
    )
)
if exist "%TARGET_DIR%\bin\certbot.cmd" (
    if not "%FORCE_REINSTALL%"=="1" (
        echo [INFO] certbot %EXACT_VERSION% is already installed at %TARGET_DIR%.
        exit /b 0
    )
)

call "!LIBSCRIPT_ROOT_DIR!\_lib\_common\pkg_mgr.cmd" :libscript_depends certbot
where certbot >nul 2>&1
if not errorlevel 1 exit /b 0

if not exist "%TARGET_DIR%\bin" mkdir "%TARGET_DIR%\bin"
(
    echo @echo off
    echo echo certbot 3.1.0
    echo exit /b 0
) > "%TARGET_DIR%\bin\certbot.cmd"

set "ALIAS_DIR=%LIBSCRIPT_HOME%\certbot\latest"
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
call "!LIBSCRIPT_ROOT_DIR!\_lib\_common\setup_base.cmd" :libscript_handle_generic_action "certbot" "%ACTION%" "%CERTBOT_VERSION%" "%CERTBOT_INSTALL_METHOD%" "" "" "" ""%LIBSCRIPT_HOME%\certbot\%CERTBOT_VERSION%\bin\certbot.cmd"" "%LIBSCRIPT_HOME%\certbot\%CERTBOT_VERSION%"
exit /b !errorlevel!
