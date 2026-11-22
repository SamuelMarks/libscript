@echo off
:: # install_modes.cmd
:: ## Overview
:: Clean-snapshot 3-mode installer runner on Windows (`Step 2`) driving `headless`, `quick`, and `custom` guest installs.
:: ## Usage
:: install_modes.cmd <stage|headless|quick|custom|run-trial> [args...]

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
set "IM_ACT=%~1"
if "!IM_ACT!"=="" goto :im_help
if /i "!IM_ACT!"=="--help" goto :im_help
if /i "!IM_ACT!"=="-h" goto :im_help
if /i "!IM_ACT!"=="stage" ( call :im_stage_package_to_guest "%~2" "%~3" "%~4" "%~5" & exit /b !errorlevel! )
if /i "!IM_ACT!"=="headless" ( call :im_run_headless_install "%~2" "%~3" "%~4" "%~5" & exit /b !errorlevel! )
if /i "!IM_ACT!"=="quick" ( call :im_run_quick_install "%~2" "%~3" "%~4" "%~5" "%~6" & exit /b !errorlevel! )
if /i "!IM_ACT!"=="custom" ( call :im_run_custom_install "%~2" "%~3" "%~4" "%~5" "%~6" "%~7" & exit /b !errorlevel! )
if /i "!IM_ACT!"=="run-trial" ( call :im_execute_mode_trial "%~2" "%~3" "%~4" "%~5" "%~6" "%~7" "%~8" "%~9" & exit /b !errorlevel! )
echo [ERROR] Unknown install_modes action: !IM_ACT! >&2
exit /b 1

:: ## im_stage_package_to_guest
:: Stages the resolved installer package, packaging.json, and guest UI helpers into the guest VM.
:im_stage_package_to_guest
set "_ws=%~1"
set "_fam=%~2"
set "_pkg=%~3"
set "_man=%~4"
set "_guest_dir=/tmp/libscript_exp"
if /i "!_fam!"=="windows" set "_guest_dir=C:/libscript_exp"
for %%P in ("!_pkg!") do set "_pkg_base=%%~nxP"
if /i "!_fam!"=="windows" (
    call "!SCRIPT_DIR!\vagrant_substrate.cmd" exec "!_ws!" "windows" "New-Item -ItemType Directory -Force -Path '!_guest_dir!/screenshots' | Out-Null"
) else (
    call "!SCRIPT_DIR!\vagrant_substrate.cmd" exec "!_ws!" "!_fam!" "mkdir -p '!_guest_dir!/screenshots'"
)
call "!SCRIPT_DIR!\vagrant_substrate.cmd" upload "!_ws!" "!_pkg!" "!_guest_dir!/!_pkg_base!"
call "!SCRIPT_DIR!\vagrant_substrate.cmd" upload "!_ws!" "!_man!" "!_guest_dir!/packaging.json"
for %%H in (click_button.ps1 click_button.sh open_browser.ps1 open_browser.sh create_desktop_shortcuts.ps1 create_desktop_shortcuts.sh) do (
    if exist "!LIBSCRIPT_ROOT_DIR!\synthesis\msi\%%H" call "!SCRIPT_DIR!\vagrant_substrate.cmd" upload "!_ws!" "!LIBSCRIPT_ROOT_DIR!\synthesis\msi\%%H" "!_guest_dir!/%%H"
)
for %%G in (guest_capture_agent.sh guest_capture_agent.cmd guest_capture_agent.ps1) do (
    if exist "!SCRIPT_DIR!\%%G" call "!SCRIPT_DIR!\vagrant_substrate.cmd" upload "!_ws!" "!SCRIPT_DIR!\%%G" "!_guest_dir!/%%G"
)
set "IM_GPKG=!_guest_dir!/!_pkg_base!"
echo.!IM_GPKG!
exit /b 0

:: ## im_run_headless_install
:: Executes 100% unattended guest CLI installation for msi, exe, deb, rpm, pkg, or dmg packages.
:im_run_headless_install
set "_ws=%~1"
set "_fam=%~2"
set "_fmt=%~3"
set "_gpkg=%~4"
if /i "!_fam!"=="windows" (
    if /i "!_fmt!"=="msi" (
        call "!SCRIPT_DIR!\vagrant_substrate.cmd" exec "!_ws!" "windows" "$p = Start-Process -FilePath 'msiexec.exe' -ArgumentList '/i', '\"!_gpkg!\"', '/qn', '/norestart', '/l*v', 'C:/libscript_exp/install_headless.log' -Wait -PassThru; exit $p.ExitCode"
        exit /b !errorlevel!
    )
    call "!SCRIPT_DIR!\vagrant_substrate.cmd" exec "!_ws!" "windows" "$p = Start-Process -FilePath '!_gpkg!' -ArgumentList '/VERYSILENT', '/SUPPRESSMSGBOXES', '/NORESTART' -Wait -PassThru; exit $p.ExitCode"
    exit /b !errorlevel!
)
if /i "!_fmt!"=="deb" (
    call "!SCRIPT_DIR!\vagrant_substrate.cmd" exec "!_ws!" "!_fam!" "sudo DEBIAN_FRONTEND=noninteractive apt-get install -y '!_gpkg!'"
    exit /b !errorlevel!
)
if /i "!_fmt!"=="rpm" (
    call "!SCRIPT_DIR!\vagrant_substrate.cmd" exec "!_ws!" "!_fam!" "sudo dnf install -y '!_gpkg!' || sudo rpm -Uvh '!_gpkg!'"
    exit /b !errorlevel!
)
if /i "!_fmt!"=="pkg" (
    call "!SCRIPT_DIR!\vagrant_substrate.cmd" exec "!_ws!" "!_fam!" "sudo installer -pkg '!_gpkg!' -target /"
    exit /b !errorlevel!
)
exit /b 0

:: ## im_prepare_guest_gui_session
:: Registers interactive GUI session helpers inside the guest VM.
:im_prepare_guest_gui_session
set "_ws=%~1"
set "_fam=%~2"
if /i "!_fam!"=="windows" (
    call "!SCRIPT_DIR!\vagrant_substrate.cmd" exec "!_ws!" "windows" "$u = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name; $p = New-ScheduledTaskPrincipal -UserId $u -LogonType Interactive -RunLevel Highest; $a = New-ScheduledTaskAction -Execute 'powershell.exe' -Argument '-NoProfile -ExecutionPolicy Bypass -File C:/libscript_exp/run_gui_step.ps1'; Register-ScheduledTask -TaskName 'LibScriptExpGui' -Action $a -Principal $p -Force | Out-Null"
)
exit /b 0

:: ## im_run_quick_install
:: Drives the default quick/simple GUI installation wizard inside the guest VM.
:im_run_quick_install
set "_ws=%~1"
set "_fam=%~2"
set "_fmt=%~3"
set "_gpkg=%~4"
call :im_prepare_guest_gui_session "!_ws!" "!_fam!"
if /i "!_fam!"=="windows" (
    call "!SCRIPT_DIR!\vagrant_substrate.cmd" exec "!_ws!" "windows" "Set-Content -Path 'C:/libscript_exp/run_gui_step.ps1' -Value 'Start-Process msiexec.exe -ArgumentList \"/i\", \"!_gpkg!\", \"/l*v\", \"C:/libscript_exp/install_quick.log\"'; Start-ScheduledTask -TaskName 'LibScriptExpGui'; Start-Sleep -Seconds 5"
    for %%B in ("Next" "I accept" "Next" "Next" "Install" "Finish") do (
        call "!SCRIPT_DIR!\vagrant_substrate.cmd" exec "!_ws!" "windows" "Set-Content -Path 'C:/libscript_exp/run_gui_step.ps1' -Value '& C:/libscript_exp/click_button.ps1 -ButtonText %%~B'; Start-ScheduledTask -TaskName 'LibScriptExpGui'; Start-Sleep -Seconds 3"
    )
    exit /b 0
)
call :im_run_headless_install "!_ws!" "!_fam!" "!_fmt!" "!_gpkg!"
exit /b !errorlevel!

:: ## im_run_custom_install
:: Drives the custom/advanced GUI installation wizard path inside the guest VM.
:im_run_custom_install
set "_ws=%~1"
set "_fam=%~2"
set "_fmt=%~3"
set "_gpkg=%~4"
set "_sj=%~5"
call :im_prepare_guest_gui_session "!_ws!" "!_fam!"
if /i "!_fam!"=="windows" (
    call "!SCRIPT_DIR!\vagrant_substrate.cmd" exec "!_ws!" "windows" "Set-Content -Path 'C:/libscript_exp/run_gui_step.ps1' -Value 'Start-Process msiexec.exe -ArgumentList \"/i\", \"!_gpkg!\", \"/l*v\", \"C:/libscript_exp/install_custom.log\"'; Start-ScheduledTask -TaskName 'LibScriptExpGui'; Start-Sleep -Seconds 5"
    for %%B in ("Next" "I accept" "Next" "Custom" "Next" "Next" "Install" "Finish") do (
        call "!SCRIPT_DIR!\vagrant_substrate.cmd" exec "!_ws!" "windows" "Set-Content -Path 'C:/libscript_exp/run_gui_step.ps1' -Value '& C:/libscript_exp/click_button.ps1 -ButtonText %%~B'; Start-ScheduledTask -TaskName 'LibScriptExpGui'; Start-Sleep -Seconds 3"
    )
    exit /b 0
)
call :im_run_headless_install "!_ws!" "!_fam!" "!_fmt!" "!_gpkg!"
exit /b !errorlevel!

:: ## im_execute_mode_trial
:: Restores vanilla snapshot, installs package in target mode, and invokes guest_ui_verify.cmd.
:im_execute_mode_trial
set "_ws=%~1"
set "_prov=%~2"
set "_fam=%~3"
set "_snap=%~4"
set "_mode=%~5"
set "_fmt=%~6"
set "_pkg=%~7"
set "_sj=%~8"
call "!SCRIPT_DIR!\vagrant_substrate.cmd" snapshot-restore "!_ws!" "!_prov!" "!_fam!" "!_snap!" "!_sj!"
if errorlevel 1 exit /b 1
for /f "usebackq delims=" %%M in (`jq -r ".installer_e2e.packaging_manifest" "!_sj!"`) do set "_man_rel=%%M"
for %%D in ("!_sj!") do set "_sdir=%%~dpD"
set "_man=!_sdir!!_man_rel:/=\!"
call :im_stage_package_to_guest "!_ws!" "!_fam!" "!_pkg!" "!_man!"
if /i "!_mode!"=="headless" call :im_run_headless_install "!_ws!" "!_fam!" "!_fmt!" "!IM_GPKG!"
if /i "!_mode!"=="quick" call :im_run_quick_install "!_ws!" "!_fam!" "!_fmt!" "!IM_GPKG!" "true"
if /i "!_mode!"=="custom" call :im_run_custom_install "!_ws!" "!_fam!" "!_fmt!" "!IM_GPKG!" "!_sj!" "true"
if errorlevel 1 exit /b 1
call "!SCRIPT_DIR!\guest_ui_verify.cmd" verify "!_ws!" "!_fam!" "!_sj!" "!_man!" "!EXP_MODE_OUT_DIR!" "!_mode!" "0"
exit /b !errorlevel!

:: ## im_help
:: Prints CLI usage for install_modes.cmd.
:im_help
echo Usage: install_modes.cmd ^<stage^|headless^|quick^|custom^|run-trial^> [args...]
exit /b 0
