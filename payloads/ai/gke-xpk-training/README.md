# GKE XPK Multi-Slice Training Payload (`gke-xpk-training`)

Tier 4 payload for provisioning and submitting multi-slice distributed machine learning training
workloads (`JAX`, `MaxText`, `PyTorch/XLA FSDP`, `Keras`) onto Google Kubernetes Engine (GKE) TPU
clusters via `xpk`.

## Usage

```sh
./payloads/ai/gke-xpk-training/setup.sh
./payloads/ai/gke-xpk-training/deploy.sh
  --docker-image "gcr.io/my-project/maxtext:latest"
  --command "python3 MaxText/train.py MaxText/configs/base.yml"
  --tpu-type "v5litepod-16"
  --num-slices 2
  --spot
```

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->

| Variable               | Description                                                                  | Default           | Aliases/Examples |
| ---------------------- | ---------------------------------------------------------------------------- | ----------------- | ---------------- |
| `XPK_CLUSTER_NAME`     | Name of the target GKE XPK cluster.                                          | `ml-xpk-cluster`  |                  |
| `WORKLOAD_NAME`        | Unique identifier for the XPK training workload.                             | `ml-training-job` |                  |
| `TRAIN_SCRIPT`         | Training entrypoint command executed inside the container across TPU slices. | `python train.py` |                  |
| `DOCKER_IMAGE`         | Container image containing the JAX/MaxText/PyTorch training environment.     | `none`            |                  |
| `TPU_ACCELERATOR_TYPE` | TPU accelerator topology (e.g. v4-8, v5litepod-16, v5p-8).                   | `v4-8`            |                  |
| `TPU_SLICE_COUNT`      | Number of TPU slices for multi-slice data-parallel / FSDP training.          | `1`               |                  |
| `TPU_SCHEDULING_TYPE`  | Provisioning scheduling mode ('spot' for TFRC/preemptible or 'on-demand').   | `none`            |                  |
| `GCP_PROJECT_ID`       | Google Cloud Project ID hosting the GKE XPK cluster.                         | `none`            |                  |
| `GCP_ZONE`             | Google Cloud compute zone where the TPU nodes reside.                        | `none`            |                  |
| `HF_TOKEN`             | Optional Hugging Face authentication token injected into the workload.       | `none`            |                  |

<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
