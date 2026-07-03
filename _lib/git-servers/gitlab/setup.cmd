@echo off
:: # setup.cmd
::
:: ## Overview
:: Primary setup script for GitLab on Windows.
::
:: ## Usage
:: Routes to generic setup via `setup_base.cmd`.

setlocal EnableDelayedExpansion
call "%~dp0\..\..\_common\setup_base.cmd" %*
