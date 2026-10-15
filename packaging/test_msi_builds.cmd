@echo off
:: # test_msi_builds.cmd
::
:: ## Overview
:: Tests MSI building across multiple platforms via Vagrant.
::
:: ## Usage
::   call packaging\test_msi_builds.cmd

setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"

if defined STACK (
    echo !STACK! | findstr /C:":%THIS_FILE%:" >nul 2^>^&1
    if not errorlevel 1 (
        echo [STOP] processing "%THIS_FILE%" ^>^&2
        exit /b 0
    )
)
set "STACK=%STACK%:%THIS_FILE%:"

set "SCRIPT_DIR=%~dp0"
set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"

:: ## find_root
:: Finds the root directory of the libscript repository.
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
cd /d "%LIBSCRIPT_ROOT_DIR%\vagrant" || exit /b 1

set "VMS=windows-11 macos-14-arm64 debian-13 freebsd-15.1 omnios"

for %%V in (%VMS%) do (
    echo [INFO] Testing on %%V...
    pushd "%%V"
    if errorlevel 1 exit /b 1
    
    vagrant up
    if errorlevel 1 exit /b 1
    
    if "%%V"=="windows-11" (
        vagrant ssh -c "cmd.exe /c \"C:\libscript\packaging\build_msi.cmd --out C:\libscript\test_build\""
    ) else (
        vagrant ssh -c "/bin/sh /vagrant/packaging/build_msi.sh --out /vagrant/test_build"
    )
    if errorlevel 1 exit /b 1
    
    echo [PASS] %%V built successfully.
    popd
)

echo [PASS] All platforms tested successfully.
exit /b 0
