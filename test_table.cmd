@echo off
:: # test_table.cmd
::
:: ## Overview
:: Generates a markdown table displaying the testing status of components on Windows.
::
:: ## Usage
:: Run this script to generate components_table.tmp and print it.

setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"
set "SCRIPT_DIR=%~dp0"
if "%SCRIPT_DIR:~-1%"=="\" set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"

> components_table.tmp (
    echo ## Supported Components
    echo.
    echo ^| Component ^| Linux ^| Windows ^| DOS ^| SunOS ^| FreeBSD ^|
    echo ^|---^|---^|---^|---^|---^|---^|
)

for /d %%C in ("%SCRIPT_DIR%\_lib\*") do (
    for /d %%D in ("%%C\*") do (
        set "comp_name=%%~nxD"
        if not "!comp_name!"=="_common" (
            set "linux_status=-"
            if exist "%SCRIPT_DIR%\tests_tmp\!comp_name!.linux.alpine.success" set "linux_status=OK"
            if exist "%SCRIPT_DIR%\tests_tmp\!comp_name!.linux.alpine.failure" set "linux_status=FAIL"
            >> components_table.tmp echo ^| `!comp_name!` ^| !linux_status! ^| - ^| - ^| - ^| - ^|
        )
    )
)

type components_table.tmp
exit /b 0
