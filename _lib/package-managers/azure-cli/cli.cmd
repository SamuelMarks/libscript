@echo off
setlocal EnableDelayedExpansion
set "PACKAGE_NAME=azure-cli"
call "%~dp0\..\..\_common\component_core.cmd" %*
