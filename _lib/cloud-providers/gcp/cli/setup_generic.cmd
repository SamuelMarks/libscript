@echo off
:: ## Overview
:: Windows setup for cli
::
:: ## Usage
:: Managed by libscript. Provides download, install, ls, ls-remote, use capabilities.
set "THIS_FILE=%~f0"

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
:: Executes action_ls functionality.
:action_ls
if "%CLI_INSTALL_METHOD%"=="mise" ( mise ls cli & exit /b 0 )
if "%CLI_INSTALL_METHOD%"=="asdf" ( asdf list cli & exit /b 0 )
if "%CLI_INSTALL_METHOD%"=="pkgx" ( echo pkgx does not have a local list command & exit /b 0 )
if "%CLI_INSTALL_METHOD%"=="vfox" ( vfox ls cli & exit /b 0 )
if "%CLI_INSTALL_METHOD%"=="system" ( echo System package manager does not support ls directly here. & exit /b 0 )
dir /b "%LIBSCRIPT_HOME%\cli\" 2>nul
exit /b 0

:: ## action_ls_remote
:: Executes action_ls_remote functionality.
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
:: Executes action_use functionality.
:action_use
if "%CLI_INSTALL_METHOD%"=="mise" ( mise use "cli@%CLI_VERSION%" & exit /b 0 )
if "%CLI_INSTALL_METHOD%"=="asdf" ( asdf global cli "%CLI_VERSION%" & exit /b 0 )
if "%CLI_INSTALL_METHOD%"=="pkgx" ( echo pkgx does not use explicit versions this way & exit /b 0 )
if "%CLI_INSTALL_METHOD%"=="vfox" ( vfox use "cli@%CLI_VERSION%" & exit /b 0 )
if "%CLI_INSTALL_METHOD%"=="system" ( echo Cannot 'use' specific version with system package manager. & exit /b 0 )
echo libscript_symlink_alias not implemented natively in cmd yet.
exit /b 0

:: ## action_download
:: Executes action_download functionality.
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
:: Executes action_install functionality.
:action_install
if "%CLI_INSTALL_METHOD%"=="system" (
    winget install cli --accept-package-agreements --accept-source-agreements
    exit /b !errorlevel!
)
