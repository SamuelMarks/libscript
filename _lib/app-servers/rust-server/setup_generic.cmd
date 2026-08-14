@echo off
:: ## Overview
:: Windows setup for rust-server
::
:: ## Usage
:: Managed by libscript. Provides download, install, ls, ls-remote, use capabilities.

if "%ACTION%"=="" set ACTION=install
if "%RUST_SERVER_VERSION%"=="" set RUST_SERVER_VERSION=latest

if "%LIBSCRIPT_HOME%"=="" (
    set "LIBSCRIPT_HOME=%USERPROFILE%\.libscript"
)
if "%DOWNLOAD_DIR%"=="" (
    set "DOWNLOAD_DIR=%TEMP%\libscript_downloads"
)

:: Resolve install method
if "%RUST_SERVER_INSTALL_METHOD%"=="" (
    if not "%LIBSCRIPT_DEFAULT_INSTALL_METHOD%"=="" (
        set "RUST_SERVER_INSTALL_METHOD=%LIBSCRIPT_DEFAULT_INSTALL_METHOD%"
    ) else (
        set "RUST_SERVER_INSTALL_METHOD=libscript_native"
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

:: ## action_ls
:: Executes action_ls functionality.
:action_ls
if "%RUST_SERVER_INSTALL_METHOD%"=="mise" ( mise ls rust-server & exit /b 0 )
if "%RUST_SERVER_INSTALL_METHOD%"=="asdf" ( asdf list rust-server & exit /b 0 )
if "%RUST_SERVER_INSTALL_METHOD%"=="pkgx" ( echo pkgx does not have a local list command & exit /b 0 )
if "%RUST_SERVER_INSTALL_METHOD%"=="vfox" ( vfox ls rust-server & exit /b 0 )
if "%RUST_SERVER_INSTALL_METHOD%"=="system" ( echo System package manager does not support ls directly here. & exit /b 0 )
if exist "%LIBSCRIPT_HOME%\rust-server" ( dir /b "%LIBSCRIPT_HOME%\rust-server" )
exit /b 0

:: ## action_ls_remote
:: Executes action_ls_remote functionality.
:action_ls_remote
if "%RUST_SERVER_INSTALL_METHOD%"=="mise" ( mise ls-remote rust-server & exit /b 0 )
if "%RUST_SERVER_INSTALL_METHOD%"=="asdf" ( asdf list all rust-server & exit /b 0 )
if "%RUST_SERVER_INSTALL_METHOD%"=="pkgx" ( echo pkgx does not have a local list command & exit /b 0 )
if "%RUST_SERVER_INSTALL_METHOD%"=="vfox" ( vfox ls all rust-server & exit /b 0 )
if "%RUST_SERVER_INSTALL_METHOD%"=="system" ( echo System package manager does not support ls-remote directly here. & exit /b 0 )
if not "%RUST_SERVER_RELEASES_URL%"=="" (
    curl -sSL "%RUST_SERVER_RELEASES_URL%"
) else (
    git ls-remote --tags "https://github.com/rust-lang/rust" 2^>nul ^| findstr /R "[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*"
)
exit /b 0

:: ## action_use
:: Executes action_use functionality.
:action_use
if "%RUST_SERVER_INSTALL_METHOD%"=="mise" ( mise use "rust-server@%RUST_SERVER_VERSION%" & exit /b 0 )
if "%RUST_SERVER_INSTALL_METHOD%"=="asdf" ( asdf global rust-server "%RUST_SERVER_VERSION%" & exit /b 0 )
if "%RUST_SERVER_INSTALL_METHOD%"=="pkgx" ( echo pkgx does not use explicit versions this way & exit /b 0 )
if "%RUST_SERVER_INSTALL_METHOD%"=="vfox" ( vfox use "rust-server@%RUST_SERVER_VERSION%" & exit /b 0 )
if "%RUST_SERVER_INSTALL_METHOD%"=="system" ( echo Cannot 'use' specific version with system package manager. & exit /b 0 )

if "%RUST_SERVER_VERSION%"=="latest" (set "EXACT_VERSION=%RUST_SERVER_VERSION%"
) else if "%RUST_SERVER_VERSION%"=="lts" (set "EXACT_VERSION=%RUST_SERVER_VERSION%"
) else (
    set "EXACT_VERSION=%RUST_SERVER_VERSION%"
)
if "%EXACT_VERSION%"=="" set "EXACT_VERSION=%RUST_SERVER_VERSION%"

set "TARGET_DIR=%LIBSCRIPT_HOME%\rust-server\%EXACT_VERSION%"
set "ALIAS_DIR=%LIBSCRIPT_HOME%\rust-server\%RUST_SERVER_VERSION%"

if not "%TARGET_DIR%"=="%ALIAS_DIR%" (
    if exist "%ALIAS_DIR%" rmdir "%ALIAS_DIR%"
    mklink /J "%ALIAS_DIR%" "%TARGET_DIR%" >nul 2>&1
)
exit /b 0

:: ## action_download
:: Executes action_download functionality.
:action_download
if "%RUST_SERVER_INSTALL_METHOD%"=="libscript_native" (
    echo Downloading rust-server %RUST_SERVER_VERSION% to %DOWNLOAD_DIR%\rust-server...
    if not exist "%DOWNLOAD_DIR%\rust-server" mkdir "%DOWNLOAD_DIR%\rust-server"
    if not "%RUST_SERVER_DOWNLOAD_URL%"=="" (
        curl -sSL "%RUST_SERVER_DOWNLOAD_URL%" -o "%DOWNLOAD_DIR%\rust-server\rust-server-%RUST_SERVER_VERSION%.zip"
    ) else (
        echo RUST_SERVER_DOWNLOAD_URL is not defined. Skipping.
    )
)
exit /b 0

:: ## action_install
:: Executes action_install functionality.
:action_install
if "%RUST_SERVER_INSTALL_METHOD%"=="system" (
    winget install rust-server --accept-package-agreements --accept-source-agreements
    exit /b !errorlevel!
)
if "%RUST_SERVER_INSTALL_METHOD%"=="mise" ( mise install "rust-server@%RUST_SERVER_VERSION%" & exit /b 0 )
if "%RUST_SERVER_INSTALL_METHOD%"=="asdf" ( asdf install rust-server "%RUST_SERVER_VERSION%" & exit /b 0 )
if "%RUST_SERVER_INSTALL_METHOD%"=="pkgx" ( pkgx install "rust-server@%RUST_SERVER_VERSION%" & exit /b 0 )
if "%RUST_SERVER_INSTALL_METHOD%"=="vfox" ( vfox add rust-server & vfox install "rust-server@%RUST_SERVER_VERSION%" & exit /b 0 )

set "TARGET_DIR=%LIBSCRIPT_HOME%\rust-server\%RUST_SERVER_VERSION%"
if not exist "%TARGET_DIR%\bin" (
    echo Installing rust-server %RUST_SERVER_VERSION% natively to %TARGET_DIR%...
    if not exist "%TARGET_DIR%\bin" mkdir "%TARGET_DIR%\bin"
    if exist "%DOWNLOAD_DIR%\rust-server\rust-server-%RUST_SERVER_VERSION%.zip" (
        echo Extracting from cache...
        tar -xf "%DOWNLOAD_DIR%\rust-server\rust-server-%RUST_SERVER_VERSION%.zip" -C "%TARGET_DIR%"
    ) else if exist "%DOWNLOAD_DIR%\rust-server\rust-server-%RUST_SERVER_VERSION%.tar.gz" (
        echo Extracting from cache...
        tar -xf "%DOWNLOAD_DIR%\rust-server\rust-server-%RUST_SERVER_VERSION%.tar.gz" -C "%TARGET_DIR%"
    ) else if not "%RUST_SERVER_DOWNLOAD_URL%"=="" (
        echo Downloading and extracting...
        curl -sSL "%RUST_SERVER_DOWNLOAD_URL%" -o "%TEMP%\rust-server.zip"
        tar -xf "%TEMP%\rust-server.zip" -C "%TARGET_DIR%"
    ) else (
        echo No download URL or cache available for rust-server.
    )
) else (
    echo rust-server %RUST_SERVER_VERSION% is already installed.
)
set "ALIAS_DIR=%LIBSCRIPT_HOME%\rust-server\%RUST_SERVER_VERSION%"
if not "%TARGET_DIR%"=="%ALIAS_DIR%" (
    if exist "%ALIAS_DIR%" rmdir "%ALIAS_DIR%"
    mklink /J "%ALIAS_DIR%" "%TARGET_DIR%" >nul 2>&1
)
exit /b 0

:: ## action_service
:: Executes action_service functionality.
:action_service
if "%LIBSCRIPT_SERVICE_NAME%"=="" (
    if "%PACKAGE_NAME%"=="" (
        set "SVC_NAME=libscript_rust-server"
    ) else (
        set "SVC_NAME=libscript_%PACKAGE_NAME%"
    )
) else (
    set "SVC_NAME=%LIBSCRIPT_SERVICE_NAME%"
)
if "%RUST_SERVER_INSTALL_METHOD%"=="libscript_native" (
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\service.cmd" "%ACTION%" "%SVC_NAME%"
) else if "%RUST_SERVER_INSTALL_METHOD%"=="system" (
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\service.cmd" "%ACTION%" "%SVC_NAME%"
) else (
    echo %ACTION% not natively implemented for %RUST_SERVER_INSTALL_METHOD%.
)
exit /b 0

:: ## action_install_service
:: Executes action_install_service functionality.
:action_install_service
if "%LIBSCRIPT_SERVICE_NAME%"=="" (
    if "%PACKAGE_NAME%"=="" (
        set "SVC_NAME=libscript_rust-server"
    ) else (
        set "SVC_NAME=libscript_%PACKAGE_NAME%"
    )
) else (
    set "SVC_NAME=%LIBSCRIPT_SERVICE_NAME%"
)
if "%RUST_SERVER_INSTALL_METHOD%"=="libscript_native" (
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\service_install.cmd" install "%SVC_NAME%"
) else if "%RUST_SERVER_INSTALL_METHOD%"=="system" (
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\service_install.cmd" install "%SVC_NAME%"
) else (
    echo install-service not implemented for %RUST_SERVER_INSTALL_METHOD%.
)
exit /b 0

:: ## action_uninstall_service
:: Executes action_uninstall_service functionality.
:action_uninstall_service
if "%LIBSCRIPT_SERVICE_NAME%"=="" (
    if "%PACKAGE_NAME%"=="" (
        set "SVC_NAME=libscript_rust-server"
    ) else (
        set "SVC_NAME=libscript_%PACKAGE_NAME%"
    )
) else (
    set "SVC_NAME=%LIBSCRIPT_SERVICE_NAME%"
)
if "%RUST_SERVER_INSTALL_METHOD%"=="libscript_native" (
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\service_install.cmd" uninstall "%SVC_NAME%"
) else if "%RUST_SERVER_INSTALL_METHOD%"=="system" (
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\service_install.cmd" uninstall "%SVC_NAME%"
) else (
    echo uninstall-service not implemented for %RUST_SERVER_INSTALL_METHOD%.
)
exit /b 0
