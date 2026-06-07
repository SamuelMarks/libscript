@echo off
setlocal EnableDelayedExpansion
if not defined PACKAGE_NAME for %%I in ("%~dp0.") do set "PACKAGE_NAME=%%~nxI"
call "%~dp0\..\..\_common\component_core.cmd" %*
