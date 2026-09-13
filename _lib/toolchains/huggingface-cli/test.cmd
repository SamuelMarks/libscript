@echo off
rem ## Overview
rem Test suite for the huggingface-cli component.
rem
rem ## Usage
rem Execute this script to perform a component-specific test.

setlocal enabledelayedexpansion
set "THIS_FILE=%~f0"

where hf >nul 2>&1
if %errorlevel% equ 0 (
    hf --version
    exit /b 0
)

huggingface-cli --version
