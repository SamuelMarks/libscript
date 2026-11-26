@echo off
:: # setup_generic.cmd
:: ## Overview
:: Native zero-PowerShell Windows Batch setup for the Magento e-commerce stack.
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
if "!MAGENTO_VERSION!"=="" set "MAGENTO_VERSION=2.4.7"
if "!MAGENTO_WWWROOT!"=="" set "MAGENTO_WWWROOT=C:\inetpub\wwwroot\magento"
if "!MAGENTO_DB_DRIVER!"=="" set "MAGENTO_DB_DRIVER=mariadb"
if "!MAGENTO_DB_NAME!"=="" set "MAGENTO_DB_NAME=magento"
if "!MAGENTO_DB_USER!"=="" set "MAGENTO_DB_USER=magento"
if "!MAGENTO_DB_PASS!"=="" set "MAGENTO_DB_PASS=magento"
if "!MAGENTO_DB_HOST!"=="" set "MAGENTO_DB_HOST=127.0.0.1"
if "!MAGENTO_SERVER_NAME!"=="" set "MAGENTO_SERVER_NAME=localhost"
if "!MAGENTO_LISTEN!"=="" set "MAGENTO_LISTEN=80"

if exist "!MAGENTO_WWWROOT!\app" (
    echo [INFO] Magento is already installed at !MAGENTO_WWWROOT!.
    exit /b 0
)

if not "!LIBSCRIPT_SKIP_SYSTEM_DEPS!"=="1" (
    where php >nul 2>&1
    if errorlevel 1 call "!LIBSCRIPT_ROOT_DIR!\libscript.cmd" install php latest
)

if not exist "!MAGENTO_WWWROOT!" mkdir "!MAGENTO_WWWROOT!"
set "TMP_ZIP=%TEMP%\magento_!RANDOM!.zip"
set "TMP_EXT=%TEMP%\mg_ext_!RANDOM!"
set "DL_URL=https://github.com/magento/magento2/archive/refs/tags/!MAGENTO_VERSION!.zip"

call "!LIBSCRIPT_ROOT_DIR!\engine\common\pkg_mgr.cmd" :libscript_download "!DL_URL!" "!TMP_ZIP!"
if errorlevel 1 exit /b 1
if not exist "!TMP_EXT!" mkdir "!TMP_EXT!"
call "!LIBSCRIPT_ROOT_DIR!\engine\common\pkg_mgr.cmd" :libscript_extract_archive "!TMP_ZIP!" "!TMP_EXT!"
set "_MG_FLAT=0"
for /d %%D in ("!TMP_EXT!\magento*") do (
    if "!_MG_FLAT!"=="0" (
        xcopy /E /I /Y "%%~fD\*" "!MAGENTO_WWWROOT!\" >nul
        set "_MG_FLAT=1"
    )
)
if "!_MG_FLAT!"=="0" xcopy /E /I /Y "!TMP_EXT!\*" "!MAGENTO_WWWROOT!\" >nul
del /f /q "!TMP_ZIP!" 2>nul
rmdir /s /q "!TMP_EXT!" 2>nul

if /I "!MAGENTO_DB_DRIVER!"=="mariadb" (
    call "!LIBSCRIPT_ROOT_DIR!\engine\hooks\databases\provision_schema.cmd" --engine mysql --host "!MAGENTO_DB_HOST!" --port 3306 --schema "!MAGENTO_DB_NAME!" --user "!MAGENTO_DB_USER!" --password "!MAGENTO_DB_PASS!"
) else if /I "!MAGENTO_DB_DRIVER!"=="mysql" (
    call "!LIBSCRIPT_ROOT_DIR!\engine\hooks\databases\provision_schema.cmd" --engine mysql --host "!MAGENTO_DB_HOST!" --port 3306 --schema "!MAGENTO_DB_NAME!" --user "!MAGENTO_DB_USER!" --password "!MAGENTO_DB_PASS!"
)

echo [OK] Magento setup complete on !MAGENTO_SERVER_NAME! ^(Port !MAGENTO_LISTEN!^).
exit /b 0
