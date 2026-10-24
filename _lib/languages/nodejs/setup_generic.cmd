@echo off
:: # setup_generic.cmd
:: ## Overview
:: Windows setup for nodejs
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

:: Parse offline and npm options
:: ## arg_parse_loop
:: Parses command-line arguments and populates configuration variables.
:arg_parse_loop
if "%~1"=="" goto :arg_parse_done
if /i "%~1"=="--offline" set "LIBSCRIPT_OFFLINE=1"
if /i "%~1"=="-o" set "LIBSCRIPT_OFFLINE=1"
if /i "%~1"=="--npm-cache" (
    set "NPM_CACHE=%~2"
    shift
)
if /i "%~1"=="--yarn-offline-mirror" (
    set "YARN_OFFLINE_MIRROR=%~2"
    shift
)
shift
goto :arg_parse_loop
:: ## arg_parse_done
:: Continues execution after command-line argument parsing completes.
:arg_parse_done

if "%LIBSCRIPT_OFFLINE%"=="1" (
    set "npm_config_offline=true"
    set "npm_config_prefer_offline=true"
    if "%NPM_CACHE%"=="" (
        if not "%LIBSCRIPT_CACHE_DIR%"=="" (
            set "NPM_CACHE=%LIBSCRIPT_CACHE_DIR%\npm"
        ) else (
            set "NPM_CACHE=!LIBSCRIPT_ROOT_DIR!\cache\npm"
        )
    )
    set "npm_config_cache=%NPM_CACHE%"
    if "%YARN_OFFLINE_MIRROR%"=="" set "YARN_OFFLINE_MIRROR=%NPM_CACHE%"
)

if "%ACTION%"=="" set ACTION=install
if "%NODEJS_VERSION%"=="" set NODEJS_VERSION=latest

if "%LIBSCRIPT_HOME%"=="" (
    set "LIBSCRIPT_HOME=%USERPROFILE%\.libscript"
)
if "%DOWNLOAD_DIR%"=="" (
    set "DOWNLOAD_DIR=%TEMP%\libscript_downloads"
)

:: Resolve install method
if "%NODEJS_INSTALL_METHOD%"=="" (
    if not "%LIBSCRIPT_DEFAULT_INSTALL_METHOD%"=="" (
        set "NODEJS_INSTALL_METHOD=%LIBSCRIPT_DEFAULT_INSTALL_METHOD%"
    ) else (
        set "NODEJS_INSTALL_METHOD=libscript_native"
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
if "%NODEJS_INSTALL_METHOD%"=="mise" ( mise ls nodejs & exit /b 0 )
if "%NODEJS_INSTALL_METHOD%"=="asdf" ( asdf list nodejs & exit /b 0 )
if "%NODEJS_INSTALL_METHOD%"=="pkgx" ( echo pkgx does not have a local list command & exit /b 0 )
if "%NODEJS_INSTALL_METHOD%"=="vfox" ( vfox ls nodejs & exit /b 0 )
if "%NODEJS_INSTALL_METHOD%"=="system" ( echo System package manager does not support ls directly here. & exit /b 0 )
if exist "%LIBSCRIPT_HOME%\nodejs" ( dir /b "%LIBSCRIPT_HOME%\nodejs" )
exit /b 0

:: ## action_ls_remote
:: Lists upstream release versions available for download.
:action_ls_remote
if "%NODEJS_INSTALL_METHOD%"=="mise" ( mise ls-remote nodejs & exit /b 0 )
if "%NODEJS_INSTALL_METHOD%"=="asdf" ( asdf list all nodejs & exit /b 0 )
if "%NODEJS_INSTALL_METHOD%"=="pkgx" ( echo pkgx does not have a local list command & exit /b 0 )
if "%NODEJS_INSTALL_METHOD%"=="vfox" ( vfox ls all nodejs & exit /b 0 )
if "%NODEJS_INSTALL_METHOD%"=="system" ( echo System package manager does not support ls-remote directly here. & exit /b 0 )
if not "%NODEJS_RELEASES_URL%"=="" (
    curl -sSL "%NODEJS_RELEASES_URL%"
) else (
    echo ls-remote not fully implemented natively yet.
)
exit /b 0

:: ## action_use
:: Activates the specified component version by updating the active symlink or junction.
:action_use
if "%NODEJS_INSTALL_METHOD%"=="mise" ( mise use "nodejs@%NODEJS_VERSION%" & exit /b 0 )
if "%NODEJS_INSTALL_METHOD%"=="asdf" ( asdf global nodejs "%NODEJS_VERSION%" & exit /b 0 )
if "%NODEJS_INSTALL_METHOD%"=="pkgx" ( echo pkgx does not use explicit versions this way & exit /b 0 )
if "%NODEJS_INSTALL_METHOD%"=="vfox" ( vfox use "nodejs@%NODEJS_VERSION%" & exit /b 0 )
if "%NODEJS_INSTALL_METHOD%"=="system" ( echo Cannot 'use' specific version with system package manager. & exit /b 0 )

if "%NODEJS_VERSION%"=="latest" (set "EXACT_VERSION=%NODEJS_VERSION%"
) else if "%NODEJS_VERSION%"=="lts" (set "EXACT_VERSION=%NODEJS_VERSION%"
) else (
    set "EXACT_VERSION=%NODEJS_VERSION%"
)
if "%EXACT_VERSION%"=="" set "EXACT_VERSION=%NODEJS_VERSION%"

set "TARGET_DIR=%LIBSCRIPT_HOME%\nodejs\%EXACT_VERSION%"
set "ALIAS_DIR=%LIBSCRIPT_HOME%\nodejs\%NODEJS_VERSION%"

if not "%TARGET_DIR%"=="%ALIAS_DIR%" (
    if exist "%ALIAS_DIR%" rmdir "%ALIAS_DIR%"
    mklink /J "%ALIAS_DIR%" "%TARGET_DIR%" >nul 2>&1
)
exit /b 0

:: ## action_download
:: Downloads the component release archive into the local offline cache directory.
:action_download
if "%NODEJS_INSTALL_METHOD%"=="libscript_native" (
    echo Downloading nodejs %NODEJS_VERSION% to %DOWNLOAD_DIR%\nodejs...
    if not exist "%DOWNLOAD_DIR%\nodejs" mkdir "%DOWNLOAD_DIR%\nodejs"
    if not "%NODEJS_DOWNLOAD_URL%"=="" (
        call "!LIBSCRIPT_ROOT_DIR!\_lib\_common\pkg_mgr.cmd" :libscript_download "%NODEJS_DOWNLOAD_URL%" "%DOWNLOAD_DIR%\nodejs\nodejs-%NODEJS_VERSION%.zip"
    ) else (
        echo NODEJS_DOWNLOAD_URL is not defined. Skipping.
    )
)
exit /b 0

:: ## action_install
:: Installs and configures the requested version of the component.
:action_install
if "%NODEJS_INSTALL_METHOD%"=="system" (
    call "!LIBSCRIPT_ROOT_DIR!\_lib\_common\pkg_mgr.cmd" :libscript_depends nodejs
    exit /b !errorlevel!
)
if "%NODEJS_INSTALL_METHOD%"=="mise" ( mise install "nodejs@%NODEJS_VERSION%" & exit /b 0 )
if "%NODEJS_INSTALL_METHOD%"=="asdf" ( asdf install nodejs "%NODEJS_VERSION%" & exit /b 0 )
if "%NODEJS_INSTALL_METHOD%"=="pkgx" ( pkgx install "nodejs@%NODEJS_VERSION%" & exit /b 0 )
if "%NODEJS_INSTALL_METHOD%"=="vfox" ( vfox add nodejs & vfox install "nodejs@%NODEJS_VERSION%" & exit /b 0 )

set "TARGET_DIR=%LIBSCRIPT_HOME%\nodejs\%NODEJS_VERSION%"
if not exist "%TARGET_DIR%\bin\node.exe" if not exist "%TARGET_DIR%\node.exe" (
    echo Installing nodejs %NODEJS_VERSION% natively to %TARGET_DIR%...
    if not exist "%TARGET_DIR%\bin" mkdir "%TARGET_DIR%\bin"
    set "_NODE_CACHED="
    if defined LIBSCRIPT_CACHE_DIR (
        for %%Z in ("%LIBSCRIPT_CACHE_DIR%\runtimes\node*.zip") do set "_NODE_CACHED=%%~fZ"
    )
    if exist "!LIBSCRIPT_ROOT_DIR!\cache\runtimes" (
        for %%Z in ("!LIBSCRIPT_ROOT_DIR!\cache\runtimes\node*.zip") do set "_NODE_CACHED=%%~fZ"
    )
    if defined _NODE_CACHED (
        echo Extracting Node.js from offline cache !_NODE_CACHED!...
        tar -xf "!_NODE_CACHED!" -C "%TARGET_DIR%" --strip-components=1 2>nul || tar -xf "!_NODE_CACHED!" -C "%TARGET_DIR%"
        if exist "%TARGET_DIR%\node.exe" copy /y "%TARGET_DIR%\node.exe" "%TARGET_DIR%\bin\node.exe" >nul 2>&1
    ) else if exist "%DOWNLOAD_DIR%\nodejs\nodejs-%NODEJS_VERSION%.zip" (
        echo Extracting from cache...
        tar -xf "%DOWNLOAD_DIR%\nodejs\nodejs-%NODEJS_VERSION%.zip" -C "%TARGET_DIR%"
    ) else if exist "%DOWNLOAD_DIR%\nodejs\nodejs-%NODEJS_VERSION%.tar.gz" (
        echo Extracting from cache...
        tar -xf "%DOWNLOAD_DIR%\nodejs\nodejs-%NODEJS_VERSION%.tar.gz" -C "%TARGET_DIR%"
    ) else if not "%NODEJS_DOWNLOAD_URL%"=="" (
        echo Downloading and extracting...
        call "!LIBSCRIPT_ROOT_DIR!\_lib\_common\pkg_mgr.cmd" :libscript_download "%NODEJS_DOWNLOAD_URL%" "%TEMP%\nodejs.zip"
        tar -xf "%TEMP%\nodejs.zip" -C "%TARGET_DIR%"
    ) else (
        set "_NODE_ARCH=x64"
        if /i "%PROCESSOR_ARCHITECTURE%"=="ARM64" set "_NODE_ARCH=arm64"
        set "_NODE_VER=%NODEJS_VERSION%"
        if /i "!_NODE_VER!"=="latest" set "_NODE_VER=v20.18.0"
        if /i "!_NODE_VER!"=="lts" set "_NODE_VER=v20.18.0"
        if not "!_NODE_VER:~0,1!"=="v" set "_NODE_VER=v!_NODE_VER!"
        set "_NODE_URL=https://nodejs.org/dist/!_NODE_VER!/node-!_NODE_VER!-win-!_NODE_ARCH!.zip"
        echo Downloading Node.js from !_NODE_URL!...
        call "!LIBSCRIPT_ROOT_DIR!\_lib\_common\pkg_mgr.cmd" :libscript_download "!_NODE_URL!" "%TEMP%\nodejs.zip"
        if not errorlevel 1 if exist "%TEMP%\nodejs.zip" (
            tar -xf "%TEMP%\nodejs.zip" -C "%TARGET_DIR%" --strip-components=1 2>nul || tar -xf "%TEMP%\nodejs.zip" -C "%TARGET_DIR%"
            if exist "%TARGET_DIR%\node.exe" copy /y "%TARGET_DIR%\node.exe" "%TARGET_DIR%\bin\node.exe" >nul 2>&1
            del /f /q "%TEMP%\nodejs.zip" 2>nul
        ) else (
            call "!LIBSCRIPT_ROOT_DIR!\_lib\_common\pkg_mgr.cmd" :libscript_depends nodejs
        )
    )
) else (
    echo nodejs %NODEJS_VERSION% is already installed.
)
set "ALIAS_DIR=%LIBSCRIPT_HOME%\nodejs\%NODEJS_VERSION%"
if not "%TARGET_DIR%"=="%ALIAS_DIR%" (
    if exist "%ALIAS_DIR%" rmdir "%ALIAS_DIR%"
    mklink /J "%ALIAS_DIR%" "%TARGET_DIR%" >nul 2>&1
)
set "DEFAULT_DIR=%LIBSCRIPT_HOME%\nodejs\default"
if not "%TARGET_DIR%"=="%DEFAULT_DIR%" (
    if exist "%DEFAULT_DIR%" rmdir "%DEFAULT_DIR%" 2>nul
    mklink /J "%DEFAULT_DIR%" "%TARGET_DIR%" >nul 2>&1
)
exit /b 0

:: ## action_service
:: Routes service daemon control actions (start, stop, restart, status) to the service manager.
:action_service
if "%LIBSCRIPT_SERVICE_NAME%"=="" (
    if "%PACKAGE_NAME%"=="" (
        set "SVC_NAME=libscript_nodejs"
    ) else (
        set "SVC_NAME=libscript_%PACKAGE_NAME%"
    )
) else (
    set "SVC_NAME=%LIBSCRIPT_SERVICE_NAME%"
)
if "%NODEJS_INSTALL_METHOD%"=="libscript_native" (
    call "!LIBSCRIPT_ROOT_DIR!\_lib\_common\service.cmd" "%ACTION%" "%SVC_NAME%"
) else if "%NODEJS_INSTALL_METHOD%"=="system" (
    call "!LIBSCRIPT_ROOT_DIR!\_lib\_common\service.cmd" "%ACTION%" "%SVC_NAME%"
) else (
    echo %ACTION% not natively implemented for %NODEJS_INSTALL_METHOD%.
)
exit /b 0

:: ## action_install_service
:: Registers and configures the component as a persistent system service.
:action_install_service
if "%LIBSCRIPT_SERVICE_NAME%"=="" (
    if "%PACKAGE_NAME%"=="" (
        set "SVC_NAME=libscript_nodejs"
    ) else (
        set "SVC_NAME=libscript_%PACKAGE_NAME%"
    )
) else (
    set "SVC_NAME=%LIBSCRIPT_SERVICE_NAME%"
)
if "%NODEJS_INSTALL_METHOD%"=="libscript_native" (
    call "!LIBSCRIPT_ROOT_DIR!\_lib\_common\service_install.cmd" install "%SVC_NAME%"
) else if "%NODEJS_INSTALL_METHOD%"=="system" (
    call "!LIBSCRIPT_ROOT_DIR!\_lib\_common\service_install.cmd" install "%SVC_NAME%"
) else (
    echo install-service not implemented for %NODEJS_INSTALL_METHOD%.
)
exit /b 0

:: ## action_uninstall_service
:: Stops and removes the registered system service for the component.
:action_uninstall_service
if "%LIBSCRIPT_SERVICE_NAME%"=="" (
    if "%PACKAGE_NAME%"=="" (
        set "SVC_NAME=libscript_nodejs"
    ) else (
        set "SVC_NAME=libscript_%PACKAGE_NAME%"
    )
) else (
    set "SVC_NAME=%LIBSCRIPT_SERVICE_NAME%"
)
if "%NODEJS_INSTALL_METHOD%"=="libscript_native" (
    call "!LIBSCRIPT_ROOT_DIR!\_lib\_common\service_install.cmd" uninstall "%SVC_NAME%"
) else if "%NODEJS_INSTALL_METHOD%"=="system" (
    call "!LIBSCRIPT_ROOT_DIR!\_lib\_common\service_install.cmd" uninstall "%SVC_NAME%"
) else (
    echo uninstall-service not implemented for %NODEJS_INSTALL_METHOD%.
)
exit /b 0
