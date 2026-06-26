@echo off
setlocal EnableDelayedExpansion
set "PACKAGE_NAME=nextcloud"
call "%~dp0..\..\..\_lib\_common\component_core.cmd" %*
