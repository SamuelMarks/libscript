@echo off
:: # uninstall_generic.cmd
::
:: ## Overview
:: Generic uninstall script for msys2 on Windows.
::
:: ## Usage
:: Routes to generic uninstallation via `_common\uninstall_generic.cmd`.

setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"
if exist "%~dp0\..\..\_common\uninstall_generic.cmd" (
    call "%~dp0\..\..\_common\uninstall_generic.cmd" %*
)
