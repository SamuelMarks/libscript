@echo off
:: # env.cmd
::
:: ## Overview
:: Environment initialization for PostgreSQL on Windows.
:: Defines defaults such as `POSTGRES_VERSION`, `POSTGRES_URL`, and prepends bin to PATH.
::
:: ## Usage
:: call _lib\databases\postgres\env.cmd

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
if not "%POSTGRES_URL_VERSION%"=="" set "POSTGRES_VERSION=%POSTGRES_URL_VERSION%"
if "%POSTGRES_VERSION%"=="" if not "%POSTGRESQL_VERSION%"=="" set "POSTGRES_VERSION=%POSTGRESQL_VERSION%"
if "%POSTGRES_VERSION%"=="" set "POSTGRES_VERSION=latest"
set "CALLER_SCRIPT_DIR=%SCRIPT_DIR%"
call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\env_base.cmd" "postgres" "%POSTGRES_VERSION%"

if /i "%POSTGRES_VERSION%"=="latest" (
    if exist "%LIBSCRIPT_HOME%\postgres\default\bin" (
        set "POSTGRES_VERSION=default"
    ) else if exist "%LIBSCRIPT_HOME%\postgres\latest\bin" (
        set "POSTGRES_VERSION=latest"
    ) else if exist "%LIBSCRIPT_HOME%\postgres\17\bin" (
        set "POSTGRES_VERSION=17"
    ) else if exist "%ProgramFiles%\PostgreSQL\17\bin" (
        set "POSTGRES_VERSION=17"
    ) else if exist "%LIBSCRIPT_HOME%\postgres\16\bin" (
        set "POSTGRES_VERSION=16"
    ) else if exist "%ProgramFiles%\PostgreSQL\16\bin" (
        set "POSTGRES_VERSION=16"
    ) else if exist "%LIBSCRIPT_HOME%\postgres\15\bin" (
        set "POSTGRES_VERSION=15"
    ) else if exist "%ProgramFiles%\PostgreSQL\15\bin" (
        set "POSTGRES_VERSION=15"
    ) else (
        set "POSTGRES_VERSION=17"
    )
)
set "POSTGRESQL_VERSION=%POSTGRES_VERSION%"
if not "%POSTGRES_PASSWORD_FILE%"=="" (
    if exist "%POSTGRES_PASSWORD_FILE%" (
        set /p POSTGRES_PASSWORD=<"%POSTGRES_PASSWORD_FILE%"
    )
)
if not "%POSTGRES_URL%"=="" (
    set "_PG_REST=%POSTGRES_URL:*://=%"
    for /f "tokens=1,2 delims=@" %%A in ("!_PG_REST!") do (
        if not "%%B"=="" (
            for /f "tokens=1,2 delims=:" %%U in ("%%A") do (
                if "%POSTGRES_USER%"=="" set "POSTGRES_USER=%%U"
                if "%POSTGRES_PASSWORD%"=="" if not "%%V"=="" set "POSTGRES_PASSWORD=%%V"
            )
            for /f "tokens=1,2 delims=/" %%H in ("%%B") do (
                for /f "tokens=1,2 delims=:" %%M in ("%%H") do (
                    if "%POSTGRES_HOST%"=="" set "POSTGRES_HOST=%%M"
                    if "%POSTGRES_PORT%"=="" if not "%%N"=="" set "POSTGRES_PORT=%%N"
                )
                if "%POSTGRES_DB%"=="" if not "%%I"=="" (
                    for /f "tokens=1 delims=?" %%D in ("%%I") do set "POSTGRES_DB=%%D"
                )
            )
        )
    )
)
if "%POSTGRES_USER%"=="" set "POSTGRES_USER=postgres"
if "%POSTGRES_PASSWORD%"=="" set "POSTGRES_PASSWORD=password"
if "%POSTGRES_HOST%"=="" set "POSTGRES_HOST=localhost"
if "%POSTGRES_PORT%"=="" set "POSTGRES_PORT=5432"
if "%POSTGRES_DB%"=="" set "POSTGRES_DB=%POSTGRES_USER%"
if "%POSTGRES_URL%"=="" (
    if "%POSTGRES_PORT%"=="5432" (
        set "POSTGRES_URL=postgres://%POSTGRES_USER%:%POSTGRES_PASSWORD%@%POSTGRES_HOST%/%POSTGRES_DB%"
    ) else (
        set "POSTGRES_URL=postgres://%POSTGRES_USER%:%POSTGRES_PASSWORD%@%POSTGRES_HOST%:%POSTGRES_PORT%/%POSTGRES_DB%"
    )
)

set "_NEW_PATH=!PATH!"
for %%D in ("%ProgramFiles%\PostgreSQL\15\bin" "%ProgramFiles%\PostgreSQL\16\bin" "%ProgramFiles%\PostgreSQL\17\bin" "%ProgramFiles%\PostgreSQL\%POSTGRES_VERSION%\bin" "%LIBSCRIPT_HOME%\postgres\default\bin" "%LIBSCRIPT_HOME%\postgres\%POSTGRES_VERSION%\bin") do (
    if exist "%%~fD" (
        echo ";!_NEW_PATH!;" | findstr /I /C:";%%~fD;" >nul 2>&1
        if errorlevel 1 set "_NEW_PATH=%%~fD;!_NEW_PATH!"
    )
)
echo ";!_NEW_PATH!;" | findstr /I /C:";%LIBSCRIPT_HOME%\postgres\%POSTGRES_VERSION%\bin;" >nul 2>&1
if errorlevel 1 set "_NEW_PATH=%LIBSCRIPT_HOME%\postgres\%POSTGRES_VERSION%\bin;!_NEW_PATH!"

endlocal & (
    set "LIBSCRIPT_HOME=%LIBSCRIPT_HOME%"
    set "POSTGRES_VERSION=%POSTGRES_VERSION%"
    set "POSTGRESQL_VERSION=%POSTGRESQL_VERSION%"
    set "POSTGRES_USER=%POSTGRES_USER%"
    set "POSTGRES_PASSWORD=%POSTGRES_PASSWORD%"
    set "POSTGRES_HOST=%POSTGRES_HOST%"
    set "POSTGRES_PORT=%POSTGRES_PORT%"
    set "POSTGRES_DB=%POSTGRES_DB%"
    set "POSTGRES_URL=%POSTGRES_URL%"
    set "PATH=%_NEW_PATH%"
)
exit /b 0
