@echo off
:: # build_openedx_msi.cmd
::
:: ## Overview
:: Generates a WiX Windows Installer (.msi) package for Open edX on Windows.
:: Delegates to generic packaging\build_msi.cmd with stacks\cms\openedx target.
::
:: ## Usage
:: call packaging\build_openedx_msi.cmd [OPTIONS]

setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"
set "SCRIPT_DIR=%~dp0"
set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"

:: ## find_root
:: Finds the root directory of the libscript repository.
for %%I in ("%SCRIPT_DIR%") do set "LIBSCRIPT_ROOT_DIR=%%~fI"

:: ## find_root_loop
:: Iterates upward through the directory tree looking for libscript.cmd.
:find_root_loop
if exist "%LIBSCRIPT_ROOT_DIR%\libscript.cmd" goto found_root
for %%I in ("%LIBSCRIPT_ROOT_DIR%\..") do set "PARENT_DIR=%%~fI"
if "%PARENT_DIR%"=="%LIBSCRIPT_ROOT_DIR%" goto found_root
set "LIBSCRIPT_ROOT_DIR=%PARENT_DIR%"
goto find_root_loop

:: ## found_root
:: Target label reached once the libscript root directory is located.
:found_root

:: ## delegate_build
:: Calls generic build_msi.cmd targeting stacks\cms\openedx.
call "%SCRIPT_DIR%\build_msi.cmd" stacks\cms\openedx %*
exit /b %ERRORLEVEL%
