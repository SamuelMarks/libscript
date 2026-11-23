# Tier 4 (`T4`) Cloud Provider: Oracle Cloud Infrastructure (OCI) (`infrastructure/providers/oci/`)

## Overview

Provisions and manages Oracle Cloud Infrastructure compute instances, Virtual Cloud Networks (VCNs),
and block volumes.

## Usage

```sh
# Invoke provider CLI operations
./libscript.sh infrastructure oci --help

# Provision a node and deploy a stack
./libscript.sh provision oci my-node default-net default-region ./ ~/app
```

```cmd
.\libscript.cmd infrastructure oci --help
.\libscript.cmd provision oci my-node default-net default-region .\ ~/app
```

## Configuration Options

<!-- BEGIN_VARS -->

| Variable                  | Description                                                                                                                                  | Default               |
| :------------------------ | :------------------------------------------------------------------------------------------------------------------------------------------- | :-------------------- |
| `OCI_INSTALL_METHOD`      | How to install oci. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, and 'from-source' compiles from source. | `libscript_native`    |
| `OCI_VERSION`             | Specific version of oci to install.                                                                                                          | `latest`              |
| `OCI_DOWNLOAD_URL`        | Override URL for downloading oci binary or archive artifacts.                                                                                | `-`                   |
| `OCI_RELEASES_URL`        | Override URL for querying oci available remote releases.                                                                                     | `-`                   |
| `OCI_REGION`              | Default Oracle Cloud Infrastructure region identifier (e.g., us-ashburn-1).                                                                  | `us-ashburn-1`        |
| `OCI_COMPARTMENT_ID`      | Default OCI compartment OCID for VCN, security list, and compute instance provisioning.                                                      | `-`                   |
| `OCI_SUBNET_ID`           | Default OCI subnet OCID attached to provisioned compute instances.                                                                           | `-`                   |
| `OCI_AVAILABILITY_DOMAIN` | Target OCI availability domain (e.g., Uocm:PHX-AD-1) for compute instances.                                                                  | `-`                   |
| `OCI_SHAPE`               | Default OCI compute instance shape.                                                                                                          | `VM.Standard.E4.Flex` |

> **Global Framework Variables**: Core paths, offline cache controls, and target triplet variables
> are documented in [`engine/common/README.md`](../../../engine/common/README.md).

<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
