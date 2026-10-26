@echo off
:: # setup_generic.cmd
:: ## Overview
:: Windows setup script for MySQL.
::
:: ## Usage
:: Called internally by setup.cmd / cli.cmd.
setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"

if defined STACK (
    echo "!STACK!" | findstr /C:":!THIS_FILE!:" >nul 2>&1
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

if "%ACTION%"=="" set "ACTION=install"
if "%MYSQL_VERSION%"=="" set "MYSQL_VERSION=8.4.11"
if "%LIBSCRIPT_HOME%"=="" set "LIBSCRIPT_HOME=%USERPROFILE%\.libscript"

if "%ACTION%"=="install" (
    where mysql >nul 2>&1
    if not errorlevel 1 (
        echo [INFO] mysql is already installed on the system.
        exit /b 0
    )
    if exist "%LIBSCRIPT_HOME%\mysql\%MYSQL_VERSION%\bin\mysql.exe" (
        echo [INFO] mysql is already installed in %LIBSCRIPT_HOME%\mysql\%MYSQL_VERSION%\bin.
        exit /b 0
    )
    if defined LIBSCRIPT_CACHE_DIR (
        for %%Z in ("%LIBSCRIPT_CACHE_DIR%\databases\mysql*.zip" "%LIBSCRIPT_CACHE_DIR%\datastores\mysql*.zip") do (
            if exist "%%~fZ" (
                echo [INFO] Extracting MySQL from offline cache %%~fZ...
                if not exist "%LIBSCRIPT_HOME%\mysql\%MYSQL_VERSION%" mkdir "%LIBSCRIPT_HOME%\mysql\%MYSQL_VERSION%"
                tar -xf "%%~fZ" -C "%LIBSCRIPT_HOME%\mysql\%MYSQL_VERSION%" --strip-components=1 2>nul || tar -xf "%%~fZ" -C "%LIBSCRIPT_HOME%\mysql\%MYSQL_VERSION%"
                if not "%MYSQL_VERSION%"=="latest" (
                    if exist "%LIBSCRIPT_HOME%\mysql\latest" rmdir "%LIBSCRIPT_HOME%\mysql\latest" 2>nul
                    mklink /J "%LIBSCRIPT_HOME%\mysql\latest" "%LIBSCRIPT_HOME%\mysql\%MYSQL_VERSION%" >nul 2>&1
                )
                exit /b 0
            )
        )
    )
    if not "%PROP_OPENEDX_FAST_VERIFY%"=="1" (
        call "!LIBSCRIPT_ROOT_DIR!\_lib\_common\pkg_mgr.cmd" :libscript_depends mysql
        if not errorlevel 1 exit /b 0
    )
    echo [INFO] Provisioning MySQL native service directory at %LIBSCRIPT_HOME%\mysql\%MYSQL_VERSION%...
    if not exist "%LIBSCRIPT_HOME%\mysql\%MYSQL_VERSION%\bin" mkdir "%LIBSCRIPT_HOME%\mysql\%MYSQL_VERSION%\bin"
    exit /b 0
) else if "%ACTION%"=="uninstall" (
    where winget >nul 2>&1 && winget uninstall --id Oracle.MySQL --silent
    where choco >nul 2>&1 && choco uninstall mysql -y
    exit /b 0
) else if "%ACTION%"=="test" (
    mysql --version
    exit /b %ERRORLEVEL%
)

exit /b 0
