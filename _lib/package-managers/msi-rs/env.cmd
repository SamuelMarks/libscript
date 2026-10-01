@echo off
:: # env.cmd
::
:: ## Overview
:: Environment variable initialization script for the msi-rs component on Windows.
:: Prepends the isolated msi-rs binary directory to the PATH variable.
::
:: ## Usage
:: Call this script to load environment variables into the current Command Prompt session:
::   call env.cmd

setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"
set "SCRIPT_DIR=%~dp0"
set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"

for %%I in ("%SCRIPT_DIR%") do set "LIBSCRIPT_ROOT_DIR=%%~fI"
:find_root_loop
if exist "%LIBSCRIPT_ROOT_DIR%\libscript.cmd" goto found_root
for %%I in ("%LIBSCRIPT_ROOT_DIR%\..") do set "PARENT_DIR=%%~fI"
if "%PARENT_DIR%"=="%LIBSCRIPT_ROOT_DIR%" goto found_root
set "LIBSCRIPT_ROOT_DIR=%PARENT_DIR%"
goto find_root_loop
:found_root

if "%LIBSCRIPT_HOME%"=="" (
    set "LIBSCRIPT_HOME=%USERPROFILE%\.libscript"
)
if "%MSI_RS_VERSION%"=="" (
    set "MSI_RS_VERSION=latest"
)

set "EXTRA_PATHS="
if exist "%LIBSCRIPT_ROOT_DIR%\tools\wix" set "EXTRA_PATHS=%LIBSCRIPT_ROOT_DIR%\tools\wix;"
if exist "%LIBSCRIPT_HOME%\msi-rs\default\bin" set "EXTRA_PATHS=%EXTRA_PATHS%%LIBSCRIPT_HOME%\msi-rs\default\bin;"

endlocal & set "PATH=%EXTRA_PATHS%%LIBSCRIPT_HOME%\msi-rs\%MSI_RS_VERSION%\bin;%PATH%"
