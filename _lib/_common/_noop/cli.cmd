@echo off
:: # cli.cmd
::
:: ## Overview
:: Provides the command-line interface logic for the `_noop` component on Windows.
:: This component acts as a stub or template, meaning this script intentionally
:: executes a no-operation and exits successfully.
:: 
:: ## Usage
:: Run this script directly to execute the no-op behavior.

setlocal EnableDelayedExpansion
REM No-op cli
set "THIS_FILE=%~f0"
exit /b 0
