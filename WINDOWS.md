# Windows Compatibility & Native Execution

LibScript provides first-class, zero-dependency support for Windows environments. It eliminates the
need for POSIX emulation layers (such as Cygwin, MSYS2, or WSL) for core toolchain version
management, stack provisioning, and multicloud orchestration.

---

## 🏛️ Dual-Platform Parity Architecture

Every shell script in LibScript has an identical, companion Windows Command Prompt (`.cmd`) script,
optionally accompanied by a PowerShell (`.ps1`) wrapper.

### Standard Windows Batch Script Preamble

All `.cmd` files enforce delayed expansion, canonical `THIS_FILE` path resolution, and re-entrant
`STACK` recursion guards within their first 25 lines:

```cmd
@echo off
setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"

SET "searchVal=;%THIS_FILE%;"
IF NOT DEFINED STACK (
    SET "STACK=;%THIS_FILE%;"
    echo [CONTINUE] processing "%THIS_FILE%"
) ELSE (
    IF NOT "!STACK:%searchVal%=!"=="!STACK!" (
        echo [STOP]     processing "%THIS_FILE%"
        SET ERRORLEVEL=0
        goto end
    ) ELSE (
        SET "STACK=!STACK!%THIS_FILE%;"
        echo [CONTINUE] processing "%THIS_FILE%"
    )
)

:: Canonical SCRIPT_DIR and LIBSCRIPT_ROOT_DIR resolution
for %%I in ("%THIS_FILE%\..") do set "SCRIPT_DIR=%%~fI"
if not defined LIBSCRIPT_ROOT_DIR (
    set "LIBSCRIPT_ROOT_DIR=%SCRIPT_DIR%"
    :find_root
    if not exist "!LIBSCRIPT_ROOT_DIR!\libscript.cmd" (
        for %%I in ("!LIBSCRIPT_ROOT_DIR!\..") do set "LIBSCRIPT_ROOT_DIR=%%~fI"
        goto find_root
    )
)
```

---

## 🛑 Option A Win32 Hard-Fail Boundary Proforma

Operating system image assembly and kernel baking (Tier 2) inherently rely on Linux kernel
primitives (`unshare`, `mount`, `losetup`, `mknod`). Windows Batch and PowerShell scripts must
**never** attempt fake Win32 emulation of these primitives.

Instead, companion Windows scripts for these operations adhere to the **Option A Proforma**:

1. **Immediate Exit Code 86**: Terminates execution immediately with **exit code `86`**
   (`EX_UNAVAILABLE` / `ENOSYS`).
2. **Clear Redirection**: Emits diagnostic output instructing the operator to invoke the
   containerized or virtualized builder (`_lib/orchestration/vm_builder.cmd` or
   `package-as docker`).

```cmd
:: Standard Option A Proforma Header
if not "%OS%"=="Windows_NT" exit /b 86
echo [ERROR] Native Linux kernel synthesis (mount/unshare/losetup) is unsupported on Win32. >&2
echo [INFO]  Please delegate synthesis to the VM builder: >&2
echo         call "%LIBSCRIPT_ROOT_DIR%\_lib\orchestration\vm_builder.cmd" %* >&2
echo [INFO]  Or generate containerized artifacts: >&2
echo         call "%LIBSCRIPT_ROOT_DIR%\libscript.cmd" package-as docker >&2
exit /b 86
```

### Scope of Option A Scripts

The following scripts implement Option A on Windows:

- `_lib/orchestration/vfs/mount_target_vfs.cmd` / `.ps1`
- `_lib/orchestration/vfs/umount_target_vfs.cmd` / `.ps1`
- `_lib/orchestration/runner/runner.cmd` / `.ps1`
- `_lib/storage/provision_disk.cmd` / `.ps1`

---

## ⚡ Native Toolchain Version Management (Tier 1)

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
(`packaging/template_msi.cmd`):

- Embeds ARP icons (`.ico`), scrollable RTF license agreements, and top/dialog banner bitmaps.
- Registers native Windows Services using WiX `<ServiceInstall>` and `<ServiceControl>` tags.
- Configures environment variables and firewall rules during install.

### 2. Inno Setup (.EXE)

Generates lightweight single-file setup executables (`packaging/template_inno.cmd`):

- Modern wizard UI with support for multi-license review.
- Silent non-interactive installation flag: `/VERYSILENT /SUPPRESSMSGBOXES`.

### 3. NSIS (.EXE)

Compiles scriptable setup wizards using the Nullsoft Scriptable Install System
(`packaging/template_nsis.cmd`):

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
