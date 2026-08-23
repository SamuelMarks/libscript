@echo off
rem ## Overview
rem Test suite for the 7zip component.
rem
rem ## Usage
rem Execute this script to perform a component-specific test.

setlocal enabledelayedexpansion

7z i
if %errorlevel% neq 0 (
    7za i
)
