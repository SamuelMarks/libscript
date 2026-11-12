@echo off
:: # setup_generic.cmd
:: ## Overview
:: Windows setup for grub implementing the Version Manager Contract.
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
if "%GRUB_INSTALL_METHOD%"=="" (
    if not "%LIBSCRIPT_GLOBAL_INSTALL_METHOD%"=="" (
        set "GRUB_INSTALL_METHOD=%LIBSCRIPT_GLOBAL_INSTALL_METHOD%"
    ) else (
        set "GRUB_INSTALL_METHOD=libscript_native"
    )
)
if "%ACTION%"=="" set "ACTION=install"
if "%GRUB_VERSION%"=="" set "GRUB_VERSION=latest"

if "%ACTION%"=="ls" goto :action_ls
if "%ACTION%"=="ls-remote" goto :action_ls_remote
if "%ACTION%"=="use" goto :action_use
if "%ACTION%"=="download" goto :action_download
if "%ACTION%"=="install" goto :action_install
goto :action_other

:: ## action_ls
:: Lists locally installed versions of grub.
:action_ls
if "%GRUB_INSTALL_METHOD%"=="libscript_native" (
    if exist "%LIBSCRIPT_HOME%\grub" dir /b "%LIBSCRIPT_HOME%\grub"
) else (
    where grub-install >nul 2>&1 && grub-install --version
)
exit /b 0

:: ## action_ls_remote
:: Queries available remote versions of grub.
:action_ls_remote
set "RELEASES_URL=%GRUB_RELEASES_URL%"
if "!RELEASES_URL!"=="" set "RELEASES_URL=https://ftp.gnu.org/gnu/grub/"
echo [ls-remote] Fetching available grub versions from !RELEASES_URL!...
call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\pkg_mgr.cmd" :libscript_fetch_stdout "!RELEASES_URL!"
exit /b 0

:: ## action_use
:: Activates a specific installed version of grub and updates alias junctions.
:action_use
call :resolve_version
set "TARGET_DIR=%LIBSCRIPT_HOME%\grub\!EXACT_VERSION!"
if not exist "!TARGET_DIR!" (
    echo Version !EXACT_VERSION! not installed. Installing...
    set "ACTION=install"
    call "%~f0"
)
call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\versioning.cmd" :libscript_symlink_alias "grub" "%GRUB_VERSION%" "!EXACT_VERSION!"
call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\versioning.cmd" :libscript_symlink_alias "grub" "default" "!EXACT_VERSION!"
exit /b 0

:: ## action_download
:: Downloads the grub release artifact to the local cache directory.
:action_download
call :resolve_version
set "URL=%GRUB_DOWNLOAD_URL%"
if "!URL!"=="" set "URL=https://ftp.gnu.org/gnu/grub/grub-{VERSION}.tar.xz"
call set "URL=%%URL:{VERSION}=!EXACT_VERSION!%%"
set "DL_DIR=%DOWNLOAD_DIR%"
if "!DL_DIR!"=="" set "DL_DIR=%TEMP%\libscript_downloads"
set "DL_DIR=!DL_DIR!\grub"
if not exist "!DL_DIR!" mkdir "!DL_DIR!"
for %%F in ("!URL!") do set "ARCHIVE_NAME=%%~nxF"
echo [download] Pre-downloading grub %GRUB_VERSION% from !URL! to !DL_DIR!\!ARCHIVE_NAME!...
call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\pkg_mgr.cmd" :libscript_download "!URL!" "!DL_DIR!\!ARCHIVE_NAME!"
exit /b !errorlevel!

:: ## action_install
:: Installs grub via from-source, system package manager, or libscript_native isolation.
:action_install
call :stage_grub_sysroot
if /i "%GRUB_INSTALL_METHOD%"=="from-source" (
    call :resolve_version
    set "TARGET_DIR=%LIBSCRIPT_HOME%\grub\!EXACT_VERSION!"
    set "SRC_URL=%GRUB_DOWNLOAD_URL%"
    if "!SRC_URL!"=="" set "SRC_URL=https://ftp.gnu.org/gnu/grub/grub-{VERSION}.tar.xz"
    call set "SRC_URL=%%SRC_URL:{VERSION}=!EXACT_VERSION!%%"
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\source_builder.cmd" :libscript_build_component_from_source "grub" "!EXACT_VERSION!" "grub-install" "c" "autotools" "!SRC_URL!"
    exit /b !errorlevel!
)
if "%GRUB_INSTALL_METHOD%"=="system" (
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\pkg_mgr.cmd" :libscript_depends grub
    exit /b !errorlevel!
)
if /i "%GRUB_INSTALL_METHOD%"=="winget" (
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\pkg_mgr.cmd" :libscript_depends_via winget grub
    exit /b !errorlevel!
)
if /i "%GRUB_INSTALL_METHOD%"=="choco" (
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\pkg_mgr.cmd" :libscript_depends_via choco grub
    exit /b !errorlevel!
)
if /i "%GRUB_INSTALL_METHOD%"=="scoop" (
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\pkg_mgr.cmd" :libscript_depends_via scoop grub
    exit /b !errorlevel!
)
call :resolve_version
set "TARGET_DIR=%LIBSCRIPT_HOME%\grub\!EXACT_VERSION!"
set "_BIN_FOUND=0"
if exist "!TARGET_DIR!\bin\grub-install.exe" set "_BIN_FOUND=1"
if exist "!TARGET_DIR!\bin\grub-install.cmd" set "_BIN_FOUND=1"
if exist "!TARGET_DIR!\bin\grub-install.bat" set "_BIN_FOUND=1"
if "!_BIN_FOUND!"=="1" (
    if not "%FORCE_REINSTALL%"=="1" (
        echo [INFO] grub !EXACT_VERSION! is already installed at !TARGET_DIR!.
        call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\versioning.cmd" :libscript_symlink_alias "grub" "%GRUB_VERSION%" "!EXACT_VERSION!"
        call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\versioning.cmd" :libscript_symlink_alias "grub" "default" "!EXACT_VERSION!"
        exit /b 0
    )
)
set "URL=%GRUB_DOWNLOAD_URL%"
if "!URL!"=="" set "URL=https://ftp.gnu.org/gnu/grub/grub-{VERSION}.tar.xz"
call set "URL=%%URL:{VERSION}=!EXACT_VERSION!%%"
if "!URL!"=="" (
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\pkg_mgr.cmd" :libscript_depends grub
    exit /b !errorlevel!
)
if not exist "!TARGET_DIR!\bin" mkdir "!TARGET_DIR!\bin"
set "DL_DIR=%DOWNLOAD_DIR%"
if "!DL_DIR!"=="" set "DL_DIR=%TEMP%\libscript_downloads"
for %%F in ("!URL!") do set "ARCHIVE_NAME=%%~nxF"
set "CACHED_DL=!DL_DIR!\grub\!ARCHIVE_NAME!"
if exist "!CACHED_DL!" (
    echo [install] Using cached archive !CACHED_DL!...
    set "TMP_FILE=!CACHED_DL!"
) else (
    set "TMP_FILE=%TEMP%\grub-!RANDOM!.archive"
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
            if exist "%%~fD\bin\grub-install.exe" set "_DO_FLAT=1"
            if exist "%%~fD\bin\grub-install.bat" set "_DO_FLAT=1"
            if exist "%%~fD\bin\grub-install.cmd" set "_DO_FLAT=1"
            if exist "%%~fD\grub-install.exe" set "_DO_FLAT=1"
            if exist "%%~fD\grub-install.cmd" set "_DO_FLAT=1"
            if exist "%%~fD\grub-install.bat" set "_DO_FLAT=1"
            if "!_DO_FLAT!"=="1" (
                move /y "%%~fD" "!TARGET_DIR!_flat" >nul
                xcopy /E /I /Y "!TARGET_DIR!_flat\*" "!TARGET_DIR!\" >nul
                rmdir /s /q "!TARGET_DIR!_flat"
            )
        )
    )
    if not exist "!TARGET_DIR!\bin\grub-install.exe" (
        if exist "!TARGET_DIR!\grub-install.exe" (
            copy /y "!TARGET_DIR!\grub-install.exe" "!TARGET_DIR!\bin\grub-install.exe" >nul
        )
    )
    if not exist "!TARGET_DIR!\bin\grub-install.cmd" (
        if exist "!TARGET_DIR!\grub-install.cmd" (
            copy /y "!TARGET_DIR!\grub-install.cmd" "!TARGET_DIR!\bin\grub-install.cmd" >nul
        )
    )
    if not exist "!TARGET_DIR!\bin\grub-install.bat" (
        if exist "!TARGET_DIR!\grub-install.bat" (
            copy /y "!TARGET_DIR!\grub-install.bat" "!TARGET_DIR!\bin\grub-install.bat" >nul
        )
    )
) else (
    copy /y "!TMP_FILE!" "!TARGET_DIR!\bin\grub-install.exe" >nul
)
if not "!TMP_FILE!"=="!CACHED_DL!" del /f /q "!TMP_FILE!" 2>nul
call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\versioning.cmd" :libscript_symlink_alias "grub" "%GRUB_VERSION%" "!EXACT_VERSION!"
call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\versioning.cmd" :libscript_symlink_alias "grub" "default" "!EXACT_VERSION!"
exit /b 0

:: ## resolve_version
:: Resolves latest or lts version alias into EXACT_VERSION.
:resolve_version
if /i "%GRUB_VERSION%"=="latest" goto :resolve_remote_gh_tag
if /i "%GRUB_VERSION%"=="lts" goto :resolve_remote_gh_tag
if /i "%GRUB_VERSION%"=="stable" goto :resolve_remote_gh_tag
set "EXACT_VERSION=%GRUB_VERSION%"
exit /b 0

:: ## resolve_remote_gh_tag
:: Queries GitHub Releases API for the latest tag with offline fallback.
:resolve_remote_gh_tag
set "EXACT_VERSION="
if not "" == "" (
    for /f "delims=" %%T in ('call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\pkg_mgr.cmd" :libscript_resolve_github_tag "https://api.github.com/repos//releases/latest"') do (
        set "EXACT_VERSION=%%T"
    )
)
if not "v" == "" (
    if not "!EXACT_VERSION!"=="" set "EXACT_VERSION=!EXACT_VERSION:v=!"
)
if "!EXACT_VERSION!"=="" set "EXACT_VERSION=2.12"
exit /b 0

:: ## stage_grub_sysroot
:: Stages default /boot/grub/grub.cfg into LIBSCRIPT_TARGET_SYSROOT when configured.
:stage_grub_sysroot
if "%LIBSCRIPT_TARGET_SYSROOT%"=="" exit /b 0
if not exist "%LIBSCRIPT_TARGET_SYSROOT%\boot\grub" mkdir "%LIBSCRIPT_TARGET_SYSROOT%\boot\grub"
if not exist "%LIBSCRIPT_TARGET_SYSROOT%\var\lib\libscript\stamps" mkdir "%LIBSCRIPT_TARGET_SYSROOT%\var\lib\libscript\stamps"
if not exist "%LIBSCRIPT_TARGET_SYSROOT%\boot\grub\grub.cfg" (
    > "%LIBSCRIPT_TARGET_SYSROOT%\boot\grub\grub.cfg" echo set default=0
    >> "%LIBSCRIPT_TARGET_SYSROOT%\boot\grub\grub.cfg" echo set timeout=3
)
> "%LIBSCRIPT_TARGET_SYSROOT%\var\lib\libscript\stamps\.stamp.grub" echo staged
exit /b 0

:: ## action_other
:: Delegates service and lifecycle actions to setup_base.cmd.
:action_other
call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\setup_base.cmd" :libscript_handle_generic_action "grub" "%ACTION%" "%GRUB_VERSION%" "%GRUB_INSTALL_METHOD%" "" "" "" "\"%LIBSCRIPT_HOME%\grub\%GRUB_VERSION%\\bin\\grub-install.exe\"" "%LIBSCRIPT_HOME%\grub\%GRUB_VERSION%"
exit /b !errorlevel!
