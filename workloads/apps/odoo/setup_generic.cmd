@echo off
:: # setup_generic.cmd
:: ## Overview
:: Native zero-PowerShell Windows Batch setup for the Odoo ERP system stack.
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
if "!ODOO_VERSION!"=="" set "ODOO_VERSION=17.0"
if "!ODOO_WWWROOT!"=="" set "ODOO_WWWROOT=C:\inetpub\wwwroot\odoo"
if "!ODOO_DB_TYPE!"=="" set "ODOO_DB_TYPE=postgres"
if "!ODOO_DB_NAME!"=="" set "ODOO_DB_NAME=odoo"
if "!ODOO_DB_USER!"=="" set "ODOO_DB_USER=odoo"
if "!ODOO_DB_PASS!"=="" set "ODOO_DB_PASS=odoo"
if "!ODOO_DB_HOST!"=="" set "ODOO_DB_HOST=127.0.0.1"
if "!ODOO_DB_PORT!"=="" set "ODOO_DB_PORT=5432"
if "!ODOO_PORT!"=="" set "ODOO_PORT=8069"
if "!ODOO_SERVER_NAME!"=="" set "ODOO_SERVER_NAME=localhost"
if "!ODOO_LISTEN!"=="" set "ODOO_LISTEN=80"

if exist "!ODOO_WWWROOT!\odoo-bin" (
    echo [INFO] Odoo is already installed at !ODOO_WWWROOT!.
    exit /b 0
)

if not "!LIBSCRIPT_SKIP_SYSTEM_DEPS!"=="1" (
    where python >nul 2>&1
    if errorlevel 1 call "!LIBSCRIPT_ROOT_DIR!\libscript.cmd" install python 3.11
    if /I "!ODOO_DB_TYPE!"=="postgres" (
        where psql >nul 2>&1
        if errorlevel 1 call "!LIBSCRIPT_ROOT_DIR!\libscript.cmd" install postgres latest
    )
)

if not exist "!ODOO_WWWROOT!" mkdir "!ODOO_WWWROOT!"
set "TMP_ZIP=%TEMP%\odoo_!RANDOM!.zip"
set "TMP_EXT=%TEMP%\odoo_ext_!RANDOM!"
set "DL_URL=https://github.com/odoo/odoo/archive/refs/heads/!ODOO_VERSION!.zip"

call "!LIBSCRIPT_ROOT_DIR!\engine\common\pkg_mgr.cmd" :libscript_download "!DL_URL!" "!TMP_ZIP!"
if errorlevel 1 exit /b 1
if not exist "!TMP_EXT!" mkdir "!TMP_EXT!"
call "!LIBSCRIPT_ROOT_DIR!\engine\common\pkg_mgr.cmd" :libscript_extract_archive "!TMP_ZIP!" "!TMP_EXT!"
set "_ODOO_FLAT=0"
for /d %%D in ("!TMP_EXT!\odoo*") do (
    if "!_ODOO_FLAT!"=="0" (
        xcopy /E /I /Y "%%~fD\*" "!ODOO_WWWROOT!\" >nul
        set "_ODOO_FLAT=1"
    )
)
if "!_ODOO_FLAT!"=="0" xcopy /E /I /Y "!TMP_EXT!\*" "!ODOO_WWWROOT!\" >nul
del /f /q "!TMP_ZIP!" 2>nul
rmdir /s /q "!TMP_EXT!" 2>nul

if exist "!ODOO_WWWROOT!\requirements.txt" (
    where python >nul 2>&1
    if not errorlevel 1 python -m pip install -r "!ODOO_WWWROOT!\requirements.txt" 2>nul
)

if /I "!ODOO_DB_TYPE!"=="postgres" (
    call "!LIBSCRIPT_ROOT_DIR!\engine\hooks\databases\provision_schema.cmd" --engine postgres --host "!ODOO_DB_HOST!" --port "!ODOO_DB_PORT!" --schema "!ODOO_DB_NAME!" --user "!ODOO_DB_USER!" --password "!ODOO_DB_PASS!"
) else if /I "!ODOO_DB_TYPE!"=="mariadb" (
    call "!LIBSCRIPT_ROOT_DIR!\engine\hooks\databases\provision_schema.cmd" --engine mysql --host "!ODOO_DB_HOST!" --port 3306 --schema "!ODOO_DB_NAME!" --user "!ODOO_DB_USER!" --password "!ODOO_DB_PASS!"
)

if not exist "!ODOO_WWWROOT!\odoo.conf" (
    (
        echo [options]
        echo admin_passwd = admin
        echo db_host = !ODOO_DB_HOST!
        echo db_port = !ODOO_DB_PORT!
        echo db_user = !ODOO_DB_USER!
        echo db_password = !ODOO_DB_PASS!
        echo db_name = !ODOO_DB_NAME!
        echo http_port = !ODOO_PORT!
        echo proxy_mode = True
        echo addons_path = !ODOO_WWWROOT!\addons
    ) > "!ODOO_WWWROOT!\odoo.conf"
)

echo [OK] Odoo setup complete on !ODOO_SERVER_NAME! ^(Port !ODOO_LISTEN!^).
exit /b 0
