@echo off
:: # env.cmd
::
:: ## Overview
:: Internal script for xpk on Windows.
::
:: ## Usage
:: Executes initialization, logic, or testing for xpk.
set "THIS_FILE=%~f0"

if "%LIBSCRIPT_HOME%"=="" (
    set "LIBSCRIPT_BASE_DIR=%USERPROFILE%\.libscript"
) else (
    set "LIBSCRIPT_BASE_DIR=%LIBSCRIPT_HOME%"
)
set "XPK_DIR=%LIBSCRIPT_BASE_DIR%\xpk\%XPK_VERSION%"
set "PATH=%XPK_DIR%\bin;%PATH%"
set "PYTHONPATH=%XPK_DIR%;%PYTHONPATH%"
