@echo off
rem ## Overview
rem Test suite for the gcp component.
rem
rem ## Usage
rem Execute this script to perform a component-specific test.

setlocal enabledelayedexpansion

if exist "%~dp0cli.cmd" (
    call "%~dp0cli.cmd" --help >nul
) else (
    exit /b 0
)
