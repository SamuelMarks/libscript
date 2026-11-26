@echo off
:: # setup_generic.cmd
:: ## Overview
:: Native zero-PowerShell Windows Batch setup for the phpBB forum software stack.
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
if "!PHPBB_VERSION!"=="" set "PHPBB_VERSION=3.3.11"
if "!PHPBB_MAJOR_VERSION!"=="" set "PHPBB_MAJOR_VERSION=3.3"
if "!PHPBB_WWWROOT!"=="" set "PHPBB_WWWROOT=C:\inetpub\wwwroot\phpbb"
if "!PHPBB_DB_TYPE!"=="" set "PHPBB_DB_TYPE=sqlite"
if "!PHPBB_SERVER_NAME!"=="" set "PHPBB_SERVER_NAME=localhost"
if "!PHPBB_LISTEN!"=="" set "PHPBB_LISTEN=80"

if exist "!PHPBB_WWWROOT!\phpbb" (
    echo [INFO] phpBB is already installed at !PHPBB_WWWROOT!.
    exit /b 0
)

if not "!LIBSCRIPT_SKIP_SYSTEM_DEPS!"=="1" (
    where php >nul 2>&1
    if errorlevel 1 call "!LIBSCRIPT_ROOT_DIR!\libscript.cmd" install php latest
)

if not exist "!PHPBB_WWWROOT!" mkdir "!PHPBB_WWWROOT!"
set "TMP_ZIP=%TEMP%\phpbb_!RANDOM!.zip"
set "TMP_EXT=%TEMP%\pb_ext_!RANDOM!"
set "DL_URL=https://download.phpbb.com/pub/release/!PHPBB_MAJOR_VERSION!/!PHPBB_VERSION!/phpBB-!PHPBB_VERSION!.zip"

call "!LIBSCRIPT_ROOT_DIR!\engine\common\pkg_mgr.cmd" :libscript_download "!DL_URL!" "!TMP_ZIP!"
if errorlevel 1 exit /b 1
if not exist "!TMP_EXT!" mkdir "!TMP_EXT!"
call "!LIBSCRIPT_ROOT_DIR!\engine\common\pkg_mgr.cmd" :libscript_extract_archive "!TMP_ZIP!" "!TMP_EXT!"
if exist "!TMP_EXT!\phpBB3" (
    xcopy /E /I /Y "!TMP_EXT!\phpBB3\*" "!PHPBB_WWWROOT!\" >nul
) else (
    xcopy /E /I /Y "!TMP_EXT!\*" "!PHPBB_WWWROOT!\" >nul
)
del /f /q "!TMP_ZIP!" 2>nul
rmdir /s /q "!TMP_EXT!" 2>nul

if /I "!PHPBB_DB_TYPE!"=="sqlite" (
    if not exist "!PHPBB_WWWROOT!\store" mkdir "!PHPBB_WWWROOT!\store"
)

echo [OK] phpBB setup complete on !PHPBB_SERVER_NAME! ^(Port !PHPBB_LISTEN!^).
exit /b 0
