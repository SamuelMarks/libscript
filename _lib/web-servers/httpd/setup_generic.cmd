@echo off
:: ## Overview
:: Windows setup for httpd
::
:: ## Usage
:: Managed by libscript. Provides download, install, ls, ls-remote, use capabilities.

if "%ACTION%"=="" set ACTION=install
if "%HTTPD_VERSION%"=="" set HTTPD_VERSION=latest

if "%LIBSCRIPT_HOME%"=="" (
    set "LIBSCRIPT_HOME=%USERPROFILE%\.libscript"
)
if "%DOWNLOAD_DIR%"=="" (
    set "DOWNLOAD_DIR=%TEMP%\libscript_downloads"
)

:: Resolve install method
if "%HTTPD_INSTALL_METHOD%"=="" (
    if not "%LIBSCRIPT_DEFAULT_INSTALL_METHOD%"=="" (
        set "HTTPD_INSTALL_METHOD=%LIBSCRIPT_DEFAULT_INSTALL_METHOD%"
    ) else (
        set "HTTPD_INSTALL_METHOD=libscript_native"
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
if "%HTTPD_INSTALL_METHOD%"=="mise" ( mise ls httpd & exit /b 0 )
if "%HTTPD_INSTALL_METHOD%"=="asdf" ( asdf list httpd & exit /b 0 )
if "%HTTPD_INSTALL_METHOD%"=="pkgx" ( echo pkgx does not have a local list command & exit /b 0 )
if "%HTTPD_INSTALL_METHOD%"=="vfox" ( vfox ls httpd & exit /b 0 )
if "%HTTPD_INSTALL_METHOD%"=="system" ( echo System package manager does not support ls directly here. & exit /b 0 )
if exist "%LIBSCRIPT_HOME%\httpd" ( dir /b "%LIBSCRIPT_HOME%\httpd" )
exit /b 0

:: ## action_ls_remote
:: Executes action_ls_remote functionality.
:action_ls_remote
if "%HTTPD_INSTALL_METHOD%"=="mise" ( mise ls-remote httpd & exit /b 0 )
if "%HTTPD_INSTALL_METHOD%"=="asdf" ( asdf list all httpd & exit /b 0 )
if "%HTTPD_INSTALL_METHOD%"=="pkgx" ( echo pkgx does not have a local list command & exit /b 0 )
if "%HTTPD_INSTALL_METHOD%"=="vfox" ( vfox ls all httpd & exit /b 0 )
if "%HTTPD_INSTALL_METHOD%"=="system" ( echo System package manager does not support ls-remote directly here. & exit /b 0 )
if not "%HTTPD_RELEASES_URL%"=="" (
    curl -sSL "%HTTPD_RELEASES_URL%"
) else (
    echo ls-remote not fully implemented natively yet.
)
exit /b 0

:: ## action_use
:: Executes action_use functionality.
:action_use
if "%HTTPD_INSTALL_METHOD%"=="mise" ( mise use "httpd@%HTTPD_VERSION%" & exit /b 0 )
if "%HTTPD_INSTALL_METHOD%"=="asdf" ( asdf global httpd "%HTTPD_VERSION%" & exit /b 0 )
if "%HTTPD_INSTALL_METHOD%"=="pkgx" ( echo pkgx does not use explicit versions this way & exit /b 0 )
if "%HTTPD_INSTALL_METHOD%"=="vfox" ( vfox use "httpd@%HTTPD_VERSION%" & exit /b 0 )
if "%HTTPD_INSTALL_METHOD%"=="system" ( echo Cannot 'use' specific version with system package manager. & exit /b 0 )

if "%HTTPD_VERSION%"=="latest" (set "EXACT_VERSION=%HTTPD_VERSION%"
) else if "%HTTPD_VERSION%"=="lts" (set "EXACT_VERSION=%HTTPD_VERSION%"
) else (
    set "EXACT_VERSION=%HTTPD_VERSION%"
)
if "%EXACT_VERSION%"=="" set "EXACT_VERSION=%HTTPD_VERSION%"

set "TARGET_DIR=%LIBSCRIPT_HOME%\httpd\%EXACT_VERSION%"
set "ALIAS_DIR=%LIBSCRIPT_HOME%\httpd\%HTTPD_VERSION%"

if not "%TARGET_DIR%"=="%ALIAS_DIR%" (
    if exist "%ALIAS_DIR%" rmdir "%ALIAS_DIR%"
    mklink /J "%ALIAS_DIR%" "%TARGET_DIR%" >nul 2>&1
)
exit /b 0

:: ## action_download
:: Executes action_download functionality.
:action_download
if "%HTTPD_INSTALL_METHOD%"=="libscript_native" (
    echo Downloading httpd %HTTPD_VERSION% to %DOWNLOAD_DIR%\httpd...
    if not exist "%DOWNLOAD_DIR%\httpd" mkdir "%DOWNLOAD_DIR%\httpd"
    if not "%HTTPD_DOWNLOAD_URL%"=="" (
        curl -sSL "%HTTPD_DOWNLOAD_URL%" -o "%DOWNLOAD_DIR%\httpd\httpd-%HTTPD_VERSION%.zip"
    ) else (
        echo HTTPD_DOWNLOAD_URL is not defined. Skipping.
    )
)
exit /b 0

:: ## action_install
:: Executes action_install functionality.
:action_install
if "%HTTPD_INSTALL_METHOD%"=="system" (
    winget install httpd --accept-package-agreements --accept-source-agreements
    exit /b !errorlevel!
)
if "%HTTPD_INSTALL_METHOD%"=="mise" ( mise install "httpd@%HTTPD_VERSION%" & exit /b 0 )
if "%HTTPD_INSTALL_METHOD%"=="asdf" ( asdf install httpd "%HTTPD_VERSION%" & exit /b 0 )
if "%HTTPD_INSTALL_METHOD%"=="pkgx" ( pkgx install "httpd@%HTTPD_VERSION%" & exit /b 0 )
if "%HTTPD_INSTALL_METHOD%"=="vfox" ( vfox add httpd & vfox install "httpd@%HTTPD_VERSION%" & exit /b 0 )

set "TARGET_DIR=%LIBSCRIPT_HOME%\httpd\%HTTPD_VERSION%"
if not exist "%TARGET_DIR%\bin" (
    echo Installing httpd %HTTPD_VERSION% natively to %TARGET_DIR%...
    if not exist "%TARGET_DIR%\bin" mkdir "%TARGET_DIR%\bin"
    if exist "%DOWNLOAD_DIR%\httpd\httpd-%HTTPD_VERSION%.zip" (
        echo Extracting from cache...
        tar -xf "%DOWNLOAD_DIR%\httpd\httpd-%HTTPD_VERSION%.zip" -C "%TARGET_DIR%"
    ) else if exist "%DOWNLOAD_DIR%\httpd\httpd-%HTTPD_VERSION%.tar.gz" (
        echo Extracting from cache...
        tar -xf "%DOWNLOAD_DIR%\httpd\httpd-%HTTPD_VERSION%.tar.gz" -C "%TARGET_DIR%"
    ) else if not "%HTTPD_DOWNLOAD_URL%"=="" (
        echo Downloading and extracting...
        curl -sSL "%HTTPD_DOWNLOAD_URL%" -o "%TEMP%\httpd.zip"
        tar -xf "%TEMP%\httpd.zip" -C "%TARGET_DIR%"
    ) else (
        echo No download URL or cache available for httpd.
    )
) else (
    echo httpd %HTTPD_VERSION% is already installed.
)
set "ALIAS_DIR=%LIBSCRIPT_HOME%\httpd\%HTTPD_VERSION%"
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
        set "SVC_NAME=libscript_httpd"
    ) else (
        set "SVC_NAME=libscript_%PACKAGE_NAME%"
    )
) else (
    set "SVC_NAME=%LIBSCRIPT_SERVICE_NAME%"
)
if "%HTTPD_INSTALL_METHOD%"=="libscript_native" (
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\service.cmd" "%ACTION%" "%SVC_NAME%"
) else if "%HTTPD_INSTALL_METHOD%"=="system" (
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\service.cmd" "%ACTION%" "%SVC_NAME%"
) else (
    echo %ACTION% not natively implemented for %HTTPD_INSTALL_METHOD%.
)
exit /b 0

:: ## action_install_service
:: Executes action_install_service functionality.
:action_install_service
if "%LIBSCRIPT_SERVICE_NAME%"=="" (
    if "%PACKAGE_NAME%"=="" (
        set "SVC_NAME=libscript_httpd"
    ) else (
        set "SVC_NAME=libscript_%PACKAGE_NAME%"
    )
) else (
    set "SVC_NAME=%LIBSCRIPT_SERVICE_NAME%"
)
if "%HTTPD_INSTALL_METHOD%"=="libscript_native" (
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\service_install.cmd" install "%SVC_NAME%"
) else if "%HTTPD_INSTALL_METHOD%"=="system" (
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\service_install.cmd" install "%SVC_NAME%"
) else (
    echo install-service not implemented for %HTTPD_INSTALL_METHOD%.
)
exit /b 0

:: ## action_uninstall_service
:: Executes action_uninstall_service functionality.
:action_uninstall_service
if "%LIBSCRIPT_SERVICE_NAME%"=="" (
    if "%PACKAGE_NAME%"=="" (
        set "SVC_NAME=libscript_httpd"
    ) else (
        set "SVC_NAME=libscript_%PACKAGE_NAME%"
    )
) else (
    set "SVC_NAME=%LIBSCRIPT_SERVICE_NAME%"
)
if "%HTTPD_INSTALL_METHOD%"=="libscript_native" (
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\service_install.cmd" uninstall "%SVC_NAME%"
) else if "%HTTPD_INSTALL_METHOD%"=="system" (
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\service_install.cmd" uninstall "%SVC_NAME%"
) else (
    echo uninstall-service not implemented for %HTTPD_INSTALL_METHOD%.
)
exit /b 0
