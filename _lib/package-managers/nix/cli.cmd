@echo off
setlocal EnableDelayedExpansion
set "PACKAGE_NAME=nix"
call "%~dp0\..\..\_common\component_core.cmd" %*
