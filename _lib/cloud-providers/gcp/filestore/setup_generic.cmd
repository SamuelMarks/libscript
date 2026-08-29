@echo off
:: ## Overview
:: Windows setup for filestore
::
:: ## Usage
:: Managed by libscript. Provides download, install, ls, ls-remote, use capabilities.
set "THIS_FILE=%~f0"

if "%ACTION%"=="" set ACTION=install
if "%FILESTORE_VERSION%"=="" set FILESTORE_VERSION=latest

if "%LIBSCRIPT_HOME%"=="" (
    set "LIBSCRIPT_HOME=%USERPROFILE%\.libscript"
)
if "%DOWNLOAD_DIR%"=="" (
    set "DOWNLOAD_DIR=%TEMP%\libscript_downloads"
)

:: Resolve install method
if "%FILESTORE_INSTALL_METHOD%"=="" (
    if not "%LIBSCRIPT_DEFAULT_INSTALL_METHOD%"=="" (
        set "FILESTORE_INSTALL_METHOD=%LIBSCRIPT_DEFAULT_INSTALL_METHOD%"
    ) else (
        set "FILESTORE_INSTALL_METHOD=libscript_native"
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
if "%FILESTORE_INSTALL_METHOD%"=="mise" ( mise ls filestore & exit /b 0 )
if "%FILESTORE_INSTALL_METHOD%"=="asdf" ( asdf list filestore & exit /b 0 )
if "%FILESTORE_INSTALL_METHOD%"=="pkgx" ( echo pkgx does not have a local list command & exit /b 0 )
if "%FILESTORE_INSTALL_METHOD%"=="vfox" ( vfox ls filestore & exit /b 0 )
if "%FILESTORE_INSTALL_METHOD%"=="system" ( echo System package manager does not support ls directly here. & exit /b 0 )
dir /b "%LIBSCRIPT_HOME%\filestore\" 2>nul
exit /b 0

:: ## action_ls_remote
:: Executes action_ls_remote functionality.
:action_ls_remote
if "%FILESTORE_INSTALL_METHOD%"=="mise" ( mise ls-remote filestore & exit /b 0 )
if "%FILESTORE_INSTALL_METHOD%"=="asdf" ( asdf list all filestore & exit /b 0 )
if "%FILESTORE_INSTALL_METHOD%"=="pkgx" ( echo pkgx does not have a local list command & exit /b 0 )
if "%FILESTORE_INSTALL_METHOD%"=="vfox" ( vfox ls all filestore & exit /b 0 )
if "%FILESTORE_INSTALL_METHOD%"=="system" ( echo System package manager does not support ls-remote directly here. & exit /b 0 )
if not "%FILESTORE_RELEASES_URL%"=="" (
    curl -sSL "%FILESTORE_RELEASES_URL%"
) else (
    git ls-remote --tags "https://github.com/google/jax" 2^>nul ^| findstr /R "[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*"
)
exit /b 0

:: ## action_use
:: Executes action_use functionality.
:action_use
if "%FILESTORE_INSTALL_METHOD%"=="mise" ( mise use "filestore@%FILESTORE_VERSION%" & exit /b 0 )
if "%FILESTORE_INSTALL_METHOD%"=="asdf" ( asdf global filestore "%FILESTORE_VERSION%" & exit /b 0 )
if "%FILESTORE_INSTALL_METHOD%"=="pkgx" ( echo pkgx does not use explicit versions this way & exit /b 0 )
if "%FILESTORE_INSTALL_METHOD%"=="vfox" ( vfox use "filestore@%FILESTORE_VERSION%" & exit /b 0 )
if "%FILESTORE_INSTALL_METHOD%"=="system" ( echo Cannot 'use' specific version with system package manager. & exit /b 0 )
echo libscript_symlink_alias not implemented natively in cmd yet.
exit /b 0

:: ## action_download
:: Executes action_download functionality.
:action_download
if "%FILESTORE_INSTALL_METHOD%"=="libscript_native" (
    echo Downloading filestore %FILESTORE_VERSION% to %DOWNLOAD_DIR%\filestore...
    if not exist "%DOWNLOAD_DIR%\filestore" mkdir "%DOWNLOAD_DIR%\filestore"
    if not "%FILESTORE_DOWNLOAD_URL%"=="" (
        curl -sSL "%FILESTORE_DOWNLOAD_URL%" -o "%DOWNLOAD_DIR%\filestore\filestore-%FILESTORE_VERSION%.zip"
    ) else (
        echo FILESTORE_DOWNLOAD_URL is not defined. Skipping.
    )
)
exit /b 0

:: ## action_install
:: Executes action_install functionality.
:action_install
if "%FILESTORE_INSTALL_METHOD%"=="system" (
    winget install filestore --accept-package-agreements --accept-source-agreements
    exit /b !errorlevel!
)
@echo off
setlocal EnableDelayedExpansion
if not "%TPU_ACCELERATOR_TYPE%"=="" (
  if not "%TPU_VERSION%"=="" (
    echo Checking compatibility for %TPU_ACCELERATOR_TYPE% and %TPU_VERSION%
    rem Simple warning mechanism for Windows
    echo WARNING: Ensure %TPU_VERSION% is compatible with %TPU_ACCELERATOR_TYPE%
  )
)
