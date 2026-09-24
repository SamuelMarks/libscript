@echo off
:: # cli.cmd
::
:: ## Overview
:: Command-line interface entry point for PulseAudio sound server on Windows.
::
:: ## Usage
:: Execute this script to perform CLI actions for PulseAudio.

setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"
set "PACKAGE_NAME=pulseaudio"
call "%~dp0..\..\_common\component_core.cmd" %*
