@echo off
rem ## Overview
rem Test suite for Bento Builder stack on Windows.
rem
rem ## Usage
rem Call this script to run tests for Bento Builder on Windows.

setlocal enabledelayedexpansion
set "THIS_FILE=%~f0"

echo === Checking Bento Builder components on Windows ===
call "%~dp0\..\..\..\_lib\orchestration\qemu\test.cmd"
call "%~dp0\..\..\..\_lib\orchestration\virtualbox\test.cmd"
call "%~dp0\..\..\..\_lib\orchestration\packer\test.cmd"
call "%~dp0\..\..\..\_lib\orchestration\vagrant\test.cmd"
echo === Checks finished ===
