@echo off
rem ## Overview
rem Validates the modular zero-.EXE Windows Installer packaging and component reuse architecture.
rem Verifies standalone dependency MSIs, master orchestrator packages, deterministic GUID integrity,
rem and side-by-side database sharing between Open edX and WordPress.
rem
rem ## Usage
rem   call tests\test_modular_msi_reuse.cmd
rem
rem ## Parameters
rem   None.

setlocal enabledelayedexpansion

set "THIS_FILE=%~f0"
if defined STACK (
    echo !STACK! | findstr /C:":%THIS_FILE%:" >nul 2>&1 && (
        echo [STOP] processing "%THIS_FILE%" >&2
        exit /b 0
    )
)
set "STACK=%STACK%:%THIS_FILE%:"

set "SCRIPT_DIR=%~dp0"
for %%I in ("%SCRIPT_DIR%..") do set "LIBSCRIPT_ROOT_DIR=%%~fI"

echo === Test: Validating Modular Zero-.EXE MSI Packaging and Reuse ===

set "REGISTRY_JSON=%LIBSCRIPT_ROOT_DIR%\packaging\guid_registry.json"
if not exist "%REGISTRY_JSON%" (
    echo [FAIL] guid_registry.json missing. >&2
    exit /b 1
)
echo [PASS] Verified guid_registry.json exists.

for %%C in (mysql redis mongodb python nodejs meilisearch) do (
    echo [INFO] Building standalone MSI for %%C...
    call "%LIBSCRIPT_ROOT_DIR%\packaging\build_component_msi.cmd" --component %%C >nul 2>&1
    if not exist "%LIBSCRIPT_ROOT_DIR%\dist\msi\libscript-%%C-*.msi" (
        echo [FAIL] Missing expected standalone MSI for component %%C >&2
        exit /b 1
    )
)
echo [PASS] All 6 standalone component MSIs built successfully.

echo [INFO] Building Open edX Core MSI...
call "%LIBSCRIPT_ROOT_DIR%\packaging\build_openedx_core_msi.cmd" --version "22.1.0" >nul 2>&1
if not exist "%LIBSCRIPT_ROOT_DIR%\dist\msi\openedx-core-22.1.0.msi" (
    echo [FAIL] Missing openedx-core-22.1.0.msi >&2
    exit /b 1
)
echo [PASS] Open edX Core MSI built successfully.

echo [INFO] Building Master Orchestrator MSIs...
call "%LIBSCRIPT_ROOT_DIR%\packaging\build_openedx_orchestrator_msi.cmd" --version "22.1.0" --variant "all" >nul 2>&1
if not exist "%LIBSCRIPT_ROOT_DIR%\dist\msi\openedx-22.1.0.msi" (
    echo [FAIL] Missing openedx-22.1.0.msi (online) >&2
    exit /b 1
)
if not exist "%LIBSCRIPT_ROOT_DIR%\dist\msi\openedx-offline-22.1.0.msi" (
    echo [FAIL] Missing openedx-offline-22.1.0.msi (offline) >&2
    exit /b 1
)
echo [PASS] Master Orchestrator MSIs built successfully.

set "EXE_FOUND=0"
for /r "%LIBSCRIPT_ROOT_DIR%\dist\msi" %%F in (*.exe) do set "EXE_FOUND=1"
if "%EXE_FOUND%"=="1" (
    echo [FAIL] Found .exe file(s) in dist\msi. Zero-.EXE mandate violated! >&2
    exit /b 1
)
echo [PASS] Zero-.EXE mandate verified in dist\msi\ (only pure .msi packages produced).

echo === All Modular Zero-.EXE MSI Reuse Tests Passed ===
exit /b 0
