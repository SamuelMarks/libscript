@echo off
:: # audit_tiers.cmd
:: ## Overview
:: Pure Zero-PowerShell Windows Batch architectural tier auditor enforcing T0-T5 + Orthogonal Planes
:: boundaries (TIER_UPWARD_IMPORT, LIB_ATOMIC_PURITY, NO_FRACTIONAL_TIERS, NO_LEGACY_ALIASES).
:: ## Usage
:: devtools\audit\audit_tiers.cmd [--all|--staged] [--root <repo_dir>]

setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"

if defined STACK (
    echo "!STACK!" | findstr /I /C:":!THIS_FILE!:" >nul 2>&1
    if not errorlevel 1 (
        if "%LIBSCRIPT_DEBUG%"=="1" echo [STOP] processing "!THIS_FILE!" >&2
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

set "TARGET_ROOT=!LIBSCRIPT_ROOT_DIR!"
goto :parse_args

:: ## parse_args
:: Parses CLI options for audit_tiers.cmd.
:parse_args
if "%~1"=="" goto :args_done
if /i "%~1"=="--help" goto :show_help
if /i "%~1"=="-h" goto :show_help
if /i "%~1"=="--root" (
    set "TARGET_ROOT=%~2"
    shift
    shift
    goto :parse_args
)
shift
goto :parse_args

:: ## show_help
:: Displays usage instructions for audit_tiers.cmd.
:show_help
echo Usage: devtools\audit\audit_tiers.cmd [--all^|--staged] [--root ^<repo_dir^>]
exit /b 0

:: ## args_done
:: Runs all four architectural tier verification passes.
:args_done
for %%R in ("!TARGET_ROOT!") do set "TARGET_ROOT=%%~fR"
set "ERRORS=0"

call :check_no_legacy_aliases
call :check_lib_atomic_purity
call :check_upward_imports
call :check_no_fractional_tiers

if not "!ERRORS!"=="0" (
    echo [FAIL] Architectural tier audit failed with !ERRORS! violation^(s^). >&2
    exit /b 1
)
echo [PASS] All T0-T5 tiers and orthogonal planes satisfy strict architectural boundaries.
exit /b 0

:: ## check_no_legacy_aliases
:: Verifies deleted legacy directories and normalize_component_alias shims do not exist.
:check_no_legacy_aliases
for %%L in (_lib\_common _lib\orchestration _lib\web-apps _lib\cloud-providers _lib\cloud _lib\ai-serving _lib\ml-training _lib\storage _lib\freebsd _lib\illumos _lib\reactos topologies payloads profiles packaging marketplace cli\commands\package_as cli\commands\packaging cli\commands\cloud cli\commands\marketplace cli\commands\ml cli\commands\services cli\commands\experiment) do (
    if exist "!TARGET_ROOT!\%%L" (
        echo [TIER VIOLATION] [NO_LEGACY_ALIASES] %%L: Deleted legacy directory reappeared. >&2
        set /a ERRORS+=1
    )
)
for %%R in (libscript.sh libscript.cmd) do (
    if exist "!TARGET_ROOT!\%%R" (
        findstr /C:"normalize_component_alias" "!TARGET_ROOT!\%%R" >nul 2>&1
        if not errorlevel 1 (
            echo [TIER VIOLATION] [NO_LEGACY_ALIASES] %%R: Legacy normalize_component_alias redirect table is forbidden. >&2
            set /a ERRORS+=1
        )
    )
)
exit /b 0

:: ## check_lib_atomic_purity
:: Verifies _lib\ contains exclusively atomic T1/T2 component directories with zero loose scripts or *-suite folders.
:check_lib_atomic_purity
if not exist "!TARGET_ROOT!\_lib\" exit /b 0
set "_AT_BASE=%TEMP%"
if "!_AT_BASE!"=="" set "_AT_BASE=%TMP%"
if "!_AT_BASE!"=="" set "_AT_BASE=!LIBSCRIPT_ROOT_DIR!\build"
if not exist "!_AT_BASE!" mkdir "!_AT_BASE!" >nul 2>&1
for %%A in ("!_AT_BASE!") do set "_AT_BASE=%%~fA"
set "_AT_TMP1=!_AT_BASE!\ls_at_lat1_!RANDOM!_!RANDOM!.txt"
set "_AT_TMP2=!_AT_BASE!\ls_at_lat2_!RANDOM!_!RANDOM!.txt"
for /d %%C in ("!TARGET_ROOT!\_lib\*") do (
    set "_CN=%%~nxC"
    if "!_CN:~0,1!"=="_" (
        echo [TIER VIOLATION] [LIB_ATOMIC_PURITY] _lib\!_CN!: Underscore helper directory inside _lib\ belongs in T0 engine\. >&2
        set /a ERRORS+=1
    ) else (
        for %%F in ("%%C\*") do (
            if /i not "%%~nxF"=="README.md" (
                echo [TIER VIOLATION] [LIB_ATOMIC_PURITY] _lib\!_CN!\%%~nxF: Loose category script inside _lib\ is forbidden. >&2
                set /a ERRORS+=1
            )
        )
        for /d %%D in ("%%C\*") do (
            set "_DN=%%~nxD"
            if /i "!_DN:~-6!"=="-suite" (
                echo [TIER VIOLATION] [LIB_ATOMIC_PURITY] _lib\!_CN!\!_DN!: Experiment suites belong in experiments\. >&2
                set /a ERRORS+=1
            )
            if not exist "%%D\manifest.json" (
                echo [TIER VIOLATION] [LIB_ATOMIC_PURITY] _lib\!_CN!\!_DN!: Missing manifest.json. >&2
                set /a ERRORS+=1
            ) else (
                findstr /R /C:".tier.[ ]*:[ ]*.T[12]." "%%D\manifest.json" >nul 2>&1
                if errorlevel 1 (
                    echo [TIER VIOLATION] [LIB_ATOMIC_PURITY] _lib\!_CN!\!_DN!\manifest.json: Must declare tier T1 or T2. >&2
                    set /a ERRORS+=1
                )
            )
            call :check_component_lateral_refs "%%D" "!_CN!" "!_DN!"
        )
    )
)
del /f /q "!_AT_TMP1!" "!_AT_TMP2!" >nul 2>&1
exit /b 0

:: ## check_component_lateral_refs
:: Audits a single _lib\<category>\<component> directory for lateral cross-component or stale _common references without cmd.exe pipes.
:check_component_lateral_refs
set "_CLR_DIR=%~1"
set "_CLR_CAT=%~2"
set "_CLR_CMP=%~3"
pushd "!_CLR_DIR!" >nul 2>&1
if errorlevel 1 exit /b 0
findstr /R /C:"\.\.[/\\]_common[/\\]" /C:"\.\.[/\\]\.\.[/\\]_common[/\\]" /C:"\.\.[/\\][a-zA-Z0-9_-]*[/\\]setup\." /C:"\.\.[/\\][a-zA-Z0-9_-]*[/\\]cli\." /C:"\.\.[/\\][a-zA-Z0-9_-]*[/\\]env\." /C:"\.\.[/\\][a-zA-Z0-9_-]*[/\\]service\." /C:"\.\.[/\\][a-zA-Z0-9_-]*[/\\]uninstall\." /C:"\.\.[/\\][a-zA-Z0-9_-]*[/\\]test\." "*.sh" "*.cmd" "*.ps1" > "!_AT_TMP1!" 2>nul
popd >nul 2>&1
set "_CLR_HIT=0"
for %%Z in ("!_AT_TMP1!") do if not "%%~zZ"=="0" set "_CLR_HIT=1"
if "!_CLR_HIT!"=="1" (
    findstr /V /I /R /C:":#[ ]" /C:":::" /C:":rem " /C:"^[ 	]*#" /C:"^[ 	]*::" /C:"^[ 	]*rem " "!_AT_TMP1!" >nul 2>&1
    if not errorlevel 1 (
        echo [TIER VIOLATION] [LIB_ATOMIC_PURITY] _lib\!_CLR_CAT!\!_CLR_CMP!: Lateral cross-component or stale _common reference is forbidden. >&2
        set /a ERRORS+=1
        exit /b 0
    )
)
pushd "!_CLR_DIR!" >nul 2>&1
if errorlevel 1 exit /b 0
findstr /N /R /C:"_lib[/\\][a-z0-9-][a-z0-9-]*[/\\][a-z0-9-][a-z0-9-]*[/\\]" "*.sh" "*.cmd" "*.ps1" > "!_AT_TMP1!" 2>nul
popd >nul 2>&1
set "_CLR_HIT=0"
for %%Z in ("!_AT_TMP1!") do if not "%%~zZ"=="0" set "_CLR_HIT=1"
if "!_CLR_HIT!"=="0" exit /b 0
findstr /V /I /R /C:"_lib[/\\]!_CLR_CAT![/\\]!_CLR_CMP![/\\]" "!_AT_TMP1!" > "!_AT_TMP2!" 2>nul
set "_CLR_HIT2=0"
for %%Y in ("!_AT_TMP2!") do if not "%%~zY"=="0" set "_CLR_HIT2=1"
if "!_CLR_HIT2!"=="0" exit /b 0
findstr /V /I /R /C:":[0-9][0-9]*:[ 	]*#" /C:"^[0-9][0-9]*:[ 	]*#" /C:":[0-9][0-9]*:[ 	]*::" /C:"^[0-9][0-9]*:[ 	]*::" /C:":[0-9][0-9]*:[ 	]*rem " /C:"^[0-9][0-9]*:[ 	]*rem " "!_AT_TMP2!" >nul 2>&1
if not errorlevel 1 (
    echo [TIER VIOLATION] [LIB_ATOMIC_PURITY] _lib\!_CLR_CAT!\!_CLR_CMP!: Lateral cross-component or stale _common reference is forbidden. >&2
    set /a ERRORS+=1
)
exit /b 0

:: ## check_upward_imports
:: Enforces downward-only tier imports across _lib, traits, infrastructure, and workloads.
:check_upward_imports
if exist "!TARGET_ROOT!\_lib\" (
    findstr /S /R /C:"synthesis[/\\]" /C:"infrastructure[/\\]" /C:"workloads[/\\]" /C:"traits[/\\]" /C:"experiments[/\\]" "!TARGET_ROOT!\_lib\*.sh" "!TARGET_ROOT!\_lib\*.cmd" "!TARGET_ROOT!\_lib\*.ps1" "!TARGET_ROOT!\_lib\*.json" >nul 2>&1
    if not errorlevel 1 (
        echo [TIER VIOLATION] [TIER_UPWARD_IMPORT] _lib: T1/T2 recipe layer references higher tier. >&2
        set /a ERRORS+=1
    )
)
if exist "!TARGET_ROOT!\infrastructure\" (
    findstr /S /R /C:"workloads[/\\]" /C:"experiments[/\\]" "!TARGET_ROOT!\infrastructure\*.sh" "!TARGET_ROOT!\infrastructure\*.cmd" "!TARGET_ROOT!\infrastructure\*.ps1" "!TARGET_ROOT!\infrastructure\*.json" >nul 2>&1
    if not errorlevel 1 (
        echo [TIER VIOLATION] [TIER_UPWARD_IMPORT] infrastructure: T4 infrastructure layer references higher tier. >&2
        set /a ERRORS+=1
    )
)
if exist "!TARGET_ROOT!\workloads\" (
    findstr /S /R /C:"experiments[/\\]" "!TARGET_ROOT!\workloads\*.sh" "!TARGET_ROOT!\workloads\*.cmd" "!TARGET_ROOT!\workloads\*.ps1" "!TARGET_ROOT!\workloads\*.json" >nul 2>&1
    if not errorlevel 1 (
        echo [TIER VIOLATION] [TIER_UPWARD_IMPORT] workloads: T5 workloads layer references Plane B experiments. >&2
        set /a ERRORS+=1
    )
)
if exist "!TARGET_ROOT!\traits\" (
    findstr /S /R /C:"synthesis[/\\]" /C:"infrastructure[/\\]" /C:"workloads[/\\]" /C:"experiments[/\\]" "!TARGET_ROOT!\traits\*.sh" "!TARGET_ROOT!\traits\*.cmd" "!TARGET_ROOT!\traits\*.ps1" "!TARGET_ROOT!\traits\*.json" >nul 2>&1
    if not errorlevel 1 (
        echo [TIER VIOLATION] [TIER_UPWARD_IMPORT] traits: Plane A traits references higher tier. >&2
        set /a ERRORS+=1
    )
)
exit /b 0

:: ## check_no_fractional_tiers
:: Rejects stale fractional tier labels (Tier 1.5, Tier 3.5).
:check_no_fractional_tiers
for %%M in (ARCHITECTURE.md README.md libscript.sh libscript.cmd) do (
    if exist "!TARGET_ROOT!\%%M" (
        findstr /R /C:"Tier 1\.5" /C:"Tier 3\.5" "!TARGET_ROOT!\%%M" >nul 2>&1
        if not errorlevel 1 (
            echo [TIER VIOLATION] [NO_FRACTIONAL_TIERS] %%M: Stale fractional tier label found. >&2
            set /a ERRORS+=1
        )
    )
)
exit /b 0
