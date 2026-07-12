@echo off
:: ## Overview
:: Windows setup for swupd
::
:: ## Usage
:: Managed by libscript. Provides download, install, ls, ls-remote, use capabilities.

if "%ACTION%"=="" set ACTION=install
if "%SWUPD_VERSION%"=="" set SWUPD_VERSION=latest

if "%LIBSCRIPT_HOME%"=="" (
    set "LIBSCRIPT_HOME=%USERPROFILE%\.libscript"
)
if "%DOWNLOAD_DIR%"=="" (
    set "DOWNLOAD_DIR=%TEMP%\libscript_downloads"
)

:: Resolve install method
if "%SWUPD_INSTALL_METHOD%"=="" (
    if not "%LIBSCRIPT_DEFAULT_INSTALL_METHOD%"=="" (
        set "SWUPD_INSTALL_METHOD=%LIBSCRIPT_DEFAULT_INSTALL_METHOD%"
    ) else (
        set "SWUPD_INSTALL_METHOD=libscript_native"
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
if "%SWUPD_INSTALL_METHOD%"=="mise" ( mise ls swupd & exit /b 0 )
if "%SWUPD_INSTALL_METHOD%"=="asdf" ( asdf list swupd & exit /b 0 )
if "%SWUPD_INSTALL_METHOD%"=="pkgx" ( echo pkgx does not have a local list command & exit /b 0 )
if "%SWUPD_INSTALL_METHOD%"=="vfox" ( vfox ls swupd & exit /b 0 )
if "%SWUPD_INSTALL_METHOD%"=="system" ( echo System package manager does not support ls directly here. & exit /b 0 )
if exist "%LIBSCRIPT_HOME%\swupd" ( dir /b "%LIBSCRIPT_HOME%\swupd" )
exit /b 0

:action_ls_remote
if "%SWUPD_INSTALL_METHOD%"=="mise" ( mise ls-remote swupd & exit /b 0 )
if "%SWUPD_INSTALL_METHOD%"=="asdf" ( asdf list all swupd & exit /b 0 )
if "%SWUPD_INSTALL_METHOD%"=="pkgx" ( echo pkgx does not have a local list command & exit /b 0 )
if "%SWUPD_INSTALL_METHOD%"=="vfox" ( vfox ls all swupd & exit /b 0 )
if "%SWUPD_INSTALL_METHOD%"=="system" ( echo System package manager does not support ls-remote directly here. & exit /b 0 )
if not "%SWUPD_RELEASES_URL%"=="" (
    curl -sSL "%SWUPD_RELEASES_URL%"
) else (
    git ls-remote --tags "https://github.com/sbabic/swupdate" 2^>nul ^| findstr /R "[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*"
)
exit /b 0

:action_use
if "%SWUPD_INSTALL_METHOD%"=="mise" ( mise use "swupd@%SWUPD_VERSION%" & exit /b 0 )
if "%SWUPD_INSTALL_METHOD%"=="asdf" ( asdf global swupd "%SWUPD_VERSION%" & exit /b 0 )
if "%SWUPD_INSTALL_METHOD%"=="pkgx" ( echo pkgx does not use explicit versions this way & exit /b 0 )
if "%SWUPD_INSTALL_METHOD%"=="vfox" ( vfox use "swupd@%SWUPD_VERSION%" & exit /b 0 )
if "%SWUPD_INSTALL_METHOD%"=="system" ( echo Cannot 'use' specific version with system package manager. & exit /b 0 )

if "%SWUPD_VERSION%"=="latest" (set "EXACT_VERSION=%SWUPD_VERSION%"
) else if "%SWUPD_VERSION%"=="lts" (set "EXACT_VERSION=%SWUPD_VERSION%"
) else (
    set "EXACT_VERSION=%SWUPD_VERSION%"
)
if "%EXACT_VERSION%"=="" set "EXACT_VERSION=%SWUPD_VERSION%"

set "TARGET_DIR=%LIBSCRIPT_HOME%\swupd\%EXACT_VERSION%"
set "ALIAS_DIR=%LIBSCRIPT_HOME%\swupd\%SWUPD_VERSION%"

if not "%TARGET_DIR%"=="%ALIAS_DIR%" (
    if exist "%ALIAS_DIR%" rmdir "%ALIAS_DIR%"
    mklink /J "%ALIAS_DIR%" "%TARGET_DIR%" >nul 2>&1
)
exit /b 0

:action_download
if "%SWUPD_INSTALL_METHOD%"=="libscript_native" (
    echo Downloading swupd %SWUPD_VERSION% to %DOWNLOAD_DIR%\swupd...
    if not exist "%DOWNLOAD_DIR%\swupd" mkdir "%DOWNLOAD_DIR%\swupd"
    if not "%SWUPD_DOWNLOAD_URL%"=="" (
        curl -sSL "%SWUPD_DOWNLOAD_URL%" -o "%DOWNLOAD_DIR%\swupd\swupd-%SWUPD_VERSION%.zip"
    ) else (
        echo SWUPD_DOWNLOAD_URL is not defined. Skipping.
    )
)
exit /b 0

:action_install
if "%SWUPD_INSTALL_METHOD%"=="system" (
    winget install swupd --accept-package-agreements --accept-source-agreements
    exit /b !errorlevel!
)
if "%SWUPD_INSTALL_METHOD%"=="mise" ( mise install "swupd@%SWUPD_VERSION%" & exit /b 0 )
if "%SWUPD_INSTALL_METHOD%"=="asdf" ( asdf install swupd "%SWUPD_VERSION%" & exit /b 0 )
if "%SWUPD_INSTALL_METHOD%"=="pkgx" ( pkgx install "swupd@%SWUPD_VERSION%" & exit /b 0 )
if "%SWUPD_INSTALL_METHOD%"=="vfox" ( vfox add swupd & vfox install "swupd@%SWUPD_VERSION%" & exit /b 0 )

set "TARGET_DIR=%LIBSCRIPT_HOME%\swupd\%SWUPD_VERSION%"
if not exist "%TARGET_DIR%\bin" (
    echo Installing swupd %SWUPD_VERSION% natively to %TARGET_DIR%...
    if not exist "%TARGET_DIR%\bin" mkdir "%TARGET_DIR%\bin"
    if exist "%DOWNLOAD_DIR%\swupd\swupd-%SWUPD_VERSION%.zip" (
        echo Extracting from cache...
        tar -xf "%DOWNLOAD_DIR%\swupd\swupd-%SWUPD_VERSION%.zip" -C "%TARGET_DIR%"
    ) else if exist "%DOWNLOAD_DIR%\swupd\swupd-%SWUPD_VERSION%.tar.gz" (
        echo Extracting from cache...
        tar -xf "%DOWNLOAD_DIR%\swupd\swupd-%SWUPD_VERSION%.tar.gz" -C "%TARGET_DIR%"
    ) else if not "%SWUPD_DOWNLOAD_URL%"=="" (
        echo Downloading and extracting...
        curl -sSL "%SWUPD_DOWNLOAD_URL%" -o "%TEMP%\swupd.zip"
        tar -xf "%TEMP%\swupd.zip" -C "%TARGET_DIR%"
    ) else (
        echo No download URL or cache available for swupd.
    )
) else (
    echo swupd %SWUPD_VERSION% is already installed.
)
set "ALIAS_DIR=%LIBSCRIPT_HOME%\swupd\%SWUPD_VERSION%"
if not "%TARGET_DIR%"=="%ALIAS_DIR%" (
    if exist "%ALIAS_DIR%" rmdir "%ALIAS_DIR%"
    mklink /J "%ALIAS_DIR%" "%TARGET_DIR%" >nul 2>&1
)
exit /b 0

:action_service
if "%LIBSCRIPT_SERVICE_NAME%"=="" (
    if "%PACKAGE_NAME%"=="" (
        set "SVC_NAME=libscript_swupd"
    ) else (
        set "SVC_NAME=libscript_%PACKAGE_NAME%"
    )
) else (
    set "SVC_NAME=%LIBSCRIPT_SERVICE_NAME%"
)
if "%SWUPD_INSTALL_METHOD%"=="libscript_native" (
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\service.cmd" "%ACTION%" "%SVC_NAME%"
) else if "%SWUPD_INSTALL_METHOD%"=="system" (
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\service.cmd" "%ACTION%" "%SVC_NAME%"
) else (
    echo %ACTION% not natively implemented for %SWUPD_INSTALL_METHOD%.
)
exit /b 0

:action_install_service
if "%LIBSCRIPT_SERVICE_NAME%"=="" (
    if "%PACKAGE_NAME%"=="" (
        set "SVC_NAME=libscript_swupd"
    ) else (
        set "SVC_NAME=libscript_%PACKAGE_NAME%"
    )
) else (
    set "SVC_NAME=%LIBSCRIPT_SERVICE_NAME%"
)
if "%SWUPD_INSTALL_METHOD%"=="libscript_native" (
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\service_install.cmd" install "%SVC_NAME%"
) else if "%SWUPD_INSTALL_METHOD%"=="system" (
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\service_install.cmd" install "%SVC_NAME%"
) else (
    echo install-service not implemented for %SWUPD_INSTALL_METHOD%.
)
exit /b 0

:action_uninstall_service
if "%LIBSCRIPT_SERVICE_NAME%"=="" (
    if "%PACKAGE_NAME%"=="" (
        set "SVC_NAME=libscript_swupd"
    ) else (
        set "SVC_NAME=libscript_%PACKAGE_NAME%"
    )
) else (
    set "SVC_NAME=%LIBSCRIPT_SERVICE_NAME%"
)
if "%SWUPD_INSTALL_METHOD%"=="libscript_native" (
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\service_install.cmd" uninstall "%SVC_NAME%"
) else if "%SWUPD_INSTALL_METHOD%"=="system" (
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\service_install.cmd" uninstall "%SVC_NAME%"
) else (
    echo uninstall-service not implemented for %SWUPD_INSTALL_METHOD%.
)
exit /b 0
