# tpu-vm-vllm Component

## Overview

This component manages the installation and execution of `tpu-vm-vllm` within the libscript
ecosystem.

## Usage

Refer to the component's setup and cli scripts for specific operations.

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->

| Variable               | Description                                               | Default     | Aliases/Examples |
| ---------------------- | --------------------------------------------------------- | ----------- | ---------------- |
| `TPU_NAME`             | Name of the TPU VM instance serving the model             | `ml-tpu-vm` |                  |
| `GCP_PROJECT_ID`       | Google Cloud Project ID where the TPU VM is provisioned   | ``          |                  |
| `TPU_ZONE`             | Google Cloud Zone for the TPU VM (e.g. us-central2-b)     | ``          |                  |
| `TPU_ACCELERATOR_TYPE` | TPU accelerator version and topology (e.g. v4-8)          | `v4-8`      |                  |
| `MODEL_NAME`           | Hugging Face or GCS model identifier served by vLLM       | ``          |                  |
| `PORT`                 | HTTP port on which vLLM exposes its OpenAI-compatible API | `8000`      |                  |

<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
