@echo off
:: # env.cmd
::
:: ## Overview
:: Environment configuration for the EDG C/C++ Compiler Frontend (edgcpp) on Windows.
::
:: ## Usage
:: call _lib\languages\edgcpp\env.cmd

setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"

if defined STACK (
    echo "!STACK!" | findstr /I /C:":!THIS_FILE!:" >nul 2>&1
    if not errorlevel 1 (
        echo [STOP] processing "!THIS_FILE!" >&2
        exit /b 0
    )
)
set "STACK=%STACK%:!THIS_FILE!:"

for %%I in ("%~dp0.") do set "SCRIPT_DIR=%%~fI"

if not defined LIBSCRIPT_ROOT_DIR (
    set "d=!SCRIPT_DIR!"
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

if "%LIBSCRIPT_HOME%"=="" set "LIBSCRIPT_HOME=%USERPROFILE%\.libscript"
set "_edg_home=%LIBSCRIPT_HOME%\edgcpp\default"
if not exist "!_edg_home!" set "_edg_home=%LIBSCRIPT_HOME%\edgcpp\7.0.1"
set "_CAND_P=!_edg_home!\bin"
echo ";!PATH!;" | findstr /I /C:";!_CAND_P!;" >nul 2>&1
if errorlevel 1 set "PATH=!_CAND_P!;!PATH!"
set "CALLER_SCRIPT_DIR=%SCRIPT_DIR%"
call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\env_base.cmd" "edgcpp"
endlocal & (
    set "LIBSCRIPT_HOME=%LIBSCRIPT_HOME%"
    set "EDGCPP_HOME=%_edg_home%"
    set "CPFE_BIN=%_edg_home%\bin\cpfe.exe"
    set "CC=%SCRIPT_DIR%\edgcpp_wrapper.cmd"
    set "CXX=%SCRIPT_DIR%\edgcpp_wrapper.cmd"
    set "HOSTCC=%SCRIPT_DIR%\edgcpp_wrapper.cmd"
    set "CC_BACKEND=edgcpp"
    set "CXX_BACKEND=edgcpp"
    set "EDGCPP_LOG_FILE=%LIBSCRIPT_HOME%\edgcpp\compile_events.jsonl"
    set "PATH=%PATH%"
)
exit /b 0
