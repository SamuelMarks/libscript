@echo off
:: # vagrant_substrate.cmd
:: ## Overview
:: Provider-agnostic Vagrant and Bento fork substrate on Windows (`Step 0`), managing box registration,
:: multi-provider workspaces, guest command/file execution, and clean `"vanilla"` VM snapshots.
:: ## Usage
:: vagrant_substrate.cmd <resolve-os|os-family|resolve-provider|provision|prepare-workspace|boot|snapshot-ensure|snapshot-restore|assert-clean|exec|upload|download|teardown> [args...]

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
set "VS_ACT=%~1"
if "!VS_ACT!"=="" goto :vs_help
if /i "!VS_ACT!"=="--help" goto :vs_help
if /i "!VS_ACT!"=="-h" goto :vs_help
if /i "!VS_ACT!"=="resolve-os" ( call :vs_resolve_target_os "%~2" & echo !VS_OUT! & exit /b 0 )
if /i "!VS_ACT!"=="os-family" ( call :vs_guest_os_family "%~2" & echo !VS_FAM! & exit /b 0 )
if /i "!VS_ACT!"=="resolve-provider" ( call :vs_resolve_provider "%~2" & if errorlevel 1 exit /b 1 & echo !VS_PROV! & exit /b 0 )
if /i "!VS_ACT!"=="provision" ( call :vs_register_bento_box "%~2" "%~3" "%~4" "%~5" "%~6" & exit /b !errorlevel! )
if /i "!VS_ACT!"=="prepare-workspace" ( call :vs_prepare_workspace "%~2" "%~3" "%~4" "%~5" "%~6" "%~7" & exit /b !errorlevel! )
if /i "!VS_ACT!"=="boot" ( call :vs_boot_vm "%~2" "%~3" "%~4" & exit /b !errorlevel! )
if /i "!VS_ACT!"=="snapshot-ensure" ( call :vs_ensure_vanilla_snapshot "%~2" "%~3" "%~4" "%~5" "%~6" & exit /b !errorlevel! )
if /i "!VS_ACT!"=="snapshot-restore" ( call :vs_restore_vanilla_snapshot "%~2" "%~3" "%~4" "%~5" "%~6" & exit /b !errorlevel! )
if /i "!VS_ACT!"=="assert-clean" ( call :vs_assert_vanilla_clean "%~2" "%~3" "%~4" & exit /b !errorlevel! )
if /i "!VS_ACT!"=="exec" ( call :vs_exec_guest "%~2" "%~3" "%~4" & exit /b !errorlevel! )
if /i "!VS_ACT!"=="upload" ( call :vs_upload_guest "%~2" "%~3" "%~4" & exit /b !errorlevel! )
if /i "!VS_ACT!"=="download" ( call :vs_download_guest "%~2" "%~3" "%~4" "%~5" & exit /b !errorlevel! )
if /i "!VS_ACT!"=="teardown" ( call :vs_teardown_vm "%~2" "%~3" & exit /b !errorlevel! )
echo [ERROR] Unknown vagrant_substrate action: !VS_ACT! >&2
exit /b 1

:: ## vs_resolve_target_os
:: Normalizes shorthand OS names into canonical Bento box OS slugs.
:vs_resolve_target_os
set "_raw=%~1"
if "!_raw!"=="" set "_raw=windows-11"
set "VS_OUT=!_raw!"
if /i "!_raw!"=="windows" set "VS_OUT=windows-11"
if /i "!_raw!"=="win" set "VS_OUT=windows-11"
if /i "!_raw!"=="win11" set "VS_OUT=windows-11"
if /i "!_raw!"=="debian" set "VS_OUT=debian-13"
if /i "!_raw!"=="rocky" set "VS_OUT=rockylinux-10.2"
if /i "!_raw!"=="rockylinux" set "VS_OUT=rockylinux-10.2"
if /i "!_raw!"=="freebsd" set "VS_OUT=freebsd-15.1"
if /i "!_raw!"=="macos" set "VS_OUT=macos-14-arm64"
if /i "!_raw!"=="alpine" set "VS_OUT=alpine-3.24"
if /i "!_raw!"=="illumos" set "VS_OUT=omnios"
exit /b 0

:: ## vs_guest_os_family
:: Classifies a target Bento OS slug into windows, macos, linux, bsd, or posix.
:vs_guest_os_family
set "_gos=%~1"
if "!_gos!"=="" set "_gos=windows-11"
set "VS_FAM=posix"
if /i "!_gos:~0,3!"=="win" set "VS_FAM=windows"
if /i "!_gos:~0,5!"=="macos" set "VS_FAM=macos"
if /i "!_gos:~0,7!"=="freebsd" set "VS_FAM=bsd"
if /i "!_gos:~0,6!"=="debian" set "VS_FAM=linux"
if /i "!_gos:~0,6!"=="ubuntu" set "VS_FAM=linux"
if /i "!_gos:~0,5!"=="rocky" set "VS_FAM=linux"
if /i "!_gos:~0,6!"=="alpine" set "VS_FAM=linux"
exit /b 0

:: ## vs_resolve_provider
:: Resolves `auto` or validates an explicit Vagrant provider on Windows hosts.
:vs_resolve_provider
set "_rp=%~1"
if "!_rp!"=="" set "_rp=auto"
if /i "!_rp!"=="auto" (
    where VBoxManage >nul 2>&1
    if not errorlevel 1 ( set "VS_PROV=virtualbox" & exit /b 0 )
    where vmrun >nul 2>&1
    if not errorlevel 1 ( set "VS_PROV=vmware_desktop" & exit /b 0 )
    where qemu-system-x86_64 >nul 2>&1
    if not errorlevel 1 ( set "VS_PROV=qemu" & exit /b 0 )
    set "VS_PROV=hyperv"
    exit /b 0
)
for %%P in (virtualbox libvirt hyperv vmware_desktop qemu utm) do (
    if /i "!_rp!"=="%%P" ( set "VS_PROV=%%P" & exit /b 0 )
)
echo [ERROR] Unsupported Vagrant provider: !_rp! >&2
exit /b 1

:: ## vs_register_bento_box
:: Idempotently ensures `<bento_prefix>/<target_os>` is registered in Vagrant.
:vs_register_bento_box
set "_pfx=%~1"
if "!_pfx!"=="" set "_pfx=bento"
call :vs_resolve_target_os "%~2"
set "_os=!VS_OUT!"
call :vs_resolve_provider "%~3"
if errorlevel 1 exit /b 1
set "_prov=!VS_PROV!"
set "_bdir=%~4"
set "_url_tpl=%~5"
set "_box=!_pfx!/!_os!"

where vagrant >nul 2>&1
if errorlevel 1 (
    set "STACK="
    call "!LIBSCRIPT_ROOT_DIR!\libscript.cmd" install vagrant latest
    if errorlevel 1 exit /b 1
)

vagrant box list 2>nul | findstr /I /C:"!_box! " | findstr /I /C:"(!_prov!," >nul 2>&1
if not errorlevel 1 (
    echo [SKIP] Vagrant box !_box! ^(!_prov!^) is already registered. >&2
    echo !_box!
    exit /b 0
)

if "!_bdir!"=="" (
    if exist "!LIBSCRIPT_ROOT_DIR!\..\bento\builds\build_complete" set "_bdir=!LIBSCRIPT_ROOT_DIR!\..\bento"
)
if not "!_bdir!"=="" (
    for %%B in ("!_bdir!\builds\build_complete\!_os!*.!_prov!.box" "!_bdir!\builds\build_complete\!_os!*.box") do (
        if exist "%%~fB" (
            vagrant box add --name "!_box!" --provider "!_prov!" "%%~fB" >&2
            echo !_box!
            exit /b 0
        )
    )
)
if not "!_url_tpl!"=="" (
    set "_cache=!LIBSCRIPT_ROOT_DIR!\cache\bento\!_pfx!_!_os!_!_prov!.box"
    if not exist "!LIBSCRIPT_ROOT_DIR!\cache\bento" mkdir "!LIBSCRIPT_ROOT_DIR!\cache\bento"
    call "!LIBSCRIPT_ROOT_DIR!\_lib\_common\pkg_mgr.cmd" :libscript_download "!_url_tpl!" "!_cache!"
    vagrant box add --name "!_box!" --provider "!_prov!" "!_cache!" >&2
)
echo !_box!
exit /b 0

:: ## vs_prepare_workspace
:: Generates an isolated Vagrant workspace directory and multi-provider Vagrantfile.
:vs_prepare_workspace
set "_suite=%~1"
set "_pfx=%~2"
if "!_pfx!"=="" set "_pfx=bento"
call :vs_resolve_target_os "%~3"
set "_os=!VS_OUT!"
call :vs_resolve_provider "%~4"
if errorlevel 1 exit /b 1
set "_prov=!VS_PROV!"
set "_cpus=%~5"
if "!_cpus!"=="" set "_cpus=4"
set "_mem=%~6"
if "!_mem!"=="" set "_mem=8192"
call :vs_guest_os_family "!_os!"
set "_fam=!VS_FAM!"
set "_ws=!LIBSCRIPT_ROOT_DIR!\tests_tmp\experiments\!_suite!\!_os!-!_prov!"
if not exist "!_ws!" mkdir "!_ws!"
(
    echo Vagrant.configure^("2"^) do ^|config^|
    echo   config.vm.box = "!_pfx!/!_os!"
    echo   config.vm.synced_folder ".", "/vagrant", disabled: true
    if /i "!_fam!"=="windows" (
        echo   config.vm.guest = :windows
        echo   config.vm.communicator = "winrm"
    )
    echo   config.vm.provider "!_prov!" do ^|v^|
    echo     v.cpus = !_cpus!
    echo   end
    echo end
) > "!_ws!\Vagrantfile"
echo !_ws!
exit /b 0

:: ## vs_exec_guest
:: Executes a command inside the guest via `vagrant winrm` or `vagrant ssh` with retry/backoff.
:vs_exec_guest
set "_ws=%~1"
set "_fam=%~2"
set "_cmd=%~3"
set "_att=0"
:: ## veg_retry
:: Retries guest WinRM or SSH execution after a brief backoff interval.
:veg_retry
pushd "!_ws!"
if /i "!_fam!"=="windows" (
    vagrant winrm --shell powershell -c "!_cmd!"
) else (
    vagrant ssh -c "!_cmd!"
)
set "_rc=!errorlevel!"
popd
if "!_rc!"=="0" exit /b 0
set /a "_att+=1"
if !_att! LSS 5 (
    ping -n 4 127.0.0.1 >nul 2>&1
    goto :veg_retry
)
exit /b 1

:: ## vs_boot_vm
:: Boots the Vagrant VM idempotently under the target provider and waits for communicator readiness.
:vs_boot_vm
set "_ws=%~1"
set "_prov=%~2"
set "_fam=%~3"
pushd "!_ws!"
vagrant up --no-provision --provider=!_prov!
set "_rc=!errorlevel!"
popd
if not "!_rc!"=="0" exit /b !_rc!
if /i "!_fam!"=="windows" (
    call :vs_exec_guest "!_ws!" "windows" "Write-Output READY" >nul
) else (
    call :vs_exec_guest "!_ws!" "!_fam!" "echo READY" >nul
)
exit /b !errorlevel!

:: ## vs_upload_guest
:: Transfers a host file or folder into the guest VM using `vagrant upload`.
:vs_upload_guest
pushd "%~1"
vagrant upload "%~2" "%~3"
set "_rc=!errorlevel!"
popd
exit /b !_rc!

:: ## vs_download_guest
:: Downloads a file from the guest VM back to the host via communicator streaming without raw scp.
:vs_download_guest
set "_ws=%~1"
set "_fam=%~2"
set "_rem=%~3"
set "_loc=%~4"
for %%D in ("!_loc!") do set "_loc_dir=%%~dpD"
if not exist "!_loc_dir!" mkdir "!_loc_dir!"
if /i "!_fam!"=="windows" (
    call :vs_exec_guest "!_ws!" "windows" "[Convert]::ToBase64String([System.IO.File]::ReadAllBytes('!_rem!'))" > "!_loc!.b64"
    powershell -NoProfile -Command "[System.IO.File]::WriteAllBytes('!_loc!', [Convert]::FromBase64String((Get-Content -Raw '!_loc!.b64').Trim()))"
    del /q "!_loc!.b64" 2>nul
) else (
    pushd "!_ws!"
    vagrant ssh -c "cat '!_rem!'" > "!_loc!"
    popd
)
exit /b 0

:: ## vs_assert_vanilla_clean
:: Verifies clean_state_probes inside the guest VM after snapshot restore.
:vs_assert_vanilla_clean
set "_ws=%~1"
set "_fam=%~2"
set "_sj=%~3"
if "!_sj!"=="" exit /b 0
if not exist "!_sj!" exit /b 0
for /f "usebackq tokens=1,2,3 delims=|" %%A in (`jq -r ".installer_e2e.vagrant.clean_state_probes[]? | \"\(.kind)|\(.target)|\(.os_family // \"any\")\"" "!_sj!"`) do (
    set "_pk=%%A"
    set "_pt=%%B"
    set "_pf=%%C"
    if /i "!_pf!"=="any" set "_pf=!_fam!"
    if /i "!_pf!"=="!_fam!" (
        if /i "!_fam!"=="windows" (
            if /i "!_pk!"=="path_absent" call :vs_exec_guest "!_ws!" "windows" "if (Test-Path '!_pt!') { exit 1 } else { exit 0 }" >nul
            if errorlevel 1 exit /b 1
        ) else (
            if /i "!_pk!"=="path_absent" call :vs_exec_guest "!_ws!" "!_fam!" "test ! -e '!_pt!'" >nul
            if errorlevel 1 exit /b 1
        )
    )
)
exit /b 0

:: ## vs_ensure_vanilla_snapshot
:: Idempotently saves the `"vanilla"` snapshot once on a verified clean guest VM.
:vs_ensure_vanilla_snapshot
set "_ws=%~1"
set "_prov=%~2"
set "_fam=%~3"
set "_snap=%~4"
if "!_snap!"=="" set "_snap=vanilla"
set "_sj=%~5"
pushd "!_ws!"
vagrant snapshot list 2>nul | findstr /I /X /C:"!_snap!" >nul 2>&1
if not errorlevel 1 (
    popd
    echo [SKIP] Vagrant snapshot "!_snap!" already exists in !_ws!. >&2
    exit /b 0
)
popd
call :vs_assert_vanilla_clean "!_ws!" "!_fam!" "!_sj!"
if errorlevel 1 exit /b 1
pushd "!_ws!"
vagrant snapshot save "!_snap!"
set "_rc=!errorlevel!"
popd
exit /b !_rc!

:: ## vs_restore_vanilla_snapshot
:: Restores the guest VM to its `"vanilla"` snapshot and verifies clean-state probes.
:vs_restore_vanilla_snapshot
set "_ws=%~1"
set "_prov=%~2"
set "_fam=%~3"
set "_snap=%~4"
if "!_snap!"=="" set "_snap=vanilla"
set "_sj=%~5"
pushd "!_ws!"
vagrant snapshot restore --no-provision "!_snap!"
set "_rc=!errorlevel!"
popd
if not "!_rc!"=="0" exit /b !_rc!
call :vs_assert_vanilla_clean "!_ws!" "!_fam!" "!_sj!"
exit /b !errorlevel!

:: ## vs_teardown_vm
:: Halts or destroys the Vagrant workspace VM cleanly.
:vs_teardown_vm
set "_ws=%~1"
set "_dest=%~2"
if not exist "!_ws!\Vagrantfile" exit /b 0
pushd "!_ws!"
if "!_dest!"=="1" (
    vagrant destroy -f
) else (
    vagrant halt
)
popd
exit /b 0

:: ## vs_help
:: Prints CLI usage for vagrant_substrate.cmd.
:vs_help
echo Usage: vagrant_substrate.cmd ^<resolve-os^|os-family^|resolve-provider^|provision^|prepare-workspace^|boot^|snapshot-ensure^|snapshot-restore^|assert-clean^|exec^|upload^|download^|teardown^> [args...]
exit /b 0
