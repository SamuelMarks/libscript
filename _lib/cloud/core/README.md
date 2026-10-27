# Cloud

The `cloud` component provides a unified multicloud interface for managing resources across various
cloud providers (AWS, Azure, GCP).

## Usage

```sh
./libscript.sh cloud <provider> <resource> <action> [args...]
```

For high-level provisioning and deprovisioning:

```sh
./libscript.sh provision [--tpu] [--shared-storage] <provider> <node_name> <rg_or_vpc> <region_or_zone> [local_repo_path] [remote_dest]
./libscript.sh deprovision [--tpu] [--shared-storage] [--retain-ip] [--retain-data] <provider> <node_name> <rg_or_vpc> <region_or_zone> [local_repo_path] [remote_dest]
```

### High-Level Orchestrator Flags

- `--tpu` / `--accelerator`: Routes the deployment to utilize specialized TPU VM components (e.g.
  `gcp-tpu-vm`), attaching the necessary network topology, queue pooling, and concurrent pod syncing
  operations natively.
- `--shared-storage`: When passed alongside `--tpu`, provisions and automatically mounts
  high-throughput NFS/Shared Disk arrays (e.g., GCP Filestore) across all cluster workers.
- `--retain-ip`: Prevents the release of static IPs during a `deprovision` action.
- `--retain-data`: Prevents the deletion of persistent stateful data disks during a `deprovision`
  action.

### Providers

- `aws`
- `azure`
- `gcp`

### Resources

- `dns`, `network`, `firewall`, `node`, `node-group`, `jumpbox`, `storage`, `cron`

### Node Actions

- `create`, `list`, `delete`, `exec`, `winrm-exec`
- `deploy` (intelligent codebase sync honoring `.gitignore`, prefers `rsync`, falls back to `scp`,
  supports `winrm` for Windows nodes)
- `scp`, `scp-from`, `winrm-cp`, `winrm-cp-from` (File transfer)
- `snapshot`, `restore` (State management)

### DNS Actions

- `map-node` (Map a running node's public IP to a DNS A record via Cloud DNS / Route53 / Azure DNS)

### Tagging Options

You can control resource tagging during `create` operations:

- `--tags <T>`: Add custom tags.
- AWS: `Key=Project,Value=Postgres15`
- Azure: `Project=Postgres15`
- GCP: `project=postgres15`
- `--no-default-tags`: Disable the default `ManagedBy=LibScript` tag.

## Authentication

LibScript uses native CLIs (`aws`, `az`, `gcloud`) under the hood. Before provisioning
infrastructure, authenticate with your chosen provider using their standard commands (e.g.,
`aws configure`, `az login`, `gcloud auth login`).

See [DOCS.md](./DOCS.md#initial-authentication-setup) for detailed authentication setup options
(Interactive and CI/CD modes).

## Global Management Commands

### Remote State Locking

When working in a team, LibScript can lock your multicloud state file to prevent concurrent
destructive operations. Supported remote backends include AWS S3 (with DynamoDB mock tracking for
locks), Azure Blob Storage (using Leases), and Google Cloud Storage (using Object Locks).

```sh
export REMOTE_STATE_URI="s3://my-team-bucket/libscript_state"
# Any mutating command will now acquire a lock, pull the state, execute, push the state, and release the lock.
./libscript.sh cloud aws node create my-node
```

### View managed resources

```sh

./libscript.sh cloud list-managed

./libscript.sh cloud list-managed Project=Postgres15
```

### Drift Detection

Detect discrepancies between your local `.libscript_state.json` and actual cloud reality (e.g.,
resources manually deleted, or untracked resources provisioned without a state file):

```sh
./libscript.sh cloud diff
```

### Backup

Backup application state (files and databases) locally or to remote object storage, and optionally
take cloud-native volume snapshots:

```sh
# Local backup keeping the last 5
./libscript.sh cloud backup my-node --target local --keep-last 5

# S3 backup with cloud-native snapshot
./libscript.sh cloud backup my-node --target s3 --snapshot
```

### Global Cleanup

```sh

./libscript.sh cloud cleanup

./libscript.sh cloud cleanup Project=Postgres15
```

### Deprovisioning (with Retention)

You can tear down a node but optionally retain its IP address or Data volume so they can be
reattached to a new instance later:

```sh
# Retain IP address (detaches EIP/PIP/Static IP instead of deleting)
./libscript.sh cloud deprovision aws my-node my-vpc us-east-1 --retain-ip

# Retain data disk
./libscript.sh cloud deprovision azure my-node my-rg eastus --retain-data
```

## Example: Project-Specific Deployment

```sh

./libscript.sh cloud aws node-group create my-nodes 3 ami-ubuntu-lts my-vpc \
 --tags "Key=Project,Value=Alpha" \
 --bootstrap "libscript.sh install nginx"

./libscript.sh cloud list-managed Project=Alpha

./libscript.sh cloud cleanup Project=Alpha
```

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->

| Variable                                | Description                                                                                                                                                                                                                                                                                                             | Default                    | Aliases/Examples |
| --------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------------------------- | ---------------- |
| `LIBSCRIPT_DEFAULT_INSTALL_METHOD`      | Global override for how software should be installed ('libscript_native' prebuilt binary, 'from-source' compiled from source code, or 'system' via OS/selected package manager).                                                                                                                                        | `libscript_native`         |                  |
| `LIBSCRIPT_PKG_MGR`                     | Explicit package manager override for 'system' or package-manager-driven installations (e.g., 'apt-get', 'apk', 'dnf', 'yum', 'zypper', 'pacman', 'brew', 'port', 'pkg', 'xbps', 'emerge', 'winget', 'choco', 'scoop', 'nix', 'guix', 'spack', 'vcpkg', 'conan'). When set, overrides auto-detection in detect_pkg_mgr. | `none`                     |                  |
| `LIBSCRIPT_BUILD_TOOLCHAIN`             | Toolchain selector used when building components from source ('default' uses the platform default C/C++ compiler via _lib/languages/c, whereas 'gcc', 'clang', 'tcc', 'custom-cc', or an explicit binary path compiles the component with that specific toolchain).                                                     | `default`                  |                  |
| `LIBSCRIPT_CUSTOM_CC_BIN`               | Optional filesystem path to a custom C compiler binary when LIBSCRIPT_BUILD_TOOLCHAIN='custom-cc'.                                                                                                                                                                                                                      | `none`                     |                  |
| `LIBSCRIPT_BUILD_CFLAGS`                | Global extra CFLAGS passed to source builds across components.                                                                                                                                                                                                                                                          | `none`                     |                  |
| `LIBSCRIPT_BUILD_LDFLAGS`               | Global extra LDFLAGS passed to source builds across components.                                                                                                                                                                                                                                                         | `none`                     |                  |
| `LIBSCRIPT_WINDOWS_PKG_MGR`             | Global package manager override for Windows (winget, choco, scoop, vcpkg).                                                                                                                                                                                                                                              | `winget`                   |                  |
| `LIBSCRIPT_LOG_LEVEL`                   | Minimum logging level (0=DEBUG, 1=INFO, 2=SUCCESS, 3=WARN, 4=ERROR).                                                                                                                                                                                                                                                    | `1`                        |                  |
| `LIBSCRIPT_LOG_FORMAT`                  | Output format for logs (text, json).                                                                                                                                                                                                                                                                                    | `text`                     |                  |
| `LIBSCRIPT_LOG_FILE`                    | File to write logs to (in addition to standard output).                                                                                                                                                                                                                                                                 | `none`                     |                  |
| `LIBSCRIPT_SERVICE_NAME`                | Overrides the default service name.                                                                                                                                                                                                                                                                                     | `none`                     |                  |
| `DOWNLOAD_DIR`                          | Directory where downloads are stored.                                                                                                                                                                                                                                                                                   | `none`                     |                  |
| `FORMAT`                                | Output format (e.g., json, text).                                                                                                                                                                                                                                                                                       | `none`                     |                  |
| `LIBSCRIPT_CACHE_DIR`                   | Directory where cached files are stored.                                                                                                                                                                                                                                                                                | `none`                     |                  |
| `LIBSCRIPT_OFFLINE`                     | Flag (0 or 1) indicating whether offline mode is active, prohibiting outgoing network calls.                                                                                                                                                                                                                            | `0`                        |                  |
| `LIBSCRIPT_FORCE_OFFLINE`               | Strict offline flag (0 or 1) that immediately aborts execution if network calls are attempted.                                                                                                                                                                                                                          | `0`                        |                  |
| `LIBSCRIPT_DOWNLOAD_DIR`                | Staging directory for temporary download artifacts.                                                                                                                                                                                                                                                                     | `none`                     |                  |
| `LIBSCRIPT_LOG_DRIVER`                  | Logging driver to use (e.g., fluentd).                                                                                                                                                                                                                                                                                  | `none`                     |                  |
| `LOGS_DIR`                              | Directory where logs should be stored.                                                                                                                                                                                                                                                                                  | `none`                     |                  |
| `VAULT_TOKEN`                           | Token for HashiCorp Vault authentication.                                                                                                                                                                                                                                                                               | `none`                     |                  |
| `PREFIX`                                | Installation prefix.                                                                                                                                                                                                                                                                                                    | `none`                     |                  |
| `SERVE_FROM`                            | Base directory or context path for the service.                                                                                                                                                                                                                                                                         | `none`                     |                  |
| `LIBSCRIPT_LOG_HOST`                    | Host for remote logging.                                                                                                                                                                                                                                                                                                | `none`                     |                  |
| `LIBSCRIPT_VERSION`                     | Specifies the version of the package to use.                                                                                                                                                                                                                                                                            | `none`                     |                  |
| `LIBSCRIPT_LOG_PORT`                    | Port for remote logging.                                                                                                                                                                                                                                                                                                | `none`                     |                  |
| `TPU_ZONE`                              | GCP Zone for TPU provisioning                                                                                                                                                                                                                                                                                           | `us-central2-b`            |                  |
| `TPU_ACCELERATOR_TYPE`                  | Type of TPU accelerator (e.g. v4-8)                                                                                                                                                                                                                                                                                     | `v4-8`                     |                  |
| `TPU_VERSION`                           | TPU VM OS version                                                                                                                                                                                                                                                                                                       | `tpu-ubuntu2204-base`      |                  |
| `GCP_PROJECT_ID`                        | GCP Project ID                                                                                                                                                                                                                                                                                                          | `none`                     |                  |
| `XPK_CLUSTER_NAME`                      | Name for the XPK GKE cluster                                                                                                                                                                                                                                                                                            | `none`                     |                  |
| `TPU_TENSOR_PARALLEL_SIZE`              | Tensor parallel size for TPU serving                                                                                                                                                                                                                                                                                    | `1`                        |                  |
| `MODEL_NAME`                            | HuggingFace model string to serve                                                                                                                                                                                                                                                                                       | `your-org/your-model-name` |                  |
| `WORKLOAD_NAME`                         | Name of the XPK workload                                                                                                                                                                                                                                                                                                | `none`                     |                  |
| `JETSTREAM_IMAGE`                       | Docker image for JetStream TPU inference                                                                                                                                                                                                                                                                                | `none`                     |                  |
| `LIBSCRIPT_HOME`                        | Base installation prefix where LibScript installs isolated component versions.                                                                                                                                                                                                                                          | `none`                     |                  |
| `LIBSCRIPT_DATA_DIR`                    | Base data directory for runtime component state, databases, and service configurations.                                                                                                                                                                                                                                 | `none`                     |                  |
| `LIBSCRIPT_BUILD_DIR`                   | Scratch build directory used when compiling components from source.                                                                                                                                                                                                                                                     | `none`                     |                  |
| `LIBSCRIPT_TARGET_SYSROOT`              | Optional target root filesystem path when provisioning chroots or OS images.                                                                                                                                                                                                                                            | `none`                     |                  |
| `LIBSCRIPT_SKIP_SYSTEM_DEPS`            | Flag (0 or 1) to skip OS-level system dependency installation during setup.                                                                                                                                                                                                                                             | `none`                     |                  |
| `LIBSCRIPT_DRY_RUN_PKG_MGR`             | Flag (0 or 1) to simulate package manager operations without mutating the system.                                                                                                                                                                                                                                       | `none`                     |                  |
| `LIBSCRIPT_ARIA2_EXPORT_FILE`           | File path to export aria2-compatible download URLs instead of downloading immediately.                                                                                                                                                                                                                                  | `none`                     |                  |
| `LIBSCRIPT_NEVER_REFRESH_CHECKSUM_DB`   | Flag (0 or 1) to prevent auto-fetching remote SHA-256 checksums when missing from checksums.txt.                                                                                                                                                                                                                        | `none`                     |                  |
| `LIBSCRIPT_DISABLE_CHECKSUM_TXT_UPDATE` | Flag (0 or 1) to prevent appending newly discovered SHA-256 hashes to _lib/checksums.txt.                                                                                                                                                                                                                               | `none`                     |                  |
| `LIBSCRIPT_LISTEN_PORT`                 | Global fallback TCP port for network-listening components.                                                                                                                                                                                                                                                              | `none`                     |                  |
| `LIBSCRIPT_LISTEN_ADDRESS`              | Global fallback bind address for network-listening components.                                                                                                                                                                                                                                                          | `none`                     |                  |
| `LIBSCRIPT_LISTEN_SOCKET`               | Global fallback UNIX domain socket path for listening components.                                                                                                                                                                                                                                                       | `none`                     |                  |
| `LIBSCRIPT_SERVICE_RUN_AS_USER`         | System user account under which daemonized services should execute.                                                                                                                                                                                                                                                     | `none`                     |                  |
| `LIBSCRIPT_GLOBAL_INSTALL_METHOD`       | Global installation strategy override applied across all components.                                                                                                                                                                                                                                                    | `none`                     |                  |
| `FORCE_REINSTALL`                       | Flag (0 or 1) to force re-downloading and reinstalling a component even if already present.                                                                                                                                                                                                                             | `none`                     |                  |
| `FORCE_REBUILD`                         | Flag (0 or 1) to force rebuilding a component or service unit from scratch.                                                                                                                                                                                                                                             | `none`                     |                  |
| `LIBSCRIPT_ALLOW_ANY_TAG_MANIPULATION`  | Flag (0 or 1) allowing cloud provider teardown operations to modify resources without matching tag filters.                                                                                                                                                                                                             | `none`                     |                  |
| `LIBSCRIPT_AZURE_RESOURCE_GROUP`        | Default Azure Resource Group name for cloud provisioning operations.                                                                                                                                                                                                                                                    | `none`                     |                  |
| `LIBSCRIPT_DASHBOARD_DIR`               | Directory path for generated monitoring and observability dashboards.                                                                                                                                                                                                                                                   | `none`                     |                  |
| `LIBSCRIPT_DEBUG`                       | Flag (0 or 1) enabling verbose debug tracing across LibScript lifecycle actions.                                                                                                                                                                                                                                        | `none`                     |                  |
| `LIBSCRIPT_FORCE_FETCH`                 | Flag (0 or 1) forcing remote artifact re-fetching even when present in local cache.                                                                                                                                                                                                                                     | `none`                     |                  |
| `LIBSCRIPT_HOST_ROOT`                   | Host root directory mount point when executing inside a container or chroot.                                                                                                                                                                                                                                            | `none`                     |                  |
| `LIBSCRIPT_HW_CORES`                    | Detected or overridden CPU core count for auto-tuning services and parallel builds.                                                                                                                                                                                                                                     | `none`                     |                  |
| `LIBSCRIPT_HW_MEM_MB`                   | Detected or overridden system memory in MiB for auto-tuning service buffer pools.                                                                                                                                                                                                                                       | `none`                     |                  |
| `LIBSCRIPT_HW_NVME`                     | Detected or overridden NVMe storage presence flag for I/O scheduler and database tuning.                                                                                                                                                                                                                                | `none`                     |                  |
| `LIBSCRIPT_HW_SIMD`                     | Detected or overridden CPU SIMD instruction set capabilities (e.g., avx2, avx512, neon).                                                                                                                                                                                                                                | `none`                     |                  |
| `LIBSCRIPT_PROFILE`                     | Active configuration profile name (e.g., dev, prod, minimal, hpc).                                                                                                                                                                                                                                                      | `none`                     |                  |
| `LIBSCRIPT_RESOLVED_CC_BIN`             | Resolved path to the active C compiler binary for source builds.                                                                                                                                                                                                                                                        | `none`                     |                  |
| `LIBSCRIPT_RESOLVED_CC_ID`              | Resolved compiler identifier (gcc, clang, tcc, msvc) for source builds.                                                                                                                                                                                                                                                 | `none`                     |                  |
| `LIBSCRIPT_RESOLVED_CC_VERSION`         | Resolved version string of the active C compiler.                                                                                                                                                                                                                                                                       | `none`                     |                  |
| `LIBSCRIPT_SOURCE_WORKDIR`              | Working directory used for extracting and compiling source tarballs.                                                                                                                                                                                                                                                    | `none`                     |                  |
| `LIBSCRIPT_TAG_ENABLE`                  | Flag (0 or 1) enabling resource tagging on cloud provider assets.                                                                                                                                                                                                                                                       | `none`                     |                  |
| `LIBSCRIPT_TAG_KEY`                     | Tag key applied to provisioned cloud provider resources.                                                                                                                                                                                                                                                                | `none`                     |                  |
| `LIBSCRIPT_TAG_VALUE`                   | Tag value applied to provisioned cloud provider resources.                                                                                                                                                                                                                                                              | `none`                     |                  |
| `LIBSCRIPT_TARGET_ARCH`                 | Target CPU architecture when cross-compiling or building OS images.                                                                                                                                                                                                                                                     | `none`                     |                  |
| `LIBSCRIPT_TARGET_LIBC`                 | Target C standard library implementation (glibc, musl, uclibc, msvcrt).                                                                                                                                                                                                                                                 | `none`                     |                  |
| `LIBSCRIPT_TARGET_OS`                   | Target operating system identifier when provisioning or cross-compiling.                                                                                                                                                                                                                                                | `none`                     |                  |
| `LIBSCRIPT_TARGET_ROOTFS`               | Filesystem path to the target rootfs directory for image synthesis.                                                                                                                                                                                                                                                     | `none`                     |                  |
| `LIBSCRIPT_VOLUME_NAME`                 | Logical storage volume name for persistent data mounts.                                                                                                                                                                                                                                                                 | `none`                     |                  |
| `LIBSCRIPT_DEFAULT_CLOUD`               | Default cloud provider to use                                                                                                                                                                                                                                                                                           | `aws`                      |                  |
| `CORE_AWS_ACCESS_KEY_ID`                | AWS Access Key ID                                                                                                                                                                                                                                                                                                       | `none`                     |                  |
| `CORE_AWS_SECRET_ACCESS_KEY`            | AWS Secret Access Key                                                                                                                                                                                                                                                                                                   | `none`                     |                  |
| `CORE_AZURE_SUBSCRIPTION_ID`            | Azure Subscription ID                                                                                                                                                                                                                                                                                                   | `none`                     |                  |
| `CORE_GCP_PROJECT_ID`                   | GCP Project ID                                                                                                                                                                                                                                                                                                          | `none`                     |                  |
| `CORE_RETAIN_IP`                        | Flag: --retain-ip. Preserve the Public IP when deprovisioning a node.                                                                                                                                                                                                                                                   | `none`                     |                  |
| `CORE_RETAIN_DATA`                      | Flag: --retain-data. Preserve the data volumes when deprovisioning a node.                                                                                                                                                                                                                                              | `none`                     |                  |
| `CORE_KEEP_LAST`                        | Flag: --keep-last <N>. Number of backups to retain per node.                                                                                                                                                                                                                                                            | `none`                     |                  |
| `CORE_FROM_BACKUP`                      | Flag: --from-backup <ID>. The ID of the backup or snapshot to restore from.                                                                                                                                                                                                                                             | `none`                     |                  |
| `CORE_DOWNLOAD_URL`                     | Override URL for downloading core binary or archive artifacts.                                                                                                                                                                                                                                                          | `none`                     |                  |
| `CORE_INSTALL_METHOD`                   | Installation method for core (libscript_native, system, or from-source).                                                                                                                                                                                                                                                | `none`                     |                  |
| `CORE_RELEASES_URL`                     | Override URL for querying core available remote releases.                                                                                                                                                                                                                                                               | `none`                     |                  |
| `CORE_VERSION`                          | Specific version of core to install (e.g., latest, lts, or exact version).                                                                                                                                                                                                                                              | `none`                     |                  |

<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
