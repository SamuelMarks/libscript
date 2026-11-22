# Windows Compatibility & Native Execution

LibScript provides first-class, zero-dependency support for Windows environments. It eliminates the
need for POSIX emulation layers (such as Cygwin, MSYS2, or WSL) for core toolchain version
management, stack provisioning, and multicloud orchestration.

---

## 🏛️ Dual-Platform Parity Architecture

Every shell script in LibScript has an identical, companion Windows Command Prompt (`.cmd`) script,
optionally accompanied by a PowerShell (`.ps1`) wrapper.

### Standard Windows Batch Script Preamble

All `.cmd` files enforce structured doc headers, delayed expansion, canonical `THIS_FILE` path
resolution, and re-entrant `:!THIS_FILE!:` `STACK` recursion guards within their first 25 lines:

```cmd
@echo off
:: # script_name.cmd
::
:: ## Overview
:: Concise description of what this batch script accomplishes.
::
:: ## Usage
:: script_name.cmd [args]

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
```

---

## 🛑 Option A Win32 Hard-Fail Boundary Proforma

Operating system image assembly and kernel baking (`T3` `synthesis/`) inherently rely on Linux
kernel primitives (`unshare`, `mount`, `losetup`, `mknod`). Windows Batch and PowerShell scripts
must **never** attempt fake Win32 emulation of these primitives.

Instead, companion Windows scripts for these operations adhere to the **Option A Proforma**:

1. **Immediate Exit Code 86**: Terminates execution immediately with **exit code `86`**
   (`EX_UNAVAILABLE` / `ENOSYS`).
2. **Clear Redirection**: Emits diagnostic output instructing the operator to invoke the
   containerized or virtualized builder (`engine/common/vm_builder.cmd` or `package-as docker`).

```cmd
:: Standard Option A Proforma Header
if not "%OS%"=="Windows_NT" exit /b 86
echo [ERROR] Native Linux kernel synthesis (mount/unshare/losetup) is unsupported on Win32. >&2
echo [INFO]  Please delegate synthesis to the VM builder: >&2
echo         call "%LIBSCRIPT_ROOT_DIR%\engine\common\vm_builder.cmd" %* >&2
echo [INFO]  Or generate containerized artifacts: >&2
echo         call "%LIBSCRIPT_ROOT_DIR%\libscript.cmd" package-as docker >&2
exit /b 86
```

### Scope of Option A Scripts

Representative Unix-kernel and distro-specific scripts implementing Option A (`exit /b 86`) on
Windows include:

- `synthesis/vfs/sysroot/mount_target_vfs.cmd` / `.ps1`
- `synthesis/vfs/sysroot/umount_target_vfs.cmd` / `.ps1`
- `synthesis/vfs/runner/runner.cmd` / `.ps1`
- `synthesis/disk/provision_disk.cmd` / `.ps1` & `engine/common/format_fs.cmd` / `.ps1`
- `synthesis/vfs/lfs-chroot.cmd`, `synthesis/vfs/lfs-mount-vfs.cmd`,
  `_lib/base-system/{lfs-base,lfs-temp-tools}/setup_generic.cmd`, and
  `_lib/toolchains/lfs-toolchain/setup_generic.cmd`
- `synthesis/formats/{disk_builder,vagrant_box}.cmd` and Unix-distro-specific
  `setup_{alpine,debian,freebsd,macos,rhel}.{cmd,ps1}` shims

---

## ⚡ Native Toolchain Version Management (`T1`)

LibScript serves as a native Windows version manager, eliminating the need for `nvm-windows`,
`pyenv-win`, or separate toolchain installers.

```cmd
:: Query remote upstream releases
call libscript.cmd ls-remote nodejs
call libscript.cmd ls-remote python

:: Install isolated versions side-by-side
call libscript.cmd install nodejs 22.14.0
call libscript.cmd install python 3.12.3
call libscript.cmd install postgres 16.2

:: Inspect local versions
call libscript.cmd ls nodejs

:: Activate in current Command Prompt session
call libscript.cmd use nodejs 22.14.0
```

### Windows Isolation & Directory Junctions

- **Isolated Sandbox**: Versions reside in `%USERPROFILE%\.libscript\<component>\<exact_version>\`.
- **Directory Junctions**: Aliases (like `lts` or `latest`) use native NTFS directory junctions
  (`mklink /J`) rather than copying gigabytes of duplicate files.
- **Session-Scoped PATH**: `env.cmd` prepends the component's `bin\` path to the current process
  `%PATH%`. It avoids modifying the permanent Windows User or System Environment Registry
  (`HKCU\Environment`).

---

## 📦 Native Installer Generation (`package-as`)

The `package-as` subsystem compiles declarative stack definitions into production-grade Windows
installers:

### 1. WiX Toolset (.MSI)

Generates standard Microsoft Installer packages via WiX Toolset v3/v4
(`synthesis/msi/template_msi.cmd`):

- Embeds ARP icons (`.ico`), scrollable RTF license agreements, and top/dialog banner bitmaps.
- Registers native Windows Services using WiX `<ServiceInstall>` and `<ServiceControl>` tags.
- Configures environment variables and firewall rules during install.

### 2. Inno Setup (.EXE)

Generates lightweight single-file setup executables (`synthesis/msi/template_inno.cmd`):

- Modern wizard UI with support for multi-license review.
- Silent non-interactive installation flag: `/VERYSILENT /SUPPRESSMSGBOXES`.

### 3. NSIS (.EXE)

Compiles scriptable setup wizards using the Nullsoft Scriptable Install System
(`synthesis/msi/template_nsis.cmd`):

- Header image bitmaps and multi-page license agreements.
- Silent non-interactive flag: `/S`.

### 4. Multi-License Acceptance & Silent Deployment

When multi-component stacks are bundled (e.g., MySQL, Redis, MongoDB, Python, Node.js), installers
mandate review and acceptance of each third-party license:

- **Interactive GUI**: Presents sequential EULA agreements with required checkboxes for each
  component.
- **Silent MSI Installs**: Pass `AGREE_ALL_LICENSES=1` with `msiexec /i installer.msi /qn`. Omission
  halts installation with MSI fatal error `1603`.
- **Silent Inno Installs**: Pass `/SILENT /ACCEPTALLICENSES=yes`.
- **Silent NSIS Installs**: Pass `/S /ACCEPTALLICENSES=1`.

---

## 🌐 Ingress & Service Supervision (`netctl`)

On Windows, the `netctl` routing engine translates declarative ingress rules directly into native
Internet Information Services (IIS) configurations:

- Generates `web.config` rewrite rules for reverse proxying to local backend services.
- Emits `appcmd.exe` automation commands for virtual directory and binding creation.
- Manages background service registration using native Windows Service Control Manager
  (`sc.exe create`).

---

## ☁️ Cloud & AI Operations from Windows

LibScript executes all multicloud and AI management commands natively from Windows Command Prompt
using official cloud CLIs:

- **AWS**: Manages EC2 instances and VPCs via `aws.exe`.
- **Azure**: Provisions Resource Groups and VNets via `az.cmd`.
- **GCP**: Orchestrates Google Cloud TPU VMs and GKE XPK training clusters natively via
  `gcloud.cmd`.

```cmd
:: Provision a cloud stack directly from Windows Command Prompt
call libscript.cmd provision aws prod-node vpc-main us-east-1 . \app
```

---

## 🧪 Windows Testing & Bento Hypervisor Boxes

LibScript maintains automated verification on Windows hosts and inside isolated Windows virtual
machines:

- **Native Host Test Runner**: `tests\run_native_tests.cmd` executes test sequences natively.
- **Vagrant Windows 11 Testing**: Tests run inside the `bento/windows-11` Vagrant box.
  - Built using the custom Bento fork at
    [https://github.com/SamuelMarks/bento/tree/multi-os-qemu-aarch64](https://github.com/SamuelMarks/bento/tree/multi-os-qemu-aarch64).
  - Supports Apple Silicon (`aarch64`) and Intel/AMD (`x86_64`) hosts.
  - Full instructions are available in [VAGRANT.md](VAGRANT.md).

---

## 🖥️ ReactOS Guest & Built-in Distribution Synthesis (`synthesis/distro/reactos/`)

LibScript supports synthesizing redistributable **ReactOS** (`0.4.16+` `i686` and `nightly`
`x86_64`) distributions with pre-installed default applications
(`synthesis/profiles/reactos/*.json`):

- **PowerShell-Free `.cmd` Execution**: `engine/common/os_info.cmd`, `pkg_mgr.cmd`, and
  `setup_base.cmd` detect ReactOS (`IS_REACTOS=1`, `TARGET_OS_FLAVOR=reactos`), prepend portable
  Win32 bootstrap tools (`%SystemDrive%\libscript\bootstrap\bin`: `curl.exe`, `7za.exe`, `jq.exe`,
  `sha256sum.exe`), and avoid `powershell.exe` / `winget` dependencies.
- **RAPPS & Silent `.msi` Provisioning**: `_lib/package-managers/rapps/` (`PKG_MGR=rapps`) parses
  upstream `rapps-db` INI definitions on the host to prefetch installers for air-gapped guest
  installation alongside `msiexec.exe /i <stack>.msi /qn AGREE_ALL_LICENSES=1` via `GuiRunOnce`
  (`reactos/unattend.inf` -> `%SystemDrive%\libscript\firstboot.cmd`).
- **Strict `i686` vs. `x86_64` PE Bitness (No WoW64)**: 64-bit ReactOS does not implement WoW64; all
  staged `.exe`/`.dll`/`.sys` binaries must match the profile's `target.arch` (`0x014c` vs.
  `0x8664`). Native Win32 C/C++ desktop utilities (`7zip`, `sumatrapdf`, `notepadpp`, `vlc`, `git`,
  `cmake`, `ninja`, `sqlite-tools`, `libscript-rest-api`) are first-class default workloads, whereas
  NT8+/NT10-only runtimes or IIS-specific features are excluded.

---

## 🧱 Native Windows & MS-DOS (`dos32`) Component-Level Package Managers

LibScript includes dedicated `T1` component-level package managers under `_lib/utilities/` for six
zero-POSIX-emulation MSVC Win32 and OpenWatcom `dos32` port suites:

- **`_lib/utilities/freebsd-usr-bin/`** (`SamuelMarks/freebsd-usr-bin-windows`): ~200 FreeBSD
  `usr.bin` tools (`sed`, `grep`, `cut`, `tr`, `sort`, `uniq`, `wc`, `head`, `tail`, `xargs`,
  `find`, `cmp`, `diff`, `patch`, `bmake`, `bsdtar`, `bsdunzip`) supporting both monolithic suite
  archives and per-applet resolution via `FREEBSD_USR_BIN_APPLET`.
- **`_lib/utilities/toybox/`** (`SamuelMarks/toybox-windows`): All-in-one BSD-licensed POSIX
  coreutils (`toybox.exe` for `X64`/`X86`/`ARM64` and `dos32`).
- **`_lib/utilities/gawk/`** (`SamuelMarks/gawk-windows`): Standalone GNU Awk 5.4+ (`gawk.exe` and
  `awk.exe` alias).
- **`_lib/utilities/busybox/`** (`SamuelMarks/busybox-windows`): Multi-call UNIX userland
  (`busybox.exe`).
- **`_lib/utilities/jq/`** (`SamuelMarks/jq-windows`): Native JSON processor (`jq.exe`).
- **`_lib/utilities/dash/`** (`SamuelMarks/dash-windows`): Native `/bin/sh` (`dash.exe` and
  `sh.exe`).

Invoking `libscript depends <pkg>` (or `depends <pkg>` / `:libscript_depends <pkg>` inside recipes)
resolves target-specific binaries automatically via `engine/common/os_info.{sh,cmd}`,
`engine/common/pkg_mgr.{sh,cmd}`, and `engine/common/pkg_map.tsv` (`PKG_MGR=libscript`): on MS-DOS
(`TARGET_OS=msdos`, `IS_MSDOS=1`), `depends jq` stages the `dos32` `jq.exe` (co-staging `DOS32A.EXE`
/ `DOS4GW.EXE` when bundled), while on Windows (`TARGET_OS=windows`) it stages the native PE
executable (`jq-{VER}-{X64|X86|ARM64}.exe`).
