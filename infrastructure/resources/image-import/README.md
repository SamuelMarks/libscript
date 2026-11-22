# Cloud Image Import (`infrastructure/resources/image-import`)

Idempotently uploads synthesized UEFI/GPT OS and unikernel disk images to cloud object storage and
registers cloud VM images across AWS EC2, Microsoft Azure Compute Gallery, and Google Cloud Compute
Engine.

## Usage

```sh
./libscript.sh image-import aws --disk=disk.raw --bucket=my-bucket --name=openedx-lms-22-1-0 [--dry-run]
./libscript.sh image-import azure --disk=disk.vhd --account=mystorage --gallery=my_sig --name=openedx-lms [--dry-run]
./libscript.sh image-import gcp --disk=disk.raw.tar.gz --bucket=my-gcs --project=my-proj --name=openedx-lms [--dry-run]
```

## Configuration

| Variable               | Default  | Description                                                             |
| ---------------------- | -------- | ----------------------------------------------------------------------- |
| `IMAGE_IMPORT_DRY_RUN` | `0`      | Emit cloud registration receipts without mutating cloud accounts.       |
| `IMAGE_IMPORT_ARCH`    | `x86_64` | Architecture registered on imported cloud images (`x86_64` or `arm64`). |

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->

| Variable               | Description                                                                       | Default  | Aliases/Examples |
| ---------------------- | --------------------------------------------------------------------------------- | -------- | ---------------- |
| `IMAGE_IMPORT_DRY_RUN` | Flag (0 or 1) emitting cloud import descriptors without invoking live cloud APIs. | `0`      |                  |
| `IMAGE_IMPORT_ARCH`    | Target CPU architecture registered on the imported cloud VM image.                | `x86_64` |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
