@echo off
setlocal EnableDelayedExpansion
:: # package-as.cmd
::
:: ## Overview
:: Packages the libscript environment into distributable formats on Windows.
:: Delegates to format-specific packaging modules under cli\commands\packaging\formats.
:: 
:: ## Usage
:: call cli\commands\packaging\package-as.cmd <format> [args...]

set "THIS_FILE=%~f0"
if defined STACK (
    echo !STACK! | findstr /C:":%THIS_FILE%:" >nul 2>&1
    if not errorlevel 1 (
        echo [STOP] processing "%THIS_FILE%" >&2
        exit /b 0
    )
)
set "STACK=%STACK%:%THIS_FILE%:"
set "SCRIPT_DIR=%~dp0"
if "%SCRIPT_DIR:~-1%"=="" set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"

if not defined LIBSCRIPT_ROOT_DIR (
    for %%i in ("%SCRIPT_DIR%\..\..\..") do set "LIBSCRIPT_ROOT_DIR=%%~fi"
)

set "PKG_TYPE=%~1"
if /i "%PKG_TYPE%"=="package-as" (
    shift
    set "PKG_TYPE=%~1"
)
shift

if /i "%PKG_TYPE%"=="docker" goto do_docker
if /i "%PKG_TYPE%"=="dockerfile" goto do_docker
if /i "%PKG_TYPE%"=="docker_compose" goto do_docker_compose
if /i "%PKG_TYPE%"=="docker-compose" goto do_docker_compose
if /i "%PKG_TYPE%"=="msi" goto do_msi
if /i "%PKG_TYPE%"=="innosetup" goto do_innosetup
if /i "%PKG_TYPE%"=="nsis" goto do_nsis
if /i "%PKG_TYPE%"=="deb" goto do_deb
if /i "%PKG_TYPE%"=="rpm" goto do_rpm
if /i "%PKG_TYPE%"=="apk" goto do_apk
if /i "%PKG_TYPE%"=="txz" goto do_txz
if /i "%PKG_TYPE%"=="pkg" goto do_pkg
if /i "%PKG_TYPE%"=="dmg" goto do_dmg
if /i "%PKG_TYPE%"=="tui" goto do_tui
if /i "%PKG_TYPE%"=="raw-img" goto do_raw_img
if /i "%PKG_TYPE%"=="raw_img" goto do_raw_img
if /i "%PKG_TYPE%"=="img" goto do_raw_img
if /i "%PKG_TYPE%"=="qcow2" goto do_qcow2
if /i "%PKG_TYPE%"=="vmdk" goto do_qcow2
if /i "%PKG_TYPE%"=="vdi" goto do_qcow2
if /i "%PKG_TYPE%"=="iso" goto do_iso
if /i "%PKG_TYPE%"=="rootfs-tar" goto do_rootfs_tar
if /i "%PKG_TYPE%"=="rootfs_tar" goto do_rootfs_tar
if /i "%PKG_TYPE%"=="bsd-img" goto do_bsd_img
if /i "%PKG_TYPE%"=="bsd_img" goto do_bsd_img
if /i "%PKG_TYPE%"=="unikernel" goto do_unikernel
if /i "%PKG_TYPE%"=="docker-image" goto do_container_base
if /i "%PKG_TYPE%"=="oci-image" goto do_container_base
if /i "%PKG_TYPE%"=="qemu-qcow2" goto do_qemu_img
if /i "%PKG_TYPE%"=="vmware-vmdk" goto do_vmware_img
if /i "%PKG_TYPE%"=="hyperv-vhd" goto do_hyperv_img
if /i "%PKG_TYPE%"=="hyperv-vhdx" goto do_hyperv_img
if /i "%PKG_TYPE%"=="proxmox-template" goto do_proxmox_img
if /i "%PKG_TYPE%"=="virtualbox-vdi" goto do_virtualbox_img
if /i "%PKG_TYPE%"=="virtualbox-ova" goto do_virtualbox_img
if /i "%PKG_TYPE%"=="xen-img" goto do_xen_img
if /i "%PKG_TYPE%"=="microvm-disk" goto do_microvm_img
if /i "%PKG_TYPE%"=="aws-ami" goto do_aws_ami
if /i "%PKG_TYPE%"=="azure-vhd" goto do_azure_vhd
if /i "%PKG_TYPE%"=="gcp-image" goto do_gcp_image
if /i "%PKG_TYPE%"=="cloud-img" goto do_cloud_img

echo Error: Unsupported package format '%PKG_TYPE%'. >&2
exit /b 1

:do_container_base
call "%LIBSCRIPT_ROOT_DIR%\cli\commands\package_as\container_base.cmd" %*
exit /b %ERRORLEVEL%

:do_qemu_img
call "%LIBSCRIPT_ROOT_DIR%\cli\commands\package_as\qemu_img.cmd" %*
exit /b %ERRORLEVEL%

:do_vmware_img
call "%LIBSCRIPT_ROOT_DIR%\cli\commands\package_as\vmware_img.cmd" %*
exit /b %ERRORLEVEL%

:do_hyperv_img
call "%LIBSCRIPT_ROOT_DIR%\cli\commands\package_as\hyperv_img.cmd" %*
exit /b %ERRORLEVEL%

:do_proxmox_img
call "%LIBSCRIPT_ROOT_DIR%\cli\commands\package_as\proxmox_img.cmd" %*
exit /b %ERRORLEVEL%

:do_virtualbox_img
call "%LIBSCRIPT_ROOT_DIR%\cli\commands\package_as\virtualbox_img.cmd" %*
exit /b %ERRORLEVEL%

:do_xen_img
call "%LIBSCRIPT_ROOT_DIR%\cli\commands\package_as\xen_img.cmd" %*
exit /b %ERRORLEVEL%

:do_microvm_img
call "%LIBSCRIPT_ROOT_DIR%\cli\commands\package_as\microvm_img.cmd" %*
exit /b %ERRORLEVEL%

:do_aws_ami
call "%LIBSCRIPT_ROOT_DIR%\cli\commands\package_as\aws_ami.cmd" %*
exit /b %ERRORLEVEL%

:do_azure_vhd
call "%LIBSCRIPT_ROOT_DIR%\cli\commands\package_as\azure_vhd.cmd" %*
exit /b %ERRORLEVEL%

:do_gcp_image
call "%LIBSCRIPT_ROOT_DIR%\cli\commands\package_as\gcp_image.cmd" %*
exit /b %ERRORLEVEL%

:do_cloud_img
call "%LIBSCRIPT_ROOT_DIR%\cli\commands\package_as\cloud_img.cmd" %*
exit /b %ERRORLEVEL%

:do_raw_img
call "%LIBSCRIPT_ROOT_DIR%\cli\commands\package_as\raw_img.cmd" %*
exit /b %ERRORLEVEL%

:do_qcow2
call "%LIBSCRIPT_ROOT_DIR%\cli\commands\package_as\qcow2.cmd" %* %PKG_TYPE%
exit /b %ERRORLEVEL%

:do_iso
call "%LIBSCRIPT_ROOT_DIR%\cli\commands\package_as\iso.cmd" %*
exit /b %ERRORLEVEL%

:do_rootfs_tar
call "%LIBSCRIPT_ROOT_DIR%\cli\commands\package_as\rootfs_tar.cmd" %*
exit /b %ERRORLEVEL%

:do_bsd_img
call "%LIBSCRIPT_ROOT_DIR%\cli\commands\package_as\bsd_img.cmd" %*
exit /b %ERRORLEVEL%

:do_unikernel
call "%LIBSCRIPT_ROOT_DIR%\cli\commands\package_as\unikernel.cmd" %*
exit /b %ERRORLEVEL%

:do_docker
call "%SCRIPT_DIR%\formats\pkg_docker.cmd" %*
exit /b %ERRORLEVEL%

:do_docker_compose
call "%SCRIPT_DIR%\formats\pkg_docker_compose.cmd" %*
exit /b %ERRORLEVEL%

:do_msi
set "FIRST_ARG=%~1"
if "!FIRST_ARG:~0,6!"=="stacks" (
    call "%LIBSCRIPT_ROOT_DIR%\packaging\build_msi.cmd" %*
    exit /b !ERRORLEVEL!
)
if /i "!FIRST_ARG!"=="openedx" (
    call "%LIBSCRIPT_ROOT_DIR%\packaging\build_msi.cmd" stacks\cms\openedx %*
    exit /b !ERRORLEVEL!
)
call "%SCRIPT_DIR%\formats\pkg_msi.cmd" %*
exit /b %ERRORLEVEL%

:do_innosetup
call "%SCRIPT_DIR%\formats\pkg_innosetup.cmd" %*
exit /b %ERRORLEVEL%

:do_nsis
call "%SCRIPT_DIR%\formats\pkg_nsis.cmd" %*
exit /b %ERRORLEVEL%

:do_deb
call "%SCRIPT_DIR%\formats\pkg_deb.cmd" %*
exit /b %ERRORLEVEL%

:do_rpm
call "%SCRIPT_DIR%\formats\pkg_rpm.cmd" %*
exit /b %ERRORLEVEL%

:do_apk
call "%SCRIPT_DIR%\formats\pkg_apk.cmd" %*
exit /b %ERRORLEVEL%

:do_txz
call "%SCRIPT_DIR%\formats\pkg_txz.cmd" %*
exit /b %ERRORLEVEL%

:do_pkg
call "%SCRIPT_DIR%\formats\pkg_pkg.cmd" %*
exit /b %ERRORLEVEL%

:do_dmg
call "%SCRIPT_DIR%\formats\pkg_dmg.cmd" %*
exit /b %ERRORLEVEL%

:do_tui
call "%SCRIPT_DIR%\formats\pkg_tui.cmd" %*
exit /b %ERRORLEVEL%
