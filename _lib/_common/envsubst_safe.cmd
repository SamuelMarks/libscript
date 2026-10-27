@echo off
:: # envsubst_safe.cmd
::
:: ## Overview
:: Safe Windows Batch alternative to `envsubst`. Interpolates `${VAR}` and `$VAR`
:: tokens from the current environment while leaving undefined variable references
:: intact instead of replacing them with empty strings.
::
:: ## Usage
:: call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\envsubst_safe.cmd" "<template_or_file>" [output_file]

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

if "%~1"=="" exit /b 0
if /i "%~1"==":envsubst_safe" (
    shift
)
call :envsubst_safe "%~1" "%~2"
exit /b !errorlevel!

:: ## envsubst_safe
:: Performs safe environment variable interpolation on a file or string.
:envsubst_safe
set "_ES_IN=%~1"
set "_ES_OUT=%~2"
if "!_ES_IN!"=="" (
    echo No input provided. 1>&2
    exit /b 2
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
