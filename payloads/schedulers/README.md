# Tier 4 Universal Workload Schedulers (`payloads/schedulers/`)

## Overview

The `payloads/schedulers/` subsystem provides deterministic translation drivers that compile a
single declarative `payload.json` manifest into native artifacts for container orchestrators, all 8+
native OS init supervisors, MicroVMs/Unikernels, and AI/HPC gang schedulers.

## Standard Scheduler Contract

Every scheduler driver (`<scheduler>.sh` and `<scheduler>.cmd`) implements six canonical verbs:

1. `compile <payload.json>`: Emits the target scheduler's native configuration or manifest to stdout
   or a staging directory without mutating live cluster state.
2. `submit <payload.json>`: Compiles and idempotently applies or schedules the workload onto the
   target execution substrate.
3. `status <workload-id>`: Queries live allocation, pod, supervisor, or job health.
4. `logs <workload-id>`: Streams or tails execution logs for the workload.
5. `stop <workload-id>`: Gracefully stops active workload instances.
6. `destroy <workload-id>`: Idempotently removes the workload registration and ephemeral state.

## Supported Scheduler Drivers

- **`kubernetes.{sh,cmd}`**: Translates `payload.json` into Kubernetes `Deployment`, `StatefulSet`,
  `Job`, `Service`, `PersistentVolumeClaim`, and `Ingress` YAML manifests applied via `kubectl`.
- **`nomad.{sh,cmd}`**: Emits HashiCorp Nomad JSON job specifications (`service`, `batch`).
- **`mesos.{sh,cmd}`**: Emits Apache Mesos / Marathon Application and Pod JSON definitions.
- **`native.{sh,cmd}`**: Delegates to `_lib/_common/service_install.{sh,cmd}` and
  `_lib/init-systems/` to target `systemd`, `openrc`, `runit`, `s6`, `dinit`, `sysvinit`, FreeBSD
  `bsd-rc`, illumos `smf`, macOS `launchd`, and Windows `sc.exe`, supporting both live runtime and
  Tier 2 offline sysroot image baking (`LIBSCRIPT_TARGET_SYSROOT`).
- **`microvm.{sh,cmd}`**: Targets Firecracker, Cloud-Hypervisor, and Solo5 unikernel tenders.
- **`xpk.{sh,cmd}`**: Schedules multi-slice TPU gang workloads via Google Cloud `xpk`.
- **`slurm_ray.{sh,cmd}`**: Compiles HPC and distributed AI workloads into Slurm `sbatch` scripts or
  Ray job submissions.
