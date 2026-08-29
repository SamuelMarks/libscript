@echo off
:: # env.cmd
::
:: ## Overview
:: Internal script for huggingface-cli on Windows.
::
:: ## Usage
:: Executes initialization, logic, or testing for huggingface-cli.
set "THIS_FILE=%~f0"

if "%LIBSCRIPT_HOME%"=="" (
    set "LIBSCRIPT_BASE_DIR=%USERPROFILE%\.libscript"
) else (
    set "LIBSCRIPT_BASE_DIR=%LIBSCRIPT_HOME%"
)
set "HUGGINGFACE_CLI_DIR=%LIBSCRIPT_BASE_DIR%\huggingface-cli\%HUGGINGFACE_CLI_VERSION%"
set "PATH=%HUGGINGFACE_CLI_DIR%\bin;%PATH%"
set "PYTHONPATH=%HUGGINGFACE_CLI_DIR%;%PYTHONPATH%"
