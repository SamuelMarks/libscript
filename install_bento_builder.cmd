@echo off
:: # install_bento_builder.cmd
::
:: ## Overview
:: Standalone Windows batch installer to provision the Bento Builder environment.
::
:: ## Usage
:: Execute this script from Command Prompt to install Bento Builder dependencies.

setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"

echo ====================================================
echo  Bento Builder Environment Installer (Windows cmd)
echo ====================================================

call "%~dp0stacks\virtualization\bento-builder\setup.cmd" install
echo Installation complete! Running validation tests...
call "%~dp0stacks\virtualization\bento-builder\test.cmd"
