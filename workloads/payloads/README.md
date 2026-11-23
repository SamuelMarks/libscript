# Tier 5 (`T5`) Declarative Workload Payloads (`workloads/payloads/`)

## Overview

`workloads/payloads/` contains scheduler-agnostic `payload.json` workload definitions conforming to
`workloads/schemas/payload.schema.json`. Any payload manifest can be compiled or submitted to
Kubernetes (`kubernetes`), Google Cloud XPK (`xpk`), Nomad (`nomad`), Apache Mesos/Marathon
(`mesos`), Slurm/Ray (`slurm_ray`), Cloud TPU VMs (`tpu_vm`), Firecracker/Cloud-Hypervisor MicroVMs
(`microvm`), RTOS hardware/emulators (`rtos_firmware`), or 8+ native OS init systems (`native`).

## Payload Catalog

### AI & Accelerator Payloads (`ai/`)

- [`ai/vllm/`](./ai/vllm/README.md): High-throughput `vLLM` OpenAI-compatible LLM inference server.
- [`ai/jetstream/`](./ai/jetstream/README.md): Google Cloud TPU `JetStream` PagedAttention serving.
- [`ai/ollama/`](./ai/ollama/README.md): Local/edge quantized LLM inference service.
- [`ai/gcp-gpu-vm/`](./ai/gcp-gpu-vm/README.md): CUDA-accelerated GPU VM training & serving payload.
- [`ai/gcp-tpu-vm/`](./ai/gcp-tpu-vm/README.md): Direct Cloud TPU VM lockstep training &
  TensorBoard.
- [`ai/gke-xpk-training/`](./ai/gke-xpk-training/README.md): Multi-slice GKE XPK (`JobSet` +
  `Kueue`) gang-scheduled TPU training job.
- [`ai/gke-xpk-inference/`](./ai/gke-xpk-inference/README.md): Auto-scaled GKE XPK TPU/GPU serving.
- [`ai/jax-tpu-multi-slice-training/`](./ai/jax-tpu-multi-slice-training/README.md): Distributed JAX
  `pjit` / Pathways multi-slice TPU pod training job.

### Web & Platform Payloads (`web/`)

- [`web/openedx/`](./web/openedx/README.md): Multi-replica Open edX LMS/CMS web application payload.

## Usage

```sh
./libscript.sh payload compile workloads/payloads/ai/vllm/payload.json --scheduler kubernetes
./libscript.sh payload submit workloads/payloads/ai/gke-xpk-training/payload.json --scheduler xpk
./libscript.sh payload status vllm-serving --scheduler native
```
