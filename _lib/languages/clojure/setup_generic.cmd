@echo off
:: # setup_generic.cmd
:: ## Overview
:: Windows setup for clojure implementing the Version Manager Contract.
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
if "%CLOJURE_INSTALL_METHOD%"=="" (
    if not "%LIBSCRIPT_GLOBAL_INSTALL_METHOD%"=="" (
        set "CLOJURE_INSTALL_METHOD=%LIBSCRIPT_GLOBAL_INSTALL_METHOD%"
    ) else (
        set "CLOJURE_INSTALL_METHOD=libscript_native"
    )
)
if "%ACTION%"=="" set "ACTION=install"
if "%CLOJURE_VERSION%"=="" set "CLOJURE_VERSION=latest"

if "%ACTION%"=="ls" goto :action_ls
if "%ACTION%"=="ls-remote" goto :action_ls_remote
if "%ACTION%"=="use" goto :action_use
if "%ACTION%"=="download" goto :action_download
if "%ACTION%"=="install" goto :action_install
goto :action_other

:: ## action_ls
:: Lists locally installed versions of clojure.
:action_ls
if "%CLOJURE_INSTALL_METHOD%"=="libscript_native" (
    if exist "%LIBSCRIPT_HOME%\clojure" dir /b "%LIBSCRIPT_HOME%\clojure"
) else (
    where clojure >nul 2>&1 && clojure --version
)
exit /b 0

:: ## action_ls_remote
:: Queries available remote versions of clojure.
:action_ls_remote
set "RELEASES_URL=%CLOJURE_RELEASES_URL%"
if "!RELEASES_URL!"=="" set "RELEASES_URL=https://api.github.com/repos/clojure/brew-install/releases"
echo [ls-remote] Fetching available clojure versions from !RELEASES_URL!...
call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\pkg_mgr.cmd" :libscript_fetch_stdout "!RELEASES_URL!"
exit /b 0

:: ## action_use
:: Activates a specific installed version of clojure and updates alias junctions.
:action_use
call :resolve_version
set "TARGET_DIR=%LIBSCRIPT_HOME%\clojure\!EXACT_VERSION!"
if not exist "!TARGET_DIR!" (
    echo Version !EXACT_VERSION! not installed. Installing...
    set "ACTION=install"
    call "%~f0"
)
if exist "%LIBSCRIPT_HOME%\clojure\%CLOJURE_VERSION%" rmdir "%LIBSCRIPT_HOME%\clojure\%CLOJURE_VERSION%" 2>nul
mklink /J "%LIBSCRIPT_HOME%\clojure\%CLOJURE_VERSION%" "!TARGET_DIR!" >nul
if exist "%LIBSCRIPT_HOME%\clojure\default" rmdir "%LIBSCRIPT_HOME%\clojure\default" 2>nul
mklink /J "%LIBSCRIPT_HOME%\clojure\default" "!TARGET_DIR!" >nul
exit /b 0

:: ## action_download
:: Downloads the clojure release artifact to the local cache directory.
:action_download
call :resolve_version
set "URL=%CLOJURE_DOWNLOAD_URL%"
if "!URL!"=="" set "URL=https://github.com/clojure/brew-install/releases/download/{VERSION}/clojure-tools.zip"
set "DL_DIR=%DOWNLOAD_DIR%"
if "!DL_DIR!"=="" set "DL_DIR=%TEMP%\libscript_downloads"
set "DL_DIR=!DL_DIR!\clojure"
if not exist "!DL_DIR!" mkdir "!DL_DIR!"
for %%F in ("!URL!") do set "ARCHIVE_NAME=%%~nxF"
echo [download] Pre-downloading clojure %CLOJURE_VERSION% from !URL! to !DL_DIR!\!ARCHIVE_NAME!...
call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\pkg_mgr.cmd" :libscript_download "!URL!" "!DL_DIR!\!ARCHIVE_NAME!"
exit /b !errorlevel!

:: ## action_install
:: Installs clojure via from-source, system package manager, or libscript_native isolation.
:action_install
if /i "%CLOJURE_INSTALL_METHOD%"=="from-source" (
    call :resolve_version
    set "TARGET_DIR=%LIBSCRIPT_HOME%\clojure\!EXACT_VERSION!"
    set "SRC_URL=%CLOJURE_DOWNLOAD_URL%"
    if "!SRC_URL!"=="" set "SRC_URL=https://github.com/clojure/brew-install/archive/refs/tags/{VERSION}.tar.gz"
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\source_builder.cmd" :libscript_build_component_from_source "clojure" "!EXACT_VERSION!" "clojure" "c"
    exit /b !errorlevel!
)
if "%CLOJURE_INSTALL_METHOD%"=="system" (
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\pkg_mgr.cmd" :libscript_depends clojure
    exit /b !errorlevel!
)
if /i "%CLOJURE_INSTALL_METHOD%"=="winget" (
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\pkg_mgr.cmd" :libscript_depends_via winget clojure
    exit /b !errorlevel!
)
if /i "%CLOJURE_INSTALL_METHOD%"=="choco" (
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\pkg_mgr.cmd" :libscript_depends_via choco clojure
    exit /b !errorlevel!
)
if /i "%CLOJURE_INSTALL_METHOD%"=="scoop" (
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\pkg_mgr.cmd" :libscript_depends_via scoop clojure
    exit /b !errorlevel!
)
call :resolve_version
set "TARGET_DIR=%LIBSCRIPT_HOME%\clojure\!EXACT_VERSION!"
set "_BIN_FOUND=0"
if exist "!TARGET_DIR!\bin\clojure.exe" set "_BIN_FOUND=1"
if exist "!TARGET_DIR!\bin\clojure.cmd" set "_BIN_FOUND=1"
if exist "!TARGET_DIR!\bin\clojure.bat" set "_BIN_FOUND=1"
if "!_BIN_FOUND!"=="1" (
    if not "%FORCE_REINSTALL%"=="1" (
        echo [INFO] clojure !EXACT_VERSION! is already installed at !TARGET_DIR!.
        call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\versioning.cmd" :libscript_symlink_alias "clojure" "%CLOJURE_VERSION%" "!EXACT_VERSION!"
        call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\versioning.cmd" :libscript_symlink_alias "clojure" "default" "!EXACT_VERSION!"
        exit /b 0
    )
)
set "URL=%CLOJURE_DOWNLOAD_URL%"
if "!URL!"=="" set "URL=https://github.com/clojure/brew-install/releases/download/{VERSION}/clojure-tools.zip"
call set "URL=%%URL:{VERSION}=!EXACT_VERSION!%%"
if "!URL!"=="" (
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\pkg_mgr.cmd" :libscript_depends clojure
    exit /b !errorlevel!
)
if not exist "!TARGET_DIR!\bin" mkdir "!TARGET_DIR!\bin"
set "DL_DIR=%DOWNLOAD_DIR%"
if "!DL_DIR!"=="" set "DL_DIR=%TEMP%\libscript_downloads"
for %%F in ("!URL!") do set "ARCHIVE_NAME=%%~nxF"
set "CACHED_DL=!DL_DIR!\clojure\!ARCHIVE_NAME!"
if exist "!CACHED_DL!" (
    echo [install] Using cached archive !CACHED_DL!...
    set "TMP_FILE=!CACHED_DL!"
) else (
    set "TMP_FILE=%TEMP%\clojure-!RANDOM!.archive"
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\pkg_mgr.cmd" :libscript_download "!URL!" "!TMP_FILE!"
    if errorlevel 1 exit /b 1
)
if /i "!URL:~-4!"==".zip" (
    powershell -NoProfile -ExecutionPolicy Bypass -Command "Expand-Archive -LiteralPath '!TMP_FILE!' -DestinationPath '!TARGET_DIR!' -Force"
    for /d %%D in ("!TARGET_DIR!\*") do (
        if /i not "%%~nxD"=="bin" (
            set "_DO_FLAT=0"
            if exist "%%~fD\bin\clojure.exe" set "_DO_FLAT=1"
            if exist "%%~fD\bin\clojure.bat" set "_DO_FLAT=1"
            if exist "%%~fD\bin\clojure.cmd" set "_DO_FLAT=1"
            if exist "%%~fD\clojure.exe" set "_DO_FLAT=1"
            if exist "%%~fD\clojure.cmd" set "_DO_FLAT=1"
            if exist "%%~fD\clojure.bat" set "_DO_FLAT=1"
            if "!_DO_FLAT!"=="1" (
                move /y "%%~fD" "!TARGET_DIR!_flat" >nul
                xcopy /E /I /Y "!TARGET_DIR!_flat\*" "!TARGET_DIR!\" >nul
                rmdir /s /q "!TARGET_DIR!_flat"
            )
        )
    )
    if not exist "!TARGET_DIR!\bin\clojure.exe" (
        if exist "!TARGET_DIR!\clojure.exe" (
            copy /y "!TARGET_DIR!\clojure.exe" "!TARGET_DIR!\bin\clojure.exe" >nul
        )
    )
    if not exist "!TARGET_DIR!\bin\clojure.cmd" (
        if exist "!TARGET_DIR!\clojure.cmd" (
            copy /y "!TARGET_DIR!\clojure.cmd" "!TARGET_DIR!\bin\clojure.cmd" >nul
        )
    )
    if not exist "!TARGET_DIR!\bin\clojure.bat" (
        if exist "!TARGET_DIR!\clojure.bat" (
            copy /y "!TARGET_DIR!\clojure.bat" "!TARGET_DIR!\bin\clojure.bat" >nul
        )
    )
) else (
    copy /y "!TMP_FILE!" "!TARGET_DIR!\bin\clojure.exe" >nul
)
if not "!TMP_FILE!"=="!CACHED_DL!" del /f /q "!TMP_FILE!" 2>nul
call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\versioning.cmd" :libscript_symlink_alias "clojure" "%CLOJURE_VERSION%" "!EXACT_VERSION!"
call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\versioning.cmd" :libscript_symlink_alias "clojure" "default" "!EXACT_VERSION!"
exit /b 0

:: ## resolve_version
:: Resolves latest or lts version alias into EXACT_VERSION.
:resolve_version
if /i "%CLOJURE_VERSION%"=="latest" goto :resolve_remote_gh_tag
if /i "%CLOJURE_VERSION%"=="lts" goto :resolve_remote_gh_tag
if /i "%CLOJURE_VERSION%"=="stable" goto :resolve_remote_gh_tag
set "EXACT_VERSION=%CLOJURE_VERSION%"
exit /b 0

:: ## resolve_remote_gh_tag
:: Queries GitHub Releases API for the latest tag with offline fallback.
:resolve_remote_gh_tag
set "EXACT_VERSION="
if not "clojure/brew-install" == "" (
    for /f "delims=" %%T in ('call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\pkg_mgr.cmd" :libscript_resolve_github_tag "https://api.github.com/repos/clojure/brew-install/releases/latest"') do (
        set "EXACT_VERSION=%%T"
    )
)
if not "" == "" (
    if not "!EXACT_VERSION!"=="" set "EXACT_VERSION=!EXACT_VERSION:=!"
)
if "!EXACT_VERSION!"=="" set "EXACT_VERSION=1.12.0.1488"
exit /b 0

:: ## action_other
:: Delegates service and lifecycle actions to setup_base.cmd.
:action_other
call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\setup_base.cmd" :libscript_handle_generic_action "clojure" "%ACTION%" "%CLOJURE_VERSION%" "%CLOJURE_INSTALL_METHOD%" "" "" "" "\"%LIBSCRIPT_HOME%\clojure\%CLOJURE_VERSION%\\bin\\clojure.exe\"" "%LIBSCRIPT_HOME%\clojure\%CLOJURE_VERSION%"
exit /b !errorlevel!
