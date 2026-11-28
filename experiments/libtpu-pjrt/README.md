<!-- cspell:words PLDI torchxla torchtpu shardmap swiglu -->

# Empirical Experiment Suite: `libtpu-pjrt` (`experiments/libtpu-pjrt`)

Clean-room Rust PJRT TPU driver, compiler, and runtime evaluation suite (`PLDI-2027-v1`, substrate
`tpu-slice`) benchmarking **`libtpu-rs`** (`https://github.com/SamuelMarks/libtpu-rs`) against
Google's closed-source **`libtpu.so`** across sub-suites **`E0` through `E9`** under **SIGPLAN
`RULE-1`–`RULE-7`** statistical and provenance controls.

The campaign audits wheel/binary provenance and unsafe TCB surface (`E0`), PJRT C ABI layout and
symbol/CFG forensics (`E1`), ELF/Mach-O section footprint, C11 cold/warm client initialization, RSS,
and multi-pod scaling (`E2`), unmodified upstream `jax` single-chip & SPMD drop-in execution (`E3`),
5-stage StableHLO/VHLO AOT compilation latency (`E4`), 2D VMEM buffer packing and register-spill
sweeps (`E5`), VLIW modulo software pipelining and pass ablations (`E6`), 29-dtype microscaling
numerics, stochastic rounding, and 18-optimizer SparseCore throughput (`E7`), **head-to-head Cloud
TPU VM multi-framework comparison (`E9`: JAX, Keras 3 -> JAX, PyTorch/`torch_xla` TorchTPU, and
TensorFlow `tensorflow-tpu`/PJRT)**, and mechanical LaTeX macro emission (`E8`).

---

## Cloud TPU VM 4-Framework Head-to-Head (`E9`)

Suite `E9` (`suites/e9_framework_matrix.{sh,cmd}`) provisions dedicated immutable twin virtualenvs
in `/dev/shm/libscript-tpu/venvs/<framework>-{og,rs}` via `workloads/ai/_common/tpu_matrix.{sh,cmd}`
and cryptographically verifies via `/proc/self/maps` that every framework process mapped the exact
target `libtpu.so` (`LIBTPU_REFERENCE_SO` vs. `LIBTPU_RS_SO`) before timing:

1. **`jax`** (`JAX_PLATFORMS=tpu`): `4096x4096` `bfloat16` GEMM, SwiGLU MLP + AdamW step, and
   multi-chip `shard_map` `pmean` SPMD collective.
2. **`keras_jax`** (`KERAS_BACKEND=jax`, `keras>=3`): `MultiHeadAttention` + SwiGLU Transformer
   `predict_on_batch` inference and `train_on_batch` (`bfloat16` mixed precision + AdamW).
3. **`pytorch_tpu`** (`torch_xla[tpu]` / TorchTPU, `PJRT_DEVICE=TPU`): `4096x4096` `bfloat16`
   `torch.matmul`, lazy `xm.mark_step()` Transformer training, and
   `torch.compile(backend="openxla")`.
4. **`tensorflow_tpu`** (`tensorflow-tpu` / PJRT C-API): `TPUClusterResolver('local')` +
   `TPUStrategy` `4096x4096` `bfloat16` `tf.linalg.matmul` and `GradientTape` training step.

```sh
# 1. Provision TFRC-guarded Cloud TPU VM slice and bootstrap libtpu + libtpu-rs
./libscript.sh experiment provision libtpu-pjrt --tfrc-config=./tfrc.json

# 2. Run E0, E1, E2, E9 (4-framework og vs rs), and E8 LaTeX synthesis
TPU_NAME=libtpu-pjrt-node ./experiments/libtpu-pjrt/run.sh \
  --tfrc-config=./tfrc.json \
  --subsuites=E0,E1,E2,E9,E8 \
  --warmup=5 \
  --trials=50 \
  --results-dir=./build/libtpu_vs_og_results

# 3. Collect artifacts and tear down Cloud TPU VM (post-flight zero-resource check)
./libscript.sh experiment collect libtpu-pjrt --results-dir=./build/libtpu_vs_og_results
./libscript.sh experiment teardown libtpu-pjrt --tfrc-config=./tfrc.json
```

```cmd
:: Windows Batch orchestrator equivalent
.\libscript.cmd experiment provision libtpu-pjrt --tfrc-config=.\tfrc.json
set TPU_NAME=libtpu-pjrt-node
.\experiments\libtpu-pjrt\run.cmd --tfrc-config=.\tfrc.json --subsuites=E0,E1,E2,E9,E8 --warmup=5 --trials=50 --results-dir=.\build\libtpu_vs_og_results
.\libscript.cmd experiment collect libtpu-pjrt --results-dir=.\build\libtpu_vs_og_results
.\libscript.cmd experiment teardown libtpu-pjrt --tfrc-config=.\tfrc.json
```

---

## Generated Artifact Summary (`E0`–`E9`)

- `e0_env_<arch>.json`, `e0_tcb.json`, `e0_wheel_provenance.json`
- `e1_abi_parity.json`, `e1_carver.json`, `e1_disasm.json`
- `e2_footprint_<arch>.json`, `e2_startup_<arch>.json`, `e2_pod_scaling_<arch>.json`
- `e3_jax_single.json`, `e3_jax_spmd.json`
- `e4_stages_<arch>.json`, `e4_vs_google_linux_x64.json`
- `e5_vmem_pack.json`, `e5_reg_spill.json`
- `e6_modulo_speedup.json`, `e6_pass_ablations.json`
- `e7_numerics.json`, `e7_sparsecore.json`
- `e9_jax_vs_og.json`, `e9_keras_jax_vs_og.json`, `e9_pytorch_tpu_vs_og.json`,
  `e9_tensorflow_tpu_vs_og.json`, `e9_framework_comparison.{json,csv,md}`
- `generated_metrics.tex`, `campaign_summary.json`
