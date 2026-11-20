@echo off
:: # audit_cmd.cmd
:: ## Overview
:: Windows Batch companion for auditing .cmd and .bat scripts across the repository using wincheck from _lib\toolchains\win-cmd-rs, with automatic zero-PowerShell bootstrapping when wincheck is missing from PATH.
:: ## Usage
:: devtools\audit\audit_cmd.cmd [--all | --staged | --severity <sev> | --dialect <d> | --format <fmt> | --exclude <rules> | file1.cmd ...]

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

set "_AC_MODE=all"
set "_AC_SEV=%LIBSCRIPT_WINCHECK_SEVERITY%"
if "!_AC_SEV!"=="" set "_AC_SEV=style"
set "_AC_DIALECT=%LIBSCRIPT_WINCHECK_DIALECT%"
if "!_AC_DIALECT!"=="" set "_AC_DIALECT=cmd"
set "_AC_FMT=%LIBSCRIPT_WINCHECK_FORMAT%"
if "!_AC_FMT!"=="" set "_AC_FMT=tty"
set "_AC_EXCL=%LIBSCRIPT_WINCHECK_EXCLUDE%"
if "!_AC_EXCL!"=="" set "_AC_EXCL=CMD1002,CMD2001,CMD2012,CMD2013,CMD3009,CMD4010"
set "_AC_INCL=%LIBSCRIPT_WINCHECK_INCLUDE%"

set "_AC_EXP_LIST=%TEMP%\libscript_ac_exp_!RANDOM!.txt"
set "_AC_CAND_LIST=%TEMP%\libscript_ac_cand_!RANDOM!.txt"
type nul > "!_AC_EXP_LIST!"
type nul > "!_AC_CAND_LIST!"
goto :parse_args

:: ## parse_args
:: Parses CLI options and explicit file paths for audit_cmd.cmd.
:parse_args
if "%~1"=="" goto :args_done
if /I "%~1"=="--help" goto :show_help
if /I "%~1"=="-h" goto :show_help
if /I "%~1"=="/?" goto :show_help
if /I "%~1"=="-?" goto :show_help
if /I "%~1"=="--all" (
    set "_AC_MODE=all"
    shift
    goto :parse_args
)
if /I "%~1"=="--staged" (
    set "_AC_MODE=staged"
    shift
    goto :parse_args
)
if /I "%~1"=="--severity" (
    set "_AC_SEV=%~2"
    shift
    shift
    goto :parse_args
)
if /I "%~1"=="-S" (
    set "_AC_SEV=%~2"
    shift
    shift
    goto :parse_args
)
if /I "%~1"=="--dialect" (
    set "_AC_DIALECT=%~2"
    shift
    shift
    goto :parse_args
)
if /I "%~1"=="--format" (
    set "_AC_FMT=%~2"
    shift
    shift
    goto :parse_args
)
if /I "%~1"=="-f" (
    set "_AC_FMT=%~2"
    shift
    shift
    goto :parse_args
)
if /I "%~1"=="--exclude" (
    set "_AC_EXCL=%~2"
    shift
    shift
    goto :parse_args
)
if /I "%~1"=="-e" (
    set "_AC_EXCL=%~2"
    shift
    shift
    goto :parse_args
)
if /I "%~1"=="--include" (
    set "_AC_INCL=%~2"
    shift
    shift
    goto :parse_args
)
if /I "%~1"=="-i" (
    set "_AC_INCL=%~2"
    shift
    shift
    goto :parse_args
)
set "_AC_MODE=explicit"
echo.%~1>> "!_AC_EXP_LIST!"
shift
goto :parse_args

:: ## show_help
:: Displays command-line usage instructions for audit_cmd.cmd.
:show_help
del /f /q "!_AC_EXP_LIST!" "!_AC_CAND_LIST!" >nul 2>&1
echo Usage: %~nx0 [--all ^| --staged ^| --severity ^<sev^> ^| --dialect ^<d^> ^| --format ^<fmt^> ^| --exclude ^<rules^> ^| ^<file^>...]
echo Audits Windows Batch ^(.cmd and .bat^) scripts using wincheck.
exit /b 0

:: ## args_done
:: Collects candidate .cmd and .bat files and dispatches wincheck static analysis.
:args_done
echo === LibScript Windows Batch ^(.cmd / .bat^) Static Analysis Audit ^(wincheck^) ===

set "_AC_COUNT=0"
if /I "!_AC_MODE!"=="staged" (
    for /f "delims=" %%F in ('git -C "!LIBSCRIPT_ROOT_DIR!" diff --no-ext-diff --cached --name-only --diff-filter=ACM -- "*.cmd" "*.bat" 2^>nul') do (
        call :maybe_add_rel "%%F"
    )
) else if /I "!_AC_MODE!"=="explicit" (
    for /f "usebackq delims=" %%F in ("!_AC_EXP_LIST!") do (
        call :maybe_add_explicit "%%F"
    )
) else (
    for /f "delims=" %%F in ('git -C "!LIBSCRIPT_ROOT_DIR!" ls-files --cached --others --exclude-standard -- "*.cmd" "*.bat" 2^>nul') do (
        call :maybe_add_rel "%%F"
    )
)

if "!_AC_COUNT!"=="0" (
    del /f /q "!_AC_EXP_LIST!" "!_AC_CAND_LIST!" >nul 2>&1
    echo [PASS] No .cmd or .bat scripts matched for auditing.
    exit /b 0
)

call :ensure_wincheck_bootstrapped
if errorlevel 1 (
    del /f /q "!_AC_EXP_LIST!" "!_AC_CAND_LIST!" >nul 2>&1
    echo [ERROR] wincheck bootstrap failed. 1>&2
    exit /b 1
)

call :run_wincheck_batches
set "_AC_RC=!ERRORLEVEL!"
del /f /q "!_AC_EXP_LIST!" "!_AC_CAND_LIST!" >nul 2>&1
if not "!_AC_RC!"=="0" exit /b !_AC_RC!
echo [PASS] All audited Windows Batch ^(.cmd / .bat^) scripts pass wincheck static analysis.
exit /b 0

:: ## maybe_add_rel
:: Filters out excluded directories and appends existing repository-relative .cmd/.bat paths.
:maybe_add_rel
set "_MAR_REL=%~1"
if "!_MAR_REL!"=="" exit /b 0
set "_MAR_NORM=!_MAR_REL:\=/!"
echo "!_MAR_NORM!" | findstr /R /C:"^node_modules/" /C:"/node_modules/" /C:"^\.git/" /C:"/\.git/" /C:"^gen/" /C:"/gen/" /C:"^tests_tmp/" /C:"/tests_tmp/" /C:"^cache/" /C:"/cache/" /C:"^build/" /C:"/build/" >nul 2>&1
if not errorlevel 1 exit /b 0
set "_MAR_FULL=!LIBSCRIPT_ROOT_DIR!\!_MAR_REL:/=\!"
if exist "!_MAR_FULL!" (
    echo.!_MAR_FULL!>> "!_AC_CAND_LIST!"
    set /a "_AC_COUNT+=1"
)
exit /b 0

:: ## maybe_add_explicit
:: Validates and appends an explicit .cmd or .bat path argument.
:maybe_add_explicit
set "_MAE_IN=%~1"
if "!_MAE_IN!"=="" exit /b 0
for %%E in ("!_MAE_IN!") do set "_MAE_EXT=%%~xE"
if /I not "!_MAE_EXT!"==".cmd" if /I not "!_MAE_EXT!"==".bat" exit /b 0
if exist "!_MAE_IN!" (
    echo.!_MAE_IN!>> "!_AC_CAND_LIST!"
    set /a "_AC_COUNT+=1"
    exit /b 0
)
if exist "!LIBSCRIPT_ROOT_DIR!\!_MAE_IN!" (
    echo.!LIBSCRIPT_ROOT_DIR!\!_MAE_IN!>> "!_AC_CAND_LIST!"
    set /a "_AC_COUNT+=1"
)
exit /b 0

:: ## load_wincheck_env
:: Loads the isolated win-cmd-rs component environment while preserving caller STACK.
:load_wincheck_env
if exist "!LIBSCRIPT_ROOT_DIR!\_lib\toolchains\win-cmd-rs\env.cmd" (
    set "_AC_SAVED_ST=!STACK!"
    call "!LIBSCRIPT_ROOT_DIR!\_lib\toolchains\win-cmd-rs\env.cmd" >nul 2>&1
    set "STACK=!_AC_SAVED_ST!"
)
exit /b 0

:: ## ensure_wincheck_bootstrapped
:: Ensures wincheck is on PATH, installing win-cmd-rs idempotently via libscript.cmd when absent.
:ensure_wincheck_bootstrapped
call :load_wincheck_env
where wincheck >nul 2>&1
if not errorlevel 1 exit /b 0
echo [BOOTSTRAP] wincheck not found on PATH; installing via LibScript version manager...
set "_WC_BOOT_VER=%WIN_CMD_RS_VERSION%"
if "!_WC_BOOT_VER!"=="" set "_WC_BOOT_VER=latest"
set "_WC_SAVED_ST=!STACK!"
set "STACK="
set "LIBSCRIPT_NEVER_REFRESH_CHECKSUM_DB=1"
call "!LIBSCRIPT_ROOT_DIR!\libscript.cmd" install win-cmd-rs "!_WC_BOOT_VER!"
set "_WC_BOOT_RC=!ERRORLEVEL!"
set "STACK=!_WC_SAVED_ST!"
if not "!_WC_BOOT_RC!"=="0" exit /b 1
call :load_wincheck_env
where wincheck >nul 2>&1
if errorlevel 1 exit /b 1
exit /b 0

:: ## run_wincheck_batches
:: Runs wincheck across all candidate files using 4 parallel workers when PowerShell is available, falling back to a pure Zero-PowerShell chunked Batch loop.
:run_wincheck_batches
set "_WC_BASE_ARGS=--severity !_AC_SEV! --dialect !_AC_DIALECT! --format !_AC_FMT!"
if not "!_AC_EXCL!"=="" set "_WC_BASE_ARGS=!_WC_BASE_ARGS! --exclude !_AC_EXCL!"
if not "!_AC_INCL!"=="" set "_WC_BASE_ARGS=!_WC_BASE_ARGS! --include !_AC_INCL!"

set "_AC_PS="
where pwsh.exe >nul 2>&1
if not errorlevel 1 set "_AC_PS=pwsh.exe"
if not defined _AC_PS (
    where powershell.exe >nul 2>&1
    if not errorlevel 1 set "_AC_PS=powershell.exe"
)

if defined _AC_PS (
    set "_LS_AC_CAND=!_AC_CAND_LIST!"
    set "_LS_AC_BASE=!_WC_BASE_ARGS!"
    "!_AC_PS!" -NoProfile -ExecutionPolicy Bypass -Command "$ErrorActionPreference = 'Stop'; $wcExe = (Get-Command wincheck -ErrorAction Stop).Source; $files = [System.IO.File]::ReadAllLines($env:_LS_AC_CAND); if ($files.Count -eq 0) { exit 0 }; $baseArgs = $env:_LS_AC_BASE; $running = New-Object 'System.Collections.Generic.List[object]'; $failed = $false; for ($i = 0; $i -lt $files.Count; $i += 80) { while ($running.Count -ge 4) { $doneIdx = -1; for ($k = 0; $k -lt $running.Count; $k++) { if ($running[$k].Proc.HasExited) { $doneIdx = $k; break } }; if ($doneIdx -lt 0) { Start-Sleep -Milliseconds 20; continue }; $item = $running[$doneIdx]; $running.RemoveAt($doneIdx); $item.Proc.WaitForExit(); $outStr = $item.Out.GetAwaiter().GetResult(); $errStr = $item.Err.GetAwaiter().GetResult(); if ($outStr) { [Console]::Out.Write($outStr) }; if ($errStr) { [Console]::Error.Write($errStr) }; if ($item.Proc.ExitCode -ne 0) { $failed = $true }; $item.Proc.Dispose() }; $end = [Math]::Min($i + 79, $files.Count - 1); $quoted = for ($j = $i; $j -le $end; $j++) { [char]34 + $files[$j] + [char]34 }; $argStr = $baseArgs + ' ' + ($quoted -join ' '); $psi = New-Object System.Diagnostics.ProcessStartInfo; $psi.FileName = $wcExe; $psi.Arguments = $argStr; $psi.UseShellExecute = $false; $psi.RedirectStandardOutput = $true; $psi.RedirectStandardError = $true; $p = [System.Diagnostics.Process]::Start($psi); [void]$running.Add(@{ Proc = $p; Out = $p.StandardOutput.ReadToEndAsync(); Err = $p.StandardError.ReadToEndAsync() }) }; foreach ($item in $running) { $item.Proc.WaitForExit(); $outStr = $item.Out.GetAwaiter().GetResult(); $errStr = $item.Err.GetAwaiter().GetResult(); if ($outStr) { [Console]::Out.Write($outStr) }; if ($errStr) { [Console]::Error.Write($errStr) }; if ($item.Proc.ExitCode -ne 0) { $failed = $true }; $item.Proc.Dispose() }; if ($failed) { exit 1 } else { exit 0 }"
    exit /b !ERRORLEVEL!
)

set "_WC_BATCH="
set "_WC_BN=0"
set "_WC_FAIL=0"
for /f "usebackq delims=" %%S in ("!_AC_CAND_LIST!") do (
    set "_WC_BATCH=!_WC_BATCH! "%%S""
    set /a "_WC_BN+=1"
    if "!_WC_BN!"=="40" (
        wincheck !_WC_BASE_ARGS! !_WC_BATCH!
        if errorlevel 1 set "_WC_FAIL=1"
        set "_WC_BATCH="
        set "_WC_BN=0"
    )
)
if not "!_WC_BN!"=="0" (
    wincheck !_WC_BASE_ARGS! !_WC_BATCH!
    if errorlevel 1 set "_WC_FAIL=1"
)
exit /b !_WC_FAIL!
