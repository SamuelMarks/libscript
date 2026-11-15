# ollama Component

## Overview

Libscript manages ollama versions natively by installing them into isolated directories under
\`LIBSCRIPT_HOME/ollama/<version>\`.

## Configuration

| Variable                | Description                                                                                                                                                            | Default            | Required |
| ----------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------ | -------- |
| `OLLAMA_INSTALL_METHOD` | How to install OLLAMA. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, 'mise', 'asdf', 'pkgx', or 'vfox' defers to third-party tools. | `libscript_native` |          |

## Version Management

As outlined in the core philosophy, `libscript` manages the versions natively. Installations are
isolated by default in `~/.libscript/<component>/<version>` and do not pollute global system paths.

## Configuration Options

<!-- BEGIN_VARS -->

| Variable                   | Description                                                                                                                                                                                    | Default                   | Aliases/Examples |
| -------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------- | ---------------- |
| `OLLAMA_INSTALL_METHOD`    | How to install OLLAMA. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, 'mise', 'asdf', 'pkgx', or 'vfox' defers to third-party tools.                         | `libscript_native`        |                  |
| `OLLAMA_MODELS`            | Directory path where Ollama stores downloaded model weights and manifests.                                                                                                                     | `/mnt/data/ollama_models` |                  |
| `OLLAMA_DOWNLOAD_URL`      | Override URL for downloading ollama binary or archive artifacts.                                                                                                                               | `none`                    |                  |
| `OLLAMA_RELEASES_URL`      | Override URL for querying ollama available remote releases.                                                                                                                                    | `none`                    |                  |
| `OLLAMA_VERSION`           | Specific version of ollama to install (e.g., latest, lts, or exact version).                                                                                                                   | `none`                    |                  |
| `OLLAMA_MODELS_DIR`        | Unambiguous filesystem directory path for Ollama daemon model storage, avoiding collision with application-level OLLAMA_MODELS.                                                                | `none`                    |                  |
| `OLLAMA_DEFAULT_MODEL`     | Default Ollama model tag to pull and verify when no explicit model list is provided.                                                                                                           | `none`                    |                  |
| `OLLAMA_HOST`              | Host and port URL where the Ollama HTTP API listens (default: http://127.0.0.1:11434).                                                                                                         | `none`                    |                  |
| `OLLAMA_MODEL_LIST`        | Comma- or space-separated list of Ollama model tags to ensure are pulled and registered.                                                                                                       | `none`                    |                  |
| `OLLAMA_READY_TIMEOUT`     | Maximum time in seconds to poll the Ollama HTTP API for readiness after service start or restart.                                                                                              | `none`                    |                  |
| `OLLAMA_NUM_PARALLEL`      | Maximum number of parallel requests each loaded Ollama model processes simultaneously (default: 1).                                                                                            | `none`                    |                  |
| `OLLAMA_MAX_LOADED_MODELS` | Maximum number of Ollama models kept loaded concurrently in memory (default: 1).                                                                                                               | `none`                    |                  |
| `OLLAMA_LLM_LIBRARY`       | GGML CPU/GPU backend library override for Ollama llama-server (e.g. 'cpu_avx2' on GPU-less VMs to prevent AVX-512/AMX segmentation faults).                                                    | `none`                    |                  |
| `OLLAMA_NUM_GPU`           | Number of model layers to offload to GPU (set to '0' on CPU-only nodes to disable headless GPU probing).                                                                                       | `none`                    |                  |
| `OLLAMA_FLASH_ATTENTION`   | Whether to enable experimental flash attention kernels in Ollama ('0' disables CPU flash attention to prevent crashes).                                                                        | `none`                    |                  |
| `OLLAMA_KV_CACHE_TYPE`     | Data type for Ollama KV cache memory allocation (default: 'f16').                                                                                                                              | `none`                    |                  |
| `OLLAMA_CONTEXT_LENGTH`    | Default context window length in tokens allocated by Ollama llama-server (default: '2048').                                                                                                    | `none`                    |                  |
| `OLLAMA_MAX_QUEUE`         | Maximum number of queued generation requests in the Ollama server (default: '16').                                                                                                             | `none`                    |                  |
| `OLLAMA_KEEP_ALIVE`        | Duration models remain loaded in memory after an inference request (default: '10m').                                                                                                           | `none`                    |                  |
| `GGML_BACKEND_AMX`         | Controls Intel AMX backend buffer allocation in GGML/llama-server (set to '0' to prevent ggml_backend_amx_buffer_type_alloc_buffer segmentation faults on Intel Sapphire/Emerald Rapids CPUs). | `none`                    |                  |
| `OLLAMA_VERIFY_INFERENCE`  | When set to '1', runs a 1-token /api/generate smoke test on pulled models and re-pulls if llama-server crashes.                                                                                | `none`                    |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `_lib/_common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
