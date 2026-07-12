@echo off
:: ## Overview
:: Windows setup for nodejs-server
::
:: ## Usage
:: Managed by libscript. Provides download, install, ls, ls-remote, use capabilities.

if "%ACTION%"=="" set ACTION=install
if "%NODEJS_SERVER_VERSION%"=="" set NODEJS_SERVER_VERSION=latest

if "%LIBSCRIPT_HOME%"=="" (
    set "LIBSCRIPT_HOME=%USERPROFILE%\.libscript"
)
if "%DOWNLOAD_DIR%"=="" (
    set "DOWNLOAD_DIR=%TEMP%\libscript_downloads"
)

:: Resolve install method
if "%NODEJS_SERVER_INSTALL_METHOD%"=="" (
    if not "%LIBSCRIPT_DEFAULT_INSTALL_METHOD%"=="" (
        set "NODEJS_SERVER_INSTALL_METHOD=%LIBSCRIPT_DEFAULT_INSTALL_METHOD%"
    ) else (
        set "NODEJS_SERVER_INSTALL_METHOD=libscript_native"
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
if "%NODEJS_SERVER_INSTALL_METHOD%"=="mise" ( mise ls nodejs-server & exit /b 0 )
if "%NODEJS_SERVER_INSTALL_METHOD%"=="asdf" ( asdf list nodejs-server & exit /b 0 )
if "%NODEJS_SERVER_INSTALL_METHOD%"=="pkgx" ( echo pkgx does not have a local list command & exit /b 0 )
if "%NODEJS_SERVER_INSTALL_METHOD%"=="vfox" ( vfox ls nodejs-server & exit /b 0 )
if "%NODEJS_SERVER_INSTALL_METHOD%"=="system" ( echo System package manager does not support ls directly here. & exit /b 0 )
if exist "%LIBSCRIPT_HOME%\nodejs-server" ( dir /b "%LIBSCRIPT_HOME%\nodejs-server" )
exit /b 0

:action_ls_remote
if "%NODEJS_SERVER_INSTALL_METHOD%"=="mise" ( mise ls-remote nodejs-server & exit /b 0 )
if "%NODEJS_SERVER_INSTALL_METHOD%"=="asdf" ( asdf list all nodejs-server & exit /b 0 )
if "%NODEJS_SERVER_INSTALL_METHOD%"=="pkgx" ( echo pkgx does not have a local list command & exit /b 0 )
if "%NODEJS_SERVER_INSTALL_METHOD%"=="vfox" ( vfox ls all nodejs-server & exit /b 0 )
if "%NODEJS_SERVER_INSTALL_METHOD%"=="system" ( echo System package manager does not support ls-remote directly here. & exit /b 0 )
if not "%NODEJS_SERVER_RELEASES_URL%"=="" (
    curl -sSL "%NODEJS_SERVER_RELEASES_URL%"
) else (
    git ls-remote --tags "https://github.com/nodejs/node" 2^>nul ^| findstr /R "[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*"
)
exit /b 0

:action_use
if "%NODEJS_SERVER_INSTALL_METHOD%"=="mise" ( mise use "nodejs-server@%NODEJS_SERVER_VERSION%" & exit /b 0 )
if "%NODEJS_SERVER_INSTALL_METHOD%"=="asdf" ( asdf global nodejs-server "%NODEJS_SERVER_VERSION%" & exit /b 0 )
if "%NODEJS_SERVER_INSTALL_METHOD%"=="pkgx" ( echo pkgx does not use explicit versions this way & exit /b 0 )
if "%NODEJS_SERVER_INSTALL_METHOD%"=="vfox" ( vfox use "nodejs-server@%NODEJS_SERVER_VERSION%" & exit /b 0 )
if "%NODEJS_SERVER_INSTALL_METHOD%"=="system" ( echo Cannot 'use' specific version with system package manager. & exit /b 0 )

if "%NODEJS_SERVER_VERSION%"=="latest" (set "EXACT_VERSION=%NODEJS_SERVER_VERSION%"
) else if "%NODEJS_SERVER_VERSION%"=="lts" (set "EXACT_VERSION=%NODEJS_SERVER_VERSION%"
) else (
    set "EXACT_VERSION=%NODEJS_SERVER_VERSION%"
)
if "%EXACT_VERSION%"=="" set "EXACT_VERSION=%NODEJS_SERVER_VERSION%"

set "TARGET_DIR=%LIBSCRIPT_HOME%\nodejs-server\%EXACT_VERSION%"
set "ALIAS_DIR=%LIBSCRIPT_HOME%\nodejs-server\%NODEJS_SERVER_VERSION%"

if not "%TARGET_DIR%"=="%ALIAS_DIR%" (
    if exist "%ALIAS_DIR%" rmdir "%ALIAS_DIR%"
    mklink /J "%ALIAS_DIR%" "%TARGET_DIR%" >nul 2>&1
)
exit /b 0

:action_download
if "%NODEJS_SERVER_INSTALL_METHOD%"=="libscript_native" (
    echo Downloading nodejs-server %NODEJS_SERVER_VERSION% to %DOWNLOAD_DIR%\nodejs-server...
    if not exist "%DOWNLOAD_DIR%\nodejs-server" mkdir "%DOWNLOAD_DIR%\nodejs-server"
    if not "%NODEJS_SERVER_DOWNLOAD_URL%"=="" (
        curl -sSL "%NODEJS_SERVER_DOWNLOAD_URL%" -o "%DOWNLOAD_DIR%\nodejs-server\nodejs-server-%NODEJS_SERVER_VERSION%.zip"
    ) else (
        echo NODEJS_SERVER_DOWNLOAD_URL is not defined. Skipping.
    )
)
exit /b 0

:action_install
if "%NODEJS_SERVER_INSTALL_METHOD%"=="system" (
    winget install nodejs-server --accept-package-agreements --accept-source-agreements
    exit /b !errorlevel!
)
if "%NODEJS_SERVER_INSTALL_METHOD%"=="mise" ( mise install "nodejs-server@%NODEJS_SERVER_VERSION%" & exit /b 0 )
if "%NODEJS_SERVER_INSTALL_METHOD%"=="asdf" ( asdf install nodejs-server "%NODEJS_SERVER_VERSION%" & exit /b 0 )
if "%NODEJS_SERVER_INSTALL_METHOD%"=="pkgx" ( pkgx install "nodejs-server@%NODEJS_SERVER_VERSION%" & exit /b 0 )
if "%NODEJS_SERVER_INSTALL_METHOD%"=="vfox" ( vfox add nodejs-server & vfox install "nodejs-server@%NODEJS_SERVER_VERSION%" & exit /b 0 )

set "TARGET_DIR=%LIBSCRIPT_HOME%\nodejs-server\%NODEJS_SERVER_VERSION%"
if not exist "%TARGET_DIR%\bin" (
    echo Installing nodejs-server %NODEJS_SERVER_VERSION% natively to %TARGET_DIR%...
    if not exist "%TARGET_DIR%\bin" mkdir "%TARGET_DIR%\bin"
    if exist "%DOWNLOAD_DIR%\nodejs-server\nodejs-server-%NODEJS_SERVER_VERSION%.zip" (
        echo Extracting from cache...
        tar -xf "%DOWNLOAD_DIR%\nodejs-server\nodejs-server-%NODEJS_SERVER_VERSION%.zip" -C "%TARGET_DIR%"
    ) else if exist "%DOWNLOAD_DIR%\nodejs-server\nodejs-server-%NODEJS_SERVER_VERSION%.tar.gz" (
        echo Extracting from cache...
        tar -xf "%DOWNLOAD_DIR%\nodejs-server\nodejs-server-%NODEJS_SERVER_VERSION%.tar.gz" -C "%TARGET_DIR%"
    ) else if not "%NODEJS_SERVER_DOWNLOAD_URL%"=="" (
        echo Downloading and extracting...
        curl -sSL "%NODEJS_SERVER_DOWNLOAD_URL%" -o "%TEMP%\nodejs-server.zip"
        tar -xf "%TEMP%\nodejs-server.zip" -C "%TARGET_DIR%"
    ) else (
        echo No download URL or cache available for nodejs-server.
    )
) else (
    echo nodejs-server %NODEJS_SERVER_VERSION% is already installed.
)
set "ALIAS_DIR=%LIBSCRIPT_HOME%\nodejs-server\%NODEJS_SERVER_VERSION%"
if not "%TARGET_DIR%"=="%ALIAS_DIR%" (
    if exist "%ALIAS_DIR%" rmdir "%ALIAS_DIR%"
    mklink /J "%ALIAS_DIR%" "%TARGET_DIR%" >nul 2>&1
)
exit /b 0

:action_service
if "%LIBSCRIPT_SERVICE_NAME%"=="" (
    if "%PACKAGE_NAME%"=="" (
        set "SVC_NAME=libscript_nodejs-server"
    ) else (
        set "SVC_NAME=libscript_%PACKAGE_NAME%"
    )
) else (
    set "SVC_NAME=%LIBSCRIPT_SERVICE_NAME%"
)
if "%NODEJS_SERVER_INSTALL_METHOD%"=="libscript_native" (
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\service.cmd" "%ACTION%" "%SVC_NAME%"
) else if "%NODEJS_SERVER_INSTALL_METHOD%"=="system" (
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\service.cmd" "%ACTION%" "%SVC_NAME%"
) else (
    echo %ACTION% not natively implemented for %NODEJS_SERVER_INSTALL_METHOD%.
)
exit /b 0

:action_install_service
if "%LIBSCRIPT_SERVICE_NAME%"=="" (
    if "%PACKAGE_NAME%"=="" (
        set "SVC_NAME=libscript_nodejs-server"
    ) else (
        set "SVC_NAME=libscript_%PACKAGE_NAME%"
    )
) else (
    set "SVC_NAME=%LIBSCRIPT_SERVICE_NAME%"
)
if "%NODEJS_SERVER_INSTALL_METHOD%"=="libscript_native" (
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\service_install.cmd" install "%SVC_NAME%"
) else if "%NODEJS_SERVER_INSTALL_METHOD%"=="system" (
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\service_install.cmd" install "%SVC_NAME%"
) else (
    echo install-service not implemented for %NODEJS_SERVER_INSTALL_METHOD%.
)
exit /b 0

:action_uninstall_service
if "%LIBSCRIPT_SERVICE_NAME%"=="" (
    if "%PACKAGE_NAME%"=="" (
        set "SVC_NAME=libscript_nodejs-server"
    ) else (
        set "SVC_NAME=libscript_%PACKAGE_NAME%"
    )
) else (
    set "SVC_NAME=%LIBSCRIPT_SERVICE_NAME%"
)
if "%NODEJS_SERVER_INSTALL_METHOD%"=="libscript_native" (
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\service_install.cmd" uninstall "%SVC_NAME%"
) else if "%NODEJS_SERVER_INSTALL_METHOD%"=="system" (
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\service_install.cmd" uninstall "%SVC_NAME%"
) else (
    echo uninstall-service not implemented for %NODEJS_SERVER_INSTALL_METHOD%.
)
exit /b 0
