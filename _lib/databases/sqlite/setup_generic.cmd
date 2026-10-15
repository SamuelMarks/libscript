@echo off
:: # setup_generic.cmd
::
:: ## Overview
:: Generic Windows setup and multi-mode build module for SQLite.
:: Supports Mode 1 (specific package manager), Mode 2 (amalgamation source build
:: with default toolchain), and Mode 3 (amalgamation source build with custom toolchain).
::
:: ## Usage
:: setup_generic.cmd [ACTION]

setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"

if defined STACK (
    echo !STACK! | findstr /C:":%THIS_FILE%:" >nul 2>&1
    if not errorlevel 1 (
        echo [STOP] processing "%THIS_FILE%" >&2
        exit /b 0
    )
)
set "STACK=%STACK%:%THIS_FILE%:"

set "SCRIPT_DIR=%~dp0"
if "%SCRIPT_DIR:~-1%"=="\\" set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"

if not defined LIBSCRIPT_ROOT_DIR (
    set "d=%SCRIPT_DIR%"
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

if "%ACTION%"=="" set "ACTION=install"
if "%SQLITE_VERSION%"=="" set "SQLITE_VERSION=latest"
if "%SQLITE_VERSION%"=="latest" (set "EXACT_VERSION=3.46.1") else (set "EXACT_VERSION=%SQLITE_VERSION%")
if "%LIBSCRIPT_HOME%"=="" set "LIBSCRIPT_HOME=%USERPROFILE%\.libscript"
if "%DOWNLOAD_DIR%"=="" set "DOWNLOAD_DIR=%LIBSCRIPT_ROOT_DIR%\cache\downloads"
if not "%SQLITE_PKG_MGR%"=="" set "LIBSCRIPT_PKG_MGR=%SQLITE_PKG_MGR%"

if "%SQLITE_INSTALL_METHOD%"=="" (
    if not "%LIBSCRIPT_DEFAULT_INSTALL_METHOD%"=="" (
        set "SQLITE_INSTALL_METHOD=%LIBSCRIPT_DEFAULT_INSTALL_METHOD%"
    ) else (
        set "SQLITE_INSTALL_METHOD=libscript_native"
    )
)

if /i "%ACTION%"=="ls" goto :action_ls
if /i "%ACTION%"=="ls-remote" goto :action_ls_remote
if /i "%ACTION%"=="use" goto :action_use
if /i "%ACTION%"=="download" goto :action_download
if /i "%ACTION%"=="install" goto :action_install
if /i "%ACTION%"=="uninstall" goto :action_uninstall
if /i "%ACTION%"=="start" goto :action_service
if /i "%ACTION%"=="stop" goto :action_service
if /i "%ACTION%"=="restart" goto :action_service
if /i "%ACTION%"=="status" goto :action_service
if /i "%ACTION%"=="health" goto :action_service
if /i "%ACTION%"=="logs" goto :action_service
if /i "%ACTION%"=="up" goto :action_service
if /i "%ACTION%"=="down" goto :action_service
if /i "%ACTION%"=="install-service" goto :action_install_service
if /i "%ACTION%"=="uninstall-service" goto :action_uninstall_service
goto :action_install

:: ## action_ls
:: Lists locally installed SQLite versions under LIBSCRIPT_HOME.
:action_ls
if exist "%LIBSCRIPT_HOME%\sqlite" dir /b "%LIBSCRIPT_HOME%\sqlite"
exit /b 0

:: ## action_ls_remote
:: Lists remote SQLite release versions.
:action_ls_remote
echo 3.45.3
echo 3.46.0
echo 3.46.1
exit /b 0

:: ## action_use
:: Activates the specified SQLite version junction.
:action_use
call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\versioning.cmd" :libscript_symlink_alias "sqlite" "default" "%EXACT_VERSION%"
exit /b 0

:: ## action_download
:: Downloads the SQLite amalgamation or prebuilt archive into the local offline cache.
:action_download
if not exist "%DOWNLOAD_DIR%\sqlite" mkdir "%DOWNLOAD_DIR%\sqlite"
set "_dl_url=%SQLITE_AMALGAMATION_URL%"
if "!_dl_url!"=="" set "_dl_url=https://www.sqlite.org/2024/sqlite-amalgamation-3460100.zip"
call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\pkg_mgr.cmd" :libscript_download "!_dl_url!" "%DOWNLOAD_DIR%\sqlite\sqlite-amalgamation-3460100.zip"
exit /b !errorlevel!

:: ## action_install
:: Routes SQLite installation to Mode 1 (package manager), Mode 2/3 (from-source amalgamation), or prebuilt binary.
:action_install
if /i "%SQLITE_INSTALL_METHOD%"=="from-source" goto :build_sqlite_from_source
if /i "%SQLITE_INSTALL_METHOD%"=="system" goto :install_sqlite_via_pkg_mgr
if /i "%SQLITE_INSTALL_METHOD%"=="winget" goto :install_sqlite_via_pkg_mgr
if /i "%SQLITE_INSTALL_METHOD%"=="choco" goto :install_sqlite_via_pkg_mgr
if /i "%SQLITE_INSTALL_METHOD%"=="scoop" goto :install_sqlite_via_pkg_mgr
if /i "%SQLITE_INSTALL_METHOD%"=="vcpkg" goto :install_sqlite_via_pkg_mgr
if /i "%SQLITE_INSTALL_METHOD%"=="mise" ( mise install "sqlite@%SQLITE_VERSION%" & exit /b 0 )
if /i "%SQLITE_INSTALL_METHOD%"=="asdf" ( asdf install sqlite "%SQLITE_VERSION%" & exit /b 0 )
if /i "%SQLITE_INSTALL_METHOD%"=="pkgx" ( pkgx install "sqlite@%SQLITE_VERSION%" & exit /b 0 )
if /i "%SQLITE_INSTALL_METHOD%"=="vfox" ( vfox add sqlite & vfox install "sqlite@%SQLITE_VERSION%" & exit /b 0 )

set "TARGET_DIR=%LIBSCRIPT_HOME%\sqlite\%EXACT_VERSION%"
if exist "%TARGET_DIR%\bin\sqlite3.exe" (
    echo [INFO] sqlite %EXACT_VERSION% is already installed at %TARGET_DIR%.
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\versioning.cmd" :libscript_symlink_alias "sqlite" "default" "%EXACT_VERSION%"
    exit /b 0
)
if not exist "%TARGET_DIR%\bin" mkdir "%TARGET_DIR%\bin"
set "_win_url=%SQLITE_DOWNLOAD_URL%"
if "!_win_url!"=="" set "_win_url=https://www.sqlite.org/2024/sqlite-tools-win-x64-3460100.zip"
call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\pkg_mgr.cmd" :libscript_download "!_win_url!" "%DOWNLOAD_DIR%\sqlite\sqlite-tools-%EXACT_VERSION%.zip"
tar -xf "%DOWNLOAD_DIR%\sqlite\sqlite-tools-%EXACT_VERSION%.zip" -C "%TARGET_DIR%\bin"
for /d %%D in ("%TARGET_DIR%\bin\sqlite-tools-*") do (
    if exist "%%~fD\sqlite3.exe" (
        move /y "%%~fD\*" "%TARGET_DIR%\bin" >nul 2>&1
        rmdir "%%~fD" >nul 2>&1
    )
)
call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\versioning.cmd" :libscript_symlink_alias "sqlite" "%SQLITE_VERSION%" "%EXACT_VERSION%"
call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\versioning.cmd" :libscript_symlink_alias "sqlite" "default" "%EXACT_VERSION%"
exit /b 0

:: ## install_sqlite_via_pkg_mgr
:: Installs SQLite on Windows via the selected package manager (winget, choco, scoop, vcpkg).
:install_sqlite_via_pkg_mgr
call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\pkg_mgr.cmd" :libscript_depends "sqlite"
exit /b !errorlevel!

:: ## build_sqlite_from_source
:: Compiles the SQLite C amalgamation from source on Windows using the resolved C toolchain.
:build_sqlite_from_source
call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\source_builder.cmd" :libscript_resolve_build_toolchain "sqlite" "%EXACT_VERSION%"
call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\source_builder.cmd" :libscript_check_source_build_idempotency "sqlite" "%EXACT_VERSION%" "sqlite3.exe"
if !errorlevel! equ 0 exit /b 0

set "_amal_url=%SQLITE_AMALGAMATION_URL%"
if "!_amal_url!"=="" set "_amal_url=https://www.sqlite.org/2024/sqlite-amalgamation-3460100.zip"
call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\source_builder.cmd" :libscript_fetch_and_extract_source "sqlite" "!_amal_url!" ""
call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\source_builder.cmd" :libscript_execute_source_build "custom" "!LIBSCRIPT_EXTRACTED_SRC_DIR!"

if /i "!LIBSCRIPT_RESOLVED_CC_BIN!"=="cl" (
    cl /O2 /Fe:"!LIBSCRIPT_BUILD_TARGET_DIR!\bin\sqlite3.exe" "!LIBSCRIPT_EXTRACTED_SRC_DIR!\shell.c" "!LIBSCRIPT_EXTRACTED_SRC_DIR!\sqlite3.c"
) else (
    "!LIBSCRIPT_RESOLVED_CC_BIN!" -O2 -DSQLITE_ENABLE_MATH_FUNCTIONS -DSQLITE_ENABLE_FTS5 -DSQLITE_ENABLE_RTREE "!LIBSCRIPT_EXTRACTED_SRC_DIR!\shell.c" "!LIBSCRIPT_EXTRACTED_SRC_DIR!\sqlite3.c" -o "!LIBSCRIPT_BUILD_TARGET_DIR!\bin\sqlite3.exe"
)
copy /y "!LIBSCRIPT_EXTRACTED_SRC_DIR!\sqlite3.h" "!LIBSCRIPT_BUILD_TARGET_DIR!\include\sqlite3.h" >nul 2>&1
call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\source_builder.cmd" :libscript_emit_build_metrics "sqlite" "%EXACT_VERSION%" "!LIBSCRIPT_BUILD_TARGET_DIR!\bin\sqlite3.exe" "-O2" ""
for %%D in ("!LIBSCRIPT_BUILD_TARGET_DIR!") do set "_leaf_dir=%%~nxD"
call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\versioning.cmd" :libscript_symlink_alias "sqlite" "default" "!_leaf_dir!"
exit /b 0

:: ## action_uninstall
:: Removes installed SQLite directories under LIBSCRIPT_HOME.
:action_uninstall
if exist "%LIBSCRIPT_HOME%\sqlite\%EXACT_VERSION%" rmdir /s /q "%LIBSCRIPT_HOME%\sqlite\%EXACT_VERSION%"
exit /b 0

:: ## action_service
:: Routes service actions for SQLite to service.cmd.
:action_service
set "SVC_NAME=libscript_sqlite"
if not "%LIBSCRIPT_SERVICE_NAME%"=="" set "SVC_NAME=%LIBSCRIPT_SERVICE_NAME%"
call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\service.cmd" "%ACTION%" "%SVC_NAME%"
exit /b 0

:: ## action_install_service
:: Installs a service definition for SQLite via service_install.cmd.
:action_install_service
set "SVC_NAME=libscript_sqlite"
if not "%LIBSCRIPT_SERVICE_NAME%"=="" set "SVC_NAME=%LIBSCRIPT_SERVICE_NAME%"
call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\service_install.cmd" install "%SVC_NAME%"
exit /b 0

:: ## action_uninstall_service
:: Uninstalls the service definition for SQLite via service_install.cmd.
:action_uninstall_service
set "SVC_NAME=libscript_sqlite"
if not "%LIBSCRIPT_SERVICE_NAME%"=="" set "SVC_NAME=%LIBSCRIPT_SERVICE_NAME%"
call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\service_install.cmd" uninstall "%SVC_NAME%"
exit /b 0
