@echo off
:: # setup_generic.cmd
:: ## Overview
:: Windows setup for cli
::
:: ## Usage
:: Managed by libscript. Provides download, install, ls, ls-remote, use capabilities.
setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"

if defined STACK (
    echo "!STACK!" | findstr /C:":!THIS_FILE!:" >nul 2>&1
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
if "%CLI_VERSION%"=="" set CLI_VERSION=latest

if "%LIBSCRIPT_HOME%"=="" (
    set "LIBSCRIPT_HOME=%USERPROFILE%\.libscript"
)
if "%DOWNLOAD_DIR%"=="" (
    set "DOWNLOAD_DIR=%TEMP%\libscript_downloads"
)

:: Resolve install method
if "%CLI_INSTALL_METHOD%"=="" (
    if not "%LIBSCRIPT_DEFAULT_INSTALL_METHOD%"=="" (
        set "CLI_INSTALL_METHOD=%LIBSCRIPT_DEFAULT_INSTALL_METHOD%"
    ) else (
        set "CLI_INSTALL_METHOD=libscript_native"
    )
)

if "%ACTION%"=="ls" goto :action_ls
if "%ACTION%"=="ls-remote" goto :action_ls_remote
if "%ACTION%"=="use" goto :action_use
if "%ACTION%"=="download" goto :action_download
if "%ACTION%"=="install" goto :action_install
goto :action_install

:: ## action_ls
:: Lists all locally installed versions of the component under LIBSCRIPT_HOME.
:action_ls
if "%CLI_INSTALL_METHOD%"=="mise" ( mise ls cli & exit /b 0 )
if "%CLI_INSTALL_METHOD%"=="asdf" ( asdf list cli & exit /b 0 )
if "%CLI_INSTALL_METHOD%"=="pkgx" ( echo pkgx does not have a local list command & exit /b 0 )
if "%CLI_INSTALL_METHOD%"=="vfox" ( vfox ls cli & exit /b 0 )
if "%CLI_INSTALL_METHOD%"=="system" ( echo System package manager does not support ls directly here. & exit /b 0 )
dir /b "%LIBSCRIPT_HOME%\cli\" 2>nul
exit /b 0

:: ## action_ls_remote
:: Lists upstream release versions available for download.
:action_ls_remote
if "%CLI_INSTALL_METHOD%"=="mise" ( mise ls-remote cli & exit /b 0 )
if "%CLI_INSTALL_METHOD%"=="asdf" ( asdf list all cli & exit /b 0 )
if "%CLI_INSTALL_METHOD%"=="pkgx" ( echo pkgx does not have a local list command & exit /b 0 )
if "%CLI_INSTALL_METHOD%"=="vfox" ( vfox ls all cli & exit /b 0 )
if "%CLI_INSTALL_METHOD%"=="system" ( echo System package manager does not support ls-remote directly here. & exit /b 0 )
if not "%CLI_RELEASES_URL%"=="" (
    curl -sSL "%CLI_RELEASES_URL%"
) else (
    git ls-remote --tags "https://github.com/googleapis/google-cloud-cpp" 2^>nul ^| findstr /R "[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*"
)
exit /b 0

:: ## action_use
:: Activates the specified component version by updating the active symlink or junction.
:action_use
if "%CLI_INSTALL_METHOD%"=="mise" ( mise use "cli@%CLI_VERSION%" & exit /b 0 )
if "%CLI_INSTALL_METHOD%"=="asdf" ( asdf global cli "%CLI_VERSION%" & exit /b 0 )
if "%CLI_INSTALL_METHOD%"=="pkgx" ( echo pkgx does not use explicit versions this way & exit /b 0 )
if "%CLI_INSTALL_METHOD%"=="vfox" ( vfox use "cli@%CLI_VERSION%" & exit /b 0 )
if "%CLI_INSTALL_METHOD%"=="system" ( echo Cannot 'use' specific version with system package manager. & exit /b 0 )
echo libscript_symlink_alias not implemented natively in cmd yet.
exit /b 0

:: ## action_download
:: Downloads the component release archive into the local offline cache directory.
:action_download
if "%CLI_INSTALL_METHOD%"=="libscript_native" (
    echo Downloading cli %CLI_VERSION% to %DOWNLOAD_DIR%\cli...
    if not exist "%DOWNLOAD_DIR%\cli" mkdir "%DOWNLOAD_DIR%\cli"
    if not "%CLI_DOWNLOAD_URL%"=="" (
        curl -sSL "%CLI_DOWNLOAD_URL%" -o "%DOWNLOAD_DIR%\cli\cli-%CLI_VERSION%.zip"
    ) else (
        echo CLI_DOWNLOAD_URL is not defined. Skipping.
    )
)
exit /b 0

:: ## action_install
:: Installs and configures the requested version of the component.
:action_install
if exist "%LIBSCRIPT_HOME%\gcp-cli\%VERSION%" (
    echo [INFO] gcp-cli %VERSION% is already installed.
    exit /b 0
)
if "%CLI_INSTALL_METHOD%"=="system" (
    winget install cli --accept-package-agreements --accept-source-agreements
    exit /b !errorlevel!
)
