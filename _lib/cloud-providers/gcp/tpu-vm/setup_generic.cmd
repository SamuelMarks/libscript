@echo off
:: ## Overview
:: Windows setup for tpu-vm
::
:: ## Usage
:: Managed by libscript. Provides download, install, ls, ls-remote, use capabilities.

if "%ACTION%"=="" set ACTION=install
if "%TPU_VM_VERSION%"=="" set TPU_VM_VERSION=latest

if "%LIBSCRIPT_HOME%"=="" (
    set "LIBSCRIPT_HOME=%USERPROFILE%\.libscript"
)
if "%DOWNLOAD_DIR%"=="" (
    set "DOWNLOAD_DIR=%TEMP%\libscript_downloads"
)

:: Resolve install method
if "%TPU_VM_INSTALL_METHOD%"=="" (
    if not "%LIBSCRIPT_DEFAULT_INSTALL_METHOD%"=="" (
        set "TPU_VM_INSTALL_METHOD=%LIBSCRIPT_DEFAULT_INSTALL_METHOD%"
    ) else (
        set "TPU_VM_INSTALL_METHOD=libscript_native"
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
if "%TPU_VM_INSTALL_METHOD%"=="mise" ( mise ls tpu-vm & exit /b 0 )
if "%TPU_VM_INSTALL_METHOD%"=="asdf" ( asdf list tpu-vm & exit /b 0 )
if "%TPU_VM_INSTALL_METHOD%"=="pkgx" ( echo pkgx does not have a local list command & exit /b 0 )
if "%TPU_VM_INSTALL_METHOD%"=="vfox" ( vfox ls tpu-vm & exit /b 0 )
if "%TPU_VM_INSTALL_METHOD%"=="system" ( echo System package manager does not support ls directly here. & exit /b 0 )
dir /b "%LIBSCRIPT_HOME%\tpu-vm\" 2>nul
exit /b 0

:: ## action_ls_remote
:: Executes action_ls_remote functionality.
:action_ls_remote
if "%TPU_VM_INSTALL_METHOD%"=="mise" ( mise ls-remote tpu-vm & exit /b 0 )
if "%TPU_VM_INSTALL_METHOD%"=="asdf" ( asdf list all tpu-vm & exit /b 0 )
if "%TPU_VM_INSTALL_METHOD%"=="pkgx" ( echo pkgx does not have a local list command & exit /b 0 )
if "%TPU_VM_INSTALL_METHOD%"=="vfox" ( vfox ls all tpu-vm & exit /b 0 )
if "%TPU_VM_INSTALL_METHOD%"=="system" ( echo System package manager does not support ls-remote directly here. & exit /b 0 )
if not "%TPU_VM_RELEASES_URL%"=="" (
    curl -sSL "%TPU_VM_RELEASES_URL%"
) else (
    git ls-remote --tags "https://github.com/google/jax" 2^>nul ^| findstr /R "[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*"
)
exit /b 0

:: ## action_use
:: Executes action_use functionality.
:action_use
if "%TPU_VM_INSTALL_METHOD%"=="mise" ( mise use "tpu-vm@%TPU_VM_VERSION%" & exit /b 0 )
if "%TPU_VM_INSTALL_METHOD%"=="asdf" ( asdf global tpu-vm "%TPU_VM_VERSION%" & exit /b 0 )
if "%TPU_VM_INSTALL_METHOD%"=="pkgx" ( echo pkgx does not use explicit versions this way & exit /b 0 )
if "%TPU_VM_INSTALL_METHOD%"=="vfox" ( vfox use "tpu-vm@%TPU_VM_VERSION%" & exit /b 0 )
if "%TPU_VM_INSTALL_METHOD%"=="system" ( echo Cannot 'use' specific version with system package manager. & exit /b 0 )
echo libscript_symlink_alias not implemented natively in cmd yet.
exit /b 0

:: ## action_download
:: Executes action_download functionality.
:action_download
if "%TPU_VM_INSTALL_METHOD%"=="libscript_native" (
    echo Downloading tpu-vm %TPU_VM_VERSION% to %DOWNLOAD_DIR%\tpu-vm...
    if not exist "%DOWNLOAD_DIR%\tpu-vm" mkdir "%DOWNLOAD_DIR%\tpu-vm"
    if not "%TPU_VM_DOWNLOAD_URL%"=="" (
        curl -sSL "%TPU_VM_DOWNLOAD_URL%" -o "%DOWNLOAD_DIR%\tpu-vm\tpu-vm-%TPU_VM_VERSION%.zip"
    ) else (
        echo TPU_VM_DOWNLOAD_URL is not defined. Skipping.
    )
)
exit /b 0

:: ## action_install
:: Executes action_install functionality.
:action_install
if "%TPU_VM_INSTALL_METHOD%"=="system" (
    winget install tpu-vm --accept-package-agreements --accept-source-agreements
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
