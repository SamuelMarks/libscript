@echo off
:: # setup_generic.cmd
:: ## Overview
:: Windows setup for redis
::
:: ## Usage
:: Managed by libscript. Provides download, install, ls, ls-remote, use capabilities.
setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"

if defined STACK (
    echo "!STACK!" | findstr /C:":!THIS_FILE!:" >nul 2>&1
    if not errorlevel 1 (
        echo [STOP] processing "!THIS_FILE!" >&2
        exit /b 0
    )
)
set "STACK=%STACK%:!THIS_FILE!:"

set "SCRIPT_DIR=%~dp0"
if "%SCRIPT_DIR:~-1%"=="\" set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"

if not defined LIBSCRIPT_ROOT_DIR (
    set "d=!SCRIPT_DIR!"
    call :find_root
)
goto :root_found

:: ## find_root
:: Ascends the directory tree looking for ROOT or libscript.cmd.
:find_root
if exist "!d!\libscript.cmd" (
    set "LIBSCRIPT_ROOT_DIR=!d!"
    exit /b 0
)
if exist "!d!\ROOT" (
    set "LIBSCRIPT_ROOT_DIR=!d!"
    exit /b 0
)
for %%P in ("!d!") do set "parent=%%~dpP"
set "d=!parent:~0,-1!"
if "!d!"=="" (
    echo Error: Could not find LIBSCRIPT_ROOT_DIR 1>&2
    exit /b 1
)
goto :find_root

:: ## root_found
:: Continues execution once LIBSCRIPT_ROOT_DIR is verified.
:root_found

if "%ACTION%"=="" set ACTION=install
if "%REDIS_VERSION%"=="" set REDIS_VERSION=latest

if "%LIBSCRIPT_HOME%"=="" (
    set "LIBSCRIPT_HOME=%USERPROFILE%\.libscript"
)
if "%DOWNLOAD_DIR%"=="" (
    set "DOWNLOAD_DIR=%TEMP%\libscript_downloads"
)

:: Resolve install method
if "%REDIS_INSTALL_METHOD%"=="" (
    if not "%LIBSCRIPT_DEFAULT_INSTALL_METHOD%"=="" (
        set "REDIS_INSTALL_METHOD=%LIBSCRIPT_DEFAULT_INSTALL_METHOD%"
    ) else (
        set "REDIS_INSTALL_METHOD=libscript_native"
    )
)

:: Resolve download URL for Windows
if "%REDIS_DOWNLOAD_URL%"=="" (
    set "_tmp_ver=%REDIS_VERSION%"
)
if "%REDIS_DOWNLOAD_URL%"=="" (
    if "%_tmp_ver%"=="latest" (
        where git >nul 2>&1
        if not errorlevel 1 (
            for /f "usebackq tokens=*" %%I in (`powershell -NoProfile -Command "git ls-remote --tags 'https://github.com/SamuelMarks/redis-windows' ^| Select-String -Pattern '\d+\.\d+\.\d+' -AllMatches ^| ForEach-Object { $_.Matches.Value } ^| Sort-Object {[version]$_} ^| Select-Object -Last 1"`) do set "_tmp_ver=%%I"
        ) else (
            set "_tmp_ver=7.2.4"
        )
    )
)
if "%REDIS_DOWNLOAD_URL%"=="" (
    if not "%_tmp_ver%"=="latest" (
        if not "%_tmp_ver%"=="" (
            set "REDIS_DOWNLOAD_URL=https://github.com/tporadowski/redis/releases/download/v5.0.14.1/Redis-x64-5.0.14.1.zip"
        )
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
:: Lists all locally installed versions of the component under LIBSCRIPT_HOME.
:action_ls
if "%REDIS_INSTALL_METHOD%"=="mise" ( mise ls redis & exit /b 0 )
if "%REDIS_INSTALL_METHOD%"=="asdf" ( asdf list redis & exit /b 0 )
if "%REDIS_INSTALL_METHOD%"=="pkgx" ( echo pkgx does not have a local list command & exit /b 0 )
if "%REDIS_INSTALL_METHOD%"=="vfox" ( vfox ls redis & exit /b 0 )
if "%REDIS_INSTALL_METHOD%"=="system" ( echo System package manager does not support ls directly here. & exit /b 0 )
if exist "%LIBSCRIPT_HOME%\redis" ( dir /b "%LIBSCRIPT_HOME%\redis" )
exit /b 0

:: ## action_ls_remote
:: Lists upstream release versions available for download.
:action_ls_remote
if "%REDIS_INSTALL_METHOD%"=="mise" ( mise ls-remote redis & exit /b 0 )
if "%REDIS_INSTALL_METHOD%"=="asdf" ( asdf list all redis & exit /b 0 )
if "%REDIS_INSTALL_METHOD%"=="pkgx" ( echo pkgx does not have a local list command & exit /b 0 )
if "%REDIS_INSTALL_METHOD%"=="vfox" ( vfox ls all redis & exit /b 0 )
if "%REDIS_INSTALL_METHOD%"=="system" ( echo System package manager does not support ls-remote directly here. & exit /b 0 )
if not "%REDIS_RELEASES_URL%"=="" (
    curl -sSL "%REDIS_RELEASES_URL%"
) else (
    git ls-remote --tags "https://github.com/SamuelMarks/redis-windows" 2^>nul ^| findstr /R "[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*"
)
exit /b 0

:: ## action_use
:: Activates the specified component version by updating the active symlink or junction.
:action_use
if "%REDIS_INSTALL_METHOD%"=="mise" ( mise use "redis@%REDIS_VERSION%" & exit /b 0 )
if "%REDIS_INSTALL_METHOD%"=="asdf" ( asdf global redis "%REDIS_VERSION%" & exit /b 0 )
if "%REDIS_INSTALL_METHOD%"=="pkgx" ( echo pkgx does not use explicit versions this way & exit /b 0 )
if "%REDIS_INSTALL_METHOD%"=="vfox" ( vfox use "redis@%REDIS_VERSION%" & exit /b 0 )
if "%REDIS_INSTALL_METHOD%"=="system" ( echo Cannot 'use' specific version with system package manager. & exit /b 0 )

if "%REDIS_VERSION%"=="latest" (set "EXACT_VERSION=%REDIS_VERSION%"
) else if "%REDIS_VERSION%"=="lts" (set "EXACT_VERSION=%REDIS_VERSION%"
) else (
    set "EXACT_VERSION=%REDIS_VERSION%"
)
if "%EXACT_VERSION%"=="" set "EXACT_VERSION=%REDIS_VERSION%"

set "TARGET_DIR=%LIBSCRIPT_HOME%\redis\%EXACT_VERSION%"
set "ALIAS_DIR=%LIBSCRIPT_HOME%\redis\%REDIS_VERSION%"

if not "%TARGET_DIR%"=="%ALIAS_DIR%" (
    if exist "%ALIAS_DIR%" rmdir "%ALIAS_DIR%"
    mklink /J "%ALIAS_DIR%" "%TARGET_DIR%" >nul 2>&1
)
exit /b 0

:: ## action_download
:: Downloads the component release archive into the local offline cache directory.
:action_download
if "%REDIS_INSTALL_METHOD%"=="libscript_native" (
    echo Downloading redis %REDIS_VERSION% to %DOWNLOAD_DIR%\redis...
    if not exist "%DOWNLOAD_DIR%\redis" mkdir "%DOWNLOAD_DIR%\redis"
    if not "%REDIS_DOWNLOAD_URL%"=="" (
        curl -sSL "%REDIS_DOWNLOAD_URL%" -o "%DOWNLOAD_DIR%\redis\redis-%REDIS_VERSION%.zip"
    ) else (
        echo REDIS_DOWNLOAD_URL is not defined. Skipping.
    )
)
exit /b 0

:: ## action_install
:: Installs and configures the requested version of the component.
:action_install
if "%REDIS_INSTALL_METHOD%"=="system" (
    winget install redis --accept-package-agreements --accept-source-agreements
    exit /b !errorlevel!
)
if "%REDIS_INSTALL_METHOD%"=="mise" ( mise install "redis@%REDIS_VERSION%" & exit /b 0 )
if "%REDIS_INSTALL_METHOD%"=="asdf" ( asdf install redis "%REDIS_VERSION%" & exit /b 0 )
if "%REDIS_INSTALL_METHOD%"=="pkgx" ( pkgx install "redis@%REDIS_VERSION%" & exit /b 0 )
if "%REDIS_INSTALL_METHOD%"=="vfox" ( vfox add redis & vfox install "redis@%REDIS_VERSION%" & exit /b 0 )

set "TARGET_DIR=%LIBSCRIPT_HOME%\redis\%REDIS_VERSION%"
if not exist "%TARGET_DIR%\bin" (
    echo Installing redis %REDIS_VERSION% natively to %TARGET_DIR%...
    if not exist "%TARGET_DIR%\bin" mkdir "%TARGET_DIR%\bin"
    if exist "%DOWNLOAD_DIR%\redis\redis-%REDIS_VERSION%.zip" (
        echo Extracting from cache...
        tar -xf "%DOWNLOAD_DIR%\redis\redis-%REDIS_VERSION%.zip" -C "%TARGET_DIR%"
    ) else if exist "%DOWNLOAD_DIR%\redis\redis-%REDIS_VERSION%.tar.gz" (
        echo Extracting from cache...
        tar -xf "%DOWNLOAD_DIR%\redis\redis-%REDIS_VERSION%.tar.gz" -C "%TARGET_DIR%"
    ) else if not "%REDIS_DOWNLOAD_URL%"=="" (
        echo Downloading and extracting...
        curl -sSL "%REDIS_DOWNLOAD_URL%" -o "%TEMP%\redis.zip"
        tar -xf "%TEMP%\redis.zip" -C "%TARGET_DIR%"
    ) else (
        echo No download URL or cache available for redis.
        exit /b 1
    )
) else (
    echo redis %REDIS_VERSION% is already installed.
)
set "ALIAS_DIR=%LIBSCRIPT_HOME%\redis\%REDIS_VERSION%"
if not "%TARGET_DIR%"=="%ALIAS_DIR%" (
    if exist "%ALIAS_DIR%" rmdir "%ALIAS_DIR%"
    mklink /J "%ALIAS_DIR%" "%TARGET_DIR%" >nul 2>&1
)
exit /b 0

:: ## action_service
:: Routes service daemon control actions (start, stop, restart, status) to the service manager.
:action_service
if "%LIBSCRIPT_SERVICE_NAME%"=="" (
    if "%PACKAGE_NAME%"=="" (
        set "SVC_NAME=libscript_redis"
    ) else (
        set "SVC_NAME=libscript_%PACKAGE_NAME%"
    )
) else (
    set "SVC_NAME=%LIBSCRIPT_SERVICE_NAME%"
)
if "%REDIS_INSTALL_METHOD%"=="libscript_native" (
    call "!LIBSCRIPT_ROOT_DIR!\_lib\_common\service.cmd" "%ACTION%" "%SVC_NAME%"
) else if "%REDIS_INSTALL_METHOD%"=="system" (
    call "!LIBSCRIPT_ROOT_DIR!\_lib\_common\service.cmd" "%ACTION%" "%SVC_NAME%"
) else (
    echo %ACTION% not natively implemented for %REDIS_INSTALL_METHOD%.
)
exit /b 0

:: ## action_install_service
:: Registers and configures the component as a persistent system service.
:action_install_service
if "%LIBSCRIPT_SERVICE_NAME%"=="" (
    if "%PACKAGE_NAME%"=="" (
        set "SVC_NAME=libscript_redis"
    ) else (
        set "SVC_NAME=libscript_%PACKAGE_NAME%"
    )
) else (
    set "SVC_NAME=%LIBSCRIPT_SERVICE_NAME%"
)
if "%REDIS_INSTALL_METHOD%"=="libscript_native" (
    call "!LIBSCRIPT_ROOT_DIR!\_lib\_common\service_install.cmd" install "%SVC_NAME%"
) else if "%REDIS_INSTALL_METHOD%"=="system" (
    call "!LIBSCRIPT_ROOT_DIR!\_lib\_common\service_install.cmd" install "%SVC_NAME%"
) else (
    echo install-service not implemented for %REDIS_INSTALL_METHOD%.
)
exit /b 0

:: ## action_uninstall_service
:: Stops and removes the registered system service for the component.
:action_uninstall_service
if "%LIBSCRIPT_SERVICE_NAME%"=="" (
    if "%PACKAGE_NAME%"=="" (
        set "SVC_NAME=libscript_redis"
    ) else (
        set "SVC_NAME=libscript_%PACKAGE_NAME%"
    )
) else (
    set "SVC_NAME=%LIBSCRIPT_SERVICE_NAME%"
)
if "%REDIS_INSTALL_METHOD%"=="libscript_native" (
    call "!LIBSCRIPT_ROOT_DIR!\_lib\_common\service_install.cmd" uninstall "%SVC_NAME%"
) else if "%REDIS_INSTALL_METHOD%"=="system" (
    call "!LIBSCRIPT_ROOT_DIR!\_lib\_common\service_install.cmd" uninstall "%SVC_NAME%"
) else (
    echo uninstall-service not implemented for %REDIS_INSTALL_METHOD%.
)
exit /b 0
