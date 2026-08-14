@echo off
:: ## Overview
:: Windows setup for dash
::
:: ## Usage
:: Managed by libscript. Provides download, install, ls, ls-remote, use capabilities.

if "%ACTION%"=="" set ACTION=install
if "%DASH_VERSION%"=="" set DASH_VERSION=latest

if "%LIBSCRIPT_HOME%"=="" (
    set "LIBSCRIPT_HOME=%USERPROFILE%\.libscript"
)
if "%DOWNLOAD_DIR%"=="" (
    set "DOWNLOAD_DIR=%TEMP%\libscript_downloads"
)

:: Resolve install method
if "%DASH_INSTALL_METHOD%"=="" (
    if not "%LIBSCRIPT_DEFAULT_INSTALL_METHOD%"=="" (
        set "DASH_INSTALL_METHOD=%LIBSCRIPT_DEFAULT_INSTALL_METHOD%"
    ) else (
        set "DASH_INSTALL_METHOD=libscript_native"
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
if "%DASH_INSTALL_METHOD%"=="mise" ( mise ls dash & exit /b 0 )
if "%DASH_INSTALL_METHOD%"=="asdf" ( asdf list dash & exit /b 0 )
if "%DASH_INSTALL_METHOD%"=="pkgx" ( echo pkgx does not have a local list command & exit /b 0 )
if "%DASH_INSTALL_METHOD%"=="vfox" ( vfox ls dash & exit /b 0 )
if "%DASH_INSTALL_METHOD%"=="system" ( echo System package manager does not support ls directly here. & exit /b 0 )
if exist "%LIBSCRIPT_HOME%\dash" ( dir /b "%LIBSCRIPT_HOME%\dash" )
exit /b 0

:: ## action_ls_remote
:: Executes action_ls_remote functionality.
:action_ls_remote
if "%DASH_INSTALL_METHOD%"=="mise" ( mise ls-remote dash & exit /b 0 )
if "%DASH_INSTALL_METHOD%"=="asdf" ( asdf list all dash & exit /b 0 )
if "%DASH_INSTALL_METHOD%"=="pkgx" ( echo pkgx does not have a local list command & exit /b 0 )
if "%DASH_INSTALL_METHOD%"=="vfox" ( vfox ls all dash & exit /b 0 )
if "%DASH_INSTALL_METHOD%"=="system" ( echo System package manager does not support ls-remote directly here. & exit /b 0 )
if not "%DASH_RELEASES_URL%"=="" (
    curl -sSL "%DASH_RELEASES_URL%"
) else (
    echo ls-remote not fully implemented natively yet.
)
exit /b 0

:: ## action_use
:: Executes action_use functionality.
:action_use
if "%DASH_INSTALL_METHOD%"=="mise" ( mise use "dash@%DASH_VERSION%" & exit /b 0 )
if "%DASH_INSTALL_METHOD%"=="asdf" ( asdf global dash "%DASH_VERSION%" & exit /b 0 )
if "%DASH_INSTALL_METHOD%"=="pkgx" ( echo pkgx does not use explicit versions this way & exit /b 0 )
if "%DASH_INSTALL_METHOD%"=="vfox" ( vfox use "dash@%DASH_VERSION%" & exit /b 0 )
if "%DASH_INSTALL_METHOD%"=="system" ( echo Cannot 'use' specific version with system package manager. & exit /b 0 )

if "%DASH_VERSION%"=="latest" (set "EXACT_VERSION=%DASH_VERSION%"
) else if "%DASH_VERSION%"=="lts" (set "EXACT_VERSION=%DASH_VERSION%"
) else (
    set "EXACT_VERSION=%DASH_VERSION%"
)
if "%EXACT_VERSION%"=="" set "EXACT_VERSION=%DASH_VERSION%"

set "TARGET_DIR=%LIBSCRIPT_HOME%\dash\%EXACT_VERSION%"
set "ALIAS_DIR=%LIBSCRIPT_HOME%\dash\%DASH_VERSION%"

if not "%TARGET_DIR%"=="%ALIAS_DIR%" (
    if exist "%ALIAS_DIR%" rmdir "%ALIAS_DIR%"
    mklink /J "%ALIAS_DIR%" "%TARGET_DIR%" >nul 2>&1
)
exit /b 0

:: ## action_download
:: Executes action_download functionality.
:action_download
if "%DASH_INSTALL_METHOD%"=="libscript_native" (
    echo Downloading dash %DASH_VERSION% to %DOWNLOAD_DIR%\dash...
    if not exist "%DOWNLOAD_DIR%\dash" mkdir "%DOWNLOAD_DIR%\dash"
    if not "%DASH_DOWNLOAD_URL%"=="" (
        curl -sSL "%DASH_DOWNLOAD_URL%" -o "%DOWNLOAD_DIR%\dash\dash-%DASH_VERSION%.zip"
    ) else (
        echo DASH_DOWNLOAD_URL is not defined. Skipping.
    )
)
exit /b 0

:: ## action_install
:: Executes action_install functionality.
:action_install
if "%DASH_INSTALL_METHOD%"=="system" (
    winget install dash --accept-package-agreements --accept-source-agreements
    exit /b !errorlevel!
)
if "%DASH_INSTALL_METHOD%"=="mise" ( mise install "dash@%DASH_VERSION%" & exit /b 0 )
if "%DASH_INSTALL_METHOD%"=="asdf" ( asdf install dash "%DASH_VERSION%" & exit /b 0 )
if "%DASH_INSTALL_METHOD%"=="pkgx" ( pkgx install "dash@%DASH_VERSION%" & exit /b 0 )
if "%DASH_INSTALL_METHOD%"=="vfox" ( vfox add dash & vfox install "dash@%DASH_VERSION%" & exit /b 0 )

set "TARGET_DIR=%LIBSCRIPT_HOME%\dash\%DASH_VERSION%"
if not exist "%TARGET_DIR%\bin" (
    echo Installing dash %DASH_VERSION% natively to %TARGET_DIR%...
    if not exist "%TARGET_DIR%\bin" mkdir "%TARGET_DIR%\bin"
    if exist "%DOWNLOAD_DIR%\dash\dash-%DASH_VERSION%.zip" (
        echo Extracting from cache...
        tar -xf "%DOWNLOAD_DIR%\dash\dash-%DASH_VERSION%.zip" -C "%TARGET_DIR%"
    ) else if exist "%DOWNLOAD_DIR%\dash\dash-%DASH_VERSION%.tar.gz" (
        echo Extracting from cache...
        tar -xf "%DOWNLOAD_DIR%\dash\dash-%DASH_VERSION%.tar.gz" -C "%TARGET_DIR%"
    ) else if not "%DASH_DOWNLOAD_URL%"=="" (
        echo Downloading and extracting...
        curl -sSL "%DASH_DOWNLOAD_URL%" -o "%TEMP%\dash.zip"
        tar -xf "%TEMP%\dash.zip" -C "%TARGET_DIR%"
    ) else (
        echo No download URL or cache available for dash.
    )
) else (
    echo dash %DASH_VERSION% is already installed.
)
set "ALIAS_DIR=%LIBSCRIPT_HOME%\dash\%DASH_VERSION%"
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
        set "SVC_NAME=libscript_dash"
    ) else (
        set "SVC_NAME=libscript_%PACKAGE_NAME%"
    )
) else (
    set "SVC_NAME=%LIBSCRIPT_SERVICE_NAME%"
)
if "%DASH_INSTALL_METHOD%"=="libscript_native" (
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\service.cmd" "%ACTION%" "%SVC_NAME%"
) else if "%DASH_INSTALL_METHOD%"=="system" (
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\service.cmd" "%ACTION%" "%SVC_NAME%"
) else (
    echo %ACTION% not natively implemented for %DASH_INSTALL_METHOD%.
)
exit /b 0

:: ## action_install_service
:: Executes action_install_service functionality.
:action_install_service
if "%LIBSCRIPT_SERVICE_NAME%"=="" (
    if "%PACKAGE_NAME%"=="" (
        set "SVC_NAME=libscript_dash"
    ) else (
        set "SVC_NAME=libscript_%PACKAGE_NAME%"
    )
) else (
    set "SVC_NAME=%LIBSCRIPT_SERVICE_NAME%"
)
if "%DASH_INSTALL_METHOD%"=="libscript_native" (
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\service_install.cmd" install "%SVC_NAME%"
) else if "%DASH_INSTALL_METHOD%"=="system" (
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\service_install.cmd" install "%SVC_NAME%"
) else (
    echo install-service not implemented for %DASH_INSTALL_METHOD%.
)
exit /b 0

:: ## action_uninstall_service
:: Executes action_uninstall_service functionality.
:action_uninstall_service
if "%LIBSCRIPT_SERVICE_NAME%"=="" (
    if "%PACKAGE_NAME%"=="" (
        set "SVC_NAME=libscript_dash"
    ) else (
        set "SVC_NAME=libscript_%PACKAGE_NAME%"
    )
) else (
    set "SVC_NAME=%LIBSCRIPT_SERVICE_NAME%"
)
if "%DASH_INSTALL_METHOD%"=="libscript_native" (
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\service_install.cmd" uninstall "%SVC_NAME%"
) else if "%DASH_INSTALL_METHOD%"=="system" (
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\service_install.cmd" uninstall "%SVC_NAME%"
) else (
    echo uninstall-service not implemented for %DASH_INSTALL_METHOD%.
)
exit /b 0
