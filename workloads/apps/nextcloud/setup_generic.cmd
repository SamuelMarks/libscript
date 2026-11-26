@echo off
:: # setup_generic.cmd
:: ## Overview
:: Native zero-PowerShell Windows Batch setup for the Nextcloud collaboration stack.
:: ## Usage
:: setup_generic.cmd [action]

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

if exist "!SCRIPT_DIR!\env.cmd" call "!SCRIPT_DIR!\env.cmd"
if "!NEXTCLOUD_VERSION!"=="" set "NEXTCLOUD_VERSION=latest"
if "!NEXTCLOUD_WWWROOT!"=="" set "NEXTCLOUD_WWWROOT=C:\inetpub\wwwroot\nextcloud"
if "!NEXTCLOUD_DB_TYPE!"=="" set "NEXTCLOUD_DB_TYPE=sqlite"
if "!NEXTCLOUD_DB_NAME!"=="" set "NEXTCLOUD_DB_NAME=nextcloud"
if "!NEXTCLOUD_DB_USER!"=="" set "NEXTCLOUD_DB_USER=nextcloud"
if "!NEXTCLOUD_DB_PASS!"=="" set "NEXTCLOUD_DB_PASS=nextcloud"
if "!NEXTCLOUD_SERVER_NAME!"=="" set "NEXTCLOUD_SERVER_NAME=localhost"
if "!NEXTCLOUD_LISTEN!"=="" set "NEXTCLOUD_LISTEN=80"

if exist "!NEXTCLOUD_WWWROOT!\core" (
    echo [INFO] Nextcloud is already installed at !NEXTCLOUD_WWWROOT!.
    exit /b 0
)

if not "!LIBSCRIPT_SKIP_SYSTEM_DEPS!"=="1" (
    where php >nul 2>&1
    if errorlevel 1 call "!LIBSCRIPT_ROOT_DIR!\libscript.cmd" install php latest
)

if not exist "!NEXTCLOUD_WWWROOT!" mkdir "!NEXTCLOUD_WWWROOT!"
set "TMP_ZIP=%TEMP%\nextcloud_!RANDOM!.zip"
set "TMP_EXT=%TEMP%\nc_ext_!RANDOM!"
if /I "!NEXTCLOUD_VERSION!"=="latest" (
    set "DL_URL=https://download.nextcloud.com/server/releases/latest.zip"
) else (
    set "DL_URL=https://download.nextcloud.com/server/releases/nextcloud-!NEXTCLOUD_VERSION!.zip"
)

call "!LIBSCRIPT_ROOT_DIR!\engine\common\pkg_mgr.cmd" :libscript_download "!DL_URL!" "!TMP_ZIP!"
if errorlevel 1 exit /b 1
if not exist "!TMP_EXT!" mkdir "!TMP_EXT!"
call "!LIBSCRIPT_ROOT_DIR!\engine\common\pkg_mgr.cmd" :libscript_extract_archive "!TMP_ZIP!" "!TMP_EXT!"
if exist "!TMP_EXT!\nextcloud" (
    xcopy /E /I /Y "!TMP_EXT!\nextcloud\*" "!NEXTCLOUD_WWWROOT!\" >nul
) else (
    xcopy /E /I /Y "!TMP_EXT!\*" "!NEXTCLOUD_WWWROOT!\" >nul
)
del /f /q "!TMP_ZIP!" 2>nul
rmdir /s /q "!TMP_EXT!" 2>nul

set "NC_DB=!NEXTCLOUD_DB_TYPE!"
if /I "!NC_DB!"=="mariadb" set "NC_DB=mysql"
if /I "!NC_DB!"=="postgres" set "NC_DB=pgsql"
if /I "!NC_DB!"=="sqlite" set "NC_DB=sqlite3"
if not exist "!NEXTCLOUD_WWWROOT!\config" mkdir "!NEXTCLOUD_WWWROOT!\config"
if not exist "!NEXTCLOUD_WWWROOT!\config\autoconfig.php" call :write_nc_cfg
echo [OK] Nextcloud setup complete on !NEXTCLOUD_SERVER_NAME! ^(Port !NEXTCLOUD_LISTEN!^).
exit /b 0

:: ## write_nc_cfg
:: Writes the initial Nextcloud autoconfig.php file.
:write_nc_cfg
echo ^<?php> "!NEXTCLOUD_WWWROOT!\config\autoconfig.php"
echo $AUTOCONFIG = array(>> "!NEXTCLOUD_WWWROOT!\config\autoconfig.php"
echo   "dbtype"        =^> "!NC_DB!",>> "!NEXTCLOUD_WWWROOT!\config\autoconfig.php"
echo   "dbname"        =^> "!NEXTCLOUD_DB_NAME!",>> "!NEXTCLOUD_WWWROOT!\config\autoconfig.php"
echo   "dbuser"        =^> "!NEXTCLOUD_DB_USER!",>> "!NEXTCLOUD_WWWROOT!\config\autoconfig.php"
echo   "dbpass"        =^> "!NEXTCLOUD_DB_PASS!",>> "!NEXTCLOUD_WWWROOT!\config\autoconfig.php"
echo   "dbhost"        =^> "localhost",>> "!NEXTCLOUD_WWWROOT!\config\autoconfig.php"
echo   "dbtableprefix" =^> "",>> "!NEXTCLOUD_WWWROOT!\config\autoconfig.php"
echo );>> "!NEXTCLOUD_WWWROOT!\config\autoconfig.php"
exit /b 0

