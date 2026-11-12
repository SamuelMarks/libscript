@echo off
:: # setup_generic.cmd
:: ## Overview
:: Windows setup for tailscale implementing the Version Manager Contract.
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
if "%TAILSCALE_INSTALL_METHOD%"=="" (
    if not "%LIBSCRIPT_GLOBAL_INSTALL_METHOD%"=="" (
        set "TAILSCALE_INSTALL_METHOD=%LIBSCRIPT_GLOBAL_INSTALL_METHOD%"
    ) else (
        set "TAILSCALE_INSTALL_METHOD=libscript_native"
    )
)
if "%ACTION%"=="" set "ACTION=install"
if "%TAILSCALE_VERSION%"=="" set "TAILSCALE_VERSION=latest"

if "%ACTION%"=="ls" goto :action_ls
if "%ACTION%"=="ls-remote" goto :action_ls_remote
if "%ACTION%"=="use" goto :action_use
if "%ACTION%"=="download" goto :action_download
if "%ACTION%"=="install" goto :action_install
goto :action_other

:: ## action_ls
:: Lists locally installed versions of tailscale.
:action_ls
if "%TAILSCALE_INSTALL_METHOD%"=="libscript_native" (
    if exist "%LIBSCRIPT_HOME%\tailscale" dir /b "%LIBSCRIPT_HOME%\tailscale"
) else (
    where tailscale >nul 2>&1 && tailscale --version
)
exit /b 0

:: ## action_ls_remote
:: Queries available remote versions of tailscale.
:action_ls_remote
set "RELEASES_URL=%TAILSCALE_RELEASES_URL%"
if "!RELEASES_URL!"=="" set "RELEASES_URL=https://pkgs.tailscale.com/stable/"
echo [ls-remote] Fetching available tailscale versions from !RELEASES_URL!...
call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\pkg_mgr.cmd" :libscript_fetch_stdout "!RELEASES_URL!"
exit /b 0

:: ## action_use
:: Activates a specific installed version of tailscale and updates alias junctions.
:action_use
call :resolve_version
set "TARGET_DIR=%LIBSCRIPT_HOME%\tailscale\!EXACT_VERSION!"
if not exist "!TARGET_DIR!" (
    echo Version !EXACT_VERSION! not installed. Installing...
    set "ACTION=install"
    call "%~f0"
)
call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\versioning.cmd" :libscript_symlink_alias "tailscale" "%TAILSCALE_VERSION%" "!EXACT_VERSION!"
call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\versioning.cmd" :libscript_symlink_alias "tailscale" "default" "!EXACT_VERSION!"
exit /b 0

:: ## action_download
:: Downloads the tailscale release artifact to the local cache directory.
:action_download
call :resolve_version
set "URL=%TAILSCALE_DOWNLOAD_URL%"
if "!URL!"=="" set "URL=https://pkgs.tailscale.com/stable/tailscale-setup-{VERSION}-amd64.msi"
call set "URL=%%URL:{VERSION}=!EXACT_VERSION!%%"
set "DL_DIR=%DOWNLOAD_DIR%"
if "!DL_DIR!"=="" set "DL_DIR=%TEMP%\libscript_downloads"
set "DL_DIR=!DL_DIR!\tailscale"
if not exist "!DL_DIR!" mkdir "!DL_DIR!"
for %%F in ("!URL!") do set "ARCHIVE_NAME=%%~nxF"
echo [download] Pre-downloading tailscale %TAILSCALE_VERSION% from !URL! to !DL_DIR!\!ARCHIVE_NAME!...
call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\pkg_mgr.cmd" :libscript_download "!URL!" "!DL_DIR!\!ARCHIVE_NAME!"
exit /b !errorlevel!

:: ## action_install
:: Installs tailscale via from-source, system package manager, or libscript_native isolation.
:action_install
if /i "%TAILSCALE_INSTALL_METHOD%"=="from-source" (
    call :resolve_version
    set "TARGET_DIR=%LIBSCRIPT_HOME%\tailscale\!EXACT_VERSION!"
    set "SRC_URL=%TAILSCALE_DOWNLOAD_URL%"
    if "!SRC_URL!"=="" set "SRC_URL=https://pkgs.tailscale.com/stable/tailscale_{VERSION}_{ARCH_GO}.tgz"
    call set "SRC_URL=%%SRC_URL:{VERSION}=!EXACT_VERSION!%%"
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\source_builder.cmd" :libscript_build_component_from_source "tailscale" "!EXACT_VERSION!" "tailscale" "go" "go" "!SRC_URL!"
    exit /b !errorlevel!
)
if "%TAILSCALE_INSTALL_METHOD%"=="system" (
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\pkg_mgr.cmd" :libscript_depends tailscale
    exit /b !errorlevel!
)
if /i "%TAILSCALE_INSTALL_METHOD%"=="winget" (
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\pkg_mgr.cmd" :libscript_depends_via winget tailscale
    exit /b !errorlevel!
)
if /i "%TAILSCALE_INSTALL_METHOD%"=="choco" (
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\pkg_mgr.cmd" :libscript_depends_via choco tailscale
    exit /b !errorlevel!
)
if /i "%TAILSCALE_INSTALL_METHOD%"=="scoop" (
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\pkg_mgr.cmd" :libscript_depends_via scoop tailscale
    exit /b !errorlevel!
)
call :resolve_version
set "TARGET_DIR=%LIBSCRIPT_HOME%\tailscale\!EXACT_VERSION!"
set "_BIN_FOUND=0"
if exist "!TARGET_DIR!\bin\tailscale.exe" set "_BIN_FOUND=1"
if exist "!TARGET_DIR!\bin\tailscale.cmd" set "_BIN_FOUND=1"
if exist "!TARGET_DIR!\bin\tailscale.bat" set "_BIN_FOUND=1"
if "!_BIN_FOUND!"=="1" (
    if not "%FORCE_REINSTALL%"=="1" (
        echo [INFO] tailscale !EXACT_VERSION! is already installed at !TARGET_DIR!.
        call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\versioning.cmd" :libscript_symlink_alias "tailscale" "%TAILSCALE_VERSION%" "!EXACT_VERSION!"
        call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\versioning.cmd" :libscript_symlink_alias "tailscale" "default" "!EXACT_VERSION!"
        exit /b 0
    )
)
set "URL=%TAILSCALE_DOWNLOAD_URL%"
if "!URL!"=="" set "URL=https://pkgs.tailscale.com/stable/tailscale-setup-{VERSION}-amd64.msi"
call set "URL=%%URL:{VERSION}=!EXACT_VERSION!%%"
if "!URL!"=="" (
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\pkg_mgr.cmd" :libscript_depends tailscale
    exit /b !errorlevel!
)
if not exist "!TARGET_DIR!\bin" mkdir "!TARGET_DIR!\bin"
set "DL_DIR=%DOWNLOAD_DIR%"
if "!DL_DIR!"=="" set "DL_DIR=%TEMP%\libscript_downloads"
for %%F in ("!URL!") do set "ARCHIVE_NAME=%%~nxF"
set "CACHED_DL=!DL_DIR!\tailscale\!ARCHIVE_NAME!"
if exist "!CACHED_DL!" (
    echo [install] Using cached archive !CACHED_DL!...
    set "TMP_FILE=!CACHED_DL!"
) else (
    set "TMP_FILE=%TEMP%\tailscale-!RANDOM!.archive"
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\pkg_mgr.cmd" :libscript_download "!URL!" "!TMP_FILE!"
    if errorlevel 1 exit /b 1
)
set "_IS_ARCHIVE=0"
if /i "!URL:~-4!"==".zip" set "_IS_ARCHIVE=zip"
if /i "!URL:~-7!"==".tar.gz" set "_IS_ARCHIVE=tar"
if /i "!URL:~-4!"==".tgz" set "_IS_ARCHIVE=tar"
if /i "!URL:~-7!"==".tar.xz" set "_IS_ARCHIVE=tar"
if /i "!URL:~-4!"==".txz" set "_IS_ARCHIVE=tar"
if /i "!URL:~-8!"==".tar.bz2" set "_IS_ARCHIVE=tar"
if /i "!URL:~-5!"==".tbz2" set "_IS_ARCHIVE=tar"
if not "!_IS_ARCHIVE!"=="0" (
    if "!_IS_ARCHIVE!"=="zip" (
        powershell -NoProfile -ExecutionPolicy Bypass -Command "Expand-Archive -LiteralPath '!TMP_FILE!' -DestinationPath '!TARGET_DIR!' -Force"
    ) else (
        tar -xf "!TMP_FILE!" -C "!TARGET_DIR!" --strip-components=1 2>nul || tar -xf "!TMP_FILE!" -C "!TARGET_DIR!"
    )
    for /d %%D in ("!TARGET_DIR!\*") do (
        if /i not "%%~nxD"=="bin" (
            set "_DO_FLAT=0"
            if exist "%%~fD\bin\tailscale.exe" set "_DO_FLAT=1"
            if exist "%%~fD\bin\tailscale.bat" set "_DO_FLAT=1"
            if exist "%%~fD\bin\tailscale.cmd" set "_DO_FLAT=1"
            if exist "%%~fD\tailscale.exe" set "_DO_FLAT=1"
            if exist "%%~fD\tailscale.cmd" set "_DO_FLAT=1"
            if exist "%%~fD\tailscale.bat" set "_DO_FLAT=1"
            if "!_DO_FLAT!"=="1" (
                move /y "%%~fD" "!TARGET_DIR!_flat" >nul
                xcopy /E /I /Y "!TARGET_DIR!_flat\*" "!TARGET_DIR!\" >nul
                rmdir /s /q "!TARGET_DIR!_flat"
            )
        )
    )
    if not exist "!TARGET_DIR!\bin\tailscale.exe" (
        if exist "!TARGET_DIR!\tailscale.exe" (
            copy /y "!TARGET_DIR!\tailscale.exe" "!TARGET_DIR!\bin\tailscale.exe" >nul
        )
    )
    if not exist "!TARGET_DIR!\bin\tailscale.cmd" (
        if exist "!TARGET_DIR!\tailscale.cmd" (
            copy /y "!TARGET_DIR!\tailscale.cmd" "!TARGET_DIR!\bin\tailscale.cmd" >nul
        )
    )
    if not exist "!TARGET_DIR!\bin\tailscale.bat" (
        if exist "!TARGET_DIR!\tailscale.bat" (
            copy /y "!TARGET_DIR!\tailscale.bat" "!TARGET_DIR!\bin\tailscale.bat" >nul
        )
    )
) else (
    copy /y "!TMP_FILE!" "!TARGET_DIR!\bin\tailscale.exe" >nul
)
if not "!TMP_FILE!"=="!CACHED_DL!" del /f /q "!TMP_FILE!" 2>nul
call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\versioning.cmd" :libscript_symlink_alias "tailscale" "%TAILSCALE_VERSION%" "!EXACT_VERSION!"
call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\versioning.cmd" :libscript_symlink_alias "tailscale" "default" "!EXACT_VERSION!"
exit /b 0

:: ## resolve_version
:: Resolves latest or lts version alias into EXACT_VERSION.
:resolve_version
if /i "%TAILSCALE_VERSION%"=="latest" goto :resolve_remote_gh_tag
if /i "%TAILSCALE_VERSION%"=="lts" goto :resolve_remote_gh_tag
if /i "%TAILSCALE_VERSION%"=="stable" goto :resolve_remote_gh_tag
set "EXACT_VERSION=%TAILSCALE_VERSION%"
exit /b 0

:: ## resolve_remote_gh_tag
:: Queries GitHub Releases API for the latest tag with offline fallback.
:resolve_remote_gh_tag
set "EXACT_VERSION="
if not "tailscale/tailscale" == "" (
    for /f "delims=" %%T in ('call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\pkg_mgr.cmd" :libscript_resolve_github_tag "https://api.github.com/repos/tailscale/tailscale/releases/latest"') do (
        set "EXACT_VERSION=%%T"
    )
)
if not "v" == "" (
    if not "!EXACT_VERSION!"=="" set "EXACT_VERSION=!EXACT_VERSION:v=!"
)
if "!EXACT_VERSION!"=="" set "EXACT_VERSION=1.78.1"
exit /b 0

:: ## action_other
:: Delegates service and lifecycle actions to setup_base.cmd.
:action_other
call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\setup_base.cmd" :libscript_handle_generic_action "tailscale" "%ACTION%" "%TAILSCALE_VERSION%" "%TAILSCALE_INSTALL_METHOD%" "" "" "" "\"%LIBSCRIPT_HOME%\tailscale\%TAILSCALE_VERSION%\\bin\\tailscale.exe\"" "%LIBSCRIPT_HOME%\tailscale\%TAILSCALE_VERSION%"
exit /b !errorlevel!
