@echo off
:: # make.cmd
::
:: ## Overview
:: Entry point for common make tasks in Windows batch environment.
::
:: ## Usage
:: make.cmd <target> [component_name]
:: Targets: test, local_tests_all, test_component, local_tests_toolchain, local_tests_languages, local_tests_databases

set "THIS_FILE=%~f0"
setlocal

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

echo Unknown target %1 >&2
echo Usage: make.cmd ^<target^> [component_name] >&2
exit /b 1

:: ## show_help
:: Displays available targets.
:show_help
echo Usage: make.cmd ^<target^> [component_name]
echo Targets: test, local_tests_all, test_component, local_tests_toolchain, local_tests_languages, local_tests_databases
exit /b 0

:: ## local_tests_all
:: Executes local_tests_all functionality.
:local_tests_all
call tests\run_local_tests.cmd all
exit /b

:: ## test_component
:: Executes test_component functionality.
:test_component
if "%~2"=="" (
    echo Usage: make.cmd test_component ^<component_name^> >&2
    exit /b 1
)
call tests\run_local_tests.cmd %2
exit /b

:: ## local_tests_toolchain
:: Executes local_tests_toolchain functionality.
:local_tests_toolchain
call tests\run_local_tests.cmd toolchains
exit /b

:: ## local_tests_languages
:: Executes local_tests_languages functionality.
:local_tests_languages
call tests\run_local_tests.cmd languages
exit /b

:: ## local_tests_databases
:: Executes local_tests_databases functionality.
:local_tests_databases
call tests\run_local_tests.cmd databases
exit /b
