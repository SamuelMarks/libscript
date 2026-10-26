@echo off
:: # setup_generic.cmd
:: ## Overview
:: Windows setup for mongodb
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
if "%MONGODB_VERSION%"=="" set MONGODB_VERSION=latest

if "%LIBSCRIPT_HOME%"=="" (
    set "LIBSCRIPT_HOME=%USERPROFILE%\.libscript"
)
if "%DOWNLOAD_DIR%"=="" (
    set "DOWNLOAD_DIR=%TEMP%\libscript_downloads"
)

:: Resolve install method
if "%MONGODB_INSTALL_METHOD%"=="" (
    if not "%LIBSCRIPT_DEFAULT_INSTALL_METHOD%"=="" (
        set "MONGODB_INSTALL_METHOD=%LIBSCRIPT_DEFAULT_INSTALL_METHOD%"
    ) else (
        set "MONGODB_INSTALL_METHOD=libscript_native"
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
if "%MONGODB_INSTALL_METHOD%"=="mise" ( mise ls mongodb & exit /b 0 )
if "%MONGODB_INSTALL_METHOD%"=="asdf" ( asdf list mongodb & exit /b 0 )
if "%MONGODB_INSTALL_METHOD%"=="pkgx" ( echo pkgx does not have a local list command & exit /b 0 )
if "%MONGODB_INSTALL_METHOD%"=="vfox" ( vfox ls mongodb & exit /b 0 )
if "%MONGODB_INSTALL_METHOD%"=="system" ( echo System package manager does not support ls directly here. & exit /b 0 )
if exist "%LIBSCRIPT_HOME%\mongodb" ( dir /b "%LIBSCRIPT_HOME%\mongodb" )
exit /b 0

:: ## action_ls_remote
:: Lists upstream release versions available for download.
:action_ls_remote
if "%MONGODB_INSTALL_METHOD%"=="mise" ( mise ls-remote mongodb & exit /b 0 )
if "%MONGODB_INSTALL_METHOD%"=="asdf" ( asdf list all mongodb & exit /b 0 )
if "%MONGODB_INSTALL_METHOD%"=="pkgx" ( echo pkgx does not have a local list command & exit /b 0 )
if "%MONGODB_INSTALL_METHOD%"=="vfox" ( vfox ls all mongodb & exit /b 0 )
if "%MONGODB_INSTALL_METHOD%"=="system" ( echo System package manager does not support ls-remote directly here. & exit /b 0 )
if not "%MONGODB_RELEASES_URL%"=="" (
    curl -sSL "%MONGODB_RELEASES_URL%"
) else (
    git ls-remote --tags "https://github.com/libscript/mongodb" 2^>nul ^| findstr /R "[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*"
)
exit /b 0

:: ## action_use
:: Activates the specified component version by updating the active symlink or junction.
:action_use
if "%MONGODB_INSTALL_METHOD%"=="mise" ( mise use "mongodb@%MONGODB_VERSION%" & exit /b 0 )
if "%MONGODB_INSTALL_METHOD%"=="asdf" ( asdf global mongodb "%MONGODB_VERSION%" & exit /b 0 )
if "%MONGODB_INSTALL_METHOD%"=="pkgx" ( echo pkgx does not use explicit versions this way & exit /b 0 )
if "%MONGODB_INSTALL_METHOD%"=="vfox" ( vfox use "mongodb@%MONGODB_VERSION%" & exit /b 0 )
if "%MONGODB_INSTALL_METHOD%"=="system" ( echo Cannot 'use' specific version with system package manager. & exit /b 0 )

if "%MONGODB_VERSION%"=="latest" (set "EXACT_VERSION=%MONGODB_VERSION%"
) else if "%MONGODB_VERSION%"=="lts" (set "EXACT_VERSION=%MONGODB_VERSION%"
) else (
    set "EXACT_VERSION=%MONGODB_VERSION%"
)
if "%EXACT_VERSION%"=="" set "EXACT_VERSION=%MONGODB_VERSION%"

set "TARGET_DIR=%LIBSCRIPT_HOME%\mongodb\%EXACT_VERSION%"
set "ALIAS_DIR=%LIBSCRIPT_HOME%\mongodb\%MONGODB_VERSION%"

if not "%TARGET_DIR%"=="%ALIAS_DIR%" (
    if exist "%ALIAS_DIR%" rmdir "%ALIAS_DIR%"
    mklink /J "%ALIAS_DIR%" "%TARGET_DIR%" >nul 2>&1
)
exit /b 0

:: ## action_download
:: Downloads the component release archive into the local offline cache directory.
:action_download
if "%MONGODB_INSTALL_METHOD%"=="libscript_native" (
    echo Downloading mongodb %MONGODB_VERSION% to %DOWNLOAD_DIR%\mongodb...
    if not exist "%DOWNLOAD_DIR%\mongodb" mkdir "%DOWNLOAD_DIR%\mongodb"
    if not "%MONGODB_DOWNLOAD_URL%"=="" (
        call "!LIBSCRIPT_ROOT_DIR!\_lib\_common\pkg_mgr.cmd" :libscript_download "%MONGODB_DOWNLOAD_URL%" "%DOWNLOAD_DIR%\mongodb\mongodb-%MONGODB_VERSION%.zip"
    ) else (
        echo MONGODB_DOWNLOAD_URL is not defined. Skipping.
    )
)
exit /b 0

:: ## action_install
:: Installs and configures the requested version of the component.
:action_install
if "%MONGODB_INSTALL_METHOD%"=="system" (
    call "!LIBSCRIPT_ROOT_DIR!\_lib\_common\pkg_mgr.cmd" :libscript_depends mongodb
    exit /b !errorlevel!
)
if "%MONGODB_INSTALL_METHOD%"=="mise" ( mise install "mongodb@%MONGODB_VERSION%" & exit /b 0 )
if "%MONGODB_INSTALL_METHOD%"=="asdf" ( asdf install mongodb "%MONGODB_VERSION%" & exit /b 0 )
if "%MONGODB_INSTALL_METHOD%"=="pkgx" ( pkgx install "mongodb@%MONGODB_VERSION%" & exit /b 0 )
if "%MONGODB_INSTALL_METHOD%"=="vfox" ( vfox add mongodb & vfox install "mongodb@%MONGODB_VERSION%" & exit /b 0 )

set "TARGET_DIR=%LIBSCRIPT_HOME%\mongodb\%MONGODB_VERSION%"
if not exist "%TARGET_DIR%\bin\mongod.exe" (
    echo Installing mongodb %MONGODB_VERSION% natively to %TARGET_DIR%...
    if not exist "%TARGET_DIR%\bin" mkdir "%TARGET_DIR%\bin"
    set "_MONGO_CACHED="
    if defined LIBSCRIPT_CACHE_DIR (
        for %%Z in ("%LIBSCRIPT_CACHE_DIR%\databases\mongodb*.zip" "%LIBSCRIPT_CACHE_DIR%\datastores\mongodb*.zip") do (
            if exist "%%~fZ" set "_MONGO_CACHED=%%~fZ"
        )
    )
    if defined _MONGO_CACHED (
        echo Extracting MongoDB from offline cache !_MONGO_CACHED!...
        tar -xf "!_MONGO_CACHED!" -C "%TARGET_DIR%" --strip-components=1 2>nul || tar -xf "!_MONGO_CACHED!" -C "%TARGET_DIR%"
    ) else if exist "%DOWNLOAD_DIR%\mongodb\mongodb-%MONGODB_VERSION%.zip" (
        echo Extracting from cache...
        tar -xf "%DOWNLOAD_DIR%\mongodb\mongodb-%MONGODB_VERSION%.zip" -C "%TARGET_DIR%"
    ) else if exist "%DOWNLOAD_DIR%\mongodb\mongodb-%MONGODB_VERSION%.tar.gz" (
        echo Extracting from cache...
        tar -xf "%DOWNLOAD_DIR%\mongodb\mongodb-%MONGODB_VERSION%.tar.gz" -C "%TARGET_DIR%"
    ) else if not "%MONGODB_DOWNLOAD_URL%"=="" (
        echo Downloading and extracting...
        call "!LIBSCRIPT_ROOT_DIR!\_lib\_common\pkg_mgr.cmd" :libscript_download "%MONGODB_DOWNLOAD_URL%" "%TEMP%\mongodb.zip"
        tar -xf "%TEMP%\mongodb.zip" -C "%TARGET_DIR%"
    ) else (
        set "_MONGO_URL=https://fastdl.mongodb.org/windows/mongodb-windows-x86_64-8.0.4.zip"
        echo Downloading MongoDB from !_MONGO_URL!...
        call "!LIBSCRIPT_ROOT_DIR!\_lib\_common\pkg_mgr.cmd" :libscript_download "!_MONGO_URL!" "%TEMP%\mongodb.zip"
        if not errorlevel 1 if exist "%TEMP%\mongodb.zip" (
            tar -xf "%TEMP%\mongodb.zip" -C "%TARGET_DIR%" --strip-components=1 2>nul || tar -xf "%TEMP%\mongodb.zip" -C "%TARGET_DIR%"
            del /f /q "%TEMP%\mongodb.zip" 2>nul
        ) else (
            call "!LIBSCRIPT_ROOT_DIR!\_lib\_common\pkg_mgr.cmd" :libscript_depends mongodb
        )
    )
) else (
    echo mongodb %MONGODB_VERSION% is already installed.
)
set "ALIAS_DIR=%LIBSCRIPT_HOME%\mongodb\%MONGODB_VERSION%"
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
        set "SVC_NAME=libscript_mongodb"
    ) else (
        set "SVC_NAME=libscript_%PACKAGE_NAME%"
    )
) else (
    set "SVC_NAME=%LIBSCRIPT_SERVICE_NAME%"
)
if "%MONGODB_INSTALL_METHOD%"=="libscript_native" (
    call "!LIBSCRIPT_ROOT_DIR!\_lib\_common\service.cmd" "%ACTION%" "%SVC_NAME%"
) else if "%MONGODB_INSTALL_METHOD%"=="system" (
    call "!LIBSCRIPT_ROOT_DIR!\_lib\_common\service.cmd" "%ACTION%" "%SVC_NAME%"
) else (
    echo %ACTION% not natively implemented for %MONGODB_INSTALL_METHOD%.
)
exit /b 0

:: ## action_install_service
:: Registers and configures the component as a persistent system service.
:action_install_service
if "%LIBSCRIPT_SERVICE_NAME%"=="" (
    if "%PACKAGE_NAME%"=="" (
        set "SVC_NAME=libscript_mongodb"
    ) else (
        set "SVC_NAME=libscript_%PACKAGE_NAME%"
    )
) else (
    set "SVC_NAME=%LIBSCRIPT_SERVICE_NAME%"
)
if "%MONGODB_INSTALL_METHOD%"=="libscript_native" (
    call "!LIBSCRIPT_ROOT_DIR!\_lib\_common\service_install.cmd" install "%SVC_NAME%"
) else if "%MONGODB_INSTALL_METHOD%"=="system" (
    call "!LIBSCRIPT_ROOT_DIR!\_lib\_common\service_install.cmd" install "%SVC_NAME%"
) else (
    echo install-service not implemented for %MONGODB_INSTALL_METHOD%.
)
exit /b 0

:: ## action_uninstall_service
:: Stops and removes the registered system service for the component.
:action_uninstall_service
if "%LIBSCRIPT_SERVICE_NAME%"=="" (
    if "%PACKAGE_NAME%"=="" (
        set "SVC_NAME=libscript_mongodb"
    ) else (
        set "SVC_NAME=libscript_%PACKAGE_NAME%"
    )
) else (
    set "SVC_NAME=%LIBSCRIPT_SERVICE_NAME%"
)
if "%MONGODB_INSTALL_METHOD%"=="libscript_native" (
    call "!LIBSCRIPT_ROOT_DIR!\_lib\_common\service_install.cmd" uninstall "%SVC_NAME%"
) else if "%MONGODB_INSTALL_METHOD%"=="system" (
    call "!LIBSCRIPT_ROOT_DIR!\_lib\_common\service_install.cmd" uninstall "%SVC_NAME%"
) else (
    echo uninstall-service not implemented for %MONGODB_INSTALL_METHOD%.
)
exit /b 0
