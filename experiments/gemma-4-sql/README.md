<!-- cspell:words betwixt maxtext libtpu pjrt tfrc xpk keras torchxla safetensors einops optax orbax omegaconf sqlglot duckdb bfloat gemmaFourSql prefill subsuites tmpfs vfio -->

# Empirical Experiment Suite: `gemma-4-sql` (`experiments/gemma-4-sql`)

> **`gemma-4-sql: TPU performance comparisons betwixt JAX, Keras, and PyTorch on Google's Gemma 4`**

Gemma 4 is the latest major open-source LLM from Google. TPU performance comparisons are made
between:

- **Hugging Face Transformers** \[which wraps PyTorch\] (`hf_transformers`);
- **PyTorch** \[native\] (`pytorch_native`);
- **Keras** \[and its JAX, TensorFlow, and PyTorch backends\] (`keras_jax`, `keras_tensorflow`,
  `keras_pytorch`);
- **MaxText** \[which wraps JAX\] (`maxtext`); and
- **JAX** \[native\] (`jax_native`).

This plugin implements a zero-cost **TPU Research Cloud (TFRC)** `$0.00` evaluation harness driving
[`SamuelMarks/gemma-4-sql`](https://github.com/SamuelMarks/gemma-4-sql) across single-host and
multi-host Google Cloud TPU VM slices (`v4-8`, `v4-16`, `v4-32`, `v5e-*`, `v5p-*`, `v6e-*`).

---

## Architecture & Sub-Suites (`E0`–`E4`)

- **`E0` (`suites/e0_tfrc_provenance.{sh,cmd}`)**: Validates `tfrc.policy.json`, workspace git SHA
  - dirty status checksum, tree hash, TPU ICI mesh topology, per-venv wheel digests/versions, and
    Stage A TPU device visibility probes across all 7 backend cells.
- **`E1` (`suites/e1_inference_throughput.{sh,cmd}`)**: Sweeps integer batch sizes (`1,8,32`) for
  Gemma 4 prefill and decode throughput (`tokens_per_sec`), separating cold XLA compile latency
  (`compile_latency_ms`) from steady-state latency quantiles (`p25`, `p50`, `p75`, `p90`, `p99`,
  `iqr`).
- **`E2` (`suites/e2_sql_evaluation.{sh,cmd}`)**: Provisions deterministic seed-42 SQLite and DuckDB
  schemas/databases under `<results-dir>/fixtures/` and evaluates Text-to-SQL execution accuracy
  alongside interactive self-correcting SQL agent accuracy.
- **`E3` (`suites/e3_training_finetuning.{sh,cmd}`)**: Benchmarks SFT, LoRA (`peft`), and DPO
  fine-tuning throughput (`tokens_per_sec_per_chip`), step latency (`step_time_ms`), and verified
  loss descent (`final_loss < initial_loss`).
- **`E4` (`suites/e4_custom_matrix_and_synthesis.{sh,cmd}`)**: Executes custom templated commands
  (`--command-template` and `libscript.json` `.ml.command_matrix`) and synthesizes 5-family and
  7-backend `comparison_summary.{json,csv,md}` plus `\gemmaFourSql*` LaTeX macros in
  `generated_metrics.tex`.

---

## Usage

### POSIX `/bin/sh`

```sh
# Validate plugin manifest & variable schema
./libscript.sh experiment validate gemma-4-sql

# Run full zero-cost TFRC lifecycle (provision -> sync -> E0..E4 -> collect -> teardown)
./libscript.sh experiment tpu_matrix \
  --tfrc-config=/path/to/gemma-4-sql/tfrc.policy.json \
  --repo-dir=/path/to/gemma-4-sql \
  --model=google/gemma-4-E4B \
  --backends=all \
  --subsuites=E0,E1,E2,E3,E4

# Re-render LaTeX macros & comparison tables idempotently without re-running E0-E3
./libscript.sh experiment render-latex gemma-4-sql --results-dir=./build/experiment_results/gemma-4-sql
```

### Windows Batch (`.cmd`)

```cmd
:: Validate plugin manifest & variable schema
call .\libscript.cmd experiment validate gemma-4-sql

:: Run full zero-cost TFRC lifecycle
call .\libscript.cmd experiment tpu_matrix "--tfrc-config=C:\repos\gemma-4-sql\tfrc.policy.json" "--repo-dir=C:\repos\gemma-4-sql" "--model=google/gemma-4-E4B" "--backends=all" "--subsuites=E0,E1,E2,E3,E4"

:: Re-render LaTeX macros & comparison tables idempotently
call .\libscript.cmd experiment render-latex gemma-4-sql "--results-dir=build\experiment_results\gemma-4-sql"
```

---

## Stage B Active HBM Guardrail (Exit Code `65`)

Every workload in `E1`–`E4` runs under `suites/stage_ab_telemetry.{sh,cmd}`. If active TPU
`/dev/accel*` / `/dev/vfio/*` file-descriptor usage or peak TPU HBM allocation is zero while
`GEMMA_4_SQL_REQUIRE_HBM=1`, the runner writes `"status": "failed_cpu_fallback"` into the cell's
`raw/*.json` artifact, triggers the TFRC `EXIT` teardown trap so zero Cloud TPU resources survive,
and exits with status **`65`**.
