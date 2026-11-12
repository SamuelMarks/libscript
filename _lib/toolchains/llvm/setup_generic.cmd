@echo off
:: # setup_generic.cmd
:: ## Overview
:: Windows setup for llvm implementing the Version Manager Contract.
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
if "%LLVM_INSTALL_METHOD%"=="" (
    if not "%LIBSCRIPT_GLOBAL_INSTALL_METHOD%"=="" (
        set "LLVM_INSTALL_METHOD=%LIBSCRIPT_GLOBAL_INSTALL_METHOD%"
    ) else (
        set "LLVM_INSTALL_METHOD=system"
    )
)
if "%ACTION%"=="" set "ACTION=install"
if "%LLVM_VERSION%"=="" set "LLVM_VERSION=latest"

if "%ACTION%"=="ls" goto :action_ls
if "%ACTION%"=="ls-remote" goto :action_ls_remote
if "%ACTION%"=="use" goto :action_use
if "%ACTION%"=="download" goto :action_download
if "%ACTION%"=="install" goto :action_install
goto :action_other

:: ## action_ls
:: Lists locally installed versions of llvm.
:action_ls
if "%LLVM_INSTALL_METHOD%"=="libscript_native" (
    if exist "%LIBSCRIPT_HOME%\llvm" dir /b "%LIBSCRIPT_HOME%\llvm"
) else (
    where llvm-config >nul 2>&1 && llvm-config --version
)
exit /b 0

:: ## action_ls_remote
:: Queries available remote versions of llvm.
:action_ls_remote
set "RELEASES_URL=%LLVM_RELEASES_URL%"
if "!RELEASES_URL!"=="" set "RELEASES_URL=https://api.github.com/repos/llvm/llvm-project/releases"
echo [ls-remote] Fetching available llvm versions from !RELEASES_URL!...
call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\pkg_mgr.cmd" :libscript_fetch_stdout "!RELEASES_URL!"
exit /b 0

:: ## action_use
:: Activates a specific installed version of llvm and updates alias junctions.
:action_use
call :resolve_version
set "TARGET_DIR=%LIBSCRIPT_HOME%\llvm\!EXACT_VERSION!"
if not exist "!TARGET_DIR!" (
    echo Version !EXACT_VERSION! not installed. Installing...
    set "ACTION=install"
    call "%~f0"
)
if exist "%LIBSCRIPT_HOME%\llvm\%LLVM_VERSION%" rmdir "%LIBSCRIPT_HOME%\llvm\%LLVM_VERSION%" 2>nul
mklink /J "%LIBSCRIPT_HOME%\llvm\%LLVM_VERSION%" "!TARGET_DIR!" >nul
if exist "%LIBSCRIPT_HOME%\llvm\default" rmdir "%LIBSCRIPT_HOME%\llvm\default" 2>nul
mklink /J "%LIBSCRIPT_HOME%\llvm\default" "!TARGET_DIR!" >nul
exit /b 0

:: ## action_download
:: Downloads the llvm release artifact to the local cache directory.
:action_download
call :resolve_version
set "URL=%LLVM_DOWNLOAD_URL%"
if "!URL!"=="" set "URL=https://github.com/llvm/llvm-project/releases/download/llvmorg-{VERSION}/llvm-{VERSION}-windows.zip"
set "DL_DIR=%DOWNLOAD_DIR%"
if "!DL_DIR!"=="" set "DL_DIR=%TEMP%\libscript_downloads"
set "DL_DIR=!DL_DIR!\llvm"
if not exist "!DL_DIR!" mkdir "!DL_DIR!"
for %%F in ("!URL!") do set "ARCHIVE_NAME=%%~nxF"
echo [download] Pre-downloading llvm %LLVM_VERSION% from !URL! to !DL_DIR!\!ARCHIVE_NAME!...
call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\pkg_mgr.cmd" :libscript_download "!URL!" "!DL_DIR!\!ARCHIVE_NAME!"
exit /b !errorlevel!

:: ## action_install
:: Installs llvm via from-source, system package manager, or libscript_native isolation.
:action_install
if /i "%LLVM_INSTALL_METHOD%"=="from-source" (
    call :resolve_version
    set "TARGET_DIR=%LIBSCRIPT_HOME%\llvm\!EXACT_VERSION!"
    set "SRC_URL=%LLVM_DOWNLOAD_URL%"
    if "!SRC_URL!"=="" set "SRC_URL=https://github.com/llvm/llvm-project/releases/download/llvmorg-{VERSION}/llvm-project-{VERSION}.src.tar.xz"
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\source_builder.cmd" :libscript_build_component_from_source "llvm" "!EXACT_VERSION!" "llvm-config" "c"
    exit /b !errorlevel!
)
if "%LLVM_INSTALL_METHOD%"=="system" (
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\pkg_mgr.cmd" :libscript_depends llvm
    exit /b !errorlevel!
)
call :resolve_version
set "TARGET_DIR=%LIBSCRIPT_HOME%\llvm\!EXACT_VERSION!"
if exist "!TARGET_DIR!\bin\llvm-config.exe" (
    if not "%FORCE_REINSTALL%"=="1" (
        echo [INFO] llvm !EXACT_VERSION! is already installed at !TARGET_DIR!.
        call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\versioning.cmd" :libscript_symlink_alias "llvm" "%LLVM_VERSION%" "!EXACT_VERSION!"
        call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\versioning.cmd" :libscript_symlink_alias "llvm" "default" "!EXACT_VERSION!"
        exit /b 0
    )
)
set "URL=%LLVM_DOWNLOAD_URL%"
if "!URL!"=="" set "URL=https://github.com/llvm/llvm-project/releases/download/llvmorg-{VERSION}/llvm-{VERSION}-windows.zip"
call set "URL=%%URL:{VERSION}=!EXACT_VERSION!%%"
if "!URL!"=="" (
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\pkg_mgr.cmd" :libscript_depends llvm
    exit /b !errorlevel!
)
if not exist "!TARGET_DIR!\bin" mkdir "!TARGET_DIR!\bin"
set "DL_DIR=%DOWNLOAD_DIR%"
if "!DL_DIR!"=="" set "DL_DIR=%TEMP%\libscript_downloads"
for %%F in ("!URL!") do set "ARCHIVE_NAME=%%~nxF"
set "CACHED_DL=!DL_DIR!\llvm\!ARCHIVE_NAME!"
if exist "!CACHED_DL!" (
    echo [install] Using cached archive !CACHED_DL!...
    set "TMP_FILE=!CACHED_DL!"
) else (
    set "TMP_FILE=%TEMP%\llvm-!RANDOM!.archive"
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\pkg_mgr.cmd" :libscript_download "!URL!" "!TMP_FILE!"
    if errorlevel 1 exit /b 1
)
if /i "!URL:~-4!"==".zip" (
    powershell -NoProfile -ExecutionPolicy Bypass -Command "Expand-Archive -LiteralPath '!TMP_FILE!' -DestinationPath '!TARGET_DIR!' -Force"
    if not exist "!TARGET_DIR!\bin\llvm-config.exe" (
        if exist "!TARGET_DIR!\llvm-config.exe" (
            move /y "!TARGET_DIR!\llvm-config.exe" "!TARGET_DIR!\bin\llvm-config.exe" >nul
        )
    )
) else (
    copy /y "!TMP_FILE!" "!TARGET_DIR!\bin\llvm-config.exe" >nul
)
if not "!TMP_FILE!"=="!CACHED_DL!" del /f /q "!TMP_FILE!" 2>nul
call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\versioning.cmd" :libscript_symlink_alias "llvm" "%LLVM_VERSION%" "!EXACT_VERSION!"
call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\versioning.cmd" :libscript_symlink_alias "llvm" "default" "!EXACT_VERSION!"
exit /b 0

:: ## resolve_version
:: Resolves latest or lts version alias into EXACT_VERSION.
:resolve_version
if /i "%LLVM_VERSION%"=="latest" goto :resolve_remote_gh_tag
if /i "%LLVM_VERSION%"=="lts" goto :resolve_remote_gh_tag
if /i "%LLVM_VERSION%"=="stable" goto :resolve_remote_gh_tag
set "EXACT_VERSION=%LLVM_VERSION%"
exit /b 0

:: ## resolve_remote_gh_tag
:: Queries GitHub Releases API for the latest tag with offline fallback.
:resolve_remote_gh_tag
set "EXACT_VERSION="
if not "llvm/llvm-project" == "" (
    for /f "delims=" %%T in ('call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\pkg_mgr.cmd" :libscript_resolve_github_tag "https://api.github.com/repos/llvm/llvm-project/releases/latest"') do (
        set "EXACT_VERSION=%%T"
    )
)
if "!EXACT_VERSION!"=="" set "EXACT_VERSION=19.1.6"
exit /b 0

:: ## action_other
:: Delegates service and lifecycle actions to setup_base.cmd.
:action_other
call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\setup_base.cmd" :libscript_handle_generic_action "llvm" "%ACTION%" "%LLVM_VERSION%" "%LLVM_INSTALL_METHOD%" "" "" "" "\"%LIBSCRIPT_HOME%\llvm\%LLVM_VERSION%\\bin\\llvm-config.exe\"" "%LIBSCRIPT_HOME%\llvm\%LLVM_VERSION%"
exit /b !errorlevel!
