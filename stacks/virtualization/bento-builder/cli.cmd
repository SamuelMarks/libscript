@echo off
:: # cli.cmd
:: Command-line interface entry point for Bento Builder stack on Windows.
setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"
set "PACKAGE_NAME=bento-builder"
call "%~dp0\..\..\..\_lib\_common\component_core.cmd" %*
