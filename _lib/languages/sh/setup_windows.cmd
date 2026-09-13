@echo off
setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"

where sh >nul 2>&1
if %errorlevel% equ 0 exit /b 0

if exist "%ProgramFiles%\Git\bin\sh.exe" exit /b 0
if exist "%ProgramFiles%\Git\usr\bin\sh.exe" exit /b 0

where busybox >nul 2>&1
if not errorlevel 1 (
    (
        echo @echo off
        echo busybox sh %%*
    ) > "%USERPROFILE%\.local\bin\sh.cmd"
    exit /b 0
)

exit /b 0
