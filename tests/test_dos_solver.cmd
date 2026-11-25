@echo off
:: # test_dos_solver.cmd
::
:: ## Overview
:: Unit test suite on Windows for T0 DOS triplets and resolve_stack.jq DOS capability strata guards.
::
:: ## Usage
:: tests\test_dos_solver.cmd

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

set "WORK=%TEMP%\dos_solver_!RANDOM!"
if not exist "!WORK!" mkdir "!WORK!"
set "LIBSCRIPT_TRIPLETS_QUIET=1"
set "STACK="
call "!LIBSCRIPT_ROOT_DIR!\engine\target\triplets.cmd" i8086 dos16-libc msdos
if /I not "!LIBSCRIPT_TARGET_TRIPLET!"=="ia16-pc-msdos" exit /b 1
set "STACK="
call "!LIBSCRIPT_ROOT_DIR!\engine\target\triplets.cmd" i386 watcom-libc msdos
if /I not "!LIBSCRIPT_TARGET_TRIPLET!"=="i386-pc-msdoswatcom" exit /b 1
set "STACK="
call "!LIBSCRIPT_ROOT_DIR!\engine\target\triplets.cmd" i586 djgpp-libc freedos
if /I not "!LIBSCRIPT_TARGET_TRIPLET!"=="i586-pc-msdosdjgpp" exit /b 1

for %%P in (freedos-1.4-djgpp-i586 msdos-4.0-djgpp-i586 msdos-2.0-realmode-i8086 msdos-1.25-heritage-i8086) do (
    set "STACK="
    call "!LIBSCRIPT_ROOT_DIR!\engine\solver\resolve_stack.cmd" "!LIBSCRIPT_ROOT_DIR!\synthesis\profiles\dos\%%P.json" "!WORK!\%%P.plan.json"
    if errorlevel 1 exit /b 1
    jq -e "any(.stages[] | select(.stage == \"stage2-target-sysroot\") | .tasks[]; .name == \"win-cmd-asm\")" "!WORK!\%%P.plan.json" >nul || exit /b 1
)

for %%D in (freedos-1.4-djgpp-i586 msdos-4.0-djgpp-i586) do (
    jq -e "any(.stages[] | select(.stage == \"stage2-target-sysroot\") | .tasks[]; .name == \"win-cmd-rs\")" "!WORK!\%%D.plan.json" >nul || exit /b 1
)

for %%K in (jq win-cmd-rs) do (
    jq ".components=[\"%%K\"]" "!LIBSCRIPT_ROOT_DIR!\synthesis\profiles\dos\msdos-1.25-heritage-i8086.json" > "!WORK!\bad125_%%K.json"
    set "STACK="
    call "!LIBSCRIPT_ROOT_DIR!\engine\solver\resolve_stack.cmd" "!WORK!\bad125_%%K.json" > "!WORK!\err1_%%K.txt" 2>&1
    if not errorlevel 1 exit /b 1
    findstr /C:"DOS1_FLAT_FCB_ONLY" "!WORK!\err1_%%K.txt" >nul || exit /b 1

    jq ".components=[\"%%K\"]" "!LIBSCRIPT_ROOT_DIR!\synthesis\profiles\dos\msdos-2.0-realmode-i8086.json" > "!WORK!\bad20_%%K.json"
    set "STACK="
    call "!LIBSCRIPT_ROOT_DIR!\engine\solver\resolve_stack.cmd" "!WORK!\bad20_%%K.json" > "!WORK!\err2_%%K.txt" 2>&1
    if not errorlevel 1 exit /b 1
    findstr /C:"DOS2_NO_DPMI32" "!WORK!\err2_%%K.txt" >nul || exit /b 1
)

for %%F in (postgres nginx) do (
    jq ".components=[\"%%F\"]" "!LIBSCRIPT_ROOT_DIR!\synthesis\profiles\dos\freedos-1.4-djgpp-i586.json" > "!WORK!\badfork_%%F.json"
    set "STACK="
    call "!LIBSCRIPT_ROOT_DIR!\engine\solver\resolve_stack.cmd" "!WORK!\badfork_%%F.json" > "!WORK!\err3_%%F.txt" 2>&1
    if not errorlevel 1 exit /b 1
    findstr /C:"DOS_INCOMPATIBLE_FORK" "!WORK!\err3_%%F.txt" >nul || exit /b 1
)

rmdir /s /q "!WORK!"
echo [PASS] DOS T0 triplets and constraint solver verified on Windows.
exit /b 0
