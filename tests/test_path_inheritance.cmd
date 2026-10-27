@echo off
:: # test_path_inheritance.cmd
::
:: ## Overview
:: End-to-end regression test on Windows verifying multi-component PATH inheritance,
:: transitive stack resolution (nodejs + postgres + python + uv + duckdb),
:: environment variable tunneling across endlocal, and strict PATH idempotency.
::
:: ## Usage
:: tests\test_path_inheritance.cmd

setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"

if defined STACK (
    echo !STACK! | findstr /I /C:":%THIS_FILE%:" >nul 2>&1
    if not errorlevel 1 (
        echo [STOP] processing "%THIS_FILE%" >&2
        exit /b 0
    )
)
set "STACK=%STACK%:%THIS_FILE%:"

set "SCRIPT_DIR=%~dp0"
if "%SCRIPT_DIR:~-1%"=="\" set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"

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

set "TEST_TMP=%TEMP%\libscript_test_path_inh_%RANDOM%"
if not exist "%TEST_TMP%\home\.libscript\nodejs\lts\bin" mkdir "%TEST_TMP%\home\.libscript\nodejs\lts\bin"
if not exist "%TEST_TMP%\home\.libscript\python\3.12\Scripts" mkdir "%TEST_TMP%\home\.libscript\python\3.12\Scripts"
if not exist "%TEST_TMP%\home\.libscript\uv\latest\bin" mkdir "%TEST_TMP%\home\.libscript\uv\latest\bin"
if not exist "%TEST_TMP%\home\.libscript\postgres\17\bin" mkdir "%TEST_TMP%\home\.libscript\postgres\17\bin"
if not exist "%TEST_TMP%\home\.libscript\duckdb\latest\bin" mkdir "%TEST_TMP%\home\.libscript\duckdb\latest\bin"

(
    echo {
    echo   "name": "backend-deploy-test",
    echo   "dependencies": {
    echo     "nodejs": "lts",
    echo     "python": "3.12",
    echo     "uv": "latest"
    echo   },
    echo   "databases": {
    echo     "primary_pg": {
    echo       "engine": "postgres",
    echo       "version": "17",
    echo       "name": "app_db",
    echo       "user": "app_user"
    echo     },
    echo     "analytics_duck": {
    echo       "engine": "duckdb",
    echo       "path": "./data/analytics.duckdb"
    echo     }
    echo   }
    echo }
) > "%TEST_TMP%\libscript.json"

set "LIBSCRIPT_HOME=%TEST_TMP%\home\.libscript"
set "STACK="
call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\env_printer.cmd" --hydrate "%TEST_TMP%\libscript.json"
set "PATH_PASS_1=!PATH!"

for %%S in (
    "%LIBSCRIPT_HOME%\nodejs\lts\bin"
    "%LIBSCRIPT_HOME%\python\3.12\Scripts"
    "%LIBSCRIPT_HOME%\uv\latest\bin"
    "%LIBSCRIPT_HOME%\postgres\17\bin"
    "%LIBSCRIPT_HOME%\duckdb\latest\bin"
) do (
    echo ";!PATH_PASS_1!;" | findstr /I /C:";%%~S;" >nul 2>&1
    if errorlevel 1 (
        echo [FAIL] Missing expected component PATH segment: %%~S >&2
        rmdir /s /q "%TEST_TMP%" >nul 2>&1
        exit /b 1
    )
)

if "!POSTGRES_URL!"=="" (
    echo [FAIL] POSTGRES_URL was not tunneled across endlocal! >&2
    rmdir /s /q "%TEST_TMP%" >nul 2>&1
    exit /b 1
)
if "!PYTHON_VERSION!"=="" (
    echo [FAIL] PYTHON_VERSION was not tunneled across endlocal! >&2
    rmdir /s /q "%TEST_TMP%" >nul 2>&1
    exit /b 1
)
if "!NODEJS_VERSION!"=="" (
    echo [FAIL] NODEJS_VERSION was not tunneled across endlocal! >&2
    rmdir /s /q "%TEST_TMP%" >nul 2>&1
    exit /b 1
)

set "STACK="
call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\env_printer.cmd" --hydrate "%TEST_TMP%\libscript.json"
set "PATH_PASS_2=!PATH!"

if not "!PATH_PASS_1!"=="!PATH_PASS_2!" (
    echo [FAIL] PATH mutated on second hydration ^(idempotency violation^)! >&2
    rmdir /s /q "%TEST_TMP%" >nul 2>&1
    exit /b 1
)

set "STACK="
call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\env_printer.cmd" --manifest "%TEST_TMP%\libscript.json" dotenv > "%TEST_TMP%\dotenv_out.txt"
findstr /B /C:"SERVICE_PATH=" "%TEST_TMP%\dotenv_out.txt" >nul 2>&1
if errorlevel 1 (
    echo [FAIL] SERVICE_PATH missing from dotenv manifest output! >&2
    rmdir /s /q "%TEST_TMP%" >nul 2>&1
    exit /b 1
)

rmdir /s /q "%TEST_TMP%" >nul 2>&1
echo [PASS] Multi-component PATH inheritance and idempotency verified successfully on Windows.
exit /b 0
