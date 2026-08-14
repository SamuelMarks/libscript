# Cloud Block Storage

The `volume` component provides a unified multicloud interface for managing and attaching block
storage volumes.

## Usage

```sh
libscript volume [create|delete|list|attach|detach] [--cloud aws|gcp|azure] [--volume-id id] [--size gb] [--zone zone] [--type type] [--node-id id] [--device path]
```

### Commands

- `create`: Provision a new block storage volume.
- `delete`: Delete an existing block storage volume.
- `list`: List managed block storage volumes.
- `attach`: Attach a block storage volume to a compute node.
- `detach`: Detach a block storage volume from a compute node.

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
| `LIBSCRIPT_CLOUD` | Cloud provider (aws, gcp, azure). | `none` |  |
| `LIBSCRIPT_VOLUME_SIZE` | Size of the volume in GB. | `none` |  |
| `LIBSCRIPT_VOLUME_ZONE` | Zone/region for the volume. | `none` |  |
| `LIBSCRIPT_VOLUME_TYPE` | Type of the volume (e.g., ssd, hdd). | `none` |  |
| `LIBSCRIPT_NODE_ID` | Node ID to attach/detach the volume. | `none` |  |
| `LIBSCRIPT_DEVICE` | Device path for attachment (e.g., /dev/sdf). | `none` |  |
| `LIBSCRIPT_VOLUME_ID` | Volume ID for operations like delete, attach, detach. | `none` |  |
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->
- Linux
- macOS
- Windows
<!-- END_PLATFORMS -->
