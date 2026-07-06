@echo off
:: ## Overview
:: Windows setup for kafka
::
:: ## Usage
:: Managed by libscript. Provides download, install, ls, ls-remote, use capabilities.

if "%ACTION%"=="" set ACTION=install
if "%KAFKA_VERSION%"=="" set KAFKA_VERSION=latest

if "%LIBSCRIPT_HOME%"=="" (
    set "LIBSCRIPT_HOME=%USERPROFILE%\.libscript"
)
if "%DOWNLOAD_DIR%"=="" (
    set "DOWNLOAD_DIR=%TEMP%\libscript_downloads"
)

:: Resolve install method
if "%KAFKA_INSTALL_METHOD%"=="" (
    if not "%LIBSCRIPT_DEFAULT_INSTALL_METHOD%"=="" (
        set "KAFKA_INSTALL_METHOD=%LIBSCRIPT_DEFAULT_INSTALL_METHOD%"
    ) else (
        set "KAFKA_INSTALL_METHOD=libscript_native"
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
if "%KAFKA_INSTALL_METHOD%"=="mise" ( mise ls kafka & exit /b 0 )
if "%KAFKA_INSTALL_METHOD%"=="asdf" ( asdf list kafka & exit /b 0 )
if "%KAFKA_INSTALL_METHOD%"=="pkgx" ( echo pkgx does not have a local list command & exit /b 0 )
if "%KAFKA_INSTALL_METHOD%"=="vfox" ( vfox ls kafka & exit /b 0 )
if "%KAFKA_INSTALL_METHOD%"=="system" ( echo System package manager does not support ls directly here. & exit /b 0 )
if exist "%LIBSCRIPT_HOME%\kafka" ( dir /b "%LIBSCRIPT_HOME%\kafka" )
exit /b 0

:action_ls_remote
if "%KAFKA_INSTALL_METHOD%"=="mise" ( mise ls-remote kafka & exit /b 0 )
if "%KAFKA_INSTALL_METHOD%"=="asdf" ( asdf list all kafka & exit /b 0 )
if "%KAFKA_INSTALL_METHOD%"=="pkgx" ( echo pkgx does not have a local list command & exit /b 0 )
if "%KAFKA_INSTALL_METHOD%"=="vfox" ( vfox ls all kafka & exit /b 0 )
if "%KAFKA_INSTALL_METHOD%"=="system" ( echo System package manager does not support ls-remote directly here. & exit /b 0 )
if not "%KAFKA_RELEASES_URL%"=="" (
    curl -sSL "%KAFKA_RELEASES_URL%"
) else (
    git ls-remote --tags "https://github.com/libscript/kafka" 2^>nul ^| findstr /R "[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*"
)
exit /b 0

:action_use
if "%KAFKA_INSTALL_METHOD%"=="mise" ( mise use "kafka@%KAFKA_VERSION%" & exit /b 0 )
if "%KAFKA_INSTALL_METHOD%"=="asdf" ( asdf global kafka "%KAFKA_VERSION%" & exit /b 0 )
if "%KAFKA_INSTALL_METHOD%"=="pkgx" ( echo pkgx does not use explicit versions this way & exit /b 0 )
if "%KAFKA_INSTALL_METHOD%"=="vfox" ( vfox use "kafka@%KAFKA_VERSION%" & exit /b 0 )
if "%KAFKA_INSTALL_METHOD%"=="system" ( echo Cannot 'use' specific version with system package manager. & exit /b 0 )

if "%KAFKA_VERSION%"=="latest" (set "EXACT_VERSION=%KAFKA_VERSION%"
) else if "%KAFKA_VERSION%"=="lts" (set "EXACT_VERSION=%KAFKA_VERSION%"
) else (
    set "EXACT_VERSION=%KAFKA_VERSION%"
)
if "%EXACT_VERSION%"=="" set "EXACT_VERSION=%KAFKA_VERSION%"

set "TARGET_DIR=%LIBSCRIPT_HOME%\kafka\%EXACT_VERSION%"
set "ALIAS_DIR=%LIBSCRIPT_HOME%\kafka\%KAFKA_VERSION%"

if not "%TARGET_DIR%"=="%ALIAS_DIR%" (
    if exist "%ALIAS_DIR%" rmdir "%ALIAS_DIR%"
    mklink /J "%ALIAS_DIR%" "%TARGET_DIR%" >nul 2>&1
)
exit /b 0

:action_download
if "%KAFKA_INSTALL_METHOD%"=="libscript_native" (
    echo Downloading kafka %KAFKA_VERSION% to %DOWNLOAD_DIR%\kafka...
    if not exist "%DOWNLOAD_DIR%\kafka" mkdir "%DOWNLOAD_DIR%\kafka"
    if not "%KAFKA_DOWNLOAD_URL%"=="" (
        curl -sSL "%KAFKA_DOWNLOAD_URL%" -o "%DOWNLOAD_DIR%\kafka\kafka-%KAFKA_VERSION%.zip"
    ) else (
        echo KAFKA_DOWNLOAD_URL is not defined. Skipping.
    )
)
exit /b 0

:action_install
if "%KAFKA_INSTALL_METHOD%"=="system" (
    winget install kafka --accept-package-agreements --accept-source-agreements
    exit /b !errorlevel!
)
if "%KAFKA_INSTALL_METHOD%"=="mise" ( mise install "kafka@%KAFKA_VERSION%" & exit /b 0 )
if "%KAFKA_INSTALL_METHOD%"=="asdf" ( asdf install kafka "%KAFKA_VERSION%" & exit /b 0 )
if "%KAFKA_INSTALL_METHOD%"=="pkgx" ( pkgx install "kafka@%KAFKA_VERSION%" & exit /b 0 )
if "%KAFKA_INSTALL_METHOD%"=="vfox" ( vfox add kafka & vfox install "kafka@%KAFKA_VERSION%" & exit /b 0 )

set "TARGET_DIR=%LIBSCRIPT_HOME%\kafka\%KAFKA_VERSION%"
if not exist "%TARGET_DIR%\bin" (
    echo Installing kafka %KAFKA_VERSION% natively to %TARGET_DIR%...
    mkdir "%TARGET_DIR%\bin"
    if exist "%DOWNLOAD_DIR%\kafka\kafka-%KAFKA_VERSION%.zip" (
        echo Extracting from cache...
        tar -xf "%DOWNLOAD_DIR%\kafka\kafka-%KAFKA_VERSION%.zip" -C "%TARGET_DIR%"
    ) else if exist "%DOWNLOAD_DIR%\kafka\kafka-%KAFKA_VERSION%.tar.gz" (
        echo Extracting from cache...
        tar -xf "%DOWNLOAD_DIR%\kafka\kafka-%KAFKA_VERSION%.tar.gz" -C "%TARGET_DIR%"
    ) else if not "%KAFKA_DOWNLOAD_URL%"=="" (
        echo Downloading and extracting...
        curl -sSL "%KAFKA_DOWNLOAD_URL%" -o "%TEMP%\kafka.zip"
        tar -xf "%TEMP%\kafka.zip" -C "%TARGET_DIR%"
    ) else (
        echo No download URL or cache available for kafka.
    )
) else (
    echo kafka %KAFKA_VERSION% is already installed.
)
set "ALIAS_DIR=%LIBSCRIPT_HOME%\kafka\%KAFKA_VERSION%"
if not "%TARGET_DIR%"=="%ALIAS_DIR%" (
    if exist "%ALIAS_DIR%" rmdir "%ALIAS_DIR%"
    mklink /J "%ALIAS_DIR%" "%TARGET_DIR%" >nul 2>&1
)
exit /b 0

:action_service
if "%LIBSCRIPT_SERVICE_NAME%"=="" (
    if "%PACKAGE_NAME%"=="" (
        set "SVC_NAME=libscript_kafka"
    ) else (
        set "SVC_NAME=libscript_%PACKAGE_NAME%"
    )
) else (
    set "SVC_NAME=%LIBSCRIPT_SERVICE_NAME%"
)
if "%KAFKA_INSTALL_METHOD%"=="libscript_native" (
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\service.cmd" "%ACTION%" "%SVC_NAME%"
) else if "%KAFKA_INSTALL_METHOD%"=="system" (
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\service.cmd" "%ACTION%" "%SVC_NAME%"
) else (
    echo %ACTION% not natively implemented for %KAFKA_INSTALL_METHOD%.
)
exit /b 0

:action_install_service
if "%LIBSCRIPT_SERVICE_NAME%"=="" (
    if "%PACKAGE_NAME%"=="" (
        set "SVC_NAME=libscript_kafka"
    ) else (
        set "SVC_NAME=libscript_%PACKAGE_NAME%"
    )
) else (
    set "SVC_NAME=%LIBSCRIPT_SERVICE_NAME%"
)
if "%KAFKA_INSTALL_METHOD%"=="libscript_native" (
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\service_install.cmd" install "%SVC_NAME%"
) else if "%KAFKA_INSTALL_METHOD%"=="system" (
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\service_install.cmd" install "%SVC_NAME%"
) else (
    echo install-service not implemented for %KAFKA_INSTALL_METHOD%.
)
exit /b 0

:action_uninstall_service
if "%LIBSCRIPT_SERVICE_NAME%"=="" (
    if "%PACKAGE_NAME%"=="" (
        set "SVC_NAME=libscript_kafka"
    ) else (
        set "SVC_NAME=libscript_%PACKAGE_NAME%"
    )
) else (
    set "SVC_NAME=%LIBSCRIPT_SERVICE_NAME%"
)
if "%KAFKA_INSTALL_METHOD%"=="libscript_native" (
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\service_install.cmd" uninstall "%SVC_NAME%"
) else if "%KAFKA_INSTALL_METHOD%"=="system" (
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\service_install.cmd" uninstall "%SVC_NAME%"
) else (
    echo uninstall-service not implemented for %KAFKA_INSTALL_METHOD%.
)
exit /b 0
