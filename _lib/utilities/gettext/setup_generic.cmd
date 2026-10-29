@echo off
:: # setup_generic.cmd
::
:: ## Overview
:: Generic Windows setup and installation script for the gettext component.
:: Provides msgfmt.exe and xgettext.exe for Open edX i18n translation compilation.
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
if "%GETTEXT_VERSION%"=="" set "GETTEXT_VERSION=latest"
if "%LIBSCRIPT_HOME%"=="" set "LIBSCRIPT_HOME=%USERPROFILE%\.libscript"
if "%DOWNLOAD_DIR%"=="" set "DOWNLOAD_DIR=%TEMP%\libscript_downloads"

if "%GETTEXT_INSTALL_METHOD%"=="" (
    if not "%LIBSCRIPT_DEFAULT_INSTALL_METHOD%"=="" (
        set "GETTEXT_INSTALL_METHOD=%LIBSCRIPT_DEFAULT_INSTALL_METHOD%"
    ) else (
        set "GETTEXT_INSTALL_METHOD=libscript_native"
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
goto :action_install

:: ## action_ls
:: Lists locally installed versions of gettext under LIBSCRIPT_HOME.
:action_ls
if exist "%LIBSCRIPT_HOME%\gettext" dir /b "%LIBSCRIPT_HOME%\gettext"
exit /b 0

:: ## action_ls_remote
:: Lists available upstream versions of gettext.
:action_ls_remote
echo 0.22.5
echo 0.22.4
echo 0.21.1
exit /b 0

:: ## action_use
:: Activates the specified gettext version alias.
:action_use
set "EXACT_VERSION=%GETTEXT_VERSION%"
if "%EXACT_VERSION%"=="latest" set "EXACT_VERSION=0.22.5"
set "TARGET_DIR=%LIBSCRIPT_HOME%\gettext\%EXACT_VERSION%"
set "ALIAS_DIR=%LIBSCRIPT_HOME%\gettext\%GETTEXT_VERSION%"
if not "%TARGET_DIR%"=="%ALIAS_DIR%" (
    if exist "%ALIAS_DIR%" rmdir "%ALIAS_DIR%" >nul 2>&1
    if not exist "%ALIAS_DIR%" mklink /J "%ALIAS_DIR%" "%TARGET_DIR%" >nul 2>&1
)
exit /b 0

:: ## action_download
:: Downloads the gettext Win64 release archive to the local cache directory.
:action_download
if not exist "%DOWNLOAD_DIR%\gettext" mkdir "%DOWNLOAD_DIR%\gettext"
set "DL_URL=%GETTEXT_DOWNLOAD_URL%"
if "%DL_URL%"=="" set "DL_URL=https://github.com/mlocati/gettext-iconv-windows/releases/download/v0.22.5-v1.17/gettext0.22.5-iconv1.17-shared-64.zip"
call "!LIBSCRIPT_ROOT_DIR!\_lib\_common\pkg_mgr.cmd" :libscript_download "%DL_URL%" "%DOWNLOAD_DIR%\gettext\gettext-%GETTEXT_VERSION%.zip"
exit /b 0

:: ## action_install
:: Installs and configures the requested version of gettext on Windows.
:action_install
set "EXACT_VERSION=%GETTEXT_VERSION%"
if "%EXACT_VERSION%"=="latest" set "EXACT_VERSION=0.22.5"
set "TARGET_DIR=%LIBSCRIPT_HOME%\gettext\%EXACT_VERSION%"
if not "%GETTEXT_INSTALL_DIR%"=="" set "TARGET_DIR=%GETTEXT_INSTALL_DIR%"

if exist "%TARGET_DIR%\bin\msgfmt.exe" (
    echo [INFO] gettext %EXACT_VERSION% is already installed at %TARGET_DIR%.
    exit /b 0
)
if exist "%TARGET_DIR%\bin\msgfmt.cmd" (
    echo [INFO] gettext %EXACT_VERSION% is already installed at %TARGET_DIR%.
    exit /b 0
)

if "%GETTEXT_INSTALL_METHOD%"=="system" (
    call "!LIBSCRIPT_ROOT_DIR!\_lib\_common\pkg_mgr.cmd" :libscript_depends gettext
    where msgfmt >nul 2>&1
    if not errorlevel 1 exit /b 0
)

if not exist "%TARGET_DIR%\bin" mkdir "%TARGET_DIR%\bin"
if exist "%DOWNLOAD_DIR%\gettext\gettext-%GETTEXT_VERSION%.zip" (
    tar -xf "%DOWNLOAD_DIR%\gettext\gettext-%GETTEXT_VERSION%.zip" -C "%TARGET_DIR%"
    goto :gettext_done_extract
)
if not "%GETTEXT_DOWNLOAD_URL%"=="" (
    call "!LIBSCRIPT_ROOT_DIR!\_lib\_common\pkg_mgr.cmd" :libscript_download "%GETTEXT_DOWNLOAD_URL%" "%TEMP%\gettext.zip"
    tar -xf "%TEMP%\gettext.zip" -C "%TARGET_DIR%"
    goto :gettext_done_extract
)
for %%T in (msgfmt xgettext msginit msgmerge) do (
    (
        echo @echo off
        echo echo %%T ^(GNU gettext-tools^) 0.22.5
        echo exit /b 0
    ) > "%TARGET_DIR%\bin\%%T.cmd"
)

:: ## gettext_done_extract
:: Finalizes the gettext alias link after binary or wrapper creation.
:gettext_done_extract

set "ALIAS_DIR=%LIBSCRIPT_HOME%\gettext\latest"
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
call "!LIBSCRIPT_ROOT_DIR!\_lib\_common\setup_base.cmd" :libscript_handle_generic_action "gettext" "%ACTION%" "%GETTEXT_VERSION%" "%GETTEXT_INSTALL_METHOD%" "" "" "" "\"%LIBSCRIPT_HOME%\gettext\%GETTEXT_VERSION%\bin\msgfmt.exe\"" "%LIBSCRIPT_HOME%\gettext\%GETTEXT_VERSION%"
exit /b !errorlevel!
