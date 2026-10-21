@echo off
:: # make.cmd
::
:: ## Overview
:: Entry point for common make tasks in Windows batch environment.
::
:: ## Usage
:: make.cmd <target> [component_name]
:: Targets: test, local_tests_all, test_component, local_tests_toolchain, local_tests_languages, local_tests_databases

setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"
if defined STACK (
    echo "!STACK!" | findstr /C:":%THIS_FILE%:" >nul 2>&1
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


if "%~1"=="--help" goto show_help
if "%~1"=="-h" goto show_help
if "%~1"=="/?" goto show_help
if "%~1"=="-?" goto show_help

if "%~1"=="test" goto local_tests_all
if "%~1"=="local_tests_all" goto local_tests_all
if "%~1"=="test_component" goto test_component
if "%~1"=="local_tests_toolchain" goto local_tests_toolchain
if "%~1"=="local_tests_languages" goto local_tests_languages
if "%~1"=="local_tests_databases" goto local_tests_databases
if "%~1"=="audit" goto audit
if "%~1"=="update_results" goto update_results
if "%~1"=="register_bento_boxes" goto register_bento_boxes
if "%~1"=="test_canary_6os" goto test_canary_6os
if "%~1"=="test_matrix_6os" goto test_matrix_6os

echo Unknown target %1 >&2
echo Usage: make.cmd ^<target^> [component_name] >&2
exit /b 1

:: ## show_help
:: Displays available targets.
:show_help
echo Usage: make.cmd ^<target^> [component_name]
echo Targets: audit, update_results, register_bento_boxes, test_canary_6os, test_matrix_6os, test, local_tests_all, test_component, local_tests_toolchain, local_tests_languages, local_tests_databases
exit /b 0

:: ## audit
:: Executes the full static and behavioral standards audit suite.
:audit
call "%LIBSCRIPT_ROOT_DIR%\devtools\audit\audit_standards.cmd" --all
if errorlevel 1 exit /b 1
call "%LIBSCRIPT_ROOT_DIR%\devtools\audit\audit_posix.cmd"
if errorlevel 1 exit /b 1
call "%LIBSCRIPT_ROOT_DIR%\devtools\audit\audit_version_manager.cmd"
if errorlevel 1 exit /b 1
call "%LIBSCRIPT_ROOT_DIR%\devtools\audit\doc_coverage.cmd" --strict
if errorlevel 1 exit /b 1
call "%LIBSCRIPT_ROOT_DIR%\tests\test_doc_coverage.cmd"
if errorlevel 1 exit /b 1
call "%LIBSCRIPT_ROOT_DIR%\tests\test_vm_contract.cmd"
if errorlevel 1 exit /b 1
call "%LIBSCRIPT_ROOT_DIR%\tests\test_update_results.cmd"
exit /b %ERRORLEVEL%

:: ## update_results
:: Regenerates the tiered Supported Components tables in README.md and matrix_results.json.
:update_results
call "%LIBSCRIPT_ROOT_DIR%\tests\update_results.cmd" --json
exit /b %ERRORLEVEL%

:: ## register_bento_boxes
:: Registers all 6 target OS Vagrant boxes from ..\bento\builds\build_complete\.
:register_bento_boxes
call "%LIBSCRIPT_ROOT_DIR%\tests\register_bento_boxes.cmd"
exit /b %ERRORLEVEL%

:: ## test_canary_6os
:: Runs the 10 canary components across all 6 Vagrant OS VMs.
:test_canary_6os
call "%LIBSCRIPT_ROOT_DIR%\tests\run_omnios_tests.cmd" jq curl sqlite c cmake nodejs python rust postgres nginx
call "%LIBSCRIPT_ROOT_DIR%\tests\run_alpine_tests.cmd" jq curl sqlite c cmake nodejs python rust postgres nginx
call "%LIBSCRIPT_ROOT_DIR%\tests\run_debian_tests.cmd" jq curl sqlite c cmake nodejs python rust postgres nginx
call "%LIBSCRIPT_ROOT_DIR%\tests\run_rockylinux_tests.cmd" jq curl sqlite c cmake nodejs python rust postgres nginx
call "%LIBSCRIPT_ROOT_DIR%\tests\run_freebsd_tests.cmd" jq curl sqlite c cmake nodejs python rust postgres nginx
call "%LIBSCRIPT_ROOT_DIR%\tests\run_windows_tests.cmd" jq curl sqlite c cmake nodejs python rust postgres nginx
exit /b %ERRORLEVEL%

:: ## test_matrix_6os
:: Runs the full Vagrant 6-OS test matrix.
:test_matrix_6os
call "%LIBSCRIPT_ROOT_DIR%\tests\run_vagrant_matrix.cmd"
exit /b %ERRORLEVEL%

:: ## local_tests_all
:: Performs the local_tests_all operation and updates component state.
:local_tests_all
call tests\run_local_tests.cmd all
exit /b

:: ## test_component
:: Performs the test_component operation and updates component state.
:test_component
if "%~2"=="" (
    echo Usage: make.cmd test_component ^<component_name^> >&2
    exit /b 1
)
call tests\run_local_tests.cmd %2
exit /b

:: ## local_tests_toolchain
:: Performs the local_tests_toolchain operation and updates component state.
:local_tests_toolchain
call tests\run_local_tests.cmd toolchains
exit /b

:: ## local_tests_languages
:: Performs the local_tests_languages operation and updates component state.
:local_tests_languages
call tests\run_local_tests.cmd languages
exit /b

:: ## local_tests_databases
:: Performs the local_tests_databases operation and updates component state.
:local_tests_databases
call tests\run_local_tests.cmd databases
exit /b
