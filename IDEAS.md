# Experimental Ideas

This document tracks experimental research directions and potential use-cases for LibScript's
architecture beyond what has already graduated into core tiers.

## Bare-Metal Accelerator Driver & Runtime Auto-Tuning (Partially Implemented)

Google Cloud TPU/GPU VM lifecycles (`payloads/ai/gcp-tpu-vm/`, `gcp-gpu-vm/`), GKE XPK & TPU VM
scheduling (`payloads/ai/gke-xpk-*`, `payloads/schedulers/tpu_vm.{sh,cmd}`), multi-worker lockstep
training (`_lib/ml-training/tpu-trainer/`), 4-role GCS ML storage
(`traits/storage/gcs_ml.{sh,cmd}`), and local/cluster AI serving recipes
(`_lib/ai-serving/inference-router/`, `_lib/app-servers/vllm/`, `_lib/app-servers/ollama/`,
`_lib/app-servers/jetstream/`) have graduated into core. Active research focuses on zero-reboot
bare-metal kernel driver staging (NVIDIA open kernel modules, AMD ROCm, and VFIO IOMMU passthrough)
with automatic CPU socket and PCIe topology pinning.

## Transactional A/B Immutable OS Updates (Partially Implemented)

Tier 2 natively synthesizes signed Unified Kernel Images (UKI), immutable SquashFS + OverlayFS
hybrid live ISOs, and Firecracker/Unikraft/OSv unikernels. Ongoing experimentation explores
transactional A/B root partition switching, `ostree`-style content-addressed sysroot deltas, and
automatic bootloader fallback on failed `hooks/probe readiness` boot checks.

## Reactive Metric-Driven Native Autoscaling

`topologies/engine.{sh,cmd} scale` and `traits/ingress/` (`netctl`) already support declarative
worker pool scaling and dynamic load-balancer registration. The next experimental step is a
lightweight, zero-daemon closed-loop controller that consumes `traits/metrics/` endpoints to
autonomously provision or drain cloud VMs in response to latency, queue-depth, or GPU utilization
thresholds—bringing Kubernetes HPA semantics to raw VMs and native init supervisors.

## Resource-Constrained Edge & Embedded Footprints (Graduated RTOS Core + Active Mesh Research)

Zephyr RTOS (`_lib/kernel/zephyr/`), FreeRTOS (`_lib/kernel/freertos/`), MCUboot cryptographic A/B
slot signing (`_lib/bootloaders/mcuboot/`), UF2/HEX firmware packaging, and WebAssembly Micro
Runtime (`_lib/runtimes/wamr/`) have graduated into core Tier 1 and Tier 2 synthesis. Ongoing
research explores peer-to-peer LAN/LoRa artifact caching so air-gapped edge fleets can synchronize
`_lib/` updates over `traits/mesh/` without central registries.
