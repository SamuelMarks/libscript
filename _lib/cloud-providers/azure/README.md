# Azure

This module configures the `azure` cloud provider capabilities within LibScript. It leverages the
Azure CLI to provide provisioning and configuration targets for Microsoft Azure.

## Purpose & Current State

- Provides runtime context and authentication pathways for Azure targets.
- Serves as the foundation for multi-cloud deployments bridging to Azure VMs, AKS, and Blob Storage.
- Fully implements native lifecycle orchestration for `network` (VNets), `firewall` (NSGs), `node`
  (VMs), `dns` (Record Sets), and code `sync` logic across both POSIX (`setup_generic.sh`) and
  Windows (`setup.ps1`) endpoints.

## Usage

Used internally by the `libscript provision` and `libscript deprovision` systems when Azure is the
target provider. You can also invoke these primitives manually to orchestrate shared instances:

```bash
# Example manual orchestration
./libscript.sh cloud azure network create my-vnet my-rg
./libscript.sh cloud azure firewall create my-nsg my-rg "22 80 443"
./libscript.sh cloud azure node create my-node Ubuntu2204 my-rg --size Standard_B2s --vnet-name my-vnet --nsg my-nsg
./libscript.sh cloud azure node deploy my-node my-rg ./ my-app
```

## Configuration Options

<!-- BEGIN_VARS -->

| Variable                               | Description                                                                                                                                                           | Default            | Aliases/Examples               |
| -------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------ | ------------------------------ |
| `LIBSCRIPT_TAG_ENABLE`                 | Flag (0 or 1) enabling resource tagging on cloud provider assets.                                                                                                     | `none`             |                                |
| `LIBSCRIPT_TAG_KEY`                    | Tag key applied to provisioned cloud provider resources.                                                                                                              | `none`             |                                |
| `LIBSCRIPT_TAG_VALUE`                  | Tag value applied to provisioned cloud provider resources.                                                                                                            | `none`             |                                |
| `LIBSCRIPT_ALLOW_ANY_TAG_MANIPULATION` | Flag (0 or 1) allowing cloud provider teardown operations to modify resources without matching tag filters.                                                           | `none`             |                                |
| `LIBSCRIPT_EXPORT_STAGE_DIR`           | Staging directory used when exporting application and database state archives.                                                                                        | `none`             |                                |
| `LIBSCRIPT_IMPORT_STAGE_DIR`           | Staging directory used when importing application and database state archives.                                                                                        | `none`             |                                |
| `AZURE_RESOURCE_GROUP`                 | Default Azure Resource Group name for cloud provisioning operations.                                                                                                  | `none`             | LIBSCRIPT_AZURE_RESOURCE_GROUP |
| `AZURE_LOCATION`                       | Azure Location                                                                                                                                                        | `eastus`           |                                |
| `AZURE_INSTALL_METHOD`                 | How to install AZURE. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, 'mise', 'asdf', 'pkgx', or 'vfox' defers to third-party tools. | `libscript_native` |                                |
| `AZURE_CONTAINER`                      | Azure Blob Storage container name used for cloud artifact transfers.                                                                                                  | `none`             |                                |
| `AZURE_DOWNLOAD_URL`                   | Override URL for downloading azure binary or archive artifacts.                                                                                                       | `none`             |                                |
| `AZURE_IMAGE_NAME`                     | Azure VM image URN or gallery image identifier used when provisioning compute instances.                                                                              | `none`             |                                |
| `AZURE_RELEASES_URL`                   | Override URL for querying azure available remote releases.                                                                                                            | `none`             |                                |
| `AZURE_STORAGE_ACCOUNT`                | Azure Storage Account name associated with cloud state or blob artifacts.                                                                                             | `none`             |                                |
| `AZURE_VERSION`                        | Specific version of azure to install (e.g., latest, lts, or exact version).                                                                                           | `none`             |                                |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `_lib/_common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
