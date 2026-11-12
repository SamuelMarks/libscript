@echo off
:: # setup_generic.cmd
:: ## Overview
:: Windows setup for cassandra implementing the Version Manager Contract.
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
if "%CASSANDRA_INSTALL_METHOD%"=="" (
    if not "%LIBSCRIPT_GLOBAL_INSTALL_METHOD%"=="" (
        set "CASSANDRA_INSTALL_METHOD=%LIBSCRIPT_GLOBAL_INSTALL_METHOD%"
    ) else (
        set "CASSANDRA_INSTALL_METHOD=libscript_native"
    )
)
if "%ACTION%"=="" set "ACTION=install"
if "%CASSANDRA_VERSION%"=="" set "CASSANDRA_VERSION=latest"

if "%ACTION%"=="ls" goto :action_ls
if "%ACTION%"=="ls-remote" goto :action_ls_remote
if "%ACTION%"=="use" goto :action_use
if "%ACTION%"=="download" goto :action_download
if "%ACTION%"=="install" goto :action_install
goto :action_other

:: ## action_ls
:: Lists locally installed versions of cassandra.
:action_ls
if "%CASSANDRA_INSTALL_METHOD%"=="libscript_native" (
    if exist "%LIBSCRIPT_HOME%\cassandra" dir /b "%LIBSCRIPT_HOME%\cassandra"
) else (
    where cassandra >nul 2>&1 && cassandra --version
)
exit /b 0

:: ## action_ls_remote
:: Queries available remote versions of cassandra.
:action_ls_remote
set "RELEASES_URL=%CASSANDRA_RELEASES_URL%"
if "!RELEASES_URL!"=="" set "RELEASES_URL=https://api.github.com/repos/apache/cassandra/tags"
echo [ls-remote] Fetching available cassandra versions from !RELEASES_URL!...
call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\pkg_mgr.cmd" :libscript_fetch_stdout "!RELEASES_URL!"
exit /b 0

:: ## action_use
:: Activates a specific installed version of cassandra and updates alias junctions.
:action_use
call :resolve_version
set "TARGET_DIR=%LIBSCRIPT_HOME%\cassandra\!EXACT_VERSION!"
if not exist "!TARGET_DIR!" (
    echo Version !EXACT_VERSION! not installed. Installing...
    set "ACTION=install"
    call "%~f0"
)
call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\versioning.cmd" :libscript_symlink_alias "cassandra" "%CASSANDRA_VERSION%" "!EXACT_VERSION!"
call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\versioning.cmd" :libscript_symlink_alias "cassandra" "default" "!EXACT_VERSION!"
exit /b 0

:: ## action_download
:: Downloads the cassandra release artifact to the local cache directory.
:action_download
call :resolve_version
set "URL=%CASSANDRA_DOWNLOAD_URL%"
if "!URL!"=="" set "URL=https://archive.apache.org/dist/cassandra/{VERSION}/apache-cassandra-{VERSION}-bin.tar.gz"
call set "URL=%%URL:{VERSION}=!EXACT_VERSION!%%"
set "DL_DIR=%DOWNLOAD_DIR%"
if "!DL_DIR!"=="" set "DL_DIR=%TEMP%\libscript_downloads"
set "DL_DIR=!DL_DIR!\cassandra"
if not exist "!DL_DIR!" mkdir "!DL_DIR!"
for %%F in ("!URL!") do set "ARCHIVE_NAME=%%~nxF"
echo [download] Pre-downloading cassandra %CASSANDRA_VERSION% from !URL! to !DL_DIR!\!ARCHIVE_NAME!...
call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\pkg_mgr.cmd" :libscript_download "!URL!" "!DL_DIR!\!ARCHIVE_NAME!"
exit /b !errorlevel!

:: ## action_install
:: Installs cassandra via from-source, system package manager, or libscript_native isolation.
:action_install
if /i "%CASSANDRA_INSTALL_METHOD%"=="from-source" (
    call :resolve_version
    set "TARGET_DIR=%LIBSCRIPT_HOME%\cassandra\!EXACT_VERSION!"
    set "SRC_URL=%CASSANDRA_DOWNLOAD_URL%"
    if "!SRC_URL!"=="" set "SRC_URL=https://github.com/apache/cassandra/archive/refs/tags/cassandra-{VERSION}.tar.gz"
    call set "SRC_URL=%%SRC_URL:{VERSION}=!EXACT_VERSION!%%"
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\source_builder.cmd" :libscript_build_component_from_source "cassandra" "!EXACT_VERSION!" "cassandra" "java" "gradle" "!SRC_URL!"
    exit /b !errorlevel!
)
if "%CASSANDRA_INSTALL_METHOD%"=="system" (
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\pkg_mgr.cmd" :libscript_depends cassandra
    exit /b !errorlevel!
)
if /i "%CASSANDRA_INSTALL_METHOD%"=="winget" (
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\pkg_mgr.cmd" :libscript_depends_via winget cassandra
    exit /b !errorlevel!
)
if /i "%CASSANDRA_INSTALL_METHOD%"=="choco" (
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\pkg_mgr.cmd" :libscript_depends_via choco cassandra
    exit /b !errorlevel!
)
if /i "%CASSANDRA_INSTALL_METHOD%"=="scoop" (
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\pkg_mgr.cmd" :libscript_depends_via scoop cassandra
    exit /b !errorlevel!
)
call :resolve_version
set "TARGET_DIR=%LIBSCRIPT_HOME%\cassandra\!EXACT_VERSION!"
set "_BIN_FOUND=0"
if exist "!TARGET_DIR!\bin\cassandra.exe" set "_BIN_FOUND=1"
if exist "!TARGET_DIR!\bin\cassandra.cmd" set "_BIN_FOUND=1"
if exist "!TARGET_DIR!\bin\cassandra.bat" set "_BIN_FOUND=1"
if "!_BIN_FOUND!"=="1" (
    if not "%FORCE_REINSTALL%"=="1" (
        echo [INFO] cassandra !EXACT_VERSION! is already installed at !TARGET_DIR!.
        call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\versioning.cmd" :libscript_symlink_alias "cassandra" "%CASSANDRA_VERSION%" "!EXACT_VERSION!"
        call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\versioning.cmd" :libscript_symlink_alias "cassandra" "default" "!EXACT_VERSION!"
        exit /b 0
    )
)
set "URL=%CASSANDRA_DOWNLOAD_URL%"
if "!URL!"=="" set "URL=https://archive.apache.org/dist/cassandra/{VERSION}/apache-cassandra-{VERSION}-bin.tar.gz"
call set "URL=%%URL:{VERSION}=!EXACT_VERSION!%%"
if "!URL!"=="" (
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\pkg_mgr.cmd" :libscript_depends cassandra
    exit /b !errorlevel!
)
if not exist "!TARGET_DIR!\bin" mkdir "!TARGET_DIR!\bin"
set "DL_DIR=%DOWNLOAD_DIR%"
if "!DL_DIR!"=="" set "DL_DIR=%TEMP%\libscript_downloads"
for %%F in ("!URL!") do set "ARCHIVE_NAME=%%~nxF"
set "CACHED_DL=!DL_DIR!\cassandra\!ARCHIVE_NAME!"
if exist "!CACHED_DL!" (
    echo [install] Using cached archive !CACHED_DL!...
    set "TMP_FILE=!CACHED_DL!"
) else (
    set "TMP_FILE=%TEMP%\cassandra-!RANDOM!.archive"
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
            if exist "%%~fD\bin\cassandra.exe" set "_DO_FLAT=1"
            if exist "%%~fD\bin\cassandra.bat" set "_DO_FLAT=1"
            if exist "%%~fD\bin\cassandra.cmd" set "_DO_FLAT=1"
            if exist "%%~fD\cassandra.exe" set "_DO_FLAT=1"
            if exist "%%~fD\cassandra.cmd" set "_DO_FLAT=1"
            if exist "%%~fD\cassandra.bat" set "_DO_FLAT=1"
            if "!_DO_FLAT!"=="1" (
                move /y "%%~fD" "!TARGET_DIR!_flat" >nul
                xcopy /E /I /Y "!TARGET_DIR!_flat\*" "!TARGET_DIR!\" >nul
                rmdir /s /q "!TARGET_DIR!_flat"
            )
        )
    )
    if not exist "!TARGET_DIR!\bin\cassandra.exe" (
        if exist "!TARGET_DIR!\cassandra.exe" (
            copy /y "!TARGET_DIR!\cassandra.exe" "!TARGET_DIR!\bin\cassandra.exe" >nul
        )
    )
    if not exist "!TARGET_DIR!\bin\cassandra.cmd" (
        if exist "!TARGET_DIR!\cassandra.cmd" (
            copy /y "!TARGET_DIR!\cassandra.cmd" "!TARGET_DIR!\bin\cassandra.cmd" >nul
        )
    )
    if not exist "!TARGET_DIR!\bin\cassandra.bat" (
        if exist "!TARGET_DIR!\cassandra.bat" (
            copy /y "!TARGET_DIR!\cassandra.bat" "!TARGET_DIR!\bin\cassandra.bat" >nul
        )
    )
) else (
    copy /y "!TMP_FILE!" "!TARGET_DIR!\bin\cassandra.exe" >nul
)
if not "!TMP_FILE!"=="!CACHED_DL!" del /f /q "!TMP_FILE!" 2>nul
call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\versioning.cmd" :libscript_symlink_alias "cassandra" "%CASSANDRA_VERSION%" "!EXACT_VERSION!"
call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\versioning.cmd" :libscript_symlink_alias "cassandra" "default" "!EXACT_VERSION!"
exit /b 0

:: ## resolve_version
:: Resolves latest or lts version alias into EXACT_VERSION.
:resolve_version
if /i "%CASSANDRA_VERSION%"=="latest" goto :resolve_remote_gh_tag
if /i "%CASSANDRA_VERSION%"=="lts" goto :resolve_remote_gh_tag
if /i "%CASSANDRA_VERSION%"=="stable" goto :resolve_remote_gh_tag
set "EXACT_VERSION=%CASSANDRA_VERSION%"
exit /b 0

:: ## resolve_remote_gh_tag
:: Queries GitHub Releases API for the latest tag with offline fallback.
:resolve_remote_gh_tag
set "EXACT_VERSION="
if not "apache/cassandra" == "" (
    for /f "delims=" %%T in ('call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\pkg_mgr.cmd" :libscript_resolve_github_tag "https://api.github.com/repos/apache/cassandra/releases/latest"') do (
        set "EXACT_VERSION=%%T"
    )
)
if not "cassandra-" == "" (
    if not "!EXACT_VERSION!"=="" set "EXACT_VERSION=!EXACT_VERSION:cassandra-=!"
)
if "!EXACT_VERSION!"=="" set "EXACT_VERSION=5.0.2"
exit /b 0

:: ## action_other
:: Delegates service and lifecycle actions to setup_base.cmd.
:action_other
call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\setup_base.cmd" :libscript_handle_generic_action "cassandra" "%ACTION%" "%CASSANDRA_VERSION%" "%CASSANDRA_INSTALL_METHOD%" "" "" "" "\"%LIBSCRIPT_HOME%\cassandra\%CASSANDRA_VERSION%\\bin\\cassandra.exe\"" "%LIBSCRIPT_HOME%\cassandra\%CASSANDRA_VERSION%"
exit /b !errorlevel!
