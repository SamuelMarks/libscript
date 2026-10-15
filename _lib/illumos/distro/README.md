# illumos Modular Distribution Substrate (`_lib/illumos/distro/`)

## Overview

The `_lib/illumos/distro/` directory houses modular assembly scripts for synthesizing tailored,
production-ready illumos distributions. It implements declarative, profile-driven component
selection across:

- **Base System Bootstrap**: Sysroot directory staging, userland proto-area setup, and release
  metadata validation (`base.sh`, `base.cmd`).
- **ZFS Dataset Hierarchy & Storage Management**: Canonical ZFS root pool (`rpool`) architecture,
  dataset layouts, `/etc/vfstab` generation, and boot environment configurations (`zfs.sh`,
  `zfs.cmd`).
- **Core System Configuration**: Nodename, hosts, login defaults, PAM, `/etc/nsswitch.conf`, DNS
  resolver, and serial console redirection (`config.sh`, `config.cmd`).
- **Package Management**: Official IPS (`pkg(1)`) repository mirrors, Joyent `pkgin`/`pkgsrc`
  bootstrap, or Tribblix `zap` catalogs (`pkg.sh`, `pkg.cmd`).
- **User Accounts & RBAC**: User creation, groups (`staff`, `sysadmin`), Solaris RBAC execution
  profiles (`Primary Administrator`), passwordless `sudoers.d`, `doas.conf`, and SSH authorized keys
  (`users.sh`, `users.cmd`).
- **Pluggable Init Systems**: Service supervision supporting native illumos SMF (`svc.startd`),
  `runit`, `s6`, `dinit`, and traditional SysV `/etc/inittab` (`init.sh`, `init.cmd`).
- **Display Protocols & Drivers**: Headless serial console mode, X11 Xorg server with
  VESA/modesetting/virtio drivers, or experimental Wayland (`display.sh`, `display.cmd`).
- **Desktop Environments**: MATE Desktop, XFCE4, Common Desktop Environment (CDE), and minimal
  window managers (`openbox`, `fluxbox`, `i3`, `dwm`) (`desktop.sh`, `desktop.cmd`).
- **Display Managers**: LightDM, SLiM, XDM, CDE dtlogin, and console `ttymon` login (`dm.sh`,
  `dm.cmd`).
- **Audio Subsystems**: Native Solaris Boomer in-kernel audio (`/dev/audio`), Open Sound System
  (OSS), PulseAudio, or headless none (`audio.sh`, `audio.cmd`).
- **Assembly Orchestrator**: JSON profile reader and pipeline coordinator (`assemble.sh`,
  `assemble.cmd`).

## Usage

To assemble a distribution sysroot from an illumos profile:

```sh
./_lib/illumos/distro/assemble.sh profiles/illumos/minimal-server.json build/illumos-sysroot
```

On Windows Command Prompt:

```cmd
.\_lib\illumos\distro\assemble.cmd profiles\illumos\minimal-server.json build\illumos-sysroot
```

## Profiles

Preset profiles are located in `profiles/illumos/`:

- `minimal-server.json`: Headless server with native SMF init, ZFS root pool, and minimal footprint.
- `zfs-cloud.json`: Cloud and Vagrant appliance with SMF, ZFS dataset hierarchies, and vagrant
  bootstrap credentials.
- `desktop-mate-x11.json`: Full illumos workstation with SMF, X11 Xorg server, MATE desktop suite,
  LightDM, and Boomer audio.
- `desktop-xfce-x11.json`: Lightweight workstation with SMF, X11 Xorg server, XFCE4 desktop suite,
  Slim login manager, and Boomer audio.
- `cde-retro-x11.json`: Classic Solaris Common Desktop Environment (CDE) with Xorg, dtlogin/xdm, and
  traditional appearance.
- `hardened-runit.json`: Minimal hardened micro-appliance running runit process supervision with
  zero GUI footprint.
- `pkgsrc-developer.json`: Developer-centric workstation profile with Joyent pkgin/pkgsrc bootstrap,
  build toolchains, and ZFS workspaces.

## Invariants & Design Guarantees

1. **Strict POSIX /bin/sh**: All `.sh` scripts adhere to POSIX standards with zero bashisms and
   utilize the canonical `THIS_FILE=` preamble and re-entrant `STACK` recursion guards.
2. **Windows Parity**: Every `.sh` script has an exact `.cmd` companion implementing identical
   flags, default paths, and delayed expansion.
3. **Idempotency**: All operations are guarded by `.libscript_stamps/*.stamp` files and defensive
   checks ensuring repeated runs produce zero drift and exit code `0`.
4. **100% Documentation**: Every script contains structured `## Overview` and `## Usage` headers
   within the first 30 lines.

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->

| Variable                           | Description                                                                                                                                                                                                                                                                                                                     | Default                    | Aliases/Examples |
| ---------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------------------------- | ---------------- |
| `LIBSCRIPT_DEFAULT_INSTALL_METHOD` | Global override for how software should be installed ('libscript_native' prebuilt binary, 'from-source' compiled from source code, 'system' via OS/selected package manager, or third-party version managers).                                                                                                                  | `libscript_native`         |                  |
| `LIBSCRIPT_PKG_MGR`                | Explicit package manager override for 'system' or package-manager-driven installations (e.g., 'apt-get', 'apk', 'dnf', 'yum', 'zypper', 'pacman', 'brew', 'port', 'pkg', 'xbps', 'emerge', 'winget', 'choco', 'scoop', 'nix', 'guix', 'spack', 'vcpkg', 'conan', 'pkgx'). When set, overrides auto-detection in detect_pkg_mgr. | `none`                     |                  |
| `LIBSCRIPT_BUILD_TOOLCHAIN`        | Toolchain selector used when building components from source ('default' uses the platform default C/C++ compiler via _lib/languages/c, whereas 'gcc', 'clang', 'tcc', 'custom-cc', or an explicit binary path compiles the component with that specific toolchain).                                                             | `default`                  |                  |
| `LIBSCRIPT_CUSTOM_CC_BIN`          | Optional filesystem path to a custom C compiler binary when LIBSCRIPT_BUILD_TOOLCHAIN='custom-cc'.                                                                                                                                                                                                                              | `none`                     |                  |
| `LIBSCRIPT_BUILD_CFLAGS`           | Global extra CFLAGS passed to source builds across components.                                                                                                                                                                                                                                                                  | `none`                     |                  |
| `LIBSCRIPT_BUILD_LDFLAGS`          | Global extra LDFLAGS passed to source builds across components.                                                                                                                                                                                                                                                                 | `none`                     |                  |
| `LIBSCRIPT_WINDOWS_PKG_MGR`        | Global package manager override for Windows (winget, choco, scoop, vcpkg).                                                                                                                                                                                                                                                      | `winget`                   |                  |
| `LIBSCRIPT_LOG_LEVEL`              | Minimum logging level (0=DEBUG, 1=INFO, 2=SUCCESS, 3=WARN, 4=ERROR).                                                                                                                                                                                                                                                            | `1`                        |                  |
| `LIBSCRIPT_LOG_FORMAT`             | Output format for logs (text, json).                                                                                                                                                                                                                                                                                            | `text`                     |                  |
| `LIBSCRIPT_LOG_FILE`               | File to write logs to (in addition to standard output).                                                                                                                                                                                                                                                                         | `none`                     |                  |
| `LIBSCRIPT_SERVICE_NAME`           | Overrides the default service name.                                                                                                                                                                                                                                                                                             | `none`                     |                  |
| `DOWNLOAD_DIR`                     | Directory where downloads are stored.                                                                                                                                                                                                                                                                                           | `none`                     |                  |
| `FORMAT`                           | Output format (e.g., json, text).                                                                                                                                                                                                                                                                                               | `none`                     |                  |
| `LIBSCRIPT_CACHE_DIR`              | Directory where cached files are stored.                                                                                                                                                                                                                                                                                        | `none`                     |                  |
| `LIBSCRIPT_OFFLINE`                | Flag (0 or 1) indicating whether offline mode is active, prohibiting outgoing network calls.                                                                                                                                                                                                                                    | `0`                        |                  |
| `LIBSCRIPT_FORCE_OFFLINE`          | Strict offline flag (0 or 1) that immediately aborts execution if network calls are attempted.                                                                                                                                                                                                                                  | `0`                        |                  |
| `LIBSCRIPT_DOWNLOAD_DIR`           | Staging directory for temporary download artifacts.                                                                                                                                                                                                                                                                             | `none`                     |                  |
| `LIBSCRIPT_LOG_DRIVER`             | Logging driver to use (e.g., fluentd).                                                                                                                                                                                                                                                                                          | `none`                     |                  |
| `LOGS_DIR`                         | Directory where logs should be stored.                                                                                                                                                                                                                                                                                          | `none`                     |                  |
| `VAULT_TOKEN`                      | Token for HashiCorp Vault authentication.                                                                                                                                                                                                                                                                                       | `none`                     |                  |
| `PREFIX`                           | Installation prefix.                                                                                                                                                                                                                                                                                                            | `none`                     |                  |
| `SERVE_FROM`                       | Base directory or context path for the service.                                                                                                                                                                                                                                                                                 | `none`                     |                  |
| `LIBSCRIPT_LOG_HOST`               | Host for remote logging.                                                                                                                                                                                                                                                                                                        | `none`                     |                  |
| `LIBSCRIPT_VERSION`                | Specifies the version of the package to use.                                                                                                                                                                                                                                                                                    | `none`                     |                  |
| `LIBSCRIPT_LOG_PORT`               | Port for remote logging.                                                                                                                                                                                                                                                                                                        | `none`                     |                  |
| `TPU_ZONE`                         | GCP Zone for TPU provisioning                                                                                                                                                                                                                                                                                                   | `us-central2-b`            |                  |
| `TPU_ACCELERATOR_TYPE`             | Type of TPU accelerator (e.g. v4-8)                                                                                                                                                                                                                                                                                             | `v4-8`                     |                  |
| `TPU_VERSION`                      | TPU VM OS version                                                                                                                                                                                                                                                                                                               | `tpu-ubuntu2204-base`      |                  |
| `GCP_PROJECT_ID`                   | GCP Project ID                                                                                                                                                                                                                                                                                                                  | `none`                     |                  |
| `XPK_CLUSTER_NAME`                 | Name for the XPK GKE cluster                                                                                                                                                                                                                                                                                                    | `none`                     |                  |
| `TPU_TENSOR_PARALLEL_SIZE`         | Tensor parallel size for TPU serving                                                                                                                                                                                                                                                                                            | `1`                        |                  |
| `MODEL_NAME`                       | HuggingFace model string to serve                                                                                                                                                                                                                                                                                               | `your-org/your-model-name` |                  |
| `WORKLOAD_NAME`                    | Name of the XPK workload                                                                                                                                                                                                                                                                                                        | `none`                     |                  |
| `JETSTREAM_IMAGE`                  | Docker image for JetStream TPU inference                                                                                                                                                                                                                                                                                        | `none`                     |                  |
| `ILLUMOS_DISTRO_VERSION`           | Target illumos/OmniOS release version to synthesize.                                                                                                                                                                                                                                                                            | `r151050`                  |                  |
| `ILLUMOS_DISTRO_INSTALL_METHOD`    | How to run illumos distro synthesis ('libscript_native' or 'system').                                                                                                                                                                                                                                                           | `libscript_native`         |                  |

<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
