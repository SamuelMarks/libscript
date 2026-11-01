@echo off
:: # verify_screenshots.cmd
:: ## Overview
:: Verifies that all generated .msi GUI and post-install browser/desktop verification screenshots exist and have valid PNG headers.
:: ## Usage
:: .\devtools\verify_screenshots.cmd [--target <name|dir|all>] [--dir <path>]

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

set "TARGET=all"
set "CC0_BASE=!LIBSCRIPT_ROOT_DIR!\..\cc0-assets\libscript"

:: ## parse_args
:: Parses command-line arguments for target component and base screenshot directory.
:parse_args
if "%~1"=="" goto :run_verify
if /I "%~1"=="--help" goto :show_help
if /I "%~1"=="-h" goto :show_help
if /I "%~1"=="/?" goto :show_help
if /I "%~1"=="-?" goto :show_help
if /I "%~1"=="--target" (
    set "TARGET=%~2"
    shift & shift
    goto :parse_args
)
if /I "%~1"=="--dir" (
    set "CC0_BASE=%~2"
    shift & shift
    goto :parse_args
)
set "TARGET=%~1"
shift
goto :parse_args

:: ## show_help
:: Displays usage instructions for verify_screenshots.cmd.
:show_help
echo Usage: %~nx0 [--target ^<name^|dir^|all^>] [--dir ^<path^>]
echo Validates PNG headers, file sizes, declared verification_screenshots, and cropped dimensions.
exit /b 0

:: ## run_verify
:: Executes PNG header, dimension, and packaging.json verification via PowerShell.
:run_verify
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
    "$root = '!LIBSCRIPT_ROOT_DIR!'; $cc0 = '!CC0_BASE!'; $target = '!TARGET!'; " ^
    "Add-Type -AssemblyName System.Drawing -ErrorAction SilentlyContinue; " ^
    "$pkgFiles = if ($target -eq 'all') { Get-ChildItem -Path (Join-Path $root '_lib') -Recurse -Filter 'packaging.json' } else { " ^
    "  $tName = Split-Path -Leaf $target; Get-ChildItem -Path (Join-Path $root '_lib') -Recurse -Filter 'packaging.json' | Where-Object { $_.Directory.Name -eq $tName } }; " ^
    "$err = 0; " ^
    "foreach ($pf in $pkgFiles) { " ^
    "  $name = $pf.Directory.Name; $sDir = Join-Path (Join-Path $cc0 $name) 'screenshots'; " ^
    "  if (-not (Test-Path $sDir)) { if ($target -ne 'all') { Write-Error \"[FAIL] Screenshot directory not found: $sDir\"; $err++ }; continue }; " ^
    "  $pngFiles = Get-ChildItem -Path $sDir -Recurse -Filter '*.png'; " ^
    "  if ($pngFiles.Count -eq 0) { Write-Error \"[FAIL] Zero PNG files found in $sDir\"; $err++; continue }; " ^
    "  foreach ($p in $pngFiles) { " ^
    "    if ($p.Length -lt 1000) { Write-Error \"[FAIL] Screenshot too small ($($p.Length) bytes): $($p.FullName)\"; $err++; continue }; " ^
    "    $bytes = [System.IO.File]::ReadAllBytes($p.FullName); " ^
    "    if ($bytes.Length -lt 8 -or $bytes[0] -ne 0x89 -or $bytes[1] -ne 0x50 -or $bytes[2] -ne 0x4E -or $bytes[3] -ne 0x47) { Write-Error \"[FAIL] Invalid PNG header: $($p.FullName)\"; $err++; continue }; " ^
    "    $w = ([int]$bytes[16] -shl 24) -bor ([int]$bytes[17] -shl 16) -bor ([int]$bytes[18] -shl 8) -bor [int]$bytes[19]; " ^
    "    $h = ([int]$bytes[20] -shl 24) -bor ([int]$bytes[21] -shl 16) -bor ([int]$bytes[22] -shl 8) -bor [int]$bytes[23]; " ^
    "    if ($w -ge 1280 -and $h -ge 800) { Write-Error \"[FAIL] Uncropped full-desktop screenshot (${w}x${h}): $($p.FullName)\"; $err++; continue }; " ^
    "    Write-Host \"[PASS] $($p.FullName) ($($p.Length) bytes, cropped ${w}x${h})\" " ^
    "  }; " ^
    "  $pkg = Get-Content -LiteralPath $pf.FullName -Raw | ConvertFrom-Json; " ^
    "  if ($pkg.verification_screenshots) { " ^
    "    foreach ($vs in $pkg.verification_screenshots) { " ^
    "      $id = $vs.id; if (-not $id) { continue }; " ^
    "      $fMain = Join-Path $sDir \"$id.png\"; " ^
    "      if (-not (Test-Path $fMain)) { Write-Error \"[FAIL] Missing declared verification screenshot: $fMain\"; $err++ }; " ^
    "      foreach ($os in @('windows','linux','macos','freebsd','illumos')) { " ^
    "        $osDir = Join-Path $sDir $os; $fOs = Join-Path $osDir \"$id.png\"; " ^
    "        if ((Test-Path $osDir) -and -not (Test-Path $fOs)) { Write-Error \"[FAIL] Missing OS verification screenshot: $fOs\"; $err++ } " ^
    "      } " ^
    "    } " ^
    "  }; " ^
    "  Write-Host \"[OK] Verified $($pngFiles.Count) cropped screenshots in $sDir\" " ^
    "}; " ^
    "if ($err -gt 0) { exit 1 } else { exit 0 }"
exit /b %ERRORLEVEL%
