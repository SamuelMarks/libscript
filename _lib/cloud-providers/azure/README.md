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
| Variable | Description | Default | Aliases/Examples |
|---|---|---|---|
| `LIBSCRIPT_DEFAULT_INSTALL_METHOD` | Global override for how software should be installed (system vs libscript_native). | `libscript_native` |  |
| `LIBSCRIPT_WINDOWS_PKG_MGR` | Global package manager override for Windows (winget, choco). | `winget` |  |
| `LIBSCRIPT_LOG_LEVEL` | Minimum logging level (0=DEBUG, 1=INFO, 2=SUCCESS, 3=WARN, 4=ERROR). | `1` |  |
| `LIBSCRIPT_LOG_FORMAT` | Output format for logs (text, json). | `text` |  |
| `LIBSCRIPT_LOG_FILE` | File to write logs to (in addition to standard output). | `none` |  |
| `LIBSCRIPT_SERVICE_NAME` | Overrides the default service name. | `none` |  |
| `DOWNLOAD_DIR` | Directory where downloads are stored. | `none` |  |
| `FORMAT` | Output format (e.g., json, text). | `none` |  |
| `LIBSCRIPT_CACHE_DIR` | Directory where cached files are stored. | `none` |  |
| `LIBSCRIPT_LOG_DRIVER` | Logging driver to use (e.g., fluentd). | `none` |  |
| `LOGS_DIR` | Directory where logs should be stored. | `none` |  |
| `VAULT_TOKEN` | Token for HashiCorp Vault authentication. | `none` |  |
| `PREFIX` | Installation prefix. | `none` |  |
| `SERVE_FROM` | Base directory or context path for the service. | `none` |  |
| `LIBSCRIPT_LOG_HOST` | Host for remote logging. | `none` |  |
| `LIBSCRIPT_VERSION` | Specifies the version of the package to use. | `none` |  |
| `LIBSCRIPT_LOG_PORT` | Port for remote logging. | `none` |  |
| `TPU_ZONE` | GCP Zone for TPU provisioning | `us-central2-b` |  |
| `TPU_ACCELERATOR_TYPE` | Type of TPU accelerator (e.g. v4-8) | `v4-8` |  |
| `TPU_VERSION` | TPU VM OS version | `tpu-ubuntu2204-base` |  |
| `GCP_PROJECT_ID` | GCP Project ID | `none` |  |
| `XPK_CLUSTER_NAME` | Name for the XPK GKE cluster | `none` |  |
| `TPU_TENSOR_PARALLEL_SIZE` | Tensor parallel size for TPU serving | `1` |  |
| `MODEL_NAME` | HuggingFace model string to serve | `your-org/your-model-name` |  |
| `WORKLOAD_NAME` | Name of the XPK workload | `none` |  |
| `JETSTREAM_IMAGE` | Docker image for JetStream TPU inference | `none` |  |
| `AZURE_RESOURCE_GROUP` | Azure Resource Group | `none` |  |
| `AZURE_LOCATION` | Azure Location | `eastus` |  |
| `AZURE_INSTALL_METHOD` | How to install AZURE. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, 'mise', 'asdf', 'pkgx', or 'vfox' defers to third-party tools. | `libscript_native` |  |
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->
- Linux
- macOS
- Windows
<!-- END_PLATFORMS -->
