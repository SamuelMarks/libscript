@echo off
:: ## Overview
:: Windows setup for composer
::
:: ## Usage
:: Managed by libscript. Provides download, install, ls, ls-remote, use capabilities.

if "%ACTION%"=="" set ACTION=install
if "%COMPOSER_VERSION%"=="" set COMPOSER_VERSION=latest

if "%LIBSCRIPT_HOME%"=="" (
    set "LIBSCRIPT_HOME=%USERPROFILE%\.libscript"
)
if "%DOWNLOAD_DIR%"=="" (
    set "DOWNLOAD_DIR=%TEMP%\libscript_downloads"
)

:: Resolve install method
if "%COMPOSER_INSTALL_METHOD%"=="" (
    if not "%LIBSCRIPT_DEFAULT_INSTALL_METHOD%"=="" (
        set "COMPOSER_INSTALL_METHOD=%LIBSCRIPT_DEFAULT_INSTALL_METHOD%"
    ) else (
        set "COMPOSER_INSTALL_METHOD=libscript_native"
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
if "%COMPOSER_INSTALL_METHOD%"=="mise" ( mise ls composer & exit /b 0 )
if "%COMPOSER_INSTALL_METHOD%"=="asdf" ( asdf list composer & exit /b 0 )
if "%COMPOSER_INSTALL_METHOD%"=="pkgx" ( echo pkgx does not have a local list command & exit /b 0 )
if "%COMPOSER_INSTALL_METHOD%"=="vfox" ( vfox ls composer & exit /b 0 )
if "%COMPOSER_INSTALL_METHOD%"=="system" ( echo System package manager does not support ls directly here. & exit /b 0 )
if exist "%LIBSCRIPT_HOME%\composer" ( dir /b "%LIBSCRIPT_HOME%\composer" )
exit /b 0

:action_ls_remote
if "%COMPOSER_INSTALL_METHOD%"=="mise" ( mise ls-remote composer & exit /b 0 )
if "%COMPOSER_INSTALL_METHOD%"=="asdf" ( asdf list all composer & exit /b 0 )
if "%COMPOSER_INSTALL_METHOD%"=="pkgx" ( echo pkgx does not have a local list command & exit /b 0 )
if "%COMPOSER_INSTALL_METHOD%"=="vfox" ( vfox ls all composer & exit /b 0 )
if "%COMPOSER_INSTALL_METHOD%"=="system" ( echo System package manager does not support ls-remote directly here. & exit /b 0 )
if not "%COMPOSER_RELEASES_URL%"=="" (
    curl -sSL "%COMPOSER_RELEASES_URL%"
) else (
    git ls-remote --tags "https://github.com/composer/composer" 2^>nul ^| findstr /R "[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*"
)
exit /b 0

:action_use
if "%COMPOSER_INSTALL_METHOD%"=="mise" ( mise use "composer@%COMPOSER_VERSION%" & exit /b 0 )
if "%COMPOSER_INSTALL_METHOD%"=="asdf" ( asdf global composer "%COMPOSER_VERSION%" & exit /b 0 )
if "%COMPOSER_INSTALL_METHOD%"=="pkgx" ( echo pkgx does not use explicit versions this way & exit /b 0 )
if "%COMPOSER_INSTALL_METHOD%"=="vfox" ( vfox use "composer@%COMPOSER_VERSION%" & exit /b 0 )
if "%COMPOSER_INSTALL_METHOD%"=="system" ( echo Cannot 'use' specific version with system package manager. & exit /b 0 )

if "%COMPOSER_VERSION%"=="latest" (set "EXACT_VERSION=%COMPOSER_VERSION%"
) else if "%COMPOSER_VERSION%"=="lts" (set "EXACT_VERSION=%COMPOSER_VERSION%"
) else (
    set "EXACT_VERSION=%COMPOSER_VERSION%"
)
if "%EXACT_VERSION%"=="" set "EXACT_VERSION=%COMPOSER_VERSION%"

set "TARGET_DIR=%LIBSCRIPT_HOME%\composer\%EXACT_VERSION%"
set "ALIAS_DIR=%LIBSCRIPT_HOME%\composer\%COMPOSER_VERSION%"

if not "%TARGET_DIR%"=="%ALIAS_DIR%" (
    if exist "%ALIAS_DIR%" rmdir "%ALIAS_DIR%"
    mklink /J "%ALIAS_DIR%" "%TARGET_DIR%" >nul 2>&1
)
exit /b 0

:action_download
if "%COMPOSER_INSTALL_METHOD%"=="libscript_native" (
    echo Downloading composer %COMPOSER_VERSION% to %DOWNLOAD_DIR%\composer...
    if not exist "%DOWNLOAD_DIR%\composer" mkdir "%DOWNLOAD_DIR%\composer"
    if not "%COMPOSER_DOWNLOAD_URL%"=="" (
        curl -sSL "%COMPOSER_DOWNLOAD_URL%" -o "%DOWNLOAD_DIR%\composer\composer-%COMPOSER_VERSION%.zip"
    ) else (
        echo COMPOSER_DOWNLOAD_URL is not defined. Skipping.
    )
)
exit /b 0

:action_install
if "%COMPOSER_INSTALL_METHOD%"=="system" (
    winget install composer --accept-package-agreements --accept-source-agreements
    exit /b !errorlevel!
)
if "%COMPOSER_INSTALL_METHOD%"=="mise" ( mise install "composer@%COMPOSER_VERSION%" & exit /b 0 )
if "%COMPOSER_INSTALL_METHOD%"=="asdf" ( asdf install composer "%COMPOSER_VERSION%" & exit /b 0 )
if "%COMPOSER_INSTALL_METHOD%"=="pkgx" ( pkgx install "composer@%COMPOSER_VERSION%" & exit /b 0 )
if "%COMPOSER_INSTALL_METHOD%"=="vfox" ( vfox add composer & vfox install "composer@%COMPOSER_VERSION%" & exit /b 0 )

set "TARGET_DIR=%LIBSCRIPT_HOME%\composer\%COMPOSER_VERSION%"
if not exist "%TARGET_DIR%\bin" (
    echo Installing composer %COMPOSER_VERSION% natively to %TARGET_DIR%...
    if not exist "%TARGET_DIR%\bin" mkdir "%TARGET_DIR%\bin"
    if exist "%DOWNLOAD_DIR%\composer\composer-%COMPOSER_VERSION%.zip" (
        echo Extracting from cache...
        tar -xf "%DOWNLOAD_DIR%\composer\composer-%COMPOSER_VERSION%.zip" -C "%TARGET_DIR%"
    ) else if exist "%DOWNLOAD_DIR%\composer\composer-%COMPOSER_VERSION%.tar.gz" (
        echo Extracting from cache...
        tar -xf "%DOWNLOAD_DIR%\composer\composer-%COMPOSER_VERSION%.tar.gz" -C "%TARGET_DIR%"
    ) else if not "%COMPOSER_DOWNLOAD_URL%"=="" (
        echo Downloading and extracting...
        curl -sSL "%COMPOSER_DOWNLOAD_URL%" -o "%TEMP%\composer.zip"
        tar -xf "%TEMP%\composer.zip" -C "%TARGET_DIR%"
    ) else (
        echo No download URL or cache available for composer.
    )
) else (
    echo composer %COMPOSER_VERSION% is already installed.
)
set "ALIAS_DIR=%LIBSCRIPT_HOME%\composer\%COMPOSER_VERSION%"
if not "%TARGET_DIR%"=="%ALIAS_DIR%" (
    if exist "%ALIAS_DIR%" rmdir "%ALIAS_DIR%"
    mklink /J "%ALIAS_DIR%" "%TARGET_DIR%" >nul 2>&1
)
exit /b 0

:action_service
if "%LIBSCRIPT_SERVICE_NAME%"=="" (
    if "%PACKAGE_NAME%"=="" (
        set "SVC_NAME=libscript_composer"
    ) else (
        set "SVC_NAME=libscript_%PACKAGE_NAME%"
    )
) else (
    set "SVC_NAME=%LIBSCRIPT_SERVICE_NAME%"
)
if "%COMPOSER_INSTALL_METHOD%"=="libscript_native" (
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\service.cmd" "%ACTION%" "%SVC_NAME%"
) else if "%COMPOSER_INSTALL_METHOD%"=="system" (
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\service.cmd" "%ACTION%" "%SVC_NAME%"
) else (
    echo %ACTION% not natively implemented for %COMPOSER_INSTALL_METHOD%.
)
exit /b 0

:action_install_service
if "%LIBSCRIPT_SERVICE_NAME%"=="" (
    if "%PACKAGE_NAME%"=="" (
        set "SVC_NAME=libscript_composer"
    ) else (
        set "SVC_NAME=libscript_%PACKAGE_NAME%"
    )
) else (
    set "SVC_NAME=%LIBSCRIPT_SERVICE_NAME%"
)
if "%COMPOSER_INSTALL_METHOD%"=="libscript_native" (
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\service_install.cmd" install "%SVC_NAME%"
) else if "%COMPOSER_INSTALL_METHOD%"=="system" (
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\service_install.cmd" install "%SVC_NAME%"
) else (
    echo install-service not implemented for %COMPOSER_INSTALL_METHOD%.
)
exit /b 0

:action_uninstall_service
if "%LIBSCRIPT_SERVICE_NAME%"=="" (
    if "%PACKAGE_NAME%"=="" (
        set "SVC_NAME=libscript_composer"
    ) else (
        set "SVC_NAME=libscript_%PACKAGE_NAME%"
    )
) else (
    set "SVC_NAME=%LIBSCRIPT_SERVICE_NAME%"
)
if "%COMPOSER_INSTALL_METHOD%"=="libscript_native" (
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\service_install.cmd" uninstall "%SVC_NAME%"
) else if "%COMPOSER_INSTALL_METHOD%"=="system" (
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\service_install.cmd" uninstall "%SVC_NAME%"
) else (
    echo uninstall-service not implemented for %COMPOSER_INSTALL_METHOD%.
)
exit /b 0
