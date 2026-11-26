@echo off
:: # setup_generic.cmd
:: ## Overview
:: Native zero-PowerShell Windows Batch setup for the Drupal CMS stack.
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
if "!DRUPAL_VERSION!"=="" set "DRUPAL_VERSION=10.2.4"
if "!DRUPAL_WWWROOT!"=="" set "DRUPAL_WWWROOT=C:\inetpub\wwwroot\drupal"
if "!DRUPAL_DB_TYPE!"=="" set "DRUPAL_DB_TYPE=mariadb"
if "!DRUPAL_DB_NAME!"=="" set "DRUPAL_DB_NAME=drupal"
if "!DRUPAL_DB_USER!"=="" set "DRUPAL_DB_USER=drupal"
if "!DRUPAL_DB_PASS!"=="" set "DRUPAL_DB_PASS=drupal"
if "!DRUPAL_SERVER_NAME!"=="" set "DRUPAL_SERVER_NAME=localhost"
if "!DRUPAL_LISTEN!"=="" set "DRUPAL_LISTEN=80"

if exist "!DRUPAL_WWWROOT!\core" (
    echo [INFO] Drupal is already installed at !DRUPAL_WWWROOT!.
    exit /b 0
)

if not "!LIBSCRIPT_SKIP_SYSTEM_DEPS!"=="1" (
    where php >nul 2>&1
    if errorlevel 1 call "!LIBSCRIPT_ROOT_DIR!\libscript.cmd" install php latest
    if /I "!DRUPAL_DB_TYPE!"=="mariadb" (
        where mysql >nul 2>&1
        if errorlevel 1 call "!LIBSCRIPT_ROOT_DIR!\libscript.cmd" install mariadb latest
    )
    if /I "!DRUPAL_DB_TYPE!"=="postgres" (
        where psql >nul 2>&1
        if errorlevel 1 call "!LIBSCRIPT_ROOT_DIR!\libscript.cmd" install postgres latest
    )
)

if not exist "!DRUPAL_WWWROOT!" mkdir "!DRUPAL_WWWROOT!"
set "TMP_ZIP=%TEMP%\drupal_!RANDOM!.zip"
set "TMP_EXT=%TEMP%\dp_ext_!RANDOM!"
set "DL_URL=https://ftp.drupal.org/files/projects/drupal-!DRUPAL_VERSION!.zip"

call "!LIBSCRIPT_ROOT_DIR!\engine\common\pkg_mgr.cmd" :libscript_download "!DL_URL!" "!TMP_ZIP!"
if errorlevel 1 exit /b 1
if not exist "!TMP_EXT!" mkdir "!TMP_EXT!"
call "!LIBSCRIPT_ROOT_DIR!\engine\common\pkg_mgr.cmd" :libscript_extract_archive "!TMP_ZIP!" "!TMP_EXT!"
if exist "!TMP_EXT!\drupal-!DRUPAL_VERSION!" (
    xcopy /E /I /Y "!TMP_EXT!\drupal-!DRUPAL_VERSION!\*" "!DRUPAL_WWWROOT!\" >nul
) else (
    xcopy /E /I /Y "!TMP_EXT!\*" "!DRUPAL_WWWROOT!\" >nul
)
del /f /q "!TMP_ZIP!" 2>nul
rmdir /s /q "!TMP_EXT!" 2>nul

if /I "!DRUPAL_DB_TYPE!"=="mariadb" (
    call "!LIBSCRIPT_ROOT_DIR!\engine\hooks\databases\provision_schema.cmd" --engine mysql --host 127.0.0.1 --port 3306 --schema "!DRUPAL_DB_NAME!" --user "!DRUPAL_DB_USER!" --password "!DRUPAL_DB_PASS!"
) else if /I "!DRUPAL_DB_TYPE!"=="mysql" (
    call "!LIBSCRIPT_ROOT_DIR!\engine\hooks\databases\provision_schema.cmd" --engine mysql --host 127.0.0.1 --port 3306 --schema "!DRUPAL_DB_NAME!" --user "!DRUPAL_DB_USER!" --password "!DRUPAL_DB_PASS!"
) else if /I "!DRUPAL_DB_TYPE!"=="postgres" (
    call "!LIBSCRIPT_ROOT_DIR!\engine\hooks\databases\provision_schema.cmd" --engine postgres --host 127.0.0.1 --port 5432 --schema "!DRUPAL_DB_NAME!" --user "!DRUPAL_DB_USER!" --password "!DRUPAL_DB_PASS!"
) else if /I "!DRUPAL_DB_TYPE!"=="sqlite" (
    if not exist "!DRUPAL_WWWROOT!\sites\default\files" mkdir "!DRUPAL_WWWROOT!\sites\default\files"
)

echo [OK] Drupal setup complete on !DRUPAL_SERVER_NAME! ^(Port !DRUPAL_LISTEN!^).
exit /b 0
