@echo off
:: # setup_generic.cmd
:: ## Overview
:: Windows setup for rethinkdb implementing the Version Manager Contract.
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
if "%RETHINKDB_INSTALL_METHOD%"=="" (
    if not "%LIBSCRIPT_GLOBAL_INSTALL_METHOD%"=="" (
        set "RETHINKDB_INSTALL_METHOD=%LIBSCRIPT_GLOBAL_INSTALL_METHOD%"
    ) else (
        set "RETHINKDB_INSTALL_METHOD=system"
    )
)
if "%ACTION%"=="" set "ACTION=install"
if "%RETHINKDB_VERSION%"=="" set "RETHINKDB_VERSION=latest"

if "%ACTION%"=="ls" goto :action_ls
if "%ACTION%"=="ls-remote" goto :action_ls_remote
if "%ACTION%"=="use" goto :action_use
if "%ACTION%"=="download" goto :action_download
if "%ACTION%"=="install" goto :action_install
goto :action_other

:: ## action_ls
:: Lists locally installed versions of rethinkdb.
:action_ls
if "%RETHINKDB_INSTALL_METHOD%"=="libscript_native" (
    if exist "%LIBSCRIPT_HOME%\rethinkdb" dir /b "%LIBSCRIPT_HOME%\rethinkdb"
) else (
    where rethinkdb >nul 2>&1 && rethinkdb --version
)
exit /b 0

:: ## action_ls_remote
:: Queries available remote versions of rethinkdb.
:action_ls_remote
set "RELEASES_URL=%RETHINKDB_RELEASES_URL%"
if "!RELEASES_URL!"=="" set "RELEASES_URL=https://api.github.com/repos/rethinkdb/rethinkdb/releases/latest"
echo [ls-remote] Fetching available rethinkdb versions from !RELEASES_URL!...
call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\pkg_mgr.cmd" :libscript_fetch_stdout "!RELEASES_URL!"
exit /b 0

:: ## action_use
:: Activates a specific installed version of rethinkdb and updates alias junctions.
:action_use
call :resolve_version
set "TARGET_DIR=%LIBSCRIPT_HOME%\rethinkdb\!EXACT_VERSION!"
if not exist "!TARGET_DIR!" (
    echo Version !EXACT_VERSION! not installed. Installing...
    set "ACTION=install"
    call "%~f0"
)
call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\versioning.cmd" :libscript_symlink_alias "rethinkdb" "%RETHINKDB_VERSION%" "!EXACT_VERSION!"
call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\versioning.cmd" :libscript_symlink_alias "rethinkdb" "default" "!EXACT_VERSION!"
exit /b 0

:: ## action_download
:: Downloads the rethinkdb release artifact to the local cache directory.
:action_download
call :resolve_version
set "URL=%RETHINKDB_DOWNLOAD_URL%"
if "!URL!"=="" set "URL=https://github.com/rethinkdb/rethinkdb/releases/download/v{VERSION}/rethinkdb-{VERSION}-windows.zip"
call set "URL=%%URL:{VERSION}=!EXACT_VERSION!%%"
set "DL_DIR=%DOWNLOAD_DIR%"
if "!DL_DIR!"=="" set "DL_DIR=%TEMP%\libscript_downloads"
set "DL_DIR=!DL_DIR!\rethinkdb"
if not exist "!DL_DIR!" mkdir "!DL_DIR!"
for %%F in ("!URL!") do set "ARCHIVE_NAME=%%~nxF"
echo [download] Pre-downloading rethinkdb %RETHINKDB_VERSION% from !URL! to !DL_DIR!\!ARCHIVE_NAME!...
call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\pkg_mgr.cmd" :libscript_download "!URL!" "!DL_DIR!\!ARCHIVE_NAME!"
exit /b !errorlevel!

:: ## action_install
:: Installs rethinkdb via from-source, system package manager, or libscript_native isolation.
:action_install
if /i "%RETHINKDB_INSTALL_METHOD%"=="from-source" (
    call :resolve_version
    set "TARGET_DIR=%LIBSCRIPT_HOME%\rethinkdb\!EXACT_VERSION!"
    set "SRC_URL=%RETHINKDB_DOWNLOAD_URL%"
    if "!SRC_URL!"=="" set "SRC_URL=https://download.rethinkdb.com/repository/raw/dist/rethinkdb-{VERSION}.tgz"
    call set "SRC_URL=%%SRC_URL:{VERSION}=!EXACT_VERSION!%%"
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\source_builder.cmd" :libscript_build_component_from_source "rethinkdb" "!EXACT_VERSION!" "rethinkdb" "c++" "autotools" "!SRC_URL!"
    exit /b !errorlevel!
)
if "%RETHINKDB_INSTALL_METHOD%"=="system" (
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\pkg_mgr.cmd" :libscript_depends rethinkdb
    exit /b !errorlevel!
)
if /i "%RETHINKDB_INSTALL_METHOD%"=="winget" (
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\pkg_mgr.cmd" :libscript_depends_via winget rethinkdb
    exit /b !errorlevel!
)
if /i "%RETHINKDB_INSTALL_METHOD%"=="choco" (
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\pkg_mgr.cmd" :libscript_depends_via choco rethinkdb
    exit /b !errorlevel!
)
if /i "%RETHINKDB_INSTALL_METHOD%"=="scoop" (
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\pkg_mgr.cmd" :libscript_depends_via scoop rethinkdb
    exit /b !errorlevel!
)
call :resolve_version
set "TARGET_DIR=%LIBSCRIPT_HOME%\rethinkdb\!EXACT_VERSION!"
set "_BIN_FOUND=0"
if exist "!TARGET_DIR!\bin\rethinkdb.exe" set "_BIN_FOUND=1"
if exist "!TARGET_DIR!\bin\rethinkdb.cmd" set "_BIN_FOUND=1"
if exist "!TARGET_DIR!\bin\rethinkdb.bat" set "_BIN_FOUND=1"
if "!_BIN_FOUND!"=="1" (
    if not "%FORCE_REINSTALL%"=="1" (
        echo [INFO] rethinkdb !EXACT_VERSION! is already installed at !TARGET_DIR!.
        call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\versioning.cmd" :libscript_symlink_alias "rethinkdb" "%RETHINKDB_VERSION%" "!EXACT_VERSION!"
        call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\versioning.cmd" :libscript_symlink_alias "rethinkdb" "default" "!EXACT_VERSION!"
        exit /b 0
    )
)
set "URL=%RETHINKDB_DOWNLOAD_URL%"
if "!URL!"=="" set "URL=https://github.com/rethinkdb/rethinkdb/releases/download/v{VERSION}/rethinkdb-{VERSION}-windows.zip"
call set "URL=%%URL:{VERSION}=!EXACT_VERSION!%%"
if "!URL!"=="" (
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\pkg_mgr.cmd" :libscript_depends rethinkdb
    exit /b !errorlevel!
)
if not exist "!TARGET_DIR!\bin" mkdir "!TARGET_DIR!\bin"
set "DL_DIR=%DOWNLOAD_DIR%"
if "!DL_DIR!"=="" set "DL_DIR=%TEMP%\libscript_downloads"
for %%F in ("!URL!") do set "ARCHIVE_NAME=%%~nxF"
set "CACHED_DL=!DL_DIR!\rethinkdb\!ARCHIVE_NAME!"
if exist "!CACHED_DL!" (
    echo [install] Using cached archive !CACHED_DL!...
    set "TMP_FILE=!CACHED_DL!"
) else (
    set "TMP_FILE=%TEMP%\rethinkdb-!RANDOM!.archive"
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
            if exist "%%~fD\bin\rethinkdb.exe" set "_DO_FLAT=1"
            if exist "%%~fD\bin\rethinkdb.bat" set "_DO_FLAT=1"
            if exist "%%~fD\bin\rethinkdb.cmd" set "_DO_FLAT=1"
            if exist "%%~fD\rethinkdb.exe" set "_DO_FLAT=1"
            if exist "%%~fD\rethinkdb.cmd" set "_DO_FLAT=1"
            if exist "%%~fD\rethinkdb.bat" set "_DO_FLAT=1"
            if "!_DO_FLAT!"=="1" (
                move /y "%%~fD" "!TARGET_DIR!_flat" >nul
                xcopy /E /I /Y "!TARGET_DIR!_flat\*" "!TARGET_DIR!\" >nul
                rmdir /s /q "!TARGET_DIR!_flat"
            )
        )
    )
    if not exist "!TARGET_DIR!\bin\rethinkdb.exe" (
        if exist "!TARGET_DIR!\rethinkdb.exe" (
            copy /y "!TARGET_DIR!\rethinkdb.exe" "!TARGET_DIR!\bin\rethinkdb.exe" >nul
        )
    )
    if not exist "!TARGET_DIR!\bin\rethinkdb.cmd" (
        if exist "!TARGET_DIR!\rethinkdb.cmd" (
            copy /y "!TARGET_DIR!\rethinkdb.cmd" "!TARGET_DIR!\bin\rethinkdb.cmd" >nul
        )
    )
    if not exist "!TARGET_DIR!\bin\rethinkdb.bat" (
        if exist "!TARGET_DIR!\rethinkdb.bat" (
            copy /y "!TARGET_DIR!\rethinkdb.bat" "!TARGET_DIR!\bin\rethinkdb.bat" >nul
        )
    )
) else (
    copy /y "!TMP_FILE!" "!TARGET_DIR!\bin\rethinkdb.exe" >nul
)
if not "!TMP_FILE!"=="!CACHED_DL!" del /f /q "!TMP_FILE!" 2>nul
call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\versioning.cmd" :libscript_symlink_alias "rethinkdb" "%RETHINKDB_VERSION%" "!EXACT_VERSION!"
call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\versioning.cmd" :libscript_symlink_alias "rethinkdb" "default" "!EXACT_VERSION!"
exit /b 0

:: ## resolve_version
:: Resolves latest or lts version alias into EXACT_VERSION.
:resolve_version
if /i "%RETHINKDB_VERSION%"=="latest" goto :resolve_remote_gh_tag
if /i "%RETHINKDB_VERSION%"=="lts" goto :resolve_remote_gh_tag
if /i "%RETHINKDB_VERSION%"=="stable" goto :resolve_remote_gh_tag
set "EXACT_VERSION=%RETHINKDB_VERSION%"
exit /b 0

:: ## resolve_remote_gh_tag
:: Queries GitHub Releases API for the latest tag with offline fallback.
:resolve_remote_gh_tag
set "EXACT_VERSION="
if not "rethinkdb/rethinkdb" == "" (
    for /f "delims=" %%T in ('call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\pkg_mgr.cmd" :libscript_resolve_github_tag "https://api.github.com/repos/rethinkdb/rethinkdb/releases/latest"') do (
        set "EXACT_VERSION=%%T"
    )
)
if not "v" == "" (
    if not "!EXACT_VERSION!"=="" set "EXACT_VERSION=!EXACT_VERSION:v=!"
)
if "!EXACT_VERSION!"=="" set "EXACT_VERSION=2.4.4"
exit /b 0

:: ## action_other
:: Delegates service and lifecycle actions to setup_base.cmd.
:action_other
call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\setup_base.cmd" :libscript_handle_generic_action "rethinkdb" "%ACTION%" "%RETHINKDB_VERSION%" "%RETHINKDB_INSTALL_METHOD%" "" "" "" "\"%LIBSCRIPT_HOME%\rethinkdb\%RETHINKDB_VERSION%\\bin\\rethinkdb.exe\"" "%LIBSCRIPT_HOME%\rethinkdb\%RETHINKDB_VERSION%"
exit /b !errorlevel!
