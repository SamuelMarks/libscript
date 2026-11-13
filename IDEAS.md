# Experimental Ideas

This document tracks experimental research directions and potential use-cases for LibScript's
architecture beyond what has already graduated into core tiers.

## Bare-Metal Accelerator Driver & Runtime Auto-Tuning (Partially Implemented)

Google Cloud TPU/GPU VM lifecycles (`payloads/ai/gcp-tpu-vm/`, `gcp-gpu-vm/`), GKE XPK training and
inference (`payloads/ai/gke-xpk-*`), and local/cluster AI serving recipes (`_lib/app-servers/vllm/`,
`_lib/app-servers/ollama/`, `_lib/ai-serving/jetstream/`) have graduated into core. Active research
focuses on zero-reboot bare-metal kernel driver staging (NVIDIA open kernel modules, AMD ROCm, and
VFIO IOMMU passthrough) with automatic CPU socket and PCIe topology pinning.

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

## Resource-Constrained Edge & Embedded Footprints

Because LibScript operates in pure POSIX `/bin/sh` without heavy interpreter runtimes (Python, Ruby,
or Node.js), we are investigating ultra-minimal BusyBox/Toybox edge profiles (< 16 MB RAM) and
peer-to-peer LAN artifact caching so air-gapped edge fleets can synchronize `_lib/` updates over
`traits/mesh/` without central registries.
