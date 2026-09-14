@echo off
rem ## Overview
rem Test suite for the nimble component.
rem
rem ## Usage
rem Execute this script to perform a component-specific test.

setlocal enabledelayedexpansion
set "THIS_FILE=%~f0"

if exist "%USERPROFILE%\.local\bin" (
    set "PATH=%USERPROFILE%\.local\bin;!PATH!"
)

nimble --version
