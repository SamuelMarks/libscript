@echo off
setlocal EnableDelayedExpansion
set "PACKAGE_NAME=nuget"
call "%~dp0\..\..\_common\component_core.cmd" %*
