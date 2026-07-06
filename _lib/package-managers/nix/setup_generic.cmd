@echo off
:: ## Overview
:: Windows setup for nix
::
:: ## Usage
:: Managed by libscript. Provides download, install, ls, ls-remote, use capabilities.

if "%ACTION%"=="" set ACTION=install
if "%NIX_VERSION%"=="" set NIX_VERSION=latest

if "%LIBSCRIPT_HOME%"=="" (
    set "LIBSCRIPT_HOME=%USERPROFILE%\.libscript"
)
if "%DOWNLOAD_DIR%"=="" (
    set "DOWNLOAD_DIR=%TEMP%\libscript_downloads"
)

:: Resolve install method
if "%NIX_INSTALL_METHOD%"=="" (
    if not "%LIBSCRIPT_DEFAULT_INSTALL_METHOD%"=="" (
        set "NIX_INSTALL_METHOD=%LIBSCRIPT_DEFAULT_INSTALL_METHOD%"
    ) else (
        set "NIX_INSTALL_METHOD=libscript_native"
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
goto :action_install

:action_ls
if "%NIX_INSTALL_METHOD%"=="mise" ( mise ls nix & exit /b 0 )
if "%NIX_INSTALL_METHOD%"=="asdf" ( asdf list nix & exit /b 0 )
if "%NIX_INSTALL_METHOD%"=="pkgx" ( echo pkgx does not have a local list command & exit /b 0 )
if "%NIX_INSTALL_METHOD%"=="vfox" ( vfox ls nix & exit /b 0 )
if "%NIX_INSTALL_METHOD%"=="system" ( echo System package manager does not support ls directly here. & exit /b 0 )
if exist "%LIBSCRIPT_HOME%\nix" ( dir /b "%LIBSCRIPT_HOME%\nix" )
exit /b 0

:action_ls_remote
if "%NIX_INSTALL_METHOD%"=="mise" ( mise ls-remote nix & exit /b 0 )
if "%NIX_INSTALL_METHOD%"=="asdf" ( asdf list all nix & exit /b 0 )
if "%NIX_INSTALL_METHOD%"=="pkgx" ( echo pkgx does not have a local list command & exit /b 0 )
if "%NIX_INSTALL_METHOD%"=="vfox" ( vfox ls all nix & exit /b 0 )
if "%NIX_INSTALL_METHOD%"=="system" ( echo System package manager does not support ls-remote directly here. & exit /b 0 )
if not "%NIX_RELEASES_URL%"=="" (
    curl -sSL "%NIX_RELEASES_URL%"
) else (
    git ls-remote --tags "https://github.com/libscript/nix" 2^>nul ^| findstr /R "[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*"
)
exit /b 0

:action_use
if "%NIX_INSTALL_METHOD%"=="mise" ( mise use "nix@%NIX_VERSION%" & exit /b 0 )
if "%NIX_INSTALL_METHOD%"=="asdf" ( asdf global nix "%NIX_VERSION%" & exit /b 0 )
if "%NIX_INSTALL_METHOD%"=="pkgx" ( echo pkgx does not use explicit versions this way & exit /b 0 )
if "%NIX_INSTALL_METHOD%"=="vfox" ( vfox use "nix@%NIX_VERSION%" & exit /b 0 )
if "%NIX_INSTALL_METHOD%"=="system" ( echo Cannot 'use' specific version with system package manager. & exit /b 0 )

if "%NIX_VERSION%"=="latest" (set "EXACT_VERSION=%NIX_VERSION%"
) else if "%NIX_VERSION%"=="lts" (set "EXACT_VERSION=%NIX_VERSION%"
) else (
    set "EXACT_VERSION=%NIX_VERSION%"
)
if "%EXACT_VERSION%"=="" set "EXACT_VERSION=%NIX_VERSION%"

set "TARGET_DIR=%LIBSCRIPT_HOME%\nix\%EXACT_VERSION%"
set "ALIAS_DIR=%LIBSCRIPT_HOME%\nix\%NIX_VERSION%"

if not "%TARGET_DIR%"=="%ALIAS_DIR%" (
    if exist "%ALIAS_DIR%" rmdir "%ALIAS_DIR%"
    mklink /J "%ALIAS_DIR%" "%TARGET_DIR%" >nul 2>&1
)
exit /b 0

:action_download
if "%NIX_INSTALL_METHOD%"=="libscript_native" (
    echo Downloading nix %NIX_VERSION% to %DOWNLOAD_DIR%\nix...
    if not exist "%DOWNLOAD_DIR%\nix" mkdir "%DOWNLOAD_DIR%\nix"
    if not "%NIX_DOWNLOAD_URL%"=="" (
        curl -sSL "%NIX_DOWNLOAD_URL%" -o "%DOWNLOAD_DIR%\nix\nix-%NIX_VERSION%.zip"
    ) else (
        echo NIX_DOWNLOAD_URL is not defined. Skipping.
    )
)
exit /b 0

:action_install
if "%NIX_INSTALL_METHOD%"=="system" (
    winget install nix --accept-package-agreements --accept-source-agreements
    exit /b !errorlevel!
)
if "%NIX_INSTALL_METHOD%"=="mise" ( mise install "nix@%NIX_VERSION%" & exit /b 0 )
if "%NIX_INSTALL_METHOD%"=="asdf" ( asdf install nix "%NIX_VERSION%" & exit /b 0 )
if "%NIX_INSTALL_METHOD%"=="pkgx" ( pkgx install "nix@%NIX_VERSION%" & exit /b 0 )
if "%NIX_INSTALL_METHOD%"=="vfox" ( vfox add nix & vfox install "nix@%NIX_VERSION%" & exit /b 0 )

set "TARGET_DIR=%LIBSCRIPT_HOME%\nix\%NIX_VERSION%"
if not exist "%TARGET_DIR%\bin" (
    echo Installing nix %NIX_VERSION% natively to %TARGET_DIR%...
    mkdir "%TARGET_DIR%\bin"
    if exist "%DOWNLOAD_DIR%\nix\nix-%NIX_VERSION%.zip" (
        echo Extracting from cache...
        tar -xf "%DOWNLOAD_DIR%\nix\nix-%NIX_VERSION%.zip" -C "%TARGET_DIR%"
    ) else if exist "%DOWNLOAD_DIR%\nix\nix-%NIX_VERSION%.tar.gz" (
        echo Extracting from cache...
        tar -xf "%DOWNLOAD_DIR%\nix\nix-%NIX_VERSION%.tar.gz" -C "%TARGET_DIR%"
    ) else if not "%NIX_DOWNLOAD_URL%"=="" (
        echo Downloading and extracting...
        curl -sSL "%NIX_DOWNLOAD_URL%" -o "%TEMP%\nix.zip"
        tar -xf "%TEMP%\nix.zip" -C "%TARGET_DIR%"
    ) else (
        echo No download URL or cache available for nix.
    )
) else (
    echo nix %NIX_VERSION% is already installed.
)
set "ALIAS_DIR=%LIBSCRIPT_HOME%\nix\%NIX_VERSION%"
if not "%TARGET_DIR%"=="%ALIAS_DIR%" (
    if exist "%ALIAS_DIR%" rmdir "%ALIAS_DIR%"
    mklink /J "%ALIAS_DIR%" "%TARGET_DIR%" >nul 2>&1
)
exit /b 0

:action_service
if "%LIBSCRIPT_SERVICE_NAME%"=="" (
    if "%PACKAGE_NAME%"=="" (
        set "SVC_NAME=libscript_nix"
    ) else (
        set "SVC_NAME=libscript_%PACKAGE_NAME%"
    )
) else (
    set "SVC_NAME=%LIBSCRIPT_SERVICE_NAME%"
)
if "%NIX_INSTALL_METHOD%"=="libscript_native" (
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\service.cmd" "%ACTION%" "%SVC_NAME%"
) else if "%NIX_INSTALL_METHOD%"=="system" (
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\service.cmd" "%ACTION%" "%SVC_NAME%"
) else (
    echo %ACTION% not natively implemented for %NIX_INSTALL_METHOD%.
)
exit /b 0

:action_install_service
if "%LIBSCRIPT_SERVICE_NAME%"=="" (
    if "%PACKAGE_NAME%"=="" (
        set "SVC_NAME=libscript_nix"
    ) else (
        set "SVC_NAME=libscript_%PACKAGE_NAME%"
    )
) else (
    set "SVC_NAME=%LIBSCRIPT_SERVICE_NAME%"
)
if "%NIX_INSTALL_METHOD%"=="libscript_native" (
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\service_install.cmd" install "%SVC_NAME%"
) else if "%NIX_INSTALL_METHOD%"=="system" (
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\service_install.cmd" install "%SVC_NAME%"
) else (
    echo install-service not implemented for %NIX_INSTALL_METHOD%.
)
exit /b 0

:action_uninstall_service
if "%LIBSCRIPT_SERVICE_NAME%"=="" (
    if "%PACKAGE_NAME%"=="" (
        set "SVC_NAME=libscript_nix"
    ) else (
        set "SVC_NAME=libscript_%PACKAGE_NAME%"
    )
) else (
    set "SVC_NAME=%LIBSCRIPT_SERVICE_NAME%"
)
if "%NIX_INSTALL_METHOD%"=="libscript_native" (
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\service_install.cmd" uninstall "%SVC_NAME%"
) else if "%NIX_INSTALL_METHOD%"=="system" (
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\service_install.cmd" uninstall "%SVC_NAME%"
) else (
    echo uninstall-service not implemented for %NIX_INSTALL_METHOD%.
)
exit /b 0
