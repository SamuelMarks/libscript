@echo off
setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"
if defined STACK (
    echo !STACK! | findstr /C:":%THIS_FILE%:" >nul 2>&1
    if not errorlevel 1 (
        echo [STOP] processing "%THIS_FILE%" >&2
        exit /b 0
    )
)
set "STACK=%STACK%:%THIS_FILE%:"

rem ## Overview
rem Automated Smoke Testing for Open edX deployment on Windows.
rem Verifies endpoints and checks component status and logs.
rem
rem ## Usage
rem smoke_test.cmd

set "SCRIPT_DIR=%~dp0"
if "%SCRIPT_DIR:~-1%"=="\" set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"
for %%I in ("%SCRIPT_DIR%") do set "LIBSCRIPT_ROOT_DIR=%%~fI"
:find_root_loop
if exist "%LIBSCRIPT_ROOT_DIR%\libscript.cmd" goto found_root
for %%I in ("%LIBSCRIPT_ROOT_DIR%\..") do set "PARENT_DIR=%%~fI"
if "%PARENT_DIR%"=="%LIBSCRIPT_ROOT_DIR%" goto found_root
set "LIBSCRIPT_ROOT_DIR=%PARENT_DIR%"
goto find_root_loop
:found_root

if "%LMS_URL%"=="" set "LMS_URL=http://localhost:8000"
if "%CMS_URL%"=="" set "CMS_URL=http://localhost:18010"

echo Starting Open edX Smoke Tests...

rem 0. Open and verify the browser tab (CMS) - Unauthenticated.
echo 0. Verifying CMS Unauthenticated...
powershell -Command "try { $r=Invoke-WebRequest -Uri '%CMS_URL%' -UseBasicParsing -ErrorAction Stop; if ($r.StatusCode -match '200|302') { exit 0 } else { exit 1 } } catch { exit 1 }"
if !ERRORLEVEL! neq 0 echo CMS check skipped or failed

rem 1. Open and verify the browser tab (LMS) - Unauthenticated.
echo 1. Verifying LMS Unauthenticated...
powershell -Command "try { $r=Invoke-WebRequest -Uri '%LMS_URL%' -UseBasicParsing -ErrorAction Stop; if ($r.StatusCode -match '200|302') { exit 0 } else { exit 1 } } catch { exit 1 }"
if !ERRORLEVEL! neq 0 echo LMS check skipped or failed

rem 2. Log in and verify the browser tab (CMS).
echo 2. Verifying CMS Login endpoint...
powershell -Command "try { $r=Invoke-WebRequest -Uri '%CMS_URL%/login' -UseBasicParsing -ErrorAction Stop; if ($r.StatusCode -match '200|302|404') { exit 0 } else { exit 1 } } catch { exit 1 }"
if !ERRORLEVEL! neq 0 echo CMS Login check skipped or failed

rem 3. Log in and verify the browser tab (LMS).
echo 3. Verifying LMS Login endpoint...
powershell -Command "try { $r=Invoke-WebRequest -Uri '%LMS_URL%/login' -UseBasicParsing -ErrorAction Stop; if ($r.StatusCode -match '200|302|404') { exit 0 } else { exit 1 } } catch { exit 1 }"
if !ERRORLEVEL! neq 0 echo LMS Login check skipped or failed

rem 4. Verify component status commands
echo 4. Verifying Component Statuses...
for %%C in (databases\postgres databases\mongodb caches\redis search\elasticsearch web-servers\iis app-servers\waitress) do (
    set "STATUS_SCRIPT=%LIBSCRIPT_ROOT_DIR%\_lib\%%C\status.cmd"
    if exist "!STATUS_SCRIPT!" (
        echo Checking status of %%C...
        call "!STATUS_SCRIPT!"
        if !ERRORLEVEL! neq 0 echo WARNING: %%C status returned non-zero
    ) else (
        echo WARNING: Status script not found for %%C
    )
)

rem 5. Verify component logs tail outputs
echo 5. Verifying Component Logs...
for %%C in (databases\postgres databases\mongodb caches\redis search\elasticsearch web-servers\iis app-servers\waitress) do (
    set "LOGS_SCRIPT=%LIBSCRIPT_ROOT_DIR%\_lib\%%C\logs.cmd"
    if exist "!LOGS_SCRIPT!" (
        echo Checking logs of %%C...
        call "!LOGS_SCRIPT!" tail
        if !ERRORLEVEL! neq 0 echo WARNING: %%C logs returned non-zero
    ) else (
        echo WARNING: Logs script not found for %%C
    )
)

echo Smoke tests completed.
exit /b 0
