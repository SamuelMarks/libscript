@echo off
:: # setup_generic.cmd
:: ## Overview
:: Windows setup for locales implementing the Version Manager Contract.
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
if "%LOCALES_INSTALL_METHOD%"=="" (
    if not "%LIBSCRIPT_GLOBAL_INSTALL_METHOD%"=="" (
        set "LOCALES_INSTALL_METHOD=%LIBSCRIPT_GLOBAL_INSTALL_METHOD%"
    ) else (
        set "LOCALES_INSTALL_METHOD=libscript_native"
    )
)
if "%ACTION%"=="" set "ACTION=install"
if "%LOCALES_VERSION%"=="" set "LOCALES_VERSION=latest"

if "%ACTION%"=="ls" goto :action_ls
if "%ACTION%"=="ls-remote" goto :action_ls_remote
if "%ACTION%"=="use" goto :action_use
if "%ACTION%"=="download" goto :action_download
if "%ACTION%"=="install" goto :action_install
goto :action_other

:: ## action_ls
:: Lists locally installed versions of locales.
:action_ls
if "%LOCALES_INSTALL_METHOD%"=="libscript_native" (
    if exist "%LIBSCRIPT_HOME%\locales" dir /b "%LIBSCRIPT_HOME%\locales"
) else (
    where localedef >nul 2>&1 && localedef --version
)
exit /b 0

:: ## action_ls_remote
:: Queries available remote versions of locales.
:action_ls_remote
set "RELEASES_URL=%LOCALES_RELEASES_URL%"
if "!RELEASES_URL!"=="" set "RELEASES_URL=https://ftp.gnu.org/gnu/glibc/"
echo [ls-remote] Fetching available locales versions from !RELEASES_URL!...
call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\pkg_mgr.cmd" :libscript_fetch_stdout "!RELEASES_URL!"
exit /b 0

:: ## action_use
:: Activates a specific installed version of locales and updates alias junctions.
:action_use
call :resolve_version
set "TARGET_DIR=%LIBSCRIPT_HOME%\locales\!EXACT_VERSION!"
if not exist "!TARGET_DIR!" (
    echo Version !EXACT_VERSION! not installed. Installing...
    set "ACTION=install"
    call "%~f0"
)
call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\versioning.cmd" :libscript_symlink_alias "locales" "%LOCALES_VERSION%" "!EXACT_VERSION!"
call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\versioning.cmd" :libscript_symlink_alias "locales" "default" "!EXACT_VERSION!"
exit /b 0

:: ## action_download
:: Downloads the locales release artifact to the local cache directory.
:action_download
call :resolve_version
set "URL=%LOCALES_DOWNLOAD_URL%"
if "!URL!"=="" set "URL=https://ftp.gnu.org/gnu/glibc/glibc-{VERSION}.tar.xz"
call set "URL=%%URL:{VERSION}=!EXACT_VERSION!%%"
set "DL_DIR=%DOWNLOAD_DIR%"
if "!DL_DIR!"=="" set "DL_DIR=%TEMP%\libscript_downloads"
set "DL_DIR=!DL_DIR!\locales"
if not exist "!DL_DIR!" mkdir "!DL_DIR!"
for %%F in ("!URL!") do set "ARCHIVE_NAME=%%~nxF"
echo [download] Pre-downloading locales %LOCALES_VERSION% from !URL! to !DL_DIR!\!ARCHIVE_NAME!...
call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\pkg_mgr.cmd" :libscript_download "!URL!" "!DL_DIR!\!ARCHIVE_NAME!"
exit /b !errorlevel!

:: ## action_install
:: Installs locales via from-source, system package manager, or libscript_native isolation.
:action_install
call :stage_locales_sysroot
if /i "%LOCALES_INSTALL_METHOD%"=="from-source" (
    call :resolve_version
    set "TARGET_DIR=%LIBSCRIPT_HOME%\locales\!EXACT_VERSION!"
    set "SRC_URL=%LOCALES_DOWNLOAD_URL%"
    if "!SRC_URL!"=="" set "SRC_URL=https://ftp.gnu.org/gnu/glibc/glibc-{VERSION}.tar.xz"
    call set "SRC_URL=%%SRC_URL:{VERSION}=!EXACT_VERSION!%%"
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\source_builder.cmd" :libscript_build_component_from_source "locales" "!EXACT_VERSION!" "localedef" "c" "autotools" "!SRC_URL!"
    exit /b !errorlevel!
)
if "%LOCALES_INSTALL_METHOD%"=="system" (
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\pkg_mgr.cmd" :libscript_depends locales
    exit /b !errorlevel!
)
if /i "%LOCALES_INSTALL_METHOD%"=="winget" (
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\pkg_mgr.cmd" :libscript_depends_via winget locales
    exit /b !errorlevel!
)
if /i "%LOCALES_INSTALL_METHOD%"=="choco" (
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\pkg_mgr.cmd" :libscript_depends_via choco locales
    exit /b !errorlevel!
)
if /i "%LOCALES_INSTALL_METHOD%"=="scoop" (
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\pkg_mgr.cmd" :libscript_depends_via scoop locales
    exit /b !errorlevel!
)
call :resolve_version
set "TARGET_DIR=%LIBSCRIPT_HOME%\locales\!EXACT_VERSION!"
set "_BIN_FOUND=0"
if exist "!TARGET_DIR!\bin\localedef.exe" set "_BIN_FOUND=1"
if exist "!TARGET_DIR!\bin\localedef.cmd" set "_BIN_FOUND=1"
if exist "!TARGET_DIR!\bin\localedef.bat" set "_BIN_FOUND=1"
if "!_BIN_FOUND!"=="1" (
    if not "%FORCE_REINSTALL%"=="1" (
        echo [INFO] locales !EXACT_VERSION! is already installed at !TARGET_DIR!.
        call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\versioning.cmd" :libscript_symlink_alias "locales" "%LOCALES_VERSION%" "!EXACT_VERSION!"
        call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\versioning.cmd" :libscript_symlink_alias "locales" "default" "!EXACT_VERSION!"
        exit /b 0
    )
)
set "URL=%LOCALES_DOWNLOAD_URL%"
if "!URL!"=="" set "URL=https://ftp.gnu.org/gnu/glibc/glibc-{VERSION}.tar.xz"
call set "URL=%%URL:{VERSION}=!EXACT_VERSION!%%"
if "!URL!"=="" (
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\pkg_mgr.cmd" :libscript_depends locales
    exit /b !errorlevel!
)
if not exist "!TARGET_DIR!\bin" mkdir "!TARGET_DIR!\bin"
set "DL_DIR=%DOWNLOAD_DIR%"
if "!DL_DIR!"=="" set "DL_DIR=%TEMP%\libscript_downloads"
for %%F in ("!URL!") do set "ARCHIVE_NAME=%%~nxF"
set "CACHED_DL=!DL_DIR!\locales\!ARCHIVE_NAME!"
if exist "!CACHED_DL!" (
    echo [install] Using cached archive !CACHED_DL!...
    set "TMP_FILE=!CACHED_DL!"
) else (
    set "TMP_FILE=%TEMP%\locales-!RANDOM!.archive"
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
            if exist "%%~fD\bin\localedef.exe" set "_DO_FLAT=1"
            if exist "%%~fD\bin\localedef.bat" set "_DO_FLAT=1"
            if exist "%%~fD\bin\localedef.cmd" set "_DO_FLAT=1"
            if exist "%%~fD\localedef.exe" set "_DO_FLAT=1"
            if exist "%%~fD\localedef.cmd" set "_DO_FLAT=1"
            if exist "%%~fD\localedef.bat" set "_DO_FLAT=1"
            if "!_DO_FLAT!"=="1" (
                move /y "%%~fD" "!TARGET_DIR!_flat" >nul
                xcopy /E /I /Y "!TARGET_DIR!_flat\*" "!TARGET_DIR!\" >nul
                rmdir /s /q "!TARGET_DIR!_flat"
            )
        )
    )
    if not exist "!TARGET_DIR!\bin\localedef.exe" (
        if exist "!TARGET_DIR!\localedef.exe" (
            copy /y "!TARGET_DIR!\localedef.exe" "!TARGET_DIR!\bin\localedef.exe" >nul
        )
    )
    if not exist "!TARGET_DIR!\bin\localedef.cmd" (
        if exist "!TARGET_DIR!\localedef.cmd" (
            copy /y "!TARGET_DIR!\localedef.cmd" "!TARGET_DIR!\bin\localedef.cmd" >nul
        )
    )
    if not exist "!TARGET_DIR!\bin\localedef.bat" (
        if exist "!TARGET_DIR!\localedef.bat" (
            copy /y "!TARGET_DIR!\localedef.bat" "!TARGET_DIR!\bin\localedef.bat" >nul
        )
    )
) else (
    copy /y "!TMP_FILE!" "!TARGET_DIR!\bin\localedef.exe" >nul
)
if not "!TMP_FILE!"=="!CACHED_DL!" del /f /q "!TMP_FILE!" 2>nul
call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\versioning.cmd" :libscript_symlink_alias "locales" "%LOCALES_VERSION%" "!EXACT_VERSION!"
call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\versioning.cmd" :libscript_symlink_alias "locales" "default" "!EXACT_VERSION!"
exit /b 0

:: ## resolve_version
:: Resolves latest or lts version alias into EXACT_VERSION.
:resolve_version
if /i "%LOCALES_VERSION%"=="latest" goto :resolve_remote_gh_tag
if /i "%LOCALES_VERSION%"=="lts" goto :resolve_remote_gh_tag
if /i "%LOCALES_VERSION%"=="stable" goto :resolve_remote_gh_tag
set "EXACT_VERSION=%LOCALES_VERSION%"
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
if "!EXACT_VERSION!"=="" set "EXACT_VERSION=2.40"
exit /b 0

:: ## stage_locales_sysroot
:: Stages /etc/locale.conf and /etc/locale.gen into LIBSCRIPT_TARGET_SYSROOT when configured.
:stage_locales_sysroot
if "%LIBSCRIPT_TARGET_SYSROOT%"=="" exit /b 0
set "_DEF_LOC=%LOCALES_DEFAULT%"
if "!_DEF_LOC!"=="" set "_DEF_LOC=en_US.UTF-8"
set "_LIST_LOC=%LOCALES_LIST%"
if "!_LIST_LOC!"=="" set "_LIST_LOC=en_US.UTF-8 UTF-8"
if not exist "%LIBSCRIPT_TARGET_SYSROOT%\etc" mkdir "%LIBSCRIPT_TARGET_SYSROOT%\etc"
if not exist "%LIBSCRIPT_TARGET_SYSROOT%\var\lib\libscript\stamps" mkdir "%LIBSCRIPT_TARGET_SYSROOT%\var\lib\libscript\stamps"
> "%LIBSCRIPT_TARGET_SYSROOT%\etc\locale.conf" echo LANG=!_DEF_LOC!
> "%LIBSCRIPT_TARGET_SYSROOT%\etc\locale.gen" echo !_LIST_LOC:,=^

!
> "%LIBSCRIPT_TARGET_SYSROOT%\var\lib\libscript\stamps\.stamp.locales" echo staged
exit /b 0

:: ## action_other
:: Delegates service and lifecycle actions to setup_base.cmd.
:action_other
call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\setup_base.cmd" :libscript_handle_generic_action "locales" "%ACTION%" "%LOCALES_VERSION%" "%LOCALES_INSTALL_METHOD%" "" "" "" "\"%LIBSCRIPT_HOME%\locales\%LOCALES_VERSION%\\bin\\localedef.exe\"" "%LIBSCRIPT_HOME%\locales\%LOCALES_VERSION%"
exit /b !errorlevel!
