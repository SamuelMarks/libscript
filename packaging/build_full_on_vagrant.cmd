@echo off
:: # build_full_on_vagrant.cmd
::
:: ## Overview
:: Builds the Open edX MSIs on the Windows 11 Vagrant guest (full build).
::
:: ## Usage
::   call build_full_on_vagrant.cmd

setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"
if defined STACK (
    echo !STACK! | findstr /C:":%THIS_FILE%:" >nul 2>&1
    if not errorlevel 1 (
        echo [STOP] processing "%THIS_FILE%" >&2
        exit /b 0
    )
)
set "STACK=%STACK%:%THIS_FILE%:"

set "SCRIPT_DIR=%~dp0"
if "%SCRIPT_DIR:~-1%"=="\" set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"

if not defined LIBSCRIPT_ROOT_DIR (
    set "d=%SCRIPT_DIR%"
    call :find_root
)
goto :root_found

:: ## find_root
:: Ascends the directory tree looking for ROOT or libscript.cmd.
:find_root
if exist "!d!\libscript.cmd" (
    set "LIBSCRIPT_ROOT_DIR=!d!"
    exit /b 0
)
if exist "!d!\ROOT" (
    set "LIBSCRIPT_ROOT_DIR=!d!"
    exit /b 0
)
for %%P in ("!d!") do set "parent=%%~dpP"
set "d=!parent:~0,-1!"
if "!d!"=="" (
    echo Error: Could not find LIBSCRIPT_ROOT_DIR 1>&2
    exit /b 1
)
goto :find_root

:: ## root_found
:: Continues execution once LIBSCRIPT_ROOT_DIR is verified.
:root_found

cd /d "%LIBSCRIPT_ROOT_DIR%\vagrant\windows-11"

echo [INFO] Creating directories on VM...
vagrant ssh -c "powershell -Command \"New-Item -ItemType Directory -Force -Path C:\libscript\""

cd /d "%LIBSCRIPT_ROOT_DIR%"
echo [INFO] Archiving repo...
tar -czf payload.tar.gz --exclude=".git" --exclude="vagrant" --exclude="tests_tmp" .

echo [INFO] Uploading archive...
cd /d "%LIBSCRIPT_ROOT_DIR%\vagrant\windows-11"
vagrant upload "%LIBSCRIPT_ROOT_DIR%\payload.tar.gz" "C:\libscript\payload.tar.gz"

echo [INFO] Extracting archive on VM...
vagrant ssh -c "powershell -Command \"cd C:\libscript; tar -xzf payload.tar.gz\""

echo [INFO] Generating build script...
(
echo $env:PATH += ';' + $env:USERPROFILE + '\.libscript\wix\3.14\bin'
echo cd C:\libscript
echo cmd.exe /c packaging\build_msi.cmd stacks\cms\openedx --online --out OpenEdX-Setup --use-wix
echo cmd.exe /c packaging\build_msi.cmd stacks\cms\openedx --offline --out OpenEdX-Setup-Offline --use-wix
) > "%LIBSCRIPT_ROOT_DIR%\build.ps1"

vagrant upload "%LIBSCRIPT_ROOT_DIR%\build.ps1" "C:\libscript\build.ps1"

echo [INFO] Running build script...
vagrant ssh -c "powershell -ExecutionPolicy Bypass -File C:\libscript\build.ps1"

echo [INFO] Downloading MSIs...
vagrant ssh -c "powershell -Command \"Copy-Item C:\libscript\*.msi C:\vagrant\ -Force\""
copy /y "%LIBSCRIPT_ROOT_DIR%\vagrant\windows-11\OpenEdX-Setup.msi" "%LIBSCRIPT_ROOT_DIR%\packaging\"
copy /y "%LIBSCRIPT_ROOT_DIR%\vagrant\windows-11\OpenEdX-Setup-Offline.msi" "%LIBSCRIPT_ROOT_DIR%\packaging\"

echo [PASS] Done!
exit /b 0
