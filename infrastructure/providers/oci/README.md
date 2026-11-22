# oci

## Purpose & Current State

**Purpose**: This document provides context and technical details for the `oci` component (part of
`_cloud-providers`) within the LibScript ecosystem. Oracle Cloud Infrastructure CLI (oci) version
manager and declarative compute, VCN network, security list, and DNS cloud driver.

## Usage

_Note: libscript manages versions natively for this component._

This directory contains the installation and configuration scripts for **Oracle Cloud Infrastructure
(OCI)**. It is designed to be executed via the global `libscript.sh` router or directly via
`cli.sh`.

### Lifecycle & Usage

**Install / Uninstall:**

```sh
libscript install oci
libscript uninstall oci
```

**Start / Stop (if configured as a background service):**

```sh
libscript start oci
libscript stop oci
```

**Package (e.g., as a Docker container):**

```sh
libscript package-as docker oci
```

_Note: On Unix environments, you can also use `./cli.sh install oci`. On Windows, use
`libscript.cmd` or `cli.cmd`._

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->

| Variable                  | Description                                                                                                                                  | Default               | Aliases/Examples |
| ------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------- | --------------------- | ---------------- |
| `OCI_INSTALL_METHOD`      | How to install oci. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, and 'from-source' compiles from source. | `libscript_native`    |                  |
| `OCI_VERSION`             | Specific version of oci to install.                                                                                                          | `latest`              | latest, stable   |
| `OCI_DOWNLOAD_URL`        | Override URL for downloading oci binary or archive artifacts.                                                                                | `none`                |                  |
| `OCI_RELEASES_URL`        | Override URL for querying oci available remote releases.                                                                                     | `none`                |                  |
| `OCI_REGION`              | Default Oracle Cloud Infrastructure region identifier (e.g., us-ashburn-1).                                                                  | `us-ashburn-1`        |                  |
| `OCI_COMPARTMENT_ID`      | Default OCI compartment OCID for VCN, security list, and compute instance provisioning.                                                      | `none`                |                  |
| `OCI_SUBNET_ID`           | Default OCI subnet OCID attached to provisioned compute instances.                                                                           | `none`                |                  |
| `OCI_AVAILABILITY_DOMAIN` | Target OCI availability domain (e.g., Uocm:PHX-AD-1) for compute instances.                                                                  | `none`                |                  |
| `OCI_SHAPE`               | Default OCI compute instance shape.                                                                                                          | `VM.Standard.E4.Flex` |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Architecture

- `setup.sh`: The main entrypoint that resolves the OS and invokes the correct script.
- `setup_generic.sh`: Fallback installation logic and native version manager operations.
- `test.sh` / `test.cmd`: Verification scripts to ensure the component is installed and functioning
  correctly.
- `vars.schema.json`: The schema definition for the CLI arguments.

## Variables

See `vars.schema.json` for details on available variables.

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
