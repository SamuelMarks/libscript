# FreeBSD Modular Distribution Substrate (`_lib/freebsd/distro/`)

## Overview

The `_lib/freebsd/distro/` directory houses modular assembly scripts for synthesizing tailored,
production-ready FreeBSD distributions. It implements flexible component selection across:

- **Base System Bootstrap**: Sysroot directory staging, release manifest validation, and extraction
  (`base.sh`, `base.cmd`).
- **Core System Configuration**: Loader configuration, rc.d configuration, fstab generation, and
  terminal lines (`config.sh`, `config.cmd`).
- **Package Management**: Official pkg(8) repository mirrors and configuration (`pkg.sh`,
  `pkg.cmd`).
- **User Accounts & Security**: User creation, groups (`wheel`, `operator`, `video`), `doas.conf`,
  `sudoers.d`, and SSH authorized keys (`users.sh`, `users.cmd`).
- **Init Systems**: Pluggable supervisors including `bsd-rc`, `openrc`, `runit`, `s6`, and `dinit`
  (`init.sh`, `init.cmd`).
- **Display Protocols & Drivers**: Wayland, X11, or headless modes with `drm-kmod` and devfs rules
  (`display.sh`, `display.cmd`).
- **Desktop Environments**: Sway, XFCE4, KDE Plasma 6, Openbox, Labwc, LXQt, and GNOME
  (`desktop.sh`, `desktop.cmd`).
- **Display Managers**: LightDM, SDDM, Greetd, and console login (`dm.sh`, `dm.cmd`).
- **Audio Subsystems**: Native FreeBSD OSS, PipeWire/WirePlumber, or none (`audio.sh`, `audio.cmd`).
- **Assembly Orchestrator**: JSON profile reader and module pipeline coordinator (`assemble.sh`,
  `assemble.cmd`).

## Usage

To assemble a distribution sysroot from a profile:

```sh
./_lib/freebsd/distro/assemble.sh profiles/freebsd/minimal-server.json build/freebsd-sysroot
```

On Windows Command Prompt:

```cmd
.\_lib\freebsd\distro\assemble.cmd profiles\freebsd\minimal-server.json build\freebsd-sysroot
```

## Profiles

Preset profiles are located in `profiles/freebsd/`:

- `minimal-server.json`: Headless server with bsd-rc and UFS2.
- `zfs-cloud.json`: Headless cloud instance with bsd-rc, ZFS root pool, and Vagrant user.
- `openrc-wayland-sway.json`: OpenRC supervisor, Wayland, Sway WM, seatd, and PipeWire.
- `desktop-xfce-x11.json`: bsd-rc supervisor, X11 Xorg, XFCE4, and LightDM.
- `plasma-wayland.json`: bsd-rc supervisor, Wayland, KDE Plasma 6, and SDDM.
- `hardened-runit.json`: Runit supervisor, minimal footprint, hardened base.

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
| `FREEBSD_DISTRO_VERSION`           | Target FreeBSD release version to synthesize.                                                                                                                                                                                                                                                                                   | `14.1-RELEASE`             |                  |
| `FREEBSD_DISTRO_INSTALL_METHOD`    | How to run FreeBSD distro synthesis ('libscript_native' or 'system').                                                                                                                                                                                                                                                           | `libscript_native`         |                  |

<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
