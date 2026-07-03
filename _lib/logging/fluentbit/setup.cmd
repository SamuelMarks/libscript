@echo off
:: # setup.cmd
::
:: ## Overview
:: Primary setup script for Fluent Bit on Windows.
::
:: ## Usage
:: Routes to generic setup via `setup_base.cmd`.

setlocal EnableDelayedExpansion
call "%~dp0\..\..\_common\setup_base.cmd" %*
