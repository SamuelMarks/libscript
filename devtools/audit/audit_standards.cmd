@echo off
:: # audit_standards.cmd
::
:: ## Overview
:: Audits codebase and staged files on Windows for adherence to LibScript engineering standards (POSIX /bin/sh, THIS_FILE, .cmd parity, idempotency, and 100% docstrings).
::
:: ## Usage
:: devtools\audit\audit_standards.cmd [--all | --staged | <file>...]

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

if /I "%~1"=="--help" goto :show_help
if /I "%~1"=="-h" goto :show_help
if /I "%~1"=="/?" goto :show_help
if /I "%~1"=="-?" goto :show_help
goto :main

:: ## show_help
:: Displays command-line usage instructions and available options.
:show_help
echo Usage: %~nx0 [--all ^| --staged ^| ^<file^>...]
echo Audits files for adherence to LibScript engineering standards.
echo.
echo Options:
echo   --all               Audit all tracked script files in repository.
echo   --staged            Audit git-staged files ^(default if no files given^).
echo   --help, -h, /?, -?  Show this help message.
exit /b 0

:: ## main
:: Dispatches to audit_standards.ps1, POSIX dash/sh audit_standards.sh, or native Batch standards checks.
:main
where pwsh.exe >nul 2>&1
if "!ERRORLEVEL!" EQU "0" (
    pwsh.exe -NoProfile -ExecutionPolicy Bypass -File "!SCRIPT_DIR!\audit_standards.ps1" %*
    exit /b !ERRORLEVEL!
)

where powershell.exe >nul 2>&1
if "!ERRORLEVEL!" EQU "0" (
    powershell.exe -NoProfile -ExecutionPolicy Bypass -File "!SCRIPT_DIR!\audit_standards.ps1" %*
    exit /b !ERRORLEVEL!
)

set "_AS_SH_BIN="
for %%S in (dash.exe sh.exe) do (
    if "!_AS_SH_BIN!"=="" (
        where %%S >nul 2>&1
        if not errorlevel 1 set "_AS_SH_BIN=%%S"
    )
)
if not "!_AS_SH_BIN!"=="" (
    set "_AS_SH_SCR=!SCRIPT_DIR:\=/!/audit_standards.sh"
    set "_AS_FWD="
    call :build_sh_args %*
    "!_AS_SH_BIN!" "!_AS_SH_SCR!" !_AS_FWD!
    exit /b !ERRORLEVEL!
)

goto :native_batch_standards_audit

:: ## build_sh_args
:: Normalizes backslashes to forward slashes in CLI file arguments for POSIX sh/dash invocation.
:build_sh_args
if "%~1"=="" exit /b 0
set "_BSA_A=%~1"
set "_BSA_N=!_BSA_A:\=/!"
set "_AS_FWD=!_AS_FWD! "!_BSA_N!""
shift
goto :build_sh_args

:: ## native_batch_standards_audit
:: Performs zero-PowerShell native Windows Batch checks for explicit files, staged files, or --all.
:native_batch_standards_audit
set "_NB_ERR=0"
set "_NB_MODE=staged"
set "_NB_EXPLICIT=0"
set "_NB_LIST=%TEMP%\ls_nb_std_!RANDOM!_!RANDOM!.txt"
type nul > "!_NB_LIST!"
call :parse_nb_args %*

if "!_NB_EXPLICIT!"=="0" (
    pushd "!LIBSCRIPT_ROOT_DIR!"
    if /I "!_NB_MODE!"=="all" (
        git ls-files "*.sh" "*.cmd" "*.bat" "*.ps1" > "!_NB_LIST!" 2>nul
    ) else (
        git diff --cached --name-only --diff-filter=ACMR > "!_NB_LIST!" 2>nul
    )
    popd
)

for /f "usebackq delims=" %%F in ("!_NB_LIST!") do (
    call :audit_nb_one_file "%%F"
)
if exist "!_NB_LIST!" del /f /q "!_NB_LIST!" >nul 2>&1

if not "!_NB_ERR!"=="0" (
    echo [AUDIT] !_NB_ERR! standards violation^(s^) found. >&2
    exit /b 1
)
echo [AUDIT] All inspected files adhere to LibScript engineering standards.
exit /b 0

:: ## parse_nb_args
:: Collects --all, --staged, or explicit target file paths into _NB_LIST.
:parse_nb_args
if "%~1"=="" exit /b 0
if /I "%~1"=="--all" (
    set "_NB_MODE=all"
    shift
    goto :parse_nb_args
)
if /I "%~1"=="--staged" (
    set "_NB_MODE=staged"
    shift
    goto :parse_nb_args
)
set "_NB_EXPLICIT=1"
>>"!_NB_LIST!" echo.%~1
shift
goto :parse_nb_args

:: ## audit_nb_one_file
:: Audits a single .sh, .cmd, or .bat file using native Windows Batch and findstr rules.
:audit_nb_one_file
set "_NBF=%~1"
if "!_NBF!"=="" exit /b 0
set "_NBF_PATH=!_NBF!"
if not exist "!_NBF_PATH!" (
    if exist "!LIBSCRIPT_ROOT_DIR!\!_NBF!" set "_NBF_PATH=!LIBSCRIPT_ROOT_DIR!\!_NBF!"
)
if not exist "!_NBF_PATH!" exit /b 0

if "!_NB_EXPLICIT!"=="0" (
    echo "!_NBF!" | findstr /I /C:"tests_tmp" /C:"node_modules" /C:".git/" /C:".git\" >nul 2>&1
    if not errorlevel 1 exit /b 0
)

for %%E in ("!_NBF_PATH!") do set "_NB_EXT=%%~xE"

if /I "!_NB_EXT!"==".sh" (
    set "_NB_CMD=!_NBF_PATH:~0,-3!.cmd"
    set "_NB_BAT=!_NBF_PATH:~0,-3!.bat"
    echo "!_NBF!" | findstr /I /C:".githooks/pre-commit" /C:".githooks\pre-commit" /C:"dockerfiles-ssh" >nul 2>&1
    if errorlevel 1 (
        if not exist "!_NB_CMD!" if not exist "!_NB_BAT!" (
            echo [STANDARDS VIOLATION] [WINDOWS_PARITY] !_NBF!: Missing Windows batch equivalent file. >&2
            set /a _NB_ERR+=1
        )
    )
    findstr /R /C:"^[ ]*eval " /C:"^[ ]*eval$" /C:"if[ ]*![ ]*([ ]*return[ ]*0" "!_NBF_PATH!" >nul 2>&1
    if not errorlevel 1 (
        findstr /R /C:"if[ ]*![ ]*([ ]*return[ ]*0" "!_NBF_PATH!" >nul 2>&1
        if not errorlevel 1 (
            echo [STANDARDS VIOLATION] [DASH_UNSAFE_RETURN_PROBE] !_NBF!: Unsafe top-level return 0 probe found. >&2
            set /a _NB_ERR+=1
        ) else (
            echo [STANDARDS VIOLATION] [BAN_EVAL] !_NBF!: Disallowed use of 'eval' found. >&2
            set /a _NB_ERR+=1
        )
    )
    exit /b 0
)

if /I "!_NB_EXT!"==".cmd" goto :audit_nb_batch_ext
if /I "!_NB_EXT!"==".bat" goto :audit_nb_batch_ext
exit /b 0

:: ## audit_nb_batch_ext
:: Enforces Batch AST/quote/loop rules (BATCH_FOR_R_DELAYED, BATCH_QUOTED_DOUBLE_CARET_BANG, POSIX_PARITY) on .cmd/.bat files.
:audit_nb_batch_ext
if "!_NB_EXPLICIT!"=="0" (
    set "_NB_SH=!_NBF_PATH:~0,-4!.sh"
    if not exist "!_NB_SH!" (
        echo [STANDARDS VIOLATION] [POSIX_PARITY] !_NBF!: Missing POSIX shell equivalent file. >&2
        set /a _NB_ERR+=1
    )
)
set "_NB_TMP_BASE=%TEMP%"
if "!_NB_TMP_BASE!"=="" set "_NB_TMP_BASE=%TMP%"
if "!_NB_TMP_BASE!"=="" set "_NB_TMP_BASE=!LIBSCRIPT_ROOT_DIR!\build"
if not exist "!_NB_TMP_BASE!" mkdir "!_NB_TMP_BASE!" >nul 2>&1
for %%A in ("!_NB_TMP_BASE!") do set "_NB_TMP_BASE=%%~fA"
set "_NB_TMP1=!_NB_TMP_BASE!\ls_nb_b1_!RANDOM!_!RANDOM!.txt"
set "_NB_TMP2=!_NB_TMP_BASE!\ls_nb_b2_!RANDOM!_!RANDOM!.txt"
findstr /I /R /C:"for[ ][ ]*/r[ ][ ]*.!" /C:"for[ ][ ]*/r[ ][ ]*!" "!_NBF_PATH!" > "!_NB_TMP1!" 2>nul
findstr /V /I /R /C:"^[ ]*::" /C:"^[ ]*rem " "!_NB_TMP1!" >nul 2>&1
if not errorlevel 1 (
    echo [STANDARDS VIOLATION] [BATCH_FOR_R_DELAYED] !_NBF!: Unexpanded delayed variable in FOR /R root path. >&2
    set /a _NB_ERR+=1
)
set "_NB_DC=^^^^"
findstr /C:"!_NB_DC!^!" "!_NBF_PATH!" > "!_NB_TMP1!" 2>nul
findstr /R /C:"=[ ]*[^ ].*!_NB_DC!^!" /C:"echo[ ].*!_NB_DC!^!" "!_NB_TMP1!" > "!_NB_TMP2!" 2>nul
findstr /V /I /R /C:"^[ ]*::" /C:"^[ ]*rem " "!_NB_TMP2!" >nul 2>&1
if not errorlevel 1 (
    echo [STANDARDS VIOLATION] [BATCH_QUOTED_DOUBLE_CARET_BANG] !_NBF!: Double-caret bang inside double quotes under EnableDelayedExpansion. >&2
    set /a _NB_ERR+=1
)
del /f /q "!_NB_TMP1!" "!_NB_TMP2!" >nul 2>&1
exit /b 0
