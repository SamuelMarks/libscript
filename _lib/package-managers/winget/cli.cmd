@echo off
setlocal EnableDelayedExpansion
set "PACKAGE_NAME=winget"
call "%~dp0\..\..\_common\component_core.cmd" %*
