@echo off
:: ## Overview
:: Windows setup for r
::
:: ## Usage
:: Managed by libscript. Provides download, install, ls, ls-remote, use capabilities.

if "%ACTION%"=="" set ACTION=install
if "%R_VERSION%"=="" set R_VERSION=latest

if "%LIBSCRIPT_HOME%"=="" (
    set "LIBSCRIPT_HOME=%USERPROFILE%\.libscript"
)
if "%DOWNLOAD_DIR%"=="" (
    set "DOWNLOAD_DIR=%TEMP%\libscript_downloads"
)

:: Resolve install method
if "%R_INSTALL_METHOD%"=="" (
    if not "%LIBSCRIPT_DEFAULT_INSTALL_METHOD%"=="" (
        set "R_INSTALL_METHOD=%LIBSCRIPT_DEFAULT_INSTALL_METHOD%"
    ) else (
        set "R_INSTALL_METHOD=libscript_native"
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
if "%R_INSTALL_METHOD%"=="mise" ( mise ls r & exit /b 0 )
if "%R_INSTALL_METHOD%"=="asdf" ( asdf list r & exit /b 0 )
if "%R_INSTALL_METHOD%"=="pkgx" ( echo pkgx does not have a local list command & exit /b 0 )
if "%R_INSTALL_METHOD%"=="vfox" ( vfox ls r & exit /b 0 )
if "%R_INSTALL_METHOD%"=="system" ( echo System package manager does not support ls directly here. & exit /b 0 )
if exist "%LIBSCRIPT_HOME%\r" ( dir /b "%LIBSCRIPT_HOME%\r" )
exit /b 0

:action_ls_remote
if "%R_INSTALL_METHOD%"=="mise" ( mise ls-remote r & exit /b 0 )
if "%R_INSTALL_METHOD%"=="asdf" ( asdf list all r & exit /b 0 )
if "%R_INSTALL_METHOD%"=="pkgx" ( echo pkgx does not have a local list command & exit /b 0 )
if "%R_INSTALL_METHOD%"=="vfox" ( vfox ls all r & exit /b 0 )
if "%R_INSTALL_METHOD%"=="system" ( echo System package manager does not support ls-remote directly here. & exit /b 0 )
if not "%R_RELEASES_URL%"=="" (
    curl -sSL "%R_RELEASES_URL%"
) else (
    git ls-remote --tags "https://github.com/libscript/r" 2^>nul ^| findstr /R "[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*"
)
exit /b 0

:action_use
if "%R_INSTALL_METHOD%"=="mise" ( mise use "r@%R_VERSION%" & exit /b 0 )
if "%R_INSTALL_METHOD%"=="asdf" ( asdf global r "%R_VERSION%" & exit /b 0 )
if "%R_INSTALL_METHOD%"=="pkgx" ( echo pkgx does not use explicit versions this way & exit /b 0 )
if "%R_INSTALL_METHOD%"=="vfox" ( vfox use "r@%R_VERSION%" & exit /b 0 )
if "%R_INSTALL_METHOD%"=="system" ( echo Cannot 'use' specific version with system package manager. & exit /b 0 )

if "%R_VERSION%"=="latest" (set "EXACT_VERSION=%R_VERSION%"
) else if "%R_VERSION%"=="lts" (set "EXACT_VERSION=%R_VERSION%"
) else (
    set "EXACT_VERSION=%R_VERSION%"
)
if "%EXACT_VERSION%"=="" set "EXACT_VERSION=%R_VERSION%"

set "TARGET_DIR=%LIBSCRIPT_HOME%\r\%EXACT_VERSION%"
set "ALIAS_DIR=%LIBSCRIPT_HOME%\r\%R_VERSION%"

if not "%TARGET_DIR%"=="%ALIAS_DIR%" (
    if exist "%ALIAS_DIR%" rmdir "%ALIAS_DIR%"
    mklink /J "%ALIAS_DIR%" "%TARGET_DIR%" >nul 2>&1
)
exit /b 0

:action_download
if "%R_INSTALL_METHOD%"=="libscript_native" (
    echo Downloading r %R_VERSION% to %DOWNLOAD_DIR%\r...
    if not exist "%DOWNLOAD_DIR%\r" mkdir "%DOWNLOAD_DIR%\r"
    if not "%R_DOWNLOAD_URL%"=="" (
        curl -sSL "%R_DOWNLOAD_URL%" -o "%DOWNLOAD_DIR%\r\r-%R_VERSION%.zip"
    ) else (
        echo R_DOWNLOAD_URL is not defined. Skipping.
    )
)
exit /b 0

:action_install
if "%R_INSTALL_METHOD%"=="system" (
    winget install r --accept-package-agreements --accept-source-agreements
    exit /b !errorlevel!
)
if "%R_INSTALL_METHOD%"=="mise" ( mise install "r@%R_VERSION%" & exit /b 0 )
if "%R_INSTALL_METHOD%"=="asdf" ( asdf install r "%R_VERSION%" & exit /b 0 )
if "%R_INSTALL_METHOD%"=="pkgx" ( pkgx install "r@%R_VERSION%" & exit /b 0 )
if "%R_INSTALL_METHOD%"=="vfox" ( vfox add r & vfox install "r@%R_VERSION%" & exit /b 0 )

set "TARGET_DIR=%LIBSCRIPT_HOME%\r\%R_VERSION%"
if not exist "%TARGET_DIR%\bin" (
    echo Installing r %R_VERSION% natively to %TARGET_DIR%...
    mkdir "%TARGET_DIR%\bin"
    if exist "%DOWNLOAD_DIR%\r\r-%R_VERSION%.zip" (
        echo Extracting from cache...
        tar -xf "%DOWNLOAD_DIR%\r\r-%R_VERSION%.zip" -C "%TARGET_DIR%"
    ) else if exist "%DOWNLOAD_DIR%\r\r-%R_VERSION%.tar.gz" (
        echo Extracting from cache...
        tar -xf "%DOWNLOAD_DIR%\r\r-%R_VERSION%.tar.gz" -C "%TARGET_DIR%"
    ) else if not "%R_DOWNLOAD_URL%"=="" (
        echo Downloading and extracting...
        curl -sSL "%R_DOWNLOAD_URL%" -o "%TEMP%\r.zip"
        tar -xf "%TEMP%\r.zip" -C "%TARGET_DIR%"
    ) else (
        echo No download URL or cache available for r.
    )
) else (
    echo r %R_VERSION% is already installed.
)
set "ALIAS_DIR=%LIBSCRIPT_HOME%\r\%R_VERSION%"
if not "%TARGET_DIR%"=="%ALIAS_DIR%" (
    if exist "%ALIAS_DIR%" rmdir "%ALIAS_DIR%"
    mklink /J "%ALIAS_DIR%" "%TARGET_DIR%" >nul 2>&1
)
exit /b 0

:action_service
if "%LIBSCRIPT_SERVICE_NAME%"=="" (
    if "%PACKAGE_NAME%"=="" (
        set "SVC_NAME=libscript_r"
    ) else (
        set "SVC_NAME=libscript_%PACKAGE_NAME%"
    )
) else (
    set "SVC_NAME=%LIBSCRIPT_SERVICE_NAME%"
)
if "%R_INSTALL_METHOD%"=="libscript_native" (
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\service.cmd" "%ACTION%" "%SVC_NAME%"
) else if "%R_INSTALL_METHOD%"=="system" (
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\service.cmd" "%ACTION%" "%SVC_NAME%"
) else (
    echo %ACTION% not natively implemented for %R_INSTALL_METHOD%.
)
exit /b 0

:action_install_service
if "%LIBSCRIPT_SERVICE_NAME%"=="" (
    if "%PACKAGE_NAME%"=="" (
        set "SVC_NAME=libscript_r"
    ) else (
        set "SVC_NAME=libscript_%PACKAGE_NAME%"
    )
) else (
    set "SVC_NAME=%LIBSCRIPT_SERVICE_NAME%"
)
if "%R_INSTALL_METHOD%"=="libscript_native" (
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\service_install.cmd" install "%SVC_NAME%"
) else if "%R_INSTALL_METHOD%"=="system" (
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\service_install.cmd" install "%SVC_NAME%"
) else (
    echo install-service not implemented for %R_INSTALL_METHOD%.
)
exit /b 0

:action_uninstall_service
if "%LIBSCRIPT_SERVICE_NAME%"=="" (
    if "%PACKAGE_NAME%"=="" (
        set "SVC_NAME=libscript_r"
    ) else (
        set "SVC_NAME=libscript_%PACKAGE_NAME%"
    )
) else (
    set "SVC_NAME=%LIBSCRIPT_SERVICE_NAME%"
)
if "%R_INSTALL_METHOD%"=="libscript_native" (
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\service_install.cmd" uninstall "%SVC_NAME%"
) else if "%R_INSTALL_METHOD%"=="system" (
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\service_install.cmd" uninstall "%SVC_NAME%"
) else (
    echo uninstall-service not implemented for %R_INSTALL_METHOD%.
)
exit /b 0
