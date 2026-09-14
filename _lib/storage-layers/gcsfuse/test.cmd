@echo off
rem ## Overview
rem Test suite for the gcsfuse component.
rem
rem ## Usage
rem Execute this script to perform a component-specific test.

setlocal enabledelayedexpansion
set "THIS_FILE=%~f0"

if exist "%~dp0env.cmd" call "%~dp0env.cmd"

gcsfuse --version
