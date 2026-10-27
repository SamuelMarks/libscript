@echo off
:: # setup_generic.cmd
:: ## Overview
:: Windows setup for kubernetes-thw
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

if "%ACTION%"=="" set ACTION=install
if "%KUBERNETES_THW_VERSION%"=="" set KUBERNETES_THW_VERSION=latest

if "%LIBSCRIPT_HOME%"=="" (
    set "LIBSCRIPT_HOME=%USERPROFILE%\.libscript"
)
if "%DOWNLOAD_DIR%"=="" (
    set "DOWNLOAD_DIR=%TEMP%\libscript_downloads"
)

:: Resolve install method
if "%KUBERNETES_THW_INSTALL_METHOD%"=="" (
    if not "%LIBSCRIPT_DEFAULT_INSTALL_METHOD%"=="" (
        set "KUBERNETES_THW_INSTALL_METHOD=%LIBSCRIPT_DEFAULT_INSTALL_METHOD%"
    ) else (
        set "KUBERNETES_THW_INSTALL_METHOD=libscript_native"
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
if "%KUBERNETES_THW_INSTALL_METHOD%"=="system" ( echo System package manager does not support ls directly here. & exit /b 0 )
if exist "%LIBSCRIPT_HOME%\kubernetes-thw" ( dir /b "%LIBSCRIPT_HOME%\kubernetes-thw" )
exit /b 0

:: ## action_ls_remote
:: Lists upstream release versions available for download.
:action_ls_remote
if "%KUBERNETES_THW_INSTALL_METHOD%"=="system" ( echo System package manager does not support ls-remote directly here. & exit /b 0 )
if not "%KUBERNETES_THW_RELEASES_URL%"=="" (
    call "!LIBSCRIPT_ROOT_DIR!\_lib\_common\pkg_mgr.cmd" :libscript_fetch_stdout "%KUBERNETES_THW_RELEASES_URL%"
) else (
    git ls-remote --tags "https://github.com/kubernetes/kubernetes" 2^>nul ^| findstr /R "[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*"
)
exit /b 0

:: ## action_use
:: Activates the specified component version by updating the active symlink or junction.
:action_use
if "%KUBERNETES_THW_INSTALL_METHOD%"=="system" ( echo Cannot 'use' specific version with system package manager. & exit /b 0 )

if "%KUBERNETES_THW_VERSION%"=="latest" (set "EXACT_VERSION=%KUBERNETES_THW_VERSION%"
) else if "%KUBERNETES_THW_VERSION%"=="lts" (set "EXACT_VERSION=%KUBERNETES_THW_VERSION%"
) else (
    set "EXACT_VERSION=%KUBERNETES_THW_VERSION%"
)
if "%EXACT_VERSION%"=="" set "EXACT_VERSION=%KUBERNETES_THW_VERSION%"

set "TARGET_DIR=%LIBSCRIPT_HOME%\kubernetes-thw\%EXACT_VERSION%"
set "ALIAS_DIR=%LIBSCRIPT_HOME%\kubernetes-thw\%KUBERNETES_THW_VERSION%"

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
if "%KUBERNETES_THW_INSTALL_METHOD%"=="libscript_native" (
    echo Downloading kubernetes-thw %KUBERNETES_THW_VERSION% to %DOWNLOAD_DIR%\kubernetes-thw...
    if not exist "%DOWNLOAD_DIR%\kubernetes-thw" mkdir "%DOWNLOAD_DIR%\kubernetes-thw"
    if not "%KUBERNETES_THW_DOWNLOAD_URL%"=="" (
        call "!LIBSCRIPT_ROOT_DIR!\_lib\_common\pkg_mgr.cmd" :libscript_download "%KUBERNETES_THW_DOWNLOAD_URL%" "%DOWNLOAD_DIR%\kubernetes-thw\kubernetes-thw-%KUBERNETES_THW_VERSION%.zip"
    ) else (
        echo KUBERNETES_THW_DOWNLOAD_URL is not defined. Skipping.
    )
)
exit /b 0

:: ## action_install
:: Installs and configures the requested version of the component.
:action_install
if "%KUBERNETES_THW_INSTALL_METHOD%"=="system" (
    call "!LIBSCRIPT_ROOT_DIR!\_lib\_common\pkg_mgr.cmd" :libscript_depends kubernetes-thw
    exit /b !errorlevel!
)

set "TARGET_DIR=%LIBSCRIPT_HOME%\kubernetes-thw\%KUBERNETES_THW_VERSION%"
if not exist "%TARGET_DIR%\bin" (
    echo Installing kubernetes-thw %KUBERNETES_THW_VERSION% natively to %TARGET_DIR%...
    if not exist "%TARGET_DIR%\bin" mkdir "%TARGET_DIR%\bin"
    if exist "%DOWNLOAD_DIR%\kubernetes-thw\kubernetes-thw-%KUBERNETES_THW_VERSION%.zip" (
        echo Extracting from cache...
        tar -xf "%DOWNLOAD_DIR%\kubernetes-thw\kubernetes-thw-%KUBERNETES_THW_VERSION%.zip" -C "%TARGET_DIR%"
    ) else if exist "%DOWNLOAD_DIR%\kubernetes-thw\kubernetes-thw-%KUBERNETES_THW_VERSION%.tar.gz" (
        echo Extracting from cache...
        tar -xf "%DOWNLOAD_DIR%\kubernetes-thw\kubernetes-thw-%KUBERNETES_THW_VERSION%.tar.gz" -C "%TARGET_DIR%"
    ) else if not "%KUBERNETES_THW_DOWNLOAD_URL%"=="" (
        echo Downloading and extracting...
        call "!LIBSCRIPT_ROOT_DIR!\_lib\_common\pkg_mgr.cmd" :libscript_download "%KUBERNETES_THW_DOWNLOAD_URL%" "%TEMP%\kubernetes-thw.zip"
        tar -xf "%TEMP%\kubernetes-thw.zip" -C "%TARGET_DIR%"
    ) else (
        echo No download URL or cache available for kubernetes-thw.
        exit /b 1
    )
) else (
    echo kubernetes-thw %KUBERNETES_THW_VERSION% is already installed.
)
set "ALIAS_DIR=%LIBSCRIPT_HOME%\kubernetes-thw\%KUBERNETES_THW_VERSION%"
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
call "!LIBSCRIPT_ROOT_DIR!\_lib\_common\setup_base.cmd" :libscript_handle_generic_action "kubernetes-thw" "%ACTION%" "%KUBERNETES_THW_VERSION%" "%KUBERNETES_THW_INSTALL_METHOD%" "" "" "" "\"%LIBSCRIPT_HOME%\kubernetes-thw\%KUBERNETES_THW_VERSION%\\bin\\kubernetes-thw.exe\"" "%LIBSCRIPT_HOME%\kubernetes-thw\%KUBERNETES_THW_VERSION%"
exit /b !errorlevel!
