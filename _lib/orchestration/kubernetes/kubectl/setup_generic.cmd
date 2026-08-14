@echo off
:: ## Overview
:: Windows setup for kubectl
::
:: ## Usage
:: Managed by libscript. Provides download, install, ls, ls-remote, use capabilities.

if "%ACTION%"=="" set ACTION=install
if "%KUBECTL_VERSION%"=="" set KUBECTL_VERSION=latest

if "%LIBSCRIPT_HOME%"=="" (
    set "LIBSCRIPT_HOME=%USERPROFILE%\.libscript"
)
if "%DOWNLOAD_DIR%"=="" (
    set "DOWNLOAD_DIR=%TEMP%\libscript_downloads"
)

:: Resolve install method
if "%KUBECTL_INSTALL_METHOD%"=="" (
    if not "%LIBSCRIPT_DEFAULT_INSTALL_METHOD%"=="" (
        set "KUBECTL_INSTALL_METHOD=%LIBSCRIPT_DEFAULT_INSTALL_METHOD%"
    ) else (
        set "KUBECTL_INSTALL_METHOD=libscript_native"
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
if "%KUBECTL_INSTALL_METHOD%"=="mise" ( mise ls kubectl & exit /b 0 )
if "%KUBECTL_INSTALL_METHOD%"=="asdf" ( asdf list kubectl & exit /b 0 )
if "%KUBECTL_INSTALL_METHOD%"=="pkgx" ( echo pkgx does not have a local list command & exit /b 0 )
if "%KUBECTL_INSTALL_METHOD%"=="vfox" ( vfox ls kubectl & exit /b 0 )
if "%KUBECTL_INSTALL_METHOD%"=="system" ( echo System package manager does not support ls directly here. & exit /b 0 )
dir /b "%LIBSCRIPT_HOME%\kubectl\" 2>nul
exit /b 0

:: ## action_ls_remote
:: Executes action_ls_remote functionality.
:action_ls_remote
if "%KUBECTL_INSTALL_METHOD%"=="mise" ( mise ls-remote kubectl & exit /b 0 )
if "%KUBECTL_INSTALL_METHOD%"=="asdf" ( asdf list all kubectl & exit /b 0 )
if "%KUBECTL_INSTALL_METHOD%"=="pkgx" ( echo pkgx does not have a local list command & exit /b 0 )
if "%KUBECTL_INSTALL_METHOD%"=="vfox" ( vfox ls all kubectl & exit /b 0 )
if "%KUBECTL_INSTALL_METHOD%"=="system" ( echo System package manager does not support ls-remote directly here. & exit /b 0 )
if not "%KUBECTL_RELEASES_URL%"=="" (
    curl -sSL "%KUBECTL_RELEASES_URL%"
) else (
    git ls-remote --tags "https://github.com/kubernetes/kubectl" 2^>nul ^| findstr /R "[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*"
)
exit /b 0

:: ## action_use
:: Executes action_use functionality.
:action_use
if "%KUBECTL_INSTALL_METHOD%"=="mise" ( mise use "kubectl@%KUBECTL_VERSION%" & exit /b 0 )
if "%KUBECTL_INSTALL_METHOD%"=="asdf" ( asdf global kubectl "%KUBECTL_VERSION%" & exit /b 0 )
if "%KUBECTL_INSTALL_METHOD%"=="pkgx" ( echo pkgx does not use explicit versions this way & exit /b 0 )
if "%KUBECTL_INSTALL_METHOD%"=="vfox" ( vfox use "kubectl@%KUBECTL_VERSION%" & exit /b 0 )
if "%KUBECTL_INSTALL_METHOD%"=="system" ( echo Cannot 'use' specific version with system package manager. & exit /b 0 )
echo libscript_symlink_alias not implemented natively in cmd yet.
exit /b 0

:: ## action_download
:: Executes action_download functionality.
:action_download
if "%KUBECTL_INSTALL_METHOD%"=="libscript_native" (
    echo Downloading kubectl %KUBECTL_VERSION% to %DOWNLOAD_DIR%\kubectl...
    if not exist "%DOWNLOAD_DIR%\kubectl" mkdir "%DOWNLOAD_DIR%\kubectl"
    if not "%KUBECTL_DOWNLOAD_URL%"=="" (
        curl -sSL "%KUBECTL_DOWNLOAD_URL%" -o "%DOWNLOAD_DIR%\kubectl\kubectl-%KUBECTL_VERSION%.zip"
    ) else (
        echo KUBECTL_DOWNLOAD_URL is not defined. Skipping.
    )
)
exit /b 0

:: ## action_install
:: Executes action_install functionality.
:action_install
if "%KUBECTL_INSTALL_METHOD%"=="system" (
    winget install kubectl --accept-package-agreements --accept-source-agreements
    exit /b !errorlevel!
)
