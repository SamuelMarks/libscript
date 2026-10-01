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
set "SCRIPT_DIR=%~dp0"
set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"

:: ## find_root
:: Finds the root directory of the libscript repository.
for %%I in ("%SCRIPT_DIR%") do set "LIBSCRIPT_ROOT_DIR=%%~fI"

:find_root_loop
if exist "%LIBSCRIPT_ROOT_DIR%\libscript.cmd" goto found_root
for %%I in ("%LIBSCRIPT_ROOT_DIR%\..") do set "PARENT_DIR=%%~fI"
if "%PARENT_DIR%"=="%LIBSCRIPT_ROOT_DIR%" goto found_root
set "LIBSCRIPT_ROOT_DIR=%PARENT_DIR%"
goto find_root_loop

:found_root
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
