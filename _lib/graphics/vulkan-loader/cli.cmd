@echo off
:: # cli.cmd
::
:: ## Overview
:: Command-line interface entry point for Vulkan Loader on Windows.
::
:: ## Usage
:: Execute this script to perform CLI actions for Vulkan Loader.

setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"
set "PACKAGE_NAME=vulkan-loader"
call "%~dp0..\..\_common\component_core.cmd" %*
