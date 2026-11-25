@echo off
:: # dos_batch_lint.cmd
::
:: ## Overview
:: Validates or lowers DOS .BAT scripts for legacy COMMAND.COM and FreeCOM compatibility
:: using wincheck --dialect dos622 (win-cmd-rs) with deterministic fallback checks for
:: CMD5004 (& chain splitting) and CMD5006 (GOTO :EOF lowering).
::
:: ## Usage
:: engine\common\dos_batch_lint.cmd [--mode=lint^|rewrite] <file.bat> [...]

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

set "SCRIPT_DIR=%~dp0"
if "%SCRIPT_DIR:~-1%"=="\" set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"

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

set "LINT_MODE=lint"
set "HAS_FILES=0"
set "OVERALL_RC=0"
call :resolve_wincheck
goto :parse_args

:: ## parse_args
:: Iterates over CLI options and dispatches each target .BAT file.
:parse_args
if "%~1"=="" goto :done_args
if /I "%~1"=="--help" goto :show_help
if /I "%~1"=="-h" goto :show_help
if "%~1"=="/?" goto :show_help
if /I "%~1"=="--rewrite" (
    set "LINT_MODE=rewrite"
    shift
    goto :parse_args
)
if /I "%~1"=="--mode=rewrite" (
    set "LINT_MODE=rewrite"
    shift
    goto :parse_args
)
if /I "%~1"=="--mode=lint" (
    set "LINT_MODE=lint"
    shift
    goto :parse_args
)
if /I "%~1"=="--mode" (
    set "LINT_MODE=%~2"
    shift
    shift
    goto :parse_args
)
set "HAS_FILES=1"
if not exist "%~1" (
    echo [ERROR] Batch file not found: %~1 1>&2
    set "OVERALL_RC=1"
    shift
    goto :parse_args
)
if /I "!LINT_MODE!"=="rewrite" (
    call :rewrite_dos622 "%~1"
    if errorlevel 1 set "OVERALL_RC=1"
) else (
    call :lint_dos622 "%~1"
    if errorlevel 1 set "OVERALL_RC=1"
)
shift
goto :parse_args

:: ## done_args
:: Finalizes argument processing and exits with accumulated status code.
:done_args
if "!HAS_FILES!"=="0" (
    call :show_help 1>&2
    exit /b 1
)
exit /b !OVERALL_RC!

:: ## show_help
:: Prints CLI usage for dos_batch_lint.cmd.
:show_help
echo Usage: %~nx0 [--mode=lint^|rewrite] ^<file.bat^> [...]
echo Validates or lowers DOS batch files for COMMAND.COM / FreeCOM ^(CMD5004, CMD5006^).
exit /b 0

:: ## resolve_wincheck
:: Locates wincheck.exe on PATH or inside LIBSCRIPT_HOME if installed.
:resolve_wincheck
set "WC_BIN="
for %%W in (wincheck.exe wincheck) do (
    where %%W >nul 2>&1
    if not errorlevel 1 (
        for /f "delims=" %%P in ('where %%W 2^>nul') do (
            if "!WC_BIN!"=="" set "WC_BIN=%%~fP"
        )
    )
)
if "!WC_BIN!"=="" (
    set "_LSH=%LIBSCRIPT_HOME%"
    if "!_LSH!"=="" set "_LSH=%USERPROFILE%\.libscript"
    if exist "!_LSH!\win-cmd-rs\default\bin\wincheck.exe" set "WC_BIN=!_LSH!\win-cmd-rs\default\bin\wincheck.exe"
)
exit /b 0

:: ## lint_dos622
:: Validates a single DOS .BAT file using wincheck --dialect dos622 or built-in findstr rules.
:lint_dos622
set "_LDF=%~1"
if not "!WC_BIN!"=="" (
    "!WC_BIN!" --help 2>&1 | findstr /I /C:"dialect" >nul 2>&1
    if not errorlevel 1 (
        "!WC_BIN!" --dialect dos622 --severity warning --exclude CMD2013 "!_LDF!"
        exit /b !errorlevel!
    )
)
set "_LDF_ERR=0"
findstr /I /R /C:"GOTO  *:EOF" "!_LDF!" >nul 2>&1
if not errorlevel 1 (
    echo [DOS622 LINT] [CMD5006] !_LDF!: GOTO :EOF is unsupported by legacy COMMAND.COM. 1>&2
    set "_LDF_ERR=1"
)
findstr /R /C:" & " "!_LDF!" | findstr /V /B /I /C:"REM " | findstr /V /B /C:"::" >nul 2>&1
if not errorlevel 1 (
    echo [DOS622 LINT] [CMD5004] !_LDF!: Unquoted ^& command separator is unsupported by legacy COMMAND.COM. 1>&2
    set "_LDF_ERR=1"
)
exit /b !_LDF_ERR!

:: ## rewrite_dos622
:: Rewrites GOTO :EOF into GOTO EOF and appends :EOF if missing.
:rewrite_dos622
set "_RDF=%~1"
set "_RDF_TMP=!_RDF!.dos622.!RANDOM!"
set "_NEED_EOF=0"
set "_HAS_EOF=0"
findstr /I /R /C:"^ *:EOF *$" "!_RDF!" >nul 2>&1
if not errorlevel 1 set "_HAS_EOF=1"
if exist "!_RDF_TMP!" del /f /q "!_RDF_TMP!" >nul 2>&1
for /f "usebackq delims=" %%L in ("!_RDF!") do call :emit_rewritten_line "%%L"
if "!_NEED_EOF!"=="1" if "!_HAS_EOF!"=="0" (
    >> "!_RDF_TMP!" echo :EOF
)
move /y "!_RDF_TMP!" "!_RDF!" >nul
exit /b 0

:: ## emit_rewritten_line
:: Lowers GOTO :EOF on a single line and appends it safely to _RDF_TMP.
:emit_rewritten_line
set "_LINE=%~1"
echo(!_LINE!| findstr /I /R /C:"GOTO  *:EOF" >nul 2>&1
if not errorlevel 1 (
    set "_LINE=!_LINE:GOTO :EOF=GOTO EOF!"
    set "_LINE=!_LINE:goto :eof=GOTO EOF!"
    set "_NEED_EOF=1"
)
>> "!_RDF_TMP!" echo(!_LINE!
exit /b 0
