@echo off
REM ## Overview
REM Runs CI tests strictly for toolchains and databases components on Windows.
REM 
REM ## Usage
REM run_tests.cmd [os_name]
REM Execute this script to test all components within _lib\toolchains and _lib\databases.
REM Optionally pass the target OS as the first argument.

setlocal enabledelayedexpansion

set "TARGET_OS=%~1"
if "!TARGET_OS!"=="" set "TARGET_OS=windows-latest"

set "FAILED_COMPONENTS="

echo ^>^>^> STARTING TESTS FOR TOOLCHAINS AND DATABASES ^<^<^<

REM Compute ROOT directory dynamically
set "SCRIPT_DIR=%~dp0"
:FIND_ROOT
if exist "%SCRIPT_DIR%\libscript.cmd" (
    set "LIBSCRIPT_ROOT_DIR=%SCRIPT_DIR%"
    goto :ROOT_FOUND
)
for %%I in ("%SCRIPT_DIR%\..") do set "SCRIPT_DIR=%%~fI"
goto :FIND_ROOT
:ROOT_FOUND

cd /d "%LIBSCRIPT_ROOT_DIR%" || exit /b 1

for %%T in ("_lib\toolchains" "_lib\databases") do (
    for /d %%D in ("%%~T\*") do (
        set "COMP=%%~D"
        REM Convert backslashes to forward slashes for compatibility with run_test_component
        set "COMP=!COMP:\=/!"
        call devtools\ci\run_test_component.cmd "!COMP!" "!TARGET_OS!" || set FAILED_COMPONENTS=!FAILED_COMPONENTS! !COMP!
    )
)

if not "!FAILED_COMPONENTS!"=="" (
    echo The following components failed: !FAILED_COMPONENTS!
    exit /b 1
)
exit /b 0
