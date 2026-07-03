@echo off
:: # setup_generic.cmd
::
:: ## Overview
:: Generic setup script for the asdf component on Windows.
:: It provides fallback installation logic and cross-platform installation steps.
::
:: ## Usage
:: This script is typically called internally by the component lifecycle.

setlocal

if "%ACTION%"=="" set ACTION=install

if "%ACTION%"=="ls" (
    echo [ls] asdf is not supported natively on Windows.
    exit /b 0
)
if "%ACTION%"=="ls-remote" (
    echo [ls-remote] asdf is not supported natively on Windows.
    exit /b 0
)
if "%ACTION%"=="use" (
    echo [use] asdf is not supported natively on Windows.
    exit /b 0
)

echo asdf is not supported natively on Windows. Use mise or scoop instead.
exit /b 1
