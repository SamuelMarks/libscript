<!-- cspell:words betwixt duckdb gemmaFourSql maxtext peft prefill subsuites tfrc torchxla venvs virtualenvs -->

# Empirical Experiment Suite: `gemma-4-sql-libtpu` (`experiments/gemma-4-sql-libtpu`)

Standalone Cloud TPU VM head-to-head evaluation running
**[`SamuelMarks/gemma-4-sql`](https://github.com/SamuelMarks/gemma-4-sql)** across all **7 Gemma 4
TPU backends** (`hf_transformers`, `pytorch_native`, `keras_jax`, `keras_tensorflow`,
`keras_pytorch`, `maxtext`, `jax_native`) comparing upstream Google **`libtpu`** (`og`) against
clean-room Rust **[`SamuelMarks/libtpu-rs`](https://github.com/SamuelMarks/libtpu-rs)** (`rs`).

---

## Twin-Virtualenv Isolation & `/proc/self/maps` Attestation

Rather than mutating a single virtualenv in-place (`pip uninstall libtpu`), `gemma-4-sql-libtpu`
delegates virtualenv construction to `workloads/ai/_common/tpu_matrix.{sh,cmd}` with explicit
`TPU_LIBTPU_PROVIDER=og|rs`:

- **`-og` pass (`results/og/`)**: Builds `/dev/shm/libscript-tpu/venvs/<group>-og` with upstream
  Google `libtpu` and binds `TPU_LIBRARY_PATH` to `<group>-og/.../site-packages/libtpu/libtpu.so`.
- **Device lock barrier**: Releases `/dev/accel*` / `/dev/vfio/*` locks (or cycles a fresh Cloud TPU
  VM when `--fresh-vm-per-provider` is passed) while preserving shared
  `/dev/shm/libscript-tpu/cache/{hf,keras}` Gemma 4 weights on-host.
- **`-rs` pass (`results/rs/`)**: Builds `/dev/shm/libscript-tpu/venvs/<group>-rs` with the drop-in
  PEP 427 `libtpu` wheel from `_lib/toolchains/libtpu-rs` and binds `TPU_LIBRARY_PATH` to
  `<group>-rs/.../site-packages/libtpu/libtpu.so`.
- **Stage A + Synthesis Attestation**: `suites/synthesize_ab.{sh,cmd}` verifies that Stage A
  `/proc/self/maps` `libtpu_mapped_so_sha256` digests are recorded and distinct (`og != rs`) across
  probed backends before emitting `ab_comparison_summary.{json,csv,md}` and `generated_metrics.tex`.

---

## Cloud TPU VM Execution Workflow

```sh
# 1. Provision TFRC-guarded Cloud TPU VM slice and bootstrap libtpu + libtpu-rs + uv
./libscript.sh experiment provision gemma-4-sql-libtpu \
  --tfrc-config=./tfrc.json \
  --repo-dir=/path/to/gemma-4-sql

# 2. Run all 7 Gemma 4 backends on OG libtpu then libtpu-rs and synthesize A/B tables
TPU_NAME=gemma4-ab-node ./experiments/gemma-4-sql-libtpu/run.sh \
  --tfrc-config=./tfrc.json \
  --repo-dir=/path/to/gemma-4-sql \
  --results-dir=./build/gemma4_libtpu_ab

# 3. Tear down Cloud TPU VM with zero-resource post-flight check
./libscript.sh experiment teardown gemma-4-sql-libtpu --tfrc-config=./tfrc.json
```

```cmd
:: Windows Batch equivalent
.\libscript.cmd experiment provision gemma-4-sql-libtpu --tfrc-config=.\tfrc.json --repo-dir=C:\repos\gemma-4-sql
set TPU_NAME=gemma4-ab-node
.\experiments\gemma-4-sql-libtpu\run.cmd --tfrc-config=.\tfrc.json --repo-dir=C:\repos\gemma-4-sql --results-dir=.\build\gemma4_libtpu_ab
.\libscript.cmd experiment teardown gemma-4-sql-libtpu --tfrc-config=.\tfrc.json
```
