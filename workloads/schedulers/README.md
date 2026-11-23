# Tier 5 (`T5`) Universal Workload Schedulers (`workloads/schedulers/`)

## Overview

`workloads/schedulers/` provides deterministic translation and execution drivers that compile a
single declarative `payload.json` manifest (`workloads/schemas/payload.schema.json`) into native
orchestrator specs across nine execution backends—spanning cloud-native clusters, HPC/AI batch
gang-schedulers, hardware-isolated microVMs, RTOS microcontrollers, and 8+ host init supervisors.

## Scheduler Drivers

- **`kubernetes.{sh,cmd}`**: Emits and applies Kubernetes `Deployment`, `StatefulSet`, `Job`,
  `Service`, and GPU/TPU resource manifests via `kubectl`.
- **`xpk.{sh,cmd}`**: Compiles multi-slice AI training and serving payloads into Google Cloud XPK
  (`JobSet` + `Kueue`) gang-scheduled workloads on `T4` `gke-tpu-cluster` substrates.
- **`tpu_vm.{sh,cmd}`**: Executes lockstep multi-worker training and inference directly across `T4`
  Google Cloud TPU VM slices (`infrastructure/providers/gcp-tpu-vm/`).
- **`slurm_ray.{sh,cmd}`**: Emits Slurm `sbatch` scripts and Ray distributed job submissions for HPC
  and GPU/CPU clusters.
- **`nomad.{sh,cmd}`**: Generates HashiCorp Nomad HCL/JSON job specs (`service`, `batch`, `system`).
- **`mesos.{sh,cmd}`**: Emits Marathon application/pod JSON definitions targeting Apache Mesos
  clusters (`infrastructure/clusters/mesos-marathon-ha/`).
- **`microvm.{sh,cmd}`**: Boots payloads inside hardware-isolated Firecracker, Cloud-Hypervisor, or
  QEMU/Solo5 unikernel and microVM instances using `T3` synthesized images.
- **`rtos_firmware.{sh,cmd}`**: Launches MCUboot-signed Zephyr RTOS and FreeRTOS firmware payloads
  in headless QEMU, Renode (`.resc`) multi-node simulations, or physical SWD/JTAG targets via
  `openocd`.
- **`native.{sh,cmd}`**: Translates payloads directly into native OS init units (`systemd`,
  `openrc`, `runit`, `s6`, `dinit`, `bsd-rc`, `launchd`, `smf`, Windows Services) in both `T3`
  offline sysroot bake mode and `T5` live host mode.

## Usage

```sh
./libscript.sh payload compile workloads/payloads/ai/vllm/payload.json --scheduler kubernetes
./libscript.sh payload submit workloads/payloads/ai/vllm/payload.json --scheduler native
./libscript.sh payload status vllm-serving --scheduler native
./libscript.sh payload logs vllm-serving --scheduler native
./libscript.sh payload stop vllm-serving --scheduler native
```
