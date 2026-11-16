# ReactOS Modular Distribution Synthesizer (`reactos-distro`)

Synthesizes reproducible, bootable **ReactOS** (`i686` and `x86_64`) distributions from declarative
JSON profiles (`execution-plan.reactos.schema.json`), supporting both fast upstream ISO repacking
and full RosBE CMake/Ninja source compilation, unattended `unattend.inf` setup, offline RAPPS +
silent `.msi` + PowerShell-free Tier 1 `.cmd` default app baking, and multi-format export (`iso`,
`raw`, `qcow2`, `vhd`, `vmdk`, `box`).

## Usage

```sh
# Assemble a ReactOS sysroot from a declarative profile
./_lib/reactos/distro/assemble.sh profiles/reactos/desktop-classic-i686.json build/reactos-sysroot

# Generate a live ReactOS installer image
./_lib/reactos/distro/live_reactos.sh build/live-reactos.iso build/live-reactos-work
```

## Configuration Variables

See [`vars.schema.json`](./vars.schema.json) for all supported configuration variables.

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->

| Variable                        | Description                                                                                                                             | Default                                                  | Aliases/Examples             |
| ------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------- | ---------------------------- |
| `LIBSCRIPT_TARGET_SYSROOT`      | Target root filesystem staging path when provisioning chroots or OS images.                                                             | `none`                                                   | LIBSCRIPT_TARGET_ROOTFS      |
| `LIBSCRIPT_TARGET_ARCH`         | Target CPU architecture when cross-compiling or building OS images.                                                                     | `none`                                                   |                              |
| `LIBSCRIPT_TARGET_LIBC`         | Target C standard library implementation (glibc, musl, uclibc, picolibc, nolibc, msvcrt).                                               | `none`                                                   |                              |
| `LIBSCRIPT_TARGET_OS`           | Target operating system identifier when provisioning or cross-compiling.                                                                | `none`                                                   |                              |
| `LIBSCRIPT_HOST_ROOT`           | Isolated cross-toolchain host directory prefix when bootstrapping or executing inside a container/chroot.                               | `none`                                                   |                              |
| `LIBSCRIPT_STAGE`               | Active multi-stage Tier 2 execution plan stage identifier (e.g., stage0, stage1, stage2, stage3).                                       | `none`                                                   |                              |
| `LIBSCRIPT_IMAGE_BUILD`         | Flag (0 or 1) indicating offline sysroot/image synthesis mode so service installers stage unit files without starting host daemons.     | `0`                                                      |                              |
| `LIBSCRIPT_STRICT_IMAGE_BUILD`  | Flag (0 or 1) enforcing strict native image synthesis and rejecting missing-tool stub fallbacks without writing completion stamps.      | `0`                                                      |                              |
| `LIBSCRIPT_ALLOW_STUB`          | Flag (0 or 1) explicitly permitting structural stub artifacts during unit and dry-run testing when hypervisor or mkfs tools are absent. | `0`                                                      |                              |
| `LIBSCRIPT_VM_WORKER`           | Virtualization worker backend override (docker, wsl2, qemu, bhyve, omnios-vm) for cross-OS disk and filesystem synthesis.               | `none`                                                   |                              |
| `LIBSCRIPT_UNIKERNEL_FRAMEWORK` | Target unikernel build framework (unikraft, nanos, osv, rumprun, mirageos) when synthesizing unikernel appliances.                      | `none`                                                   |                              |
| `LIBSCRIPT_RELEASEVER`          | Target Enterprise Linux major release version passed to dnf --releasever when staging into LIBSCRIPT_TARGET_SYSROOT.                    | `9`                                                      |                              |
| `LIBSCRIPT_SYSTEMD_DIR`         | Override directory for systemd unit and drop-in override files (defaults to /etc/systemd/system).                                       | `none`                                                   |                              |
| `LIBSCRIPT_LIB_SYSTEMD_DIR`     | Override directory for vendor systemd unit files (defaults to /lib/systemd/system).                                                     | `none`                                                   |                              |
| `LIBSCRIPT_ETC_DIR`             | Override root configuration directory for system service config files (defaults to /etc).                                               | `none`                                                   |                              |
| `LIBSCRIPT_INITD_DIR`           | Override directory for SysV/OpenRC init.d scripts (defaults to /etc/init.d).                                                            | `none`                                                   |                              |
| `LIBSCRIPT_FREEBSD_RCD_DIR`     | Override directory for FreeBSD rc.d service scripts (defaults to /usr/local/etc/rc.d).                                                  | `none`                                                   |                              |
| `LIBSCRIPT_RUN_DIR`             | Override runtime PID/socket directory (defaults to /var/run).                                                                           | `none`                                                   |                              |
| `LIBSCRIPT_USR_LOCAL_BIN`       | Override directory for locally installed system binaries (defaults to /usr/local/bin).                                                  | `none`                                                   |                              |
| `LIBSCRIPT_USR_LOCAL_ETC`       | Override directory for locally installed system configuration files (defaults to /usr/local/etc).                                       | `none`                                                   |                              |
| `LIBSCRIPT_HOME_BASE`           | Base parent directory for user home directories (defaults to /home).                                                                    | `none`                                                   |                              |
| `LIBSCRIPT_ROOT_HOME`           | Root user home directory override (defaults to /root).                                                                                  | `none`                                                   |                              |
| `REACTOS_DISTRO_VERSION`        | Target ReactOS release or channel version synthesized by reactos-distro.                                                                | `0.4.16`                                                 |                              |
| `REACTOS_DISTRO_INSTALL_METHOD` | Installation strategy for reactos-distro ('libscript_native' or 'system').                                                              | `libscript_native`                                       |                              |
| `REACTOS_DISTRO_DOWNLOAD_URL`   | Override URL for downloading a custom ReactOS BootCD or LiveCD ISO/ZIP archive.                                                         | `none`                                                   |                              |
| `REACTOS_DISTRO_RELEASES_URL`   | Override URL for querying upstream ReactOS releases.                                                                                    | `none`                                                   |                              |
| `REACTOS_DISTRO_FETCH_BASE`     | Set to '1' to download and unpack full upstream ReactOS ISO archives when online.                                                       | `0`                                                      | LIBSCRIPT_FETCH_REACTOS_BASE |
| `REACTOS_VERSION`               | Target ReactOS version passed to base and kernel synthesis scripts.                                                                     | `0.4.16`                                                 |                              |
| `REACTOS_BUILD_FROM_SOURCE`     | Set to '1' to compile ReactOS from REACTOS_SRC_DIR via RosBE instead of repacking upstream ISOs.                                        | `0`                                                      |                              |
| `REACTOS_SRC_DIR`               | Path to a local ReactOS git checkout used when REACTOS_BUILD_FROM_SOURCE=1.                                                             | `none`                                                   |                              |
| `REACTOS_QEMU_BAKE`             | Set to '1' to execute headless QEMU Stage-1/Stage-2 unattended installation when generating disk images.                                | `0`                                                      |                              |
| `LIBSCRIPT_REACTOS_MIRROR`      | Base mirror URL for official ReactOS release BootCD and LiveCD archives.                                                                | `https://sourceforge.net/projects/reactos/files/ReactOS` |                              |
| `LIBSCRIPT_REACTOS_NIGHTLY_URL` | Direct override URL for fetching a ReactOS i686 or x86_64 nightly ISO/7z archive.                                                       | `none`                                                   |                              |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `_lib/_common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
