@echo off
:: # setup_generic.cmd
:: ## Overview
:: Windows setup for zig
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
if "%ZIG_VERSION%"=="" set ZIG_VERSION=latest

if "%LIBSCRIPT_HOME%"=="" (
    set "LIBSCRIPT_HOME=%USERPROFILE%\.libscript"
)
if "%DOWNLOAD_DIR%"=="" (
    set "DOWNLOAD_DIR=%TEMP%\libscript_downloads"
)

:: Resolve install method
if "%ZIG_INSTALL_METHOD%"=="" (
    if not "%LIBSCRIPT_DEFAULT_INSTALL_METHOD%"=="" (
        set "ZIG_INSTALL_METHOD=%LIBSCRIPT_DEFAULT_INSTALL_METHOD%"
    ) else (
        set "ZIG_INSTALL_METHOD=libscript_native"
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

:: ## action_ls
:: Lists all locally installed versions of the component under LIBSCRIPT_HOME.
:action_ls
if "%ZIG_INSTALL_METHOD%"=="system" ( echo System package manager does not support ls directly here. & exit /b 0 )
if exist "%LIBSCRIPT_HOME%\zig" ( dir /b "%LIBSCRIPT_HOME%\zig" )
exit /b 0

:: ## action_ls_remote
:: Lists upstream release versions available for download.
:action_ls_remote
if "%ZIG_INSTALL_METHOD%"=="system" ( echo System package manager does not support ls-remote directly here. & exit /b 0 )
if not "%ZIG_RELEASES_URL%"=="" (
    call "!LIBSCRIPT_ROOT_DIR!\engine\common\pkg_mgr.cmd" :libscript_fetch_stdout "%ZIG_RELEASES_URL%"
) else (
    git ls-remote --tags "https://github.com/ziglang/zig" 2^>nul ^| findstr /R "[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*"
)
exit /b 0

:: ## action_use
:: Activates the specified component version by updating the active symlink or junction.
:action_use
if "%ZIG_INSTALL_METHOD%"=="system" ( echo Cannot 'use' specific version with system package manager. & exit /b 0 )

if "%ZIG_VERSION%"=="latest" (set "EXACT_VERSION=%ZIG_VERSION%"
) else if "%ZIG_VERSION%"=="lts" (set "EXACT_VERSION=%ZIG_VERSION%"
) else (
    set "EXACT_VERSION=%ZIG_VERSION%"
)
if "%EXACT_VERSION%"=="" set "EXACT_VERSION=%ZIG_VERSION%"

set "TARGET_DIR=%LIBSCRIPT_HOME%\zig\%EXACT_VERSION%"
set "ALIAS_DIR=%LIBSCRIPT_HOME%\zig\%ZIG_VERSION%"

if not "%TARGET_DIR%"=="%ALIAS_DIR%" (
    if exist "%ALIAS_DIR%" (
        dir /al "%ALIAS_DIR%" >nul 2>&1
        if not errorlevel 1 rmdir "%ALIAS_DIR%" >nul 2>&1
    )
    rmdir "%ALIAS_DIR%" >nul 2>&1
    mklink /J "%ALIAS_DIR%" "%TARGET_DIR%" >nul 2>&1
)
exit /b 0

:: ## action_download
:: Downloads the component release archive into the local offline cache directory.
:action_download
if "%ZIG_INSTALL_METHOD%"=="libscript_native" (
    echo Downloading zig %ZIG_VERSION% to %DOWNLOAD_DIR%\zig...
    if not exist "%DOWNLOAD_DIR%\zig" mkdir "%DOWNLOAD_DIR%\zig"
    if not "%ZIG_DOWNLOAD_URL%"=="" (
        call "!LIBSCRIPT_ROOT_DIR!\engine\common\pkg_mgr.cmd" :libscript_download "%ZIG_DOWNLOAD_URL%" "%DOWNLOAD_DIR%\zig\zig-%ZIG_VERSION%.zip"
    ) else (
        echo ZIG_DOWNLOAD_URL is not defined. Skipping.
    )
)
exit /b 0

:: ## action_install
:: Installs and configures the requested version of the component.
:action_install
if "%ZIG_INSTALL_METHOD%"=="system" (
    call "!LIBSCRIPT_ROOT_DIR!\engine\common\pkg_mgr.cmd" :libscript_depends zig
    exit /b !errorlevel!
)

set "EXACT_VER=%ZIG_VERSION%"
if /i "!EXACT_VER!"=="latest" set "EXACT_VER=0.13.0"
if /i "!EXACT_VER!"=="stable" set "EXACT_VER=0.13.0"
if /i "!EXACT_VER!"=="lts" set "EXACT_VER=0.13.0"
set "_ZIG_ARCH=x86_64"
if /i "%PROCESSOR_ARCHITECTURE%"=="ARM64" set "_ZIG_ARCH=aarch64"
if /i "%PROCESSOR_ARCHITEW6432%"=="ARM64" set "_ZIG_ARCH=aarch64"
set "_EFF_ZIG_URL=%ZIG_DOWNLOAD_URL%"
if "!_EFF_ZIG_URL!"=="" set "_EFF_ZIG_URL=https://ziglang.org/download/!EXACT_VER!/zig-windows-!_ZIG_ARCH!-!EXACT_VER!.zip"

set "TARGET_DIR=%LIBSCRIPT_HOME%\zig\!EXACT_VER!"
if not exist "!TARGET_DIR!\zig.exe" (
    echo Installing zig !EXACT_VER! natively to !TARGET_DIR!...
    if not exist "!TARGET_DIR!\bin" mkdir "!TARGET_DIR!\bin"
    if exist "%DOWNLOAD_DIR%\zig\zig-!EXACT_VER!.zip" (
        echo Extracting from cache...
        tar -xf "%DOWNLOAD_DIR%\zig\zig-!EXACT_VER!.zip" --strip-components=1 -C "!TARGET_DIR!"
    ) else if exist "%DOWNLOAD_DIR%\zig\zig-!EXACT_VER!.tar.gz" (
        echo Extracting from cache...
        tar -xf "%DOWNLOAD_DIR%\zig\zig-!EXACT_VER!.tar.gz" --strip-components=1 -C "!TARGET_DIR!"
    ) else (
        echo Downloading and extracting !_EFF_ZIG_URL!...
        if not exist "%DOWNLOAD_DIR%\zig" mkdir "%DOWNLOAD_DIR%\zig"
        call "!LIBSCRIPT_ROOT_DIR!\engine\common\pkg_mgr.cmd" :libscript_download "!_EFF_ZIG_URL!" "%DOWNLOAD_DIR%\zig\zig-!EXACT_VER!.zip"
        if errorlevel 1 exit /b 1
        tar -xf "%DOWNLOAD_DIR%\zig\zig-!EXACT_VER!.zip" --strip-components=1 -C "!TARGET_DIR!"
    )
    if exist "!TARGET_DIR!\zig.exe" (
        (
            echo @echo off
            echo "%%~dp0..\zig.exe" %%*
        ) > "!TARGET_DIR!\bin\zig.cmd"
    )
) else (
    echo zig !EXACT_VER! is already installed.
)
set "ALIAS_DIR=%LIBSCRIPT_HOME%\zig\%ZIG_VERSION%"
if not "%TARGET_DIR%"=="%ALIAS_DIR%" (
    if exist "%ALIAS_DIR%" (
        dir /al "%ALIAS_DIR%" >nul 2>&1
        if not errorlevel 1 rmdir "%ALIAS_DIR%" >nul 2>&1
    )
    rmdir "%ALIAS_DIR%" >nul 2>&1
    mklink /J "%ALIAS_DIR%" "%TARGET_DIR%" >nul 2>&1
)
exit /b 0

:: ## action_service
:: Routes service daemon control actions (start, stop, restart, status) to the common handler.
:action_service
goto :action_install_service
:: ## action_install_service
:: Registers and configures the component as a persistent system service.
:action_install_service
goto :action_uninstall_service
:: ## action_uninstall_service
:: Stops and removes the registered system service for the component.
:action_uninstall_service
set "STACK="
call "!LIBSCRIPT_ROOT_DIR!\engine\common\setup_base.cmd" :libscript_handle_generic_action "zig" "%ACTION%" "%ZIG_VERSION%" "%ZIG_INSTALL_METHOD%" "" "" "" "\"%LIBSCRIPT_HOME%\zig\%ZIG_VERSION%\\bin\\zig.exe\"" "%LIBSCRIPT_HOME%\zig\%ZIG_VERSION%"
exit /b !errorlevel!
