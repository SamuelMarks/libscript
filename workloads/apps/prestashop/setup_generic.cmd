@echo off
:: # setup_generic.cmd
:: ## Overview
:: Native zero-PowerShell Windows Batch setup for the PrestaShop e-commerce stack.
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
if "!PRESTASHOP_VERSION!"=="" set "PRESTASHOP_VERSION=8.1.4"
if "!PRESTASHOP_WWWROOT!"=="" set "PRESTASHOP_WWWROOT=C:\inetpub\wwwroot\prestashop"
if "!PRESTASHOP_DB_TYPE!"=="" set "PRESTASHOP_DB_TYPE=mariadb"
if "!PRESTASHOP_DB_NAME!"=="" set "PRESTASHOP_DB_NAME=prestashop"
if "!PRESTASHOP_DB_USER!"=="" set "PRESTASHOP_DB_USER=prestashop"
if "!PRESTASHOP_DB_PASS!"=="" set "PRESTASHOP_DB_PASS=prestashop"
if "!PRESTASHOP_SERVER_NAME!"=="" set "PRESTASHOP_SERVER_NAME=localhost"
if "!PRESTASHOP_LISTEN!"=="" set "PRESTASHOP_LISTEN=80"

if exist "!PRESTASHOP_WWWROOT!\classes" (
    echo [INFO] PrestaShop is already installed at !PRESTASHOP_WWWROOT!.
    exit /b 0
)

if not "!LIBSCRIPT_SKIP_SYSTEM_DEPS!"=="1" (
    where php >nul 2>&1
    if errorlevel 1 call "!LIBSCRIPT_ROOT_DIR!\libscript.cmd" install php latest
)

if not exist "!PRESTASHOP_WWWROOT!" mkdir "!PRESTASHOP_WWWROOT!"
set "TMP_ZIP=%TEMP%\prestashop_!RANDOM!.zip"
set "TMP_EXT=%TEMP%\ps_ext_!RANDOM!"
set "DL_URL=https://github.com/PrestaShop/PrestaShop/releases/download/!PRESTASHOP_VERSION!/prestashop_!PRESTASHOP_VERSION!.zip"

call "!LIBSCRIPT_ROOT_DIR!\engine\common\pkg_mgr.cmd" :libscript_download "!DL_URL!" "!TMP_ZIP!"
if errorlevel 1 exit /b 1
if not exist "!TMP_EXT!" mkdir "!TMP_EXT!"
call "!LIBSCRIPT_ROOT_DIR!\engine\common\pkg_mgr.cmd" :libscript_extract_archive "!TMP_ZIP!" "!TMP_EXT!"
if exist "!TMP_EXT!\prestashop.zip" (
    call "!LIBSCRIPT_ROOT_DIR!\engine\common\pkg_mgr.cmd" :libscript_extract_archive "!TMP_EXT!\prestashop.zip" "!PRESTASHOP_WWWROOT!"
) else (
    xcopy /E /I /Y "!TMP_EXT!\*" "!PRESTASHOP_WWWROOT!\" >nul
)
del /f /q "!TMP_ZIP!" 2>nul
rmdir /s /q "!TMP_EXT!" 2>nul

if /I "!PRESTASHOP_DB_TYPE!"=="mariadb" (
    call "!LIBSCRIPT_ROOT_DIR!\engine\hooks\databases\provision_schema.cmd" --engine mysql --host 127.0.0.1 --port 3306 --schema "!PRESTASHOP_DB_NAME!" --user "!PRESTASHOP_DB_USER!" --password "!PRESTASHOP_DB_PASS!"
) else if /I "!PRESTASHOP_DB_TYPE!"=="mysql" (
    call "!LIBSCRIPT_ROOT_DIR!\engine\hooks\databases\provision_schema.cmd" --engine mysql --host 127.0.0.1 --port 3306 --schema "!PRESTASHOP_DB_NAME!" --user "!PRESTASHOP_DB_USER!" --password "!PRESTASHOP_DB_PASS!"
) else if /I "!PRESTASHOP_DB_TYPE!"=="sqlite" (
    if not exist "!PRESTASHOP_WWWROOT!\var\sqlite" mkdir "!PRESTASHOP_WWWROOT!\var\sqlite"
)

echo [OK] PrestaShop setup complete on !PRESTASHOP_SERVER_NAME! ^(Port !PRESTASHOP_LISTEN!^).
exit /b 0
