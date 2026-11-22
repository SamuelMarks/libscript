@echo off
:: # setup_generic.cmd
:: ## Overview
:: Windows setup for west implementing the Version Manager Contract.
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

if "%LIBSCRIPT_HOME%"=="" set "LIBSCRIPT_HOME=%USERPROFILE%\.libscript"
if "%WEST_INSTALL_METHOD%"=="" (
    if not "%LIBSCRIPT_GLOBAL_INSTALL_METHOD%"=="" (
        set "WEST_INSTALL_METHOD=%LIBSCRIPT_GLOBAL_INSTALL_METHOD%"
    ) else (
        set "WEST_INSTALL_METHOD=libscript_native"
    )
)
if "%ACTION%"=="" set "ACTION=install"
if "%WEST_VERSION%"=="" set "WEST_VERSION=1.3.0"

if "%ACTION%"=="ls" goto :action_ls
if "%ACTION%"=="ls-remote" goto :action_ls_remote
if "%ACTION%"=="use" goto :action_use
if "%ACTION%"=="download" goto :action_download
if "%ACTION%"=="install" goto :action_install
goto :action_other

:: ## action_ls
:: Lists locally installed versions of west.
:action_ls
if "%WEST_INSTALL_METHOD%"=="libscript_native" (
    if exist "%LIBSCRIPT_HOME%\west" dir /b "%LIBSCRIPT_HOME%\west"
) else (
    where west >nul 2>&1 && west --version
)
exit /b 0

:: ## action_ls_remote
:: Queries available remote versions of west.
:action_ls_remote
set "RELEASES_URL=%WEST_RELEASES_URL%"
if "!RELEASES_URL!"=="" set "RELEASES_URL=https://api.github.com/repos/zephyrproject-rtos/west/releases/latest"
echo [ls-remote] Fetching available west versions from !RELEASES_URL!...
call "%LIBSCRIPT_ROOT_DIR%\engine\common\pkg_mgr.cmd" :libscript_fetch_stdout "!RELEASES_URL!"
exit /b 0

:: ## action_use
:: Activates a specific installed version of west and updates alias junctions.
:action_use
call :resolve_version
set "TARGET_DIR=%LIBSCRIPT_HOME%\west\!EXACT_VERSION!"
if not exist "!TARGET_DIR!" (
    echo Version !EXACT_VERSION! not installed. Installing...
    set "ACTION=install"
    call "%~f0"
)
call "%LIBSCRIPT_ROOT_DIR%\engine\common\versioning.cmd" :libscript_symlink_alias "west" "%WEST_VERSION%" "!EXACT_VERSION!"
call "%LIBSCRIPT_ROOT_DIR%\engine\common\versioning.cmd" :libscript_symlink_alias "west" "default" "!EXACT_VERSION!"
exit /b 0

:: ## action_download
:: Downloads the west release artifact to the local cache directory.
:action_download
call :resolve_version
set "URL=%WEST_DOWNLOAD_URL%"
if "!URL!"=="" set "URL=https://github.com/zephyrproject-rtos/west/archive/refs/tags/v${VERSION}.zip"
call set "URL=%%URL:{VERSION}=!EXACT_VERSION!%%"
set "DL_DIR=%DOWNLOAD_DIR%"
if "!DL_DIR!"=="" set "DL_DIR=%TEMP%\libscript_downloads"
set "DL_DIR=!DL_DIR!\west"
if not exist "!DL_DIR!" mkdir "!DL_DIR!"
for %%F in ("!URL!") do set "ARCHIVE_NAME=%%~nxF"
echo [download] Pre-downloading west %WEST_VERSION% from !URL! to !DL_DIR!\!ARCHIVE_NAME!...
call "%LIBSCRIPT_ROOT_DIR%\engine\common\pkg_mgr.cmd" :libscript_download "!URL!" "!DL_DIR!\!ARCHIVE_NAME!"
exit /b !errorlevel!

:: ## action_install
:: Installs west via from-source, system package manager, or libscript_native isolation.
:action_install
if /i "%WEST_INSTALL_METHOD%"=="from-source" (
    call :resolve_version
    set "TARGET_DIR=%LIBSCRIPT_HOME%\west\!EXACT_VERSION!"
    set "SRC_URL=%WEST_DOWNLOAD_URL%"
    if "!SRC_URL!"=="" set "SRC_URL=https://github.com/zephyrproject-rtos/west/archive/refs/tags/v${VERSION}.tar.gz"
    call set "SRC_URL=%%SRC_URL:{VERSION}=!EXACT_VERSION!%%"
    call "%LIBSCRIPT_ROOT_DIR%\engine\common\source_builder.cmd" :libscript_build_component_from_source "west" "!EXACT_VERSION!" "west" "c" "autotools" "!SRC_URL!"
    exit /b !errorlevel!
)
if "%WEST_INSTALL_METHOD%"=="system" (
    call "%LIBSCRIPT_ROOT_DIR%\engine\common\pkg_mgr.cmd" :libscript_depends west
    exit /b !errorlevel!
)
if /i "%WEST_INSTALL_METHOD%"=="winget" (
    call "%LIBSCRIPT_ROOT_DIR%\engine\common\pkg_mgr.cmd" :libscript_depends_via winget west
    exit /b !errorlevel!
)
if /i "%WEST_INSTALL_METHOD%"=="choco" (
    call "%LIBSCRIPT_ROOT_DIR%\engine\common\pkg_mgr.cmd" :libscript_depends_via choco west
    exit /b !errorlevel!
)
if /i "%WEST_INSTALL_METHOD%"=="scoop" (
    call "%LIBSCRIPT_ROOT_DIR%\engine\common\pkg_mgr.cmd" :libscript_depends_via scoop west
    exit /b !errorlevel!
)
call :resolve_version
set "TARGET_DIR=%LIBSCRIPT_HOME%\west\!EXACT_VERSION!"
set "_BIN_FOUND=0"
if exist "!TARGET_DIR!\bin\west.exe" set "_BIN_FOUND=1"
if exist "!TARGET_DIR!\bin\west.cmd" set "_BIN_FOUND=1"
if exist "!TARGET_DIR!\venv\Scripts\west.exe" set "_BIN_FOUND=1"
if "!_BIN_FOUND!"=="1" (
    if not "%FORCE_REINSTALL%"=="1" (
        echo [INFO] west !EXACT_VERSION! is already installed at !TARGET_DIR!.
        call "%LIBSCRIPT_ROOT_DIR%\engine\common\versioning.cmd" :libscript_symlink_alias "west" "%WEST_VERSION%" "!EXACT_VERSION!"
        call "%LIBSCRIPT_ROOT_DIR%\engine\common\versioning.cmd" :libscript_symlink_alias "west" "default" "!EXACT_VERSION!"
        exit /b 0
    )
)
if not exist "!TARGET_DIR!\bin" mkdir "!TARGET_DIR!\bin"
set "_REQ_TMP=!TARGET_DIR!\requirements.west.txt"
> "!_REQ_TMP!" echo west==!EXACT_VERSION!
call "%LIBSCRIPT_ROOT_DIR%\engine\common\python_env.cmd" libscript_python_venv "!TARGET_DIR!\venv" "" "!_REQ_TMP!"
if errorlevel 1 exit /b 1
if exist "!TARGET_DIR!\venv\Scripts\west.exe" (
    copy /y "!TARGET_DIR!\venv\Scripts\west.exe" "!TARGET_DIR!\bin\west.exe" >nul
)
call "%LIBSCRIPT_ROOT_DIR%\engine\common\versioning.cmd" :libscript_symlink_alias "west" "%WEST_VERSION%" "!EXACT_VERSION!"
call "%LIBSCRIPT_ROOT_DIR%\engine\common\versioning.cmd" :libscript_symlink_alias "west" "default" "!EXACT_VERSION!"
exit /b 0

:: ## resolve_version
:: Resolves latest or lts version alias into EXACT_VERSION.
:resolve_version
if /i "%WEST_VERSION%"=="latest" goto :resolve_remote_gh_tag
if /i "%WEST_VERSION%"=="lts" goto :resolve_remote_gh_tag
if /i "%WEST_VERSION%"=="stable" goto :resolve_remote_gh_tag
set "EXACT_VERSION=%WEST_VERSION%"
exit /b 0

:: ## resolve_remote_gh_tag
:: Queries GitHub Releases API for the latest tag with offline fallback.
:resolve_remote_gh_tag
set "EXACT_VERSION="
if not "zephyrproject-rtos/west" == "" (
    for /f "delims=" %%T in ('call "%LIBSCRIPT_ROOT_DIR%\engine\common\pkg_mgr.cmd" :libscript_resolve_github_tag "https://api.github.com/repos/zephyrproject-rtos/west/releases/latest"') do (
        set "EXACT_VERSION=%%T"
    )
)
if not "v" == "" (
    if not "!EXACT_VERSION!"=="" set "EXACT_VERSION=!EXACT_VERSION:v=!"
)
if "!EXACT_VERSION!"=="" set "EXACT_VERSION=1.0.0"
exit /b 0

:: ## action_other
:: Delegates service and lifecycle actions to setup_base.cmd.
:action_other
call "%LIBSCRIPT_ROOT_DIR%\engine\common\setup_base.cmd" :libscript_handle_generic_action "west" "%ACTION%" "%WEST_VERSION%" "%WEST_INSTALL_METHOD%" "" "" "" "\"%LIBSCRIPT_HOME%\west\%WEST_VERSION%\\bin\\west.exe\"" "%LIBSCRIPT_HOME%\west\%WEST_VERSION%"
exit /b !errorlevel!
