@echo off
:: # setup_generic.cmd
:: ## Overview
:: Windows setup for go
::
:: ## Usage
:: Managed by libscript. Provides download, install, ls, ls-remote, use capabilities.
setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"
if defined STACK (
    echo "!STACK!" | findstr /I /C:":!THIS_FILE!:" >nul 2>&1
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

:: Parse offline and go options
:: ## arg_parse_loop
:: Parses command-line arguments and populates configuration variables.
:arg_parse_loop
if "%~1"=="" goto :arg_parse_done
if /i "%~1"=="--offline" set "LIBSCRIPT_OFFLINE=1"
if /i "%~1"=="-o" set "LIBSCRIPT_OFFLINE=1"
if /i "%~1"=="--go-vendor" set "GO_VENDOR=1"
shift
goto :arg_parse_loop
:: ## arg_parse_done
:: Continues execution after command-line argument parsing completes.
:arg_parse_done

if "%LIBSCRIPT_OFFLINE%"=="1" (
    set "GOPROXY=off"
    set "GOFLAGS=%GOFLAGS% -mod=vendor"
)
if "%GO_VENDOR%"=="1" (
    set "GOPROXY=off"
    set "GOFLAGS=%GOFLAGS% -mod=vendor"
)

if "%ACTION%"=="" set ACTION=install
if "%GO_VERSION%"=="" set GO_VERSION=latest

if "%LIBSCRIPT_HOME%"=="" (
    set "LIBSCRIPT_HOME=%USERPROFILE%\.libscript"
)
if "%DOWNLOAD_DIR%"=="" (
    set "DOWNLOAD_DIR=%TEMP%\libscript_downloads"
)

:: Resolve install method
if "%GO_INSTALL_METHOD%"=="" (
    if not "%LIBSCRIPT_DEFAULT_INSTALL_METHOD%"=="" (
        set "GO_INSTALL_METHOD=%LIBSCRIPT_DEFAULT_INSTALL_METHOD%"
    ) else (
        set "GO_INSTALL_METHOD=libscript_native"
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
if "%GO_INSTALL_METHOD%"=="system" ( echo System package manager does not support ls directly here. & exit /b 0 )
if exist "%LIBSCRIPT_HOME%\go" ( dir /b "%LIBSCRIPT_HOME%\go" )
exit /b 0

:: ## action_ls_remote
:: Lists upstream release versions available for download.
:action_ls_remote
if "%GO_INSTALL_METHOD%"=="system" ( echo System package manager does not support ls-remote directly here. & exit /b 0 )
if not "%GO_RELEASES_URL%"=="" (
    call "!LIBSCRIPT_ROOT_DIR!\_lib\_common\pkg_mgr.cmd" :libscript_fetch_stdout "%GO_RELEASES_URL%"
) else (
    git ls-remote --tags "https://github.com/golang/go" 2^>nul ^| findstr /R "[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*"
)
exit /b 0

:: ## action_use
:: Activates the specified component version by updating the active symlink or junction.
:action_use
if "%GO_INSTALL_METHOD%"=="system" ( echo Cannot 'use' specific version with system package manager. & exit /b 0 )

if "%GO_VERSION%"=="latest" (set "EXACT_VERSION=%GO_VERSION%"
) else if "%GO_VERSION%"=="lts" (set "EXACT_VERSION=%GO_VERSION%"
) else (
    set "EXACT_VERSION=%GO_VERSION%"
)
if "%EXACT_VERSION%"=="" set "EXACT_VERSION=%GO_VERSION%"

set "TARGET_DIR=%LIBSCRIPT_HOME%\go\%EXACT_VERSION%"
set "ALIAS_DIR=%LIBSCRIPT_HOME%\go\%GO_VERSION%"

if not "%TARGET_DIR%"=="%ALIAS_DIR%" (
    if exist "%ALIAS_DIR%" (
        dir /al "%ALIAS_DIR%" >nul 2>&1
        if not errorlevel 1 rmdir "%ALIAS_DIR%" >nul 2>&1
    )
    if not exist "%ALIAS_DIR%" mklink /J "%ALIAS_DIR%" "%TARGET_DIR%" >nul 2>&1
)
exit /b 0

:: ## action_download
:: Downloads the component release archive into the local offline cache directory.
:action_download
if "%GO_INSTALL_METHOD%"=="libscript_native" (
    echo Downloading go %GO_VERSION% to %DOWNLOAD_DIR%\go...
    if not exist "%DOWNLOAD_DIR%\go" mkdir "%DOWNLOAD_DIR%\go"
    if not "%GO_DOWNLOAD_URL%"=="" (
        call "!LIBSCRIPT_ROOT_DIR!\_lib\_common\pkg_mgr.cmd" :libscript_download "%GO_DOWNLOAD_URL%" "%DOWNLOAD_DIR%\go\go-%GO_VERSION%.zip"
    ) else (
        echo GO_DOWNLOAD_URL is not defined. Skipping.
    )
)
exit /b 0

:: ## action_install
:: Installs and configures the requested version of the component.
:action_install
if "%GO_INSTALL_METHOD%"=="system" (
    call "!LIBSCRIPT_ROOT_DIR!\_lib\_common\pkg_mgr.cmd" :libscript_depends go
    exit /b !errorlevel!
)

set "TARGET_DIR=%LIBSCRIPT_HOME%\go\%GO_VERSION%"
if not exist "%TARGET_DIR%\bin" (
    echo Installing go %GO_VERSION% natively to %TARGET_DIR%...
    if not exist "%TARGET_DIR%\bin" mkdir "%TARGET_DIR%\bin"
    if exist "%DOWNLOAD_DIR%\go\go-%GO_VERSION%.zip" (
        echo Extracting from cache...
        tar -xf "%DOWNLOAD_DIR%\go\go-%GO_VERSION%.zip" -C "%TARGET_DIR%"
    ) else if exist "%DOWNLOAD_DIR%\go\go-%GO_VERSION%.tar.gz" (
        echo Extracting from cache...
        tar -xf "%DOWNLOAD_DIR%\go\go-%GO_VERSION%.tar.gz" -C "%TARGET_DIR%"
    ) else if not "%GO_DOWNLOAD_URL%"=="" (
        echo Downloading and extracting...
        call "!LIBSCRIPT_ROOT_DIR!\_lib\_common\pkg_mgr.cmd" :libscript_download "%GO_DOWNLOAD_URL%" "%TEMP%\go.zip"
        tar -xf "%TEMP%\go.zip" -C "%TARGET_DIR%"
    ) else (
        echo No download URL or cache available for go.
        exit /b 1
    )
) else (
    echo go %GO_VERSION% is already installed.
)
set "ALIAS_DIR=%LIBSCRIPT_HOME%\go\%GO_VERSION%"
if not "%TARGET_DIR%"=="%ALIAS_DIR%" (
    if exist "%ALIAS_DIR%" (
        dir /al "%ALIAS_DIR%" >nul 2>&1
        if not errorlevel 1 rmdir "%ALIAS_DIR%" >nul 2>&1
    )
    if not exist "%ALIAS_DIR%" mklink /J "%ALIAS_DIR%" "%TARGET_DIR%" >nul 2>&1
)
exit /b 0

:: ## action_service
:: Routes service daemon control actions (start, stop, restart, status) to the common handler.
:action_service
:: ## action_install_service
:: Registers and configures the component as a persistent system service.
:action_install_service
:: ## action_uninstall_service
:: Stops and removes the registered system service for the component.
:action_uninstall_service
set "STACK="
call "!LIBSCRIPT_ROOT_DIR!\_lib\_common\setup_base.cmd" :libscript_handle_generic_action "go" "%ACTION%" "%GO_VERSION%" "%GO_INSTALL_METHOD%" "" "" "" "\"%LIBSCRIPT_HOME%\go\%GO_VERSION%\\bin\\go.exe\"" "%LIBSCRIPT_HOME%\go\%GO_VERSION%"
exit /b !errorlevel!
