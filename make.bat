@echo off
:: ## Overview
:: Entry point for common make tasks in Windows batch environment.
::
:: ## Usage
:: make.bat <target>
:: Targets: local_tests_toolchain, local_tests_languages, local_tests_databases

setlocal

if "%~1"=="test" goto local_tests_all
if "%~1"=="local_tests_all" goto local_tests_all
if "%~1"=="test_component" goto test_component
if "%~1"=="local_tests_toolchain" goto local_tests_toolchain
if "%~1"=="local_tests_languages" goto local_tests_languages
if "%~1"=="local_tests_databases" goto local_tests_databases

echo Unknown target %1
exit /b 1

:local_tests_all
call tests\run_local_tests.cmd all
exit /b

:test_component
if "%~2"=="" (
    echo Usage: make.bat test_component ^<component_name^>
    exit /b 1
)
call tests\run_local_tests.cmd %2
exit /b

:local_tests_toolchain
call tests\run_local_tests.cmd toolchains
exit /b

:local_tests_languages
call tests\run_local_tests.cmd languages
exit /b

:local_tests_databases
call tests\run_local_tests.cmd databases
exit /b
