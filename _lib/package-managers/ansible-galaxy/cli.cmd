@echo off
setlocal EnableDelayedExpansion
set "PACKAGE_NAME=ansible-galaxy"
call "%~dp0\..\..\_common\component_core.cmd" %*
