@echo off
:: ## Overview
:: Windows setup for curl
::
:: ## Usage
:: Managed by libscript. Provides download, install, ls, ls-remote, use capabilities.

if "%ACTION%"=="" set ACTION=install
if "%CURL_VERSION%"=="" set CURL_VERSION=latest

if "%LIBSCRIPT_HOME%"=="" (
    set "LIBSCRIPT_HOME=%USERPROFILE%\.libscript"
)
if "%DOWNLOAD_DIR%"=="" (
    set "DOWNLOAD_DIR=%TEMP%\libscript_downloads"
)

:: Resolve install method
if "%CURL_INSTALL_METHOD%"=="" (
    if not "%LIBSCRIPT_DEFAULT_INSTALL_METHOD%"=="" (
        set "CURL_INSTALL_METHOD=%LIBSCRIPT_DEFAULT_INSTALL_METHOD%"
    ) else (
        set "CURL_INSTALL_METHOD=libscript_native"
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
if "%CURL_INSTALL_METHOD%"=="mise" ( mise ls curl & exit /b 0 )
if "%CURL_INSTALL_METHOD%"=="asdf" ( asdf list curl & exit /b 0 )
if "%CURL_INSTALL_METHOD%"=="pkgx" ( echo pkgx does not have a local list command & exit /b 0 )
if "%CURL_INSTALL_METHOD%"=="vfox" ( vfox ls curl & exit /b 0 )
if "%CURL_INSTALL_METHOD%"=="system" ( echo System package manager does not support ls directly here. & exit /b 0 )
if exist "%LIBSCRIPT_HOME%\curl" ( dir /b "%LIBSCRIPT_HOME%\curl" )
exit /b 0

:action_ls_remote
if "%CURL_INSTALL_METHOD%"=="mise" ( mise ls-remote curl & exit /b 0 )
if "%CURL_INSTALL_METHOD%"=="asdf" ( asdf list all curl & exit /b 0 )
if "%CURL_INSTALL_METHOD%"=="pkgx" ( echo pkgx does not have a local list command & exit /b 0 )
if "%CURL_INSTALL_METHOD%"=="vfox" ( vfox ls all curl & exit /b 0 )
if "%CURL_INSTALL_METHOD%"=="system" ( echo System package manager does not support ls-remote directly here. & exit /b 0 )
if not "%CURL_RELEASES_URL%"=="" (
    curl -sSL "%CURL_RELEASES_URL%"
) else (
    git ls-remote --tags "https://github.com/libscript/curl" 2^>nul ^| findstr /R "[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*"
)
exit /b 0

:action_use
if "%CURL_INSTALL_METHOD%"=="mise" ( mise use "curl@%CURL_VERSION%" & exit /b 0 )
if "%CURL_INSTALL_METHOD%"=="asdf" ( asdf global curl "%CURL_VERSION%" & exit /b 0 )
if "%CURL_INSTALL_METHOD%"=="pkgx" ( echo pkgx does not use explicit versions this way & exit /b 0 )
if "%CURL_INSTALL_METHOD%"=="vfox" ( vfox use "curl@%CURL_VERSION%" & exit /b 0 )
if "%CURL_INSTALL_METHOD%"=="system" ( echo Cannot 'use' specific version with system package manager. & exit /b 0 )

if "%CURL_VERSION%"=="latest" (set "EXACT_VERSION=%CURL_VERSION%"
) else if "%CURL_VERSION%"=="lts" (set "EXACT_VERSION=%CURL_VERSION%"
) else (
    set "EXACT_VERSION=%CURL_VERSION%"
)
if "%EXACT_VERSION%"=="" set "EXACT_VERSION=%CURL_VERSION%"

set "TARGET_DIR=%LIBSCRIPT_HOME%\curl\%EXACT_VERSION%"
set "ALIAS_DIR=%LIBSCRIPT_HOME%\curl\%CURL_VERSION%"

if not "%TARGET_DIR%"=="%ALIAS_DIR%" (
    if exist "%ALIAS_DIR%" rmdir "%ALIAS_DIR%"
    mklink /J "%ALIAS_DIR%" "%TARGET_DIR%" >nul 2>&1
)
exit /b 0

:action_download
if "%CURL_INSTALL_METHOD%"=="libscript_native" (
    echo Downloading curl %CURL_VERSION% to %DOWNLOAD_DIR%\curl...
    if not exist "%DOWNLOAD_DIR%\curl" mkdir "%DOWNLOAD_DIR%\curl"
    if not "%CURL_DOWNLOAD_URL%"=="" (
        curl -sSL "%CURL_DOWNLOAD_URL%" -o "%DOWNLOAD_DIR%\curl\curl-%CURL_VERSION%.zip"
    ) else (
        echo CURL_DOWNLOAD_URL is not defined. Skipping.
    )
)
exit /b 0

:action_install
if "%CURL_INSTALL_METHOD%"=="system" (
    winget install curl --accept-package-agreements --accept-source-agreements
    exit /b !errorlevel!
)
if "%CURL_INSTALL_METHOD%"=="mise" ( mise install "curl@%CURL_VERSION%" & exit /b 0 )
if "%CURL_INSTALL_METHOD%"=="asdf" ( asdf install curl "%CURL_VERSION%" & exit /b 0 )
if "%CURL_INSTALL_METHOD%"=="pkgx" ( pkgx install "curl@%CURL_VERSION%" & exit /b 0 )
if "%CURL_INSTALL_METHOD%"=="vfox" ( vfox add curl & vfox install "curl@%CURL_VERSION%" & exit /b 0 )

set "TARGET_DIR=%LIBSCRIPT_HOME%\curl\%CURL_VERSION%"
if not exist "%TARGET_DIR%\bin" (
    echo Installing curl %CURL_VERSION% natively to %TARGET_DIR%...
    mkdir "%TARGET_DIR%\bin"
    if exist "%DOWNLOAD_DIR%\curl\curl-%CURL_VERSION%.zip" (
        echo Extracting from cache...
        tar -xf "%DOWNLOAD_DIR%\curl\curl-%CURL_VERSION%.zip" -C "%TARGET_DIR%"
    ) else if exist "%DOWNLOAD_DIR%\curl\curl-%CURL_VERSION%.tar.gz" (
        echo Extracting from cache...
        tar -xf "%DOWNLOAD_DIR%\curl\curl-%CURL_VERSION%.tar.gz" -C "%TARGET_DIR%"
    ) else if not "%CURL_DOWNLOAD_URL%"=="" (
        echo Downloading and extracting...
        curl -sSL "%CURL_DOWNLOAD_URL%" -o "%TEMP%\curl.zip"
        tar -xf "%TEMP%\curl.zip" -C "%TARGET_DIR%"
    ) else (
        echo No download URL or cache available for curl.
    )
) else (
    echo curl %CURL_VERSION% is already installed.
)
set "ALIAS_DIR=%LIBSCRIPT_HOME%\curl\%CURL_VERSION%"
if not "%TARGET_DIR%"=="%ALIAS_DIR%" (
    if exist "%ALIAS_DIR%" rmdir "%ALIAS_DIR%"
    mklink /J "%ALIAS_DIR%" "%TARGET_DIR%" >nul 2>&1
)
exit /b 0

:action_service
if "%LIBSCRIPT_SERVICE_NAME%"=="" (
    if "%PACKAGE_NAME%"=="" (
        set "SVC_NAME=libscript_curl"
    ) else (
        set "SVC_NAME=libscript_%PACKAGE_NAME%"
    )
) else (
    set "SVC_NAME=%LIBSCRIPT_SERVICE_NAME%"
)
if "%CURL_INSTALL_METHOD%"=="libscript_native" (
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\service.cmd" "%ACTION%" "%SVC_NAME%"
) else if "%CURL_INSTALL_METHOD%"=="system" (
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\service.cmd" "%ACTION%" "%SVC_NAME%"
) else (
    echo %ACTION% not natively implemented for %CURL_INSTALL_METHOD%.
)
exit /b 0

:action_install_service
if "%LIBSCRIPT_SERVICE_NAME%"=="" (
    if "%PACKAGE_NAME%"=="" (
        set "SVC_NAME=libscript_curl"
    ) else (
        set "SVC_NAME=libscript_%PACKAGE_NAME%"
    )
) else (
    set "SVC_NAME=%LIBSCRIPT_SERVICE_NAME%"
)
if "%CURL_INSTALL_METHOD%"=="libscript_native" (
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\service_install.cmd" install "%SVC_NAME%"
) else if "%CURL_INSTALL_METHOD%"=="system" (
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\service_install.cmd" install "%SVC_NAME%"
) else (
    echo install-service not implemented for %CURL_INSTALL_METHOD%.
)
exit /b 0

:action_uninstall_service
if "%LIBSCRIPT_SERVICE_NAME%"=="" (
    if "%PACKAGE_NAME%"=="" (
        set "SVC_NAME=libscript_curl"
    ) else (
        set "SVC_NAME=libscript_%PACKAGE_NAME%"
    )
) else (
    set "SVC_NAME=%LIBSCRIPT_SERVICE_NAME%"
)
if "%CURL_INSTALL_METHOD%"=="libscript_native" (
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\service_install.cmd" uninstall "%SVC_NAME%"
) else if "%CURL_INSTALL_METHOD%"=="system" (
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\service_install.cmd" uninstall "%SVC_NAME%"
) else (
    echo uninstall-service not implemented for %CURL_INSTALL_METHOD%.
)
exit /b 0
