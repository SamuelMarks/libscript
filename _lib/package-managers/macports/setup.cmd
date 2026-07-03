@echo off
:: # setup.cmd
::
:: ## Overview
:: Installation and configuration script for the macports component on Windows.
:: It handles downloading, verifying, and installing the component on the host system.
::
:: ## Usage
:: Execute this script to install or configure the component.

setlocal EnableDelayedExpansion
call "%~dp0\..\..\_common\setup_base.cmd" %*
