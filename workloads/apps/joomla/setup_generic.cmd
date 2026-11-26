@echo off
:: # setup_generic.cmd
:: ## Overview
:: Native zero-PowerShell Windows Batch setup for the Joomla CMS stack.
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
if "!JOOMLA_VERSION!"=="" set "JOOMLA_VERSION=5.0.3"
if "!JOOMLA_WWWROOT!"=="" set "JOOMLA_WWWROOT=C:\inetpub\wwwroot\joomla"
if "!JOOMLA_DB_TYPE!"=="" set "JOOMLA_DB_TYPE=mariadb"
if "!JOOMLA_DB_NAME!"=="" set "JOOMLA_DB_NAME=joomla"
if "!JOOMLA_DB_USER!"=="" set "JOOMLA_DB_USER=joomla"
if "!JOOMLA_DB_PASS!"=="" set "JOOMLA_DB_PASS=joomla"
if "!JOOMLA_SERVER_NAME!"=="" set "JOOMLA_SERVER_NAME=localhost"
if "!JOOMLA_LISTEN!"=="" set "JOOMLA_LISTEN=80"

if exist "!JOOMLA_WWWROOT!\administrator" (
    echo [INFO] Joomla is already installed at !JOOMLA_WWWROOT!.
    exit /b 0
)

if not "!LIBSCRIPT_SKIP_SYSTEM_DEPS!"=="1" (
    where php >nul 2>&1
    if errorlevel 1 call "!LIBSCRIPT_ROOT_DIR!\libscript.cmd" install php latest
)

if not exist "!JOOMLA_WWWROOT!" mkdir "!JOOMLA_WWWROOT!"
set "TMP_ZIP=%TEMP%\joomla_!RANDOM!.zip"
set "DL_URL=https://github.com/joomla/joomla-cms/releases/download/!JOOMLA_VERSION!/Joomla_!JOOMLA_VERSION!-Stable-Full_Package.zip"

call "!LIBSCRIPT_ROOT_DIR!\engine\common\pkg_mgr.cmd" :libscript_download "!DL_URL!" "!TMP_ZIP!"
if errorlevel 1 exit /b 1
call "!LIBSCRIPT_ROOT_DIR!\engine\common\pkg_mgr.cmd" :libscript_extract_archive "!TMP_ZIP!" "!JOOMLA_WWWROOT!"
del /f /q "!TMP_ZIP!" 2>nul

if /I "!JOOMLA_DB_TYPE!"=="mariadb" (
    call "!LIBSCRIPT_ROOT_DIR!\engine\hooks\databases\provision_schema.cmd" --engine mysql --host 127.0.0.1 --port 3306 --schema "!JOOMLA_DB_NAME!" --user "!JOOMLA_DB_USER!" --password "!JOOMLA_DB_PASS!"
) else if /I "!JOOMLA_DB_TYPE!"=="mysql" (
    call "!LIBSCRIPT_ROOT_DIR!\engine\hooks\databases\provision_schema.cmd" --engine mysql --host 127.0.0.1 --port 3306 --schema "!JOOMLA_DB_NAME!" --user "!JOOMLA_DB_USER!" --password "!JOOMLA_DB_PASS!"
) else if /I "!JOOMLA_DB_TYPE!"=="postgres" (
    call "!LIBSCRIPT_ROOT_DIR!\engine\hooks\databases\provision_schema.cmd" --engine postgres --host 127.0.0.1 --port 5432 --schema "!JOOMLA_DB_NAME!" --user "!JOOMLA_DB_USER!" --password "!JOOMLA_DB_PASS!"
)

echo [OK] Joomla setup complete on !JOOMLA_SERVER_NAME! ^(Port !JOOMLA_LISTEN!^).
exit /b 0
