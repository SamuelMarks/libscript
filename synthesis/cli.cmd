@echo off
:: # cli.cmd
:: ## Overview
:: Tier 3 (T3) unified synthesis CLI router on Windows dispatching OS image assembly, native installer packaging,
:: offline cache hydration, distro synthesis, repo generation, and `package-as` format drivers.
:: ## Usage
:: call synthesis\cli.cmd <synthesize|build-image|build-installer|hydrate-cache|distro|repogen|package-as> [args...]

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

set "SUBCMD=%~1"
if "!SUBCMD!"=="" goto :show_help
if /i "!SUBCMD!"=="--help" goto :show_help
if /i "!SUBCMD!"=="-h" goto :show_help

if /i "!SUBCMD!"=="synthesize" goto :do_synthesize
if /i "!SUBCMD!"=="synthesize-image" goto :do_synthesize
if /i "!SUBCMD!"=="build-image" goto :do_synthesize
if /i "!SUBCMD!"=="build-installer" goto :do_build_installer
if /i "!SUBCMD!"=="hydrate-cache" goto :do_hydrate_cache
if /i "!SUBCMD!"=="distro" goto :do_distro
if /i "!SUBCMD!"=="repogen" goto :do_repogen

set "PKG_TYPE=!SUBCMD!"
if /i "!SUBCMD!"=="package-as" (
    shift
    set "PKG_TYPE=%~1"
)
shift

if /i "!PKG_TYPE!"=="docker" goto :fmt_dockerfile
if /i "!PKG_TYPE!"=="dockerfile" goto :fmt_dockerfile
if /i "!PKG_TYPE!"=="docker_compose" goto :fmt_docker_compose
if /i "!PKG_TYPE!"=="docker-compose" goto :fmt_docker_compose
if /i "!PKG_TYPE!"=="msi" goto :fmt_msi
if /i "!PKG_TYPE!"=="innosetup" goto :fmt_inno
if /i "!PKG_TYPE!"=="inno" goto :fmt_inno
if /i "!PKG_TYPE!"=="nsis" goto :fmt_nsis
if /i "!PKG_TYPE!"=="deb" goto :fmt_deb
if /i "!PKG_TYPE!"=="rpm" goto :fmt_rpm
if /i "!PKG_TYPE!"=="apk" goto :fmt_apk
if /i "!PKG_TYPE!"=="txz" goto :fmt_txz
if /i "!PKG_TYPE!"=="pkg" goto :fmt_pkg
if /i "!PKG_TYPE!"=="dmg" goto :fmt_dmg
if /i "!PKG_TYPE!"=="tui" goto :fmt_tui
if /i "!PKG_TYPE!"=="raw-img" goto :fmt_raw_img
if /i "!PKG_TYPE!"=="raw_img" goto :fmt_raw_img
if /i "!PKG_TYPE!"=="img" goto :fmt_raw_img
if /i "!PKG_TYPE!"=="qcow2" goto :fmt_qcow2
if /i "!PKG_TYPE!"=="vmdk" goto :fmt_qcow2
if /i "!PKG_TYPE!"=="vdi" goto :fmt_qcow2
if /i "!PKG_TYPE!"=="iso" goto :fmt_iso
if /i "!PKG_TYPE!"=="rootfs-tar" goto :fmt_rootfs_tar
if /i "!PKG_TYPE!"=="rootfs_tar" goto :fmt_rootfs_tar
if /i "!PKG_TYPE!"=="bsd-img" goto :fmt_bsd_img
if /i "!PKG_TYPE!"=="bsd_img" goto :fmt_bsd_img
if /i "!PKG_TYPE!"=="linux-distro" goto :fmt_linux_distro
if /i "!PKG_TYPE!"=="linux_distro" goto :fmt_linux_distro
if /i "!PKG_TYPE!"=="linux-kernel" goto :fmt_linux_kernel
if /i "!PKG_TYPE!"=="linux_kernel" goto :fmt_linux_kernel
if /i "!PKG_TYPE!"=="illumos-distro" goto :fmt_illumos_distro
if /i "!PKG_TYPE!"=="illumos_distro" goto :fmt_illumos_distro
if /i "!PKG_TYPE!"=="freebsd-distro" goto :fmt_freebsd_distro
if /i "!PKG_TYPE!"=="freebsd_distro" goto :fmt_freebsd_distro
if /i "!PKG_TYPE!"=="reactos-distro" goto :fmt_reactos_distro
if /i "!PKG_TYPE!"=="reactos_distro" goto :fmt_reactos_distro
if /i "!PKG_TYPE!"=="rtos-distro" goto :fmt_rtos_distro
if /i "!PKG_TYPE!"=="rtos_distro" goto :fmt_rtos_distro
if /i "!PKG_TYPE!"=="zephyr-distro" goto :fmt_rtos_distro
if /i "!PKG_TYPE!"=="zephyr_distro" goto :fmt_rtos_distro
if /i "!PKG_TYPE!"=="freertos-distro" goto :fmt_rtos_distro
if /i "!PKG_TYPE!"=="freertos_distro" goto :fmt_rtos_distro
if /i "!PKG_TYPE!"=="unikernel" goto :fmt_unikernel
if /i "!PKG_TYPE!"=="unikernel-img" goto :fmt_unikernel
if /i "!PKG_TYPE!"=="unikernel_img" goto :fmt_unikernel
if /i "!PKG_TYPE!"=="unikernel-distro" goto :fmt_unikernel
if /i "!PKG_TYPE!"=="unikernel_distro" goto :fmt_unikernel
if /i "!PKG_TYPE!"=="docker-image" goto :fmt_container_base
if /i "!PKG_TYPE!"=="oci-image" goto :fmt_container_base
if /i "!PKG_TYPE!"=="qemu-qcow2" goto :fmt_qemu_img
if /i "!PKG_TYPE!"=="vmware-vmdk" goto :fmt_vmware_img
if /i "!PKG_TYPE!"=="hyperv-vhd" goto :fmt_hyperv_img
if /i "!PKG_TYPE!"=="hyperv-vhdx" goto :fmt_hyperv_img
if /i "!PKG_TYPE!"=="proxmox-template" goto :fmt_proxmox_img
if /i "!PKG_TYPE!"=="virtualbox-vdi" goto :fmt_virtualbox_img
if /i "!PKG_TYPE!"=="virtualbox-ova" goto :fmt_virtualbox_img
if /i "!PKG_TYPE!"=="ova" goto :fmt_virtualbox_img
if /i "!PKG_TYPE!"=="xen-img" goto :fmt_xen_img
if /i "!PKG_TYPE!"=="microvm-disk" goto :fmt_microvm_img
if /i "!PKG_TYPE!"=="aws-ami" goto :fmt_aws_ami
if /i "!PKG_TYPE!"=="azure-vhd" goto :fmt_azure_vhd
if /i "!PKG_TYPE!"=="gcp-image" goto :fmt_gcp_image
if /i "!PKG_TYPE!"=="cloud-img" goto :fmt_cloud_img
if /i "!PKG_TYPE!"=="vagrant-box" goto :fmt_vagrantfile
if /i "!PKG_TYPE!"=="vagrant_box" goto :fmt_vagrantfile
if /i "!PKG_TYPE!"=="vagrant" goto :fmt_vagrantfile
if /i "!PKG_TYPE!"=="vagrantfile" goto :fmt_vagrantfile
if /i "!PKG_TYPE!"=="disk-builder" goto :fmt_disk_builder
if /i "!PKG_TYPE!"=="disk_builder" goto :fmt_disk_builder
if /i "!PKG_TYPE!"=="zfs-stream" goto :fmt_zfs_stream
if /i "!PKG_TYPE!"=="zfs_stream" goto :fmt_zfs_stream
if /i "!PKG_TYPE!"=="direct-kernel" goto :fmt_direct_kernel
if /i "!PKG_TYPE!"=="direct_kernel" goto :fmt_direct_kernel
if /i "!PKG_TYPE!"=="uki" goto :fmt_uki
if /i "!PKG_TYPE!"=="firmware-elf" goto :fmt_firmware
if /i "!PKG_TYPE!"=="firmware-bin" goto :fmt_firmware
if /i "!PKG_TYPE!"=="firmware_bin" goto :fmt_firmware
if /i "!PKG_TYPE!"=="firmware-hex" goto :fmt_firmware
if /i "!PKG_TYPE!"=="firmware-uf2" goto :fmt_firmware
if /i "!PKG_TYPE!"=="mcuboot-signed" goto :fmt_firmware
if /i "!PKG_TYPE!"=="renode-resc" goto :fmt_firmware

echo Error: Unsupported synthesis package format '!PKG_TYPE!'. >&2
exit /b 1

:: ## show_help
:: Displays usage instructions for the T3 synthesis router.
:show_help
echo Usage: synthesis\cli.cmd ^<synthesize^|build-image^|build-installer^|hydrate-cache^|distro^|repogen^|package-as^> [args...]
exit /b 0

:: ## do_synthesize
:: Dispatches OS/appliance image synthesis to synthesis\distro\synthesize-image.cmd.
:do_synthesize
call "!LIBSCRIPT_ROOT_DIR!\synthesis\distro\synthesize-image.cmd" %2 %3 %4 %5 %6 %7 %8 %9
exit /b !errorlevel!

:: ## do_build_installer
:: Dispatches full-stack MSI synthesis to synthesis\msi\build_msi.cmd.
:do_build_installer
call "!LIBSCRIPT_ROOT_DIR!\synthesis\msi\build_msi.cmd" %2 %3 %4 %5 %6 %7 %8 %9
exit /b !errorlevel!

:: ## do_hydrate_cache
:: Dispatches offline installer cache hydration to synthesis\msi\hydrate_offline_cache.cmd.
:do_hydrate_cache
call "!LIBSCRIPT_ROOT_DIR!\synthesis\msi\hydrate_offline_cache.cmd" %2 %3 %4 %5 %6 %7 %8 %9
exit /b !errorlevel!

:: ## do_distro
:: Dispatches Linux distribution rootfs assembly to synthesis\distro\linux\cli.cmd.
:do_distro
call "!LIBSCRIPT_ROOT_DIR!\synthesis\distro\linux\cli.cmd" %2 %3 %4 %5 %6 %7 %8 %9
exit /b !errorlevel!

:: ## do_repogen
:: Dispatches package repository index generation to synthesis\repogen\cli.cmd.
:do_repogen
call "!LIBSCRIPT_ROOT_DIR!\synthesis\repogen\cli.cmd" %2 %3 %4 %5 %6 %7 %8 %9
exit /b !errorlevel!

:: ## fmt_dockerfile
:: Dispatches Dockerfile export.
:fmt_dockerfile
call "!LIBSCRIPT_ROOT_DIR!\synthesis\formats\docker.cmd" %1 %2 %3 %4 %5 %6 %7 %8 %9
exit /b !errorlevel!

:: ## fmt_docker_compose
:: Dispatches Docker Compose export.
:fmt_docker_compose
call "!LIBSCRIPT_ROOT_DIR!\synthesis\formats\docker_compose.cmd" %1 %2 %3 %4 %5 %6 %7 %8 %9
exit /b !errorlevel!

:: ## fmt_msi
:: Dispatches Windows MSI installer generation.
:fmt_msi
if /i "%~1"=="openedx" (
    call "!LIBSCRIPT_ROOT_DIR!\synthesis\msi\build_msi.cmd" %1 %2 %3 %4 %5 %6 %7 %8 %9
    exit /b !errorlevel!
)
call "!LIBSCRIPT_ROOT_DIR!\synthesis\formats\msi.cmd" %1 %2 %3 %4 %5 %6 %7 %8 %9
exit /b !errorlevel!

:: ## fmt_inno
:: Dispatches Inno Setup installer generation.
:fmt_inno
call "!LIBSCRIPT_ROOT_DIR!\synthesis\formats\inno.cmd" %1 %2 %3 %4 %5 %6 %7 %8 %9
exit /b !errorlevel!

:: ## fmt_nsis
:: Dispatches NSIS installer generation.
:fmt_nsis
call "!LIBSCRIPT_ROOT_DIR!\synthesis\formats\nsis.cmd" %1 %2 %3 %4 %5 %6 %7 %8 %9
exit /b !errorlevel!

:: ## fmt_deb
:: Dispatches Debian .deb package generation.
:fmt_deb
call "!LIBSCRIPT_ROOT_DIR!\synthesis\formats\deb.cmd" %1 %2 %3 %4 %5 %6 %7 %8 %9
exit /b !errorlevel!

:: ## fmt_rpm
:: Dispatches RPM package generation.
:fmt_rpm
call "!LIBSCRIPT_ROOT_DIR!\synthesis\formats\rpm.cmd" %1 %2 %3 %4 %5 %6 %7 %8 %9
exit /b !errorlevel!

:: ## fmt_apk
:: Dispatches Alpine .apk package generation.
:fmt_apk
call "!LIBSCRIPT_ROOT_DIR!\synthesis\formats\apk.cmd" %1 %2 %3 %4 %5 %6 %7 %8 %9
exit /b !errorlevel!

:: ## fmt_txz
:: Dispatches FreeBSD .txz package generation.
:fmt_txz
call "!LIBSCRIPT_ROOT_DIR!\synthesis\formats\txz.cmd" %1 %2 %3 %4 %5 %6 %7 %8 %9
exit /b !errorlevel!

:: ## fmt_pkg
:: Dispatches macOS .pkg installer generation.
:fmt_pkg
call "!LIBSCRIPT_ROOT_DIR!\synthesis\formats\pkg.cmd" %1 %2 %3 %4 %5 %6 %7 %8 %9
exit /b !errorlevel!

:: ## fmt_dmg
:: Dispatches macOS .dmg image generation.
:fmt_dmg
call "!LIBSCRIPT_ROOT_DIR!\synthesis\formats\dmg.cmd" %1 %2 %3 %4 %5 %6 %7 %8 %9
exit /b !errorlevel!

:: ## fmt_tui
:: Dispatches TUI installer bundle generation.
:fmt_tui
call "!LIBSCRIPT_ROOT_DIR!\synthesis\formats\tui.cmd" %1 %2 %3 %4 %5 %6 %7 %8 %9
exit /b !errorlevel!

:: ## fmt_raw_img
:: Dispatches raw disk image export.
:fmt_raw_img
call "!LIBSCRIPT_ROOT_DIR!\synthesis\formats\raw_img.cmd" %1 %2 %3 %4 %5 %6 %7 %8 %9
exit /b !errorlevel!

:: ## fmt_qcow2
:: Dispatches qcow2/vmdk/vdi disk image export.
:fmt_qcow2
call "!LIBSCRIPT_ROOT_DIR!\synthesis\formats\qcow2.cmd" %1 %2 %3 %4 %5 %6 %7 %8 "!PKG_TYPE!"
exit /b !errorlevel!

:: ## fmt_iso
:: Dispatches bootable ISO export.
:fmt_iso
call "!LIBSCRIPT_ROOT_DIR!\synthesis\formats\iso.cmd" %1 %2 %3 %4 %5 %6 %7 %8 %9
exit /b !errorlevel!

:: ## fmt_rootfs_tar
:: Dispatches rootfs tarball export.
:fmt_rootfs_tar
call "!LIBSCRIPT_ROOT_DIR!\synthesis\formats\rootfs_tar.cmd" %1 %2 %3 %4 %5 %6 %7 %8 %9
exit /b !errorlevel!

:: ## fmt_bsd_img
:: Dispatches BSD disk image export.
:fmt_bsd_img
call "!LIBSCRIPT_ROOT_DIR!\synthesis\formats\bsd_img.cmd" %1 %2 %3 %4 %5 %6 %7 %8 %9
exit /b !errorlevel!

:: ## fmt_linux_distro
:: Dispatches Linux distro synthesis.
:fmt_linux_distro
call "!LIBSCRIPT_ROOT_DIR!\synthesis\formats\linux_distro.cmd" %1 %2 %3 %4 %5 %6 %7 %8 %9
exit /b !errorlevel!

:: ## fmt_linux_kernel
:: Dispatches standalone Linux kernel direct-boot synthesis.
:fmt_linux_kernel
set "LIBSCRIPT_LINUX_DEFAULT_FORMAT=direct-kernel"
set "LIBSCRIPT_LINUX_DEFAULT_PROFILE=!LIBSCRIPT_ROOT_DIR!\synthesis\profiles\linux\linux-kernel-gcc-tiny.json"
call "!LIBSCRIPT_ROOT_DIR!\synthesis\formats\linux_distro.cmd" %1 %2 %3 %4 %5 %6 %7 %8 %9
exit /b !errorlevel!

:: ## fmt_illumos_distro
:: Dispatches illumos distro synthesis.
:fmt_illumos_distro
call "!LIBSCRIPT_ROOT_DIR!\synthesis\formats\illumos_distro.cmd" %1 %2 %3 %4 %5 %6 %7 %8 %9
exit /b !errorlevel!

:: ## fmt_freebsd_distro
:: Dispatches FreeBSD distro synthesis.
:fmt_freebsd_distro
call "!LIBSCRIPT_ROOT_DIR!\synthesis\formats\freebsd_distro.cmd" %1 %2 %3 %4 %5 %6 %7 %8 %9
exit /b !errorlevel!

:: ## fmt_reactos_distro
:: Dispatches ReactOS distro synthesis.
:fmt_reactos_distro
call "!LIBSCRIPT_ROOT_DIR!\synthesis\formats\reactos_distro.cmd" %1 %2 %3 %4 %5 %6 %7 %8 %9
exit /b !errorlevel!

:: ## fmt_rtos_distro
:: Dispatches Zephyr and FreeRTOS firmware synthesis.
:fmt_rtos_distro
call "!LIBSCRIPT_ROOT_DIR!\synthesis\formats\rtos_distro.cmd" %1 %2 %3 %4 %5 %6 %7 %8 %9
exit /b !errorlevel!

:: ## fmt_unikernel
:: Dispatches unikernel image synthesis.
:fmt_unikernel
call "!LIBSCRIPT_ROOT_DIR!\synthesis\formats\unikernel_img.cmd" %1 %2 %3 %4 %5 %6 %7 %8 %9
exit /b !errorlevel!

:: ## fmt_container_base
:: Dispatches OCI/Docker container image export.
:fmt_container_base
call "!LIBSCRIPT_ROOT_DIR!\synthesis\formats\container_base.cmd" %1 %2 %3 %4 %5 %6 %7 %8 %9
exit /b !errorlevel!

:: ## fmt_qemu_img
:: Dispatches QEMU qcow2 image export.
:fmt_qemu_img
call "!LIBSCRIPT_ROOT_DIR!\synthesis\formats\qemu_img.cmd" %1 %2 %3 %4 %5 %6 %7 %8 %9
exit /b !errorlevel!

:: ## fmt_vmware_img
:: Dispatches VMware VMDK image export.
:fmt_vmware_img
call "!LIBSCRIPT_ROOT_DIR!\synthesis\formats\vmware_img.cmd" %1 %2 %3 %4 %5 %6 %7 %8 %9
exit /b !errorlevel!

:: ## fmt_hyperv_img
:: Dispatches Hyper-V VHD/VHDX image export.
:fmt_hyperv_img
call "!LIBSCRIPT_ROOT_DIR!\synthesis\formats\hyperv_img.cmd" %1 %2 %3 %4 %5 %6 %7 %8 %9
exit /b !errorlevel!

:: ## fmt_proxmox_img
:: Dispatches Proxmox template image export.
:fmt_proxmox_img
call "!LIBSCRIPT_ROOT_DIR!\synthesis\formats\proxmox_img.cmd" %1 %2 %3 %4 %5 %6 %7 %8 %9
exit /b !errorlevel!

:: ## fmt_virtualbox_img
:: Dispatches VirtualBox VDI/OVA image export.
:fmt_virtualbox_img
call "!LIBSCRIPT_ROOT_DIR!\synthesis\formats\virtualbox_img.cmd" %1 %2 %3 %4 %5 %6 %7 %8 %9
exit /b !errorlevel!

:: ## fmt_xen_img
:: Dispatches Xen image export.
:fmt_xen_img
call "!LIBSCRIPT_ROOT_DIR!\synthesis\formats\xen_img.cmd" %1 %2 %3 %4 %5 %6 %7 %8 %9
exit /b !errorlevel!

:: ## fmt_microvm_img
:: Dispatches microVM disk image export.
:fmt_microvm_img
call "!LIBSCRIPT_ROOT_DIR!\synthesis\formats\microvm_img.cmd" %1 %2 %3 %4 %5 %6 %7 %8 %9
exit /b !errorlevel!

:: ## fmt_aws_ami
:: Dispatches AWS AMI export.
:fmt_aws_ami
call "!LIBSCRIPT_ROOT_DIR!\synthesis\formats\aws_ami.cmd" %1 %2 %3 %4 %5 %6 %7 %8 %9
exit /b !errorlevel!

:: ## fmt_azure_vhd
:: Dispatches Azure VHD export.
:fmt_azure_vhd
call "!LIBSCRIPT_ROOT_DIR!\synthesis\formats\azure_vhd.cmd" %1 %2 %3 %4 %5 %6 %7 %8 %9
exit /b !errorlevel!

:: ## fmt_gcp_image
:: Dispatches GCP compute image export.
:fmt_gcp_image
call "!LIBSCRIPT_ROOT_DIR!\synthesis\formats\gcp_image.cmd" %1 %2 %3 %4 %5 %6 %7 %8 %9
exit /b !errorlevel!

:: ## fmt_cloud_img
:: Dispatches generic cloud-init image export.
:fmt_cloud_img
call "!LIBSCRIPT_ROOT_DIR!\synthesis\formats\cloud_img.cmd" %1 %2 %3 %4 %5 %6 %7 %8 %9
exit /b !errorlevel!

:: ## fmt_vagrantfile
:: Dispatches Vagrant box/Vagrantfile export.
:fmt_vagrantfile
call "!LIBSCRIPT_ROOT_DIR!\synthesis\formats\vagrantfile.cmd" %1 %2 %3 %4 %5 %6 %7 %8 %9
exit /b !errorlevel!

:: ## fmt_disk_builder
:: Dispatches raw partitioned disk builder.
:fmt_disk_builder
call "!LIBSCRIPT_ROOT_DIR!\synthesis\formats\disk_builder.cmd" %1 %2 %3 %4 %5 %6 %7 %8 %9
exit /b !errorlevel!

:: ## fmt_zfs_stream
:: Dispatches ZFS replication stream export.
:fmt_zfs_stream
call "!LIBSCRIPT_ROOT_DIR!\synthesis\formats\zfs_stream.cmd" %1 %2 %3 %4 %5 %6 %7 %8 %9
exit /b !errorlevel!

:: ## fmt_direct_kernel
:: Dispatches direct-kernel boot bundle export.
:fmt_direct_kernel
call "!LIBSCRIPT_ROOT_DIR!\synthesis\formats\direct_kernel.cmd" %1 %2 %3 %4 %5 %6 %7 %8 %9
exit /b !errorlevel!

:: ## fmt_uki
:: Dispatches Secure Boot Unified Kernel Image (.efi) export.
:fmt_uki
call "!LIBSCRIPT_ROOT_DIR!\synthesis\formats\uki.cmd" %1 %2 %3 %4 %5 %6 %7 %8 %9
exit /b !errorlevel!

:: ## fmt_firmware
:: Dispatches RTOS/MCU firmware binary export.
:fmt_firmware
call "!LIBSCRIPT_ROOT_DIR!\synthesis\formats\firmware_bin.cmd" "--format=!PKG_TYPE!" %1 %2 %3 %4 %5 %6 %7 %8 %9
exit /b !errorlevel!
