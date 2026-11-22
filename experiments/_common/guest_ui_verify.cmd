@echo off
:: # guest_ui_verify.cmd
:: ## Overview
:: Host-side coordinator on Windows (`Steps 3-5`) executing desktop shortcut and browser login verification inside the guest VM.
:: ## Usage
:: guest_ui_verify.cmd <plan|verify> [args...]

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
if exist "!d!\libscript.cmd" ( set "LIBSCRIPT_ROOT_DIR=!d!" & exit /b 0 )
if exist "!d!\ROOT" ( set "LIBSCRIPT_ROOT_DIR=!d!" & exit /b 0 )
for %%P in ("!d!") do set "parent=%%~dpP"
set "d=!parent:~0,-1!"
if "!d!"=="" ( echo Error: Could not find LIBSCRIPT_ROOT_DIR 1>&2 & exit /b 1 )
goto :find_root

:: ## root_found
:: Continues execution once LIBSCRIPT_ROOT_DIR is verified.
:root_found
set "GUV_ACT=%~1"
if /i "!GUV_ACT!"=="plan" ( call :guv_build_ordered_plan "%~2" "%~3" & exit /b !errorlevel! )
if /i "!GUV_ACT!"=="verify" ( call :guv_run_verification "%~2" "%~3" "%~4" "%~5" "%~6" "%~7" "%~8" & exit /b !errorlevel! )
goto :guv_help

:: ## guv_build_ordered_plan
:: Emits ordered verification_screenshots JSON grouping desktop first and per-port unauthenticated -> authenticated steps.
:guv_build_ordered_plan
jq -n --slurpfile suite "%~1" --slurpfile pkg "%~2" "($pkg[0].verification_screenshots // []) as $all | [ $all[] | select(.capture_type == \"desktop\") ] + [ ([ $all[] | select(.capture_type != \"desktop\") | .service_port ] | unique)[] as $p | ($all[] | select(.service_port == $p and .capture_type == \"browser_unauthenticated\")), ($all[] | select(.service_port == $p and .capture_type == \"browser_authenticated\")) ]"
exit /b !errorlevel!

:: ## guv_run_verification
:: Triggers guest_capture_agent inside the guest VM for each step and downloads screenshots.
:guv_run_verification
set "_ws=%~1"
set "_fam=%~2"
set "_sj=%~3"
set "_man=%~4"
set "_mode_out=%~5"
set "_mode=%~6"
if not exist "!_mode_out!\screenshots" mkdir "!_mode_out!\screenshots"
for /f "usebackq tokens=1,2,3,4,5 delims=|" %%A in (`jq -r ".verification_screenshots[]? | \"\(.id)|\(.capture_type)|\(.service_port // 80)|\(.healthcheck_path // \"/\")|\(.url_template // \"http://localhost/\")\"" "!_man!"`) do (
    if /i "%%B"=="desktop" (
        if /i "!_fam!"=="windows" (
            call "!SCRIPT_DIR!\vagrant_substrate.cmd" exec "!_ws!" "windows" "powershell -NoProfile -ExecutionPolicy Bypass -File C:/libscript_exp/guest_capture_agent.ps1 -Action desktop -OutFile C:/libscript_exp/screenshots/%%A.png"
            call "!SCRIPT_DIR!\vagrant_substrate.cmd" download "!_ws!" "windows" "C:/libscript_exp/screenshots/%%A.png" "!_mode_out!\screenshots\%%A.png"
        ) else (
            call "!SCRIPT_DIR!\vagrant_substrate.cmd" exec "!_ws!" "!_fam!" "sh /tmp/libscript_exp/guest_capture_agent.sh desktop /tmp/libscript_exp/screenshots/%%A.png if-applicable"
        )
    ) else (
        if /i "!_fam!"=="windows" (
            call "!SCRIPT_DIR!\vagrant_substrate.cmd" exec "!_ws!" "windows" "powershell -NoProfile -ExecutionPolicy Bypass -File C:/libscript_exp/guest_capture_agent.ps1 -Action browser -CaptureType %%B -OutFile C:/libscript_exp/screenshots/%%A.png -ServicePort %%C -HealthPath %%D -Url %%E"
            call "!SCRIPT_DIR!\vagrant_substrate.cmd" download "!_ws!" "windows" "C:/libscript_exp/screenshots/%%A.png" "!_mode_out!\screenshots\%%A.png"
        ) else (
            call "!SCRIPT_DIR!\vagrant_substrate.cmd" exec "!_ws!" "!_fam!" "sh /tmp/libscript_exp/guest_capture_agent.sh browser %%B /tmp/libscript_exp/screenshots/%%A.png %%C %%D %%E 300"
            call "!SCRIPT_DIR!\vagrant_substrate.cmd" download "!_ws!" "!_fam!" "/tmp/libscript_exp/screenshots/%%A.png" "!_mode_out!\screenshots\%%A.png"
        )
    )
)
jq -n --arg m "!_mode!" "{install_mode:$m,status:\"passed\"}" > "!_mode_out!\result.json"
exit /b 0

:: ## guv_help
:: Prints CLI usage for guest_ui_verify.cmd.
:guv_help
echo Usage: guest_ui_verify.cmd ^<plan^|verify^> [args...]
exit /b 0
