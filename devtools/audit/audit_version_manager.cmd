@echo off
:: # audit_version_manager.cmd
::
:: ## Overview
:: Audits all LibScript components in _lib\<category>\<component>\ for strict
:: compliance with the Version Manager Contract (WHAT_A_VERSION_MANAGER_SHOULD_LOOK_LIKE.md
:: and AGENTS.md Section 2) on Windows.
::
:: ## Usage
:: devtools\audit\audit_version_manager.cmd [component_dir ...]

setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"

if defined STACK (
    echo !STACK! | findstr /I /C:":%THIS_FILE%:" >nul 2>&1
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

echo === LibScript Version Manager Contract Audit (Win32) ===

set /a ERRORS=0
set /a AUDITED=0

for /d %%C in ("%LIBSCRIPT_ROOT_DIR%\_lib\*") do (
    set "CAT_NAME=%%~nxC"
    if not "!CAT_NAME!"=="_common" (
        for /d %%D in ("%%C\*") do (
            set /a AUDITED+=1
            for %%F in (cli.sh cli.cmd setup.sh setup.cmd env.sh env.cmd service.sh service.cmd test.sh test.cmd uninstall.sh uninstall.cmd manifest.json vars.schema.json README.md) do (
                if not exist "%%D\%%F" (
                    echo [VM CONTRACT VIOLATION] [MISSING_CONTRACT_FILE] %%D: Missing required file %%F >&2
                    set /a ERRORS+=1
                )
            )
            set "COMP_NAME=%%~nxD"
            if exist "%%D\setup.cmd" (
                findstr /I /R /C:"setup_base\.cmd" /C:"setup_generic\.cmd" "%%D\setup.cmd" >nul 2>&1
                if errorlevel 1 (
                    echo [VM CONTRACT VIOLATION] [SETUP_DELEGATION_WIN] %%D\setup.cmd: Must call or delegate to setup_base.cmd or setup_generic.cmd >&2
                    set /a ERRORS+=1
                )
            )
            if exist "%%D\env.cmd" (
                findstr /I /R /C:"^[ ]*set [^\"]*PATH=.*;%%PATH%%" "%%D\env.cmd" >nul 2>&1
                if not errorlevel 1 (
                    echo [VM CONTRACT VIOLATION] [NON_IDEMPOTENT_PATH_CMD] %%D\env.cmd: Unconditional PATH prepend in env.cmd >&2
                    set /a ERRORS+=1
                )
            )
            if /i not "!CAT_NAME!"=="package-managers" (
                for %%S in ("%%D\setup*.cmd" "%%D\uninstall*.cmd") do (
                    findstr /I /R /C:"^[ ]*winget[ ]*install" /C:"^[ ]*choco[ ]*install" /C:"^[ ]*scoop[ ]*install" /C:"winget[ ]*uninstall" /C:"choco[ ]*uninstall" /C:"scoop[ ]*uninstall" /C:"curl[ ]*-s" /C:"Invoke-WebRequest" /C:"Invoke-RestMethod" "%%S" >nul 2>&1
                    if not errorlevel 1 (
                        echo [VM CONTRACT VIOLATION] [RAW_PKG_MGR_OR_FETCH_IN_RECIPE] %%S: Direct package manager or network fetch call in recipe .cmd >&2
                        set /a ERRORS+=1
                    )
                )
            )
        )
    )
)

if !ERRORS! GTR 0 (
    echo [FAIL] Version Manager Contract Audit failed with !ERRORS! violation^(s^) across !AUDITED! components. >&2
    exit /b 1
)

echo [PASS] All !AUDITED! components strictly adhere to the LibScript Version Manager Contract!
exit /b 0
