@echo off
:: # envsubst_safe.cmd
:: ## Overview
:: Safe Windows Batch alternative to `envsubst` powered by native `gawk`/`awk` (with PowerShell fallback).
:: Interpolates `${VAR}` and `$VAR` tokens from the current environment while leaving undefined variable references intact.
:: ## Usage
:: call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\envsubst_safe.cmd" "<template_or_file>" [output_file]

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

if "%~1"=="" exit /b 0
if /i "%~1"==":envsubst_safe" (
    shift
)
call :envsubst_safe "%~1" "%~2"
exit /b !errorlevel!

:: ## resolve_awk
:: Locates gawk or awk on PATH or from the isolated LibScript gawk environment.
:resolve_awk
set "_ES_AWK="
where gawk >nul 2>&1
if not errorlevel 1 (
    set "_ES_AWK=gawk"
    exit /b 0
)
where awk >nul 2>&1
if not errorlevel 1 (
    set "_ES_AWK=awk"
    exit /b 0
)
if exist "!LIBSCRIPT_ROOT_DIR!\_lib\utilities\gawk\env.cmd" (
    call "!LIBSCRIPT_ROOT_DIR!\_lib\utilities\gawk\env.cmd" >nul 2>&1
    where gawk >nul 2>&1
    if not errorlevel 1 (
        set "_ES_AWK=gawk"
        exit /b 0
    )
)
exit /b 1

:: ## envsubst_safe
:: Performs safe environment variable interpolation on a file or string.
:envsubst_safe
set "_ES_IN=%~1"
set "_ES_OUT=%~2"
if "!_ES_IN!"=="" (
    echo No input provided. 1>&2
    exit /b 2
)

call :resolve_awk
if defined _ES_AWK (
    set "_ES_PROG=%TEMP%\ls_es_%RANDOM%_%RANDOM%.awk"
    (
        echo BEGIN { for ^(n in ENVIRON^) env[n] = ENVIRON[n] }
        echo {
        echo   line = $0; pos = 1
        echo   while ^(pos ^<= length^(line^)^) {
        echo     if ^(substr^(line, pos, 2^) == "${"^) {
        echo       if ^(match^(substr^(line, pos^), /^\$\{[A-Za-z_][A-Za-z0-9_]*\}/^)^) {
        echo         v = substr^(line, pos, RLENGTH^)
        echo         vn = substr^(v, 3, length^(v^) - 3^)
        echo         rep = ^(vn in env^) ? env[vn] : v
        echo         line = substr^(line, 1, pos - 1^) rep substr^(line, pos + RLENGTH^)
        echo         pos += length^(rep^)
        echo         continue
        echo       }
        echo     } else if ^(substr^(line, pos, 1^) == "$"^) {
        echo       if ^(match^(substr^(line, pos^), /^\$[A-Za-z_][A-Za-z0-9_]*/^)^) {
        echo         v = substr^(line, pos, RLENGTH^)
        echo         vn = substr^(v, 2^)
        echo         rep = ^(vn in env^) ? env[vn] : v
        echo         line = substr^(line, 1, pos - 1^) rep substr^(line, pos + RLENGTH^)
        echo         pos += length^(rep^)
        echo         continue
        echo       }
        echo     }
        echo     pos++
        echo   }
        echo   print line
        echo }
    ) > "!_ES_PROG!"
    if exist "!_ES_IN!" (
        if "!_ES_OUT!"=="" (
            "!_ES_AWK!" -f "!_ES_PROG!" "!_ES_IN!"
        ) else (
            "!_ES_AWK!" -f "!_ES_PROG!" "!_ES_IN!" > "!_ES_OUT!"
        )
    ) else (
        set "_ES_SRC=%TEMP%\ls_es_in_%RANDOM%_%RANDOM%.txt"
        echo !_ES_IN!> "!_ES_SRC!"
        if "!_ES_OUT!"=="" (
            "!_ES_AWK!" -f "!_ES_PROG!" "!_ES_SRC!"
        ) else (
            "!_ES_AWK!" -f "!_ES_PROG!" "!_ES_SRC!" > "!_ES_OUT!"
        )
        del /f /q "!_ES_SRC!" >nul 2>&1
    )
    set "_ES_RC=!ERRORLEVEL!"
    del /f /q "!_ES_PROG!" >nul 2>&1
    exit /b !_ES_RC!
)

where powershell >nul 2>&1
if not errorlevel 1 (
    if exist "!_ES_IN!" (
        if "!_ES_OUT!"=="" (
            powershell -NoProfile -Command "$c = [IO.File]::ReadAllText('!_ES_IN!'); [regex]::Replace($c, '\$\{([A-Za-z_][A-Za-z0-9_]*)\}|\$([A-Za-z_][A-Za-z0-9_]*)', { param($m) $k = if ($m.Groups[1].Success) { $m.Groups[1].Value } else { $m.Groups[2].Value }; $v = [Environment]::GetEnvironmentVariable($k); if ($null -ne $v) { $v } else { $m.Value } }) | Write-Host -NoNewline"
        ) else (
            powershell -NoProfile -Command "$c = [IO.File]::ReadAllText('!_ES_IN!'); $r = [regex]::Replace($c, '\$\{([A-Za-z_][A-Za-z0-9_]*)\}|\$([A-Za-z_][A-Za-z0-9_]*)', { param($m) $k = if ($m.Groups[1].Success) { $m.Groups[1].Value } else { $m.Groups[2].Value }; $v = [Environment]::GetEnvironmentVariable($k); if ($null -ne $v) { $v } else { $m.Value } }); [IO.File]::WriteAllText('!_ES_OUT!', $r)"
        )
    ) else (
        powershell -NoProfile -Command "$c = '!_ES_IN!'; [regex]::Replace($c, '\$\{([A-Za-z_][A-Za-z0-9_]*)\}|\$([A-Za-z_][A-Za-z0-9_]*)', { param($m) $k = if ($m.Groups[1].Success) { $m.Groups[1].Value } else { $m.Groups[2].Value }; $v = [Environment]::GetEnvironmentVariable($k); if ($null -ne $v) { $v } else { $m.Value } })"
    )
    exit /b 0
)

if exist "!_ES_IN!" (
    if "!_ES_OUT!"=="" (
        type "!_ES_IN!"
    ) else (
        copy /y "!_ES_IN!" "!_ES_OUT!" >nul
    )
) else (
    echo !_ES_IN!
)
exit /b 0
