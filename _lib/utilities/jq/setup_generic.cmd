@echo off
:: # setup_generic.cmd
:: ## Overview
:: Windows setup for jq
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
if "%JQ_VERSION%"=="" set JQ_VERSION=latest

if "%LIBSCRIPT_HOME%"=="" (
    set "LIBSCRIPT_HOME=%USERPROFILE%\.libscript"
)
if "%DOWNLOAD_DIR%"=="" (
    set "DOWNLOAD_DIR=%TEMP%\libscript_downloads"
)

:: Resolve install method
if "%JQ_INSTALL_METHOD%"=="" (
    if not "%LIBSCRIPT_DEFAULT_INSTALL_METHOD%"=="" (
        set "JQ_INSTALL_METHOD=%LIBSCRIPT_DEFAULT_INSTALL_METHOD%"
    ) else (
        set "JQ_INSTALL_METHOD=libscript_native"
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
if "%JQ_INSTALL_METHOD%"=="mise" ( mise ls jq & exit /b 0 )
if "%JQ_INSTALL_METHOD%"=="asdf" ( asdf list jq & exit /b 0 )
if "%JQ_INSTALL_METHOD%"=="pkgx" ( echo pkgx does not have a local list command & exit /b 0 )
if "%JQ_INSTALL_METHOD%"=="vfox" ( vfox ls jq & exit /b 0 )
if "%JQ_INSTALL_METHOD%"=="system" ( echo System package manager does not support ls directly here. & exit /b 0 )
if exist "%LIBSCRIPT_HOME%\jq" ( dir /b "%LIBSCRIPT_HOME%\jq" )
exit /b 0

:: ## action_ls_remote
:: Lists upstream release versions available for download.
:action_ls_remote
if "%JQ_INSTALL_METHOD%"=="mise" ( mise ls-remote jq & exit /b 0 )
if "%JQ_INSTALL_METHOD%"=="asdf" ( asdf list all jq & exit /b 0 )
if "%JQ_INSTALL_METHOD%"=="pkgx" ( echo pkgx does not have a local list command & exit /b 0 )
if "%JQ_INSTALL_METHOD%"=="vfox" ( vfox ls all jq & exit /b 0 )
if "%JQ_INSTALL_METHOD%"=="system" ( echo System package manager does not support ls-remote directly here. & exit /b 0 )
if not "%JQ_RELEASES_URL%"=="" (
    curl -sSL "%JQ_RELEASES_URL%"
) else (
    echo ls-remote not fully implemented natively yet.
)
exit /b 0

:: ## action_use
:: Activates the specified component version by updating the active symlink or junction.
:action_use
if "%JQ_INSTALL_METHOD%"=="mise" ( mise use "jq@%JQ_VERSION%" & exit /b 0 )
if "%JQ_INSTALL_METHOD%"=="asdf" ( asdf global jq "%JQ_VERSION%" & exit /b 0 )
if "%JQ_INSTALL_METHOD%"=="pkgx" ( echo pkgx does not use explicit versions this way & exit /b 0 )
if "%JQ_INSTALL_METHOD%"=="vfox" ( vfox use "jq@%JQ_VERSION%" & exit /b 0 )
if "%JQ_INSTALL_METHOD%"=="system" ( echo Cannot 'use' specific version with system package manager. & exit /b 0 )

if "%JQ_VERSION%"=="latest" (for /f "usebackq tokens=*" %%a in (`powershell -NoProfile -Command "(Invoke-RestMethod -Uri 'https://api.github.com/repos/jqlang/jq/releases/latest').tag_name -replace '^v',''"`) do set "EXACT_VERSION=%%a"
) else if "%JQ_VERSION%"=="lts" (for /f "usebackq tokens=*" %%a in (`powershell -NoProfile -Command "(Invoke-RestMethod -Uri 'https://api.github.com/repos/jqlang/jq/releases/latest').tag_name -replace '^v',''"`) do set "EXACT_VERSION=%%a"
) else (
    set "EXACT_VERSION=%JQ_VERSION%"
)
if "%EXACT_VERSION%"=="" set "EXACT_VERSION=%JQ_VERSION%"

set "TARGET_DIR=%LIBSCRIPT_HOME%\jq\%EXACT_VERSION%"
set "ALIAS_DIR=%LIBSCRIPT_HOME%\jq\%JQ_VERSION%"

if not "%TARGET_DIR%"=="%ALIAS_DIR%" (
    if exist "%ALIAS_DIR%" rmdir "%ALIAS_DIR%"
    mklink /J "%ALIAS_DIR%" "%TARGET_DIR%" >nul 2>&1
)
exit /b 0

:: ## action_download
:: Downloads the component release archive into the local offline cache directory.
:action_download
if "%JQ_INSTALL_METHOD%"=="libscript_native" (
    echo Downloading jq %JQ_VERSION% to %DOWNLOAD_DIR%\jq...
    if not exist "%DOWNLOAD_DIR%\jq" mkdir "%DOWNLOAD_DIR%\jq"
    if not "%JQ_DOWNLOAD_URL%"=="" (
        call "!LIBSCRIPT_ROOT_DIR!\_lib\_common\pkg_mgr.cmd" :libscript_download "%JQ_DOWNLOAD_URL%" "%DOWNLOAD_DIR%\jq\jq-%JQ_VERSION%.zip"
    ) else (
        echo JQ_DOWNLOAD_URL is not defined. Skipping.
    )
)
exit /b 0

:: ## action_install
:: Installs and configures the requested version of the component.
:action_install
if /i "%JQ_INSTALL_METHOD%"=="from-source" (
    call "!LIBSCRIPT_ROOT_DIR!\_lib\_common\source_builder.cmd" :libscript_build_component_from_source "jq" "%JQ_VERSION%" "jq" "c"
    exit /b !errorlevel!
)
if "%JQ_INSTALL_METHOD%"=="system" (
    call "!LIBSCRIPT_ROOT_DIR!\_lib\_common\pkg_mgr.cmd" :libscript_depends jq
    exit /b !errorlevel!
)
if "%JQ_INSTALL_METHOD%"=="mise" ( mise install "jq@%JQ_VERSION%" & exit /b 0 )
if "%JQ_INSTALL_METHOD%"=="asdf" ( asdf install jq "%JQ_VERSION%" & exit /b 0 )
if "%JQ_INSTALL_METHOD%"=="pkgx" ( pkgx install "jq@%JQ_VERSION%" & exit /b 0 )
if "%JQ_INSTALL_METHOD%"=="vfox" ( vfox add jq & vfox install "jq@%JQ_VERSION%" & exit /b 0 )

set "TARGET_DIR=%LIBSCRIPT_HOME%\jq\%JQ_VERSION%"
if not exist "%TARGET_DIR%\bin" (
    echo Installing jq %JQ_VERSION% natively to %TARGET_DIR%...
    if not exist "%TARGET_DIR%\bin" mkdir "%TARGET_DIR%\bin"
    if exist "%DOWNLOAD_DIR%\jq\jq-%JQ_VERSION%.zip" (
        echo Extracting from cache...
        tar -xf "%DOWNLOAD_DIR%\jq\jq-%JQ_VERSION%.zip" -C "%TARGET_DIR%"
    ) else if exist "%DOWNLOAD_DIR%\jq\jq-%JQ_VERSION%.tar.gz" (
        echo Extracting from cache...
        tar -xf "%DOWNLOAD_DIR%\jq\jq-%JQ_VERSION%.tar.gz" -C "%TARGET_DIR%"
    ) else if not "%JQ_DOWNLOAD_URL%"=="" (
        echo Downloading and extracting...
        call "!LIBSCRIPT_ROOT_DIR!\_lib\_common\pkg_mgr.cmd" :libscript_download "%JQ_DOWNLOAD_URL%" "%TEMP%\jq.zip"
        tar -xf "%TEMP%\jq.zip" -C "%TARGET_DIR%"
    ) else (
        echo No download URL or cache available for jq.
        exit /b 1
    )
) else (
    echo jq %JQ_VERSION% is already installed.
)
set "ALIAS_DIR=%LIBSCRIPT_HOME%\jq\%JQ_VERSION%"
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
        set "SVC_NAME=libscript_jq"
    ) else (
        set "SVC_NAME=libscript_%PACKAGE_NAME%"
    )
) else (
    set "SVC_NAME=%LIBSCRIPT_SERVICE_NAME%"
)
if "%JQ_INSTALL_METHOD%"=="libscript_native" (
    call "!LIBSCRIPT_ROOT_DIR!\_lib\_common\service.cmd" "%ACTION%" "%SVC_NAME%"
) else if "%JQ_INSTALL_METHOD%"=="system" (
    call "!LIBSCRIPT_ROOT_DIR!\_lib\_common\service.cmd" "%ACTION%" "%SVC_NAME%"
) else (
    echo %ACTION% not natively implemented for %JQ_INSTALL_METHOD%.
)
exit /b 0

:: ## action_install_service
:: Registers and configures the component as a persistent system service.
:action_install_service
if "%LIBSCRIPT_SERVICE_NAME%"=="" (
    if "%PACKAGE_NAME%"=="" (
        set "SVC_NAME=libscript_jq"
    ) else (
        set "SVC_NAME=libscript_%PACKAGE_NAME%"
    )
) else (
    set "SVC_NAME=%LIBSCRIPT_SERVICE_NAME%"
)
if "%JQ_INSTALL_METHOD%"=="libscript_native" (
    call "!LIBSCRIPT_ROOT_DIR!\_lib\_common\service_install.cmd" install "%SVC_NAME%"
) else if "%JQ_INSTALL_METHOD%"=="system" (
    call "!LIBSCRIPT_ROOT_DIR!\_lib\_common\service_install.cmd" install "%SVC_NAME%"
) else (
    echo install-service not implemented for %JQ_INSTALL_METHOD%.
)
exit /b 0

:: ## action_uninstall_service
:: Stops and removes the registered system service for the component.
:action_uninstall_service
if "%LIBSCRIPT_SERVICE_NAME%"=="" (
    if "%PACKAGE_NAME%"=="" (
        set "SVC_NAME=libscript_jq"
    ) else (
        set "SVC_NAME=libscript_%PACKAGE_NAME%"
    )
) else (
    set "SVC_NAME=%LIBSCRIPT_SERVICE_NAME%"
)
if "%JQ_INSTALL_METHOD%"=="libscript_native" (
    call "!LIBSCRIPT_ROOT_DIR!\_lib\_common\service_install.cmd" uninstall "%SVC_NAME%"
) else if "%JQ_INSTALL_METHOD%"=="system" (
    call "!LIBSCRIPT_ROOT_DIR!\_lib\_common\service_install.cmd" uninstall "%SVC_NAME%"
) else (
    echo uninstall-service not implemented for %JQ_INSTALL_METHOD%.
)
exit /b 0
