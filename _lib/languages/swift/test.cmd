@echo off
rem ## Overview
rem Test suite for the swift component.
rem
rem ## Usage
rem Execute this script to perform a component-specific test.

setlocal enabledelayedexpansion
set "THIS_FILE=%~f0"

if exist "%USERPROFILE%\.local\bin" (
    set "PATH=%USERPROFILE%\.local\bin;!PATH!"
)

for /d %%S in ("%LOCALAPPDATA%\Programs\Swift\Toolchains\*") do (
    if exist "%%S\usr\bin\swift.exe" set "PATH=%%S\usr\bin;!PATH!"
)
for /d %%S in ("%ProgramFiles%\Swift\Toolchains\*") do (
    if exist "%%S\usr\bin\swift.exe" set "PATH=%%S\usr\bin;!PATH!"
)

swift --version
