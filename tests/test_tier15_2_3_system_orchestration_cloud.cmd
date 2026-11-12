@echo off
:: # test_tier15_2_3_system_orchestration_cloud.cmd
::
:: ## Overview
:: End-to-end Windows Batch behavioral test suite for the 51 Tier 1.5, Tier 2, and Tier 3
:: Base System, Init, Networking, Audio, Desktop, Bootloader, Virtualization, Orchestration,
:: and Cloud Provider recipes added in Section 10.8.
::
:: ## Usage
:: tests\test_tier15_2_3_system_orchestration_cloud.cmd

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
cd /d "%LIBSCRIPT_ROOT_DIR%"

set "FAILURES=0"
set "CHECKS=0"
set "TEST_WS=%TEMP%\libscript_tier15_2_3_test_%RANDOM%"
if not exist "!TEST_WS!" mkdir "!TEST_WS!"
set "FAKE_LS_HOME=!TEST_WS!\ls_home"
set "FAKE_DL_DIR=!TEST_WS!\downloads"
set "FAKE_SYSROOT=!TEST_WS!\sysroot"
if not exist "!FAKE_LS_HOME!" mkdir "!FAKE_LS_HOME!"
if not exist "!FAKE_DL_DIR!" mkdir "!FAKE_DL_DIR!"
if not exist "!FAKE_SYSROOT!" mkdir "!FAKE_SYSROOT!"

echo === 1. Verifying 1:1 Windows Companion Parity Across All 51 Components ===
for %%B in (dbus locales ntp sysctl tzdata) do (
    if exist "_lib\base-system\%%B\cli.cmd" (
        call :pass_check "base-system\%%B has Windows cli.cmd companion"
    ) else (
        call :fail_check "base-system\%%B missing Windows cli.cmd companion"
    )
)

for %%I in (launchd smf supervisord windows-scm) do (
    if exist "_lib\init-systems\%%I\cli.cmd" (
        call :pass_check "init-systems\%%I has Windows cli.cmd companion"
    ) else (
        call :fail_check "init-systems\%%I missing Windows cli.cmd companion"
    )
)

for %%N in (bind9 coredns dnsmasq firewalld frr keepalived tailscale ufw) do (
    if exist "_lib\networking\%%N\cli.cmd" (
        call :pass_check "networking\%%N has Windows cli.cmd companion"
    ) else (
        call :fail_check "networking\%%N missing Windows cli.cmd companion"
    )
)

for %%A in (jack sndio) do (
    if exist "_lib\audio\%%A\cli.cmd" (
        call :pass_check "audio\%%A has Windows cli.cmd companion"
    ) else (
        call :fail_check "audio\%%A missing Windows cli.cmd companion"
    )
)

if exist "_lib\display-managers\ly\cli.cmd" (
    call :pass_check "display-managers\ly has Windows cli.cmd companion"
) else (
    call :fail_check "display-managers\ly missing Windows cli.cmd companion"
)

for %%D in (i3 mate) do (
    if exist "_lib\desktops\%%D\cli.cmd" (
        call :pass_check "desktops\%%D has Windows cli.cmd companion"
    ) else (
        call :fail_check "desktops\%%D missing Windows cli.cmd companion"
    )
)

for %%G in (grub limine refind systemd-boot) do (
    if exist "_lib\bootloaders\%%G\cli.cmd" (
        call :pass_check "bootloaders\%%G has Windows cli.cmd companion"
    ) else (
        call :fail_check "bootloaders\%%G missing Windows cli.cmd companion"
    )
)

for %%V in (lima multipass utm wsl) do (
    if exist "_lib\virtualization\%%V\cli.cmd" (
        call :pass_check "virtualization\%%V has Windows cli.cmd companion"
    ) else (
        call :fail_check "virtualization\%%V missing Windows cli.cmd companion"
    )
)

for %%O in (ansible buildah cilium consul containerd cri-o helm-controller k3s kubeadm libvirt lxc lxd opensearch-dashboards podman pulumi rancher skopeo terraform tofu) do (
    if exist "_lib\orchestration\%%O\cli.cmd" (
        call :pass_check "orchestration\%%O has Windows cli.cmd companion"
    ) else (
        call :fail_check "orchestration\%%O missing Windows cli.cmd companion"
    )
)

for %%C in (oci ovh) do (
    if exist "_lib\cloud-providers\%%C\cli.cmd" (
        call :pass_check "cloud-providers\%%C has Windows cli.cmd companion"
    ) else (
        call :fail_check "cloud-providers\%%C missing Windows cli.cmd companion"
    )
)

echo === 2. Verifying Windows Package Mapper Resolution ===
set "PKG_MGR=winget"
call "_lib\_common\pkg_mapper.cmd" :map_package terraform
if "!MAPPED_PKG!"=="Hashicorp.Terraform" (
    call :pass_check "pkg_mapper.cmd maps terraform -> Hashicorp.Terraform on winget"
) else (
    call :fail_check "pkg_mapper.cmd terraform winget mismatch: !MAPPED_PKG!"
)

set "PKG_MGR=winget"
call "_lib\_common\pkg_mapper.cmd" :map_package oci
if "!MAPPED_PKG!"=="Oracle.OCICLI" (
    call :pass_check "pkg_mapper.cmd maps oci -> Oracle.OCICLI on winget"
) else (
    call :fail_check "pkg_mapper.cmd oci winget mismatch: !MAPPED_PKG!"
)

echo === 3. Verifying Offline Cached Zip Extraction ^& 2x Idempotency (terraform 1.10.3) ===
set "STAGE_DIR=!TEST_WS!\stage_terraform"
if not exist "!STAGE_DIR!\terraform-1.10.3\bin" mkdir "!STAGE_DIR!\terraform-1.10.3\bin"
(
    echo @echo off
    echo echo Terraform v1.10.3
    echo exit /b 0
) > "!STAGE_DIR!\terraform-1.10.3\bin\terraform.cmd"
if not exist "!FAKE_DL_DIR!\terraform" mkdir "!FAKE_DL_DIR!\terraform"
powershell -NoProfile -ExecutionPolicy Bypass -Command "Compress-Archive -Path '!STAGE_DIR!\terraform-1.10.3' -DestinationPath '!FAKE_DL_DIR!\terraform\terraform-1.10.3.zip' -Force"

set "LIBSCRIPT_HOME=!FAKE_LS_HOME!"
set "DOWNLOAD_DIR=!FAKE_DL_DIR!"
set "TERRAFORM_INSTALL_METHOD=libscript_native"
set "TERRAFORM_DOWNLOAD_URL=https://example.invalid/terraform/terraform-1.10.3.zip"
set "STACK="
call "%LIBSCRIPT_ROOT_DIR%\libscript.cmd" install terraform 1.10.3 >nul 2>&1
if exist "!FAKE_LS_HOME!\terraform\1.10.3\bin\terraform.cmd" (
    call :pass_check "offline cached zip install placed terraform.cmd into LIBSCRIPT_HOME"
) else (
    call :fail_check "offline cached zip install failed to place terraform.cmd"
)

set "STACK="
call "%LIBSCRIPT_ROOT_DIR%\libscript.cmd" install terraform 1.10.3 > "!TEST_WS!\idem.txt" 2>&1
findstr /I /C:"already installed" "!TEST_WS!\idem.txt" >nul 2>&1
if not errorlevel 1 (
    call :pass_check "2x install terraform 1.10.3 exited early idempotently"
) else (
    call :fail_check "2x install terraform 1.10.3 did not report already installed"
)

echo === 4. Verifying OCI ^& OVHcloud DRY_RUN Cloud Drivers ===
set "DRY_RUN=true"
set "STACK="
call "_lib\cloud-providers\oci\cli.cmd" node ip demo-oci-vm > "!TEST_WS!\oci_ip.txt" 2>nul
findstr /C:"203.0.113.21" "!TEST_WS!\oci_ip.txt" >nul 2>&1
if not errorlevel 1 (
    call :pass_check "oci\cli.cmd node ip DRY_RUN returned 203.0.113.21"
) else (
    call :fail_check "oci\cli.cmd node ip DRY_RUN mismatch"
)

set "STACK="
call "_lib\cloud-providers\ovh\cli.cmd" node ip demo-ovh-vm > "!TEST_WS!\ovh_ip.txt" 2>nul
findstr /C:"203.0.113.22" "!TEST_WS!\ovh_ip.txt" >nul 2>&1
if not errorlevel 1 (
    call :pass_check "ovh\cli.cmd node ip DRY_RUN returned 203.0.113.22"
) else (
    call :fail_check "ovh\cli.cmd node ip DRY_RUN mismatch"
)

rmdir /s /q "!TEST_WS!" >nul 2>&1

if !FAILURES! gtr 0 (
    echo [FAIL] Windows Tier 1.5/2/3 System, Orchestration ^& Cloud Test Suite failed ^(!FAILURES!/!CHECKS! checks failed^) 1>&2
    exit /b 1
)
echo [SUCCESS] All !CHECKS! Windows behavioral checks passed!
exit /b 0

:: ## pass_check
:: Records a passing test assertion.
:pass_check
set /a CHECKS+=1
echo [PASS] %~1
exit /b 0

:: ## fail_check
:: Records a failing test assertion and increments FAILURES.
:fail_check
set /a CHECKS+=1
set /a FAILURES+=1
echo [FAIL] %~1 1>&2
exit /b 0
