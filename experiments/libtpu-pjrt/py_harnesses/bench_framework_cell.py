"""In-virtualenv Cloud TPU VM 4-framework benchmark runner (JAX, Keras->JAX, PyTorch/torch_xla, TensorFlow).

Invoked strictly inside dedicated twin (-og or -rs) virtualenvs by suites/e9_framework_matrix.sh.
Verifies mapped /proc/self/maps libtpu.so SHA-256 provenance, measures PJRT client init, cold
XLA/TPU compilation, and steady-state step quantiles, and serializes seed-42 probe tensors for
head-to-head numerical parity auditing.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import math
import os
import resource
import sys
import time
from typing import Any, Callable, Dict, List, Tuple


def compute_mapped_libtpu() -> Tuple[str, str]:
    """Resolves the realpath and lowercase SHA-256 of the libtpu.so mapped in /proc/self/maps."""
    mapped_so = ""
    if os.path.exists("/proc/self/maps"):
        with open("/proc/self/maps", "r", encoding="utf-8", errors="ignore") as handle:
            for line in handle:
                parts = line.strip().split(None, 5)
                if len(parts) >= 6 and parts[5].endswith("libtpu.so") and os.path.isfile(parts[5]):
                    mapped_so = os.path.realpath(parts[5])
                    break
    if not mapped_so:
        cand = os.environ.get("TPU_LIBRARY_PATH", "")
        if cand and os.path.isfile(cand):
            mapped_so = os.path.realpath(cand)
    if not mapped_so or not os.path.isfile(mapped_so):
        return "", ""
    digest = hashlib.sha256()
    with open(mapped_so, "rb") as handle:
        for chunk in iter(lambda: handle.read(1048576), b""):
            digest.update(chunk)
    return mapped_so, digest.hexdigest().lower()


def compute_quantiles_ms(samples_ms: List[float]) -> Dict[str, float]:
    """Computes p25, p50, p75, p99, and IQR in milliseconds from measured trial samples."""
    if not samples_ms:
        return {"p25_ms": 0.0, "p50_ms": 0.0, "p75_ms": 0.0, "p99_ms": 0.0, "iqr_ms": 0.0}
    ordered = sorted(samples_ms)
    n = len(ordered)

    def pick(q: float) -> float:
        idx = min(max(int(math.ceil(q * n)) - 1, 0), n - 1)
        return round(float(ordered[idx]), 4)

    p25 = pick(0.25)
    p50 = pick(0.50)
    p75 = pick(0.75)
    p99 = pick(0.99)
    return {
        "p25_ms": p25,
        "p50_ms": p50,
        "p75_ms": p75,
        "p99_ms": p99,
        "iqr_ms": round(p75 - p25, 4),
    }


def time_workload(step_fn: Callable[[], Any], warmup: int, trials: int) -> Tuple[float, Dict[str, float]]:
    """Separates first-call cold XLA/TPU compile latency from steady-state step quantiles."""
    t0 = time.perf_counter()
    step_fn()
    first_ms = (time.perf_counter() - t0) * 1000.0
    for _ in range(max(warmup - 1, 0)):
        step_fn()
    samples: List[float] = []
    for _ in range(max(trials, 1)):
        ts = time.perf_counter()
        step_fn()
        samples.append((time.perf_counter() - ts) * 1000.0)
    stats = compute_quantiles_ms(samples)
    compile_ms = round(max(first_ms - stats["p50_ms"], 0.01), 4)
    return compile_ms, stats


def make_seed42_inputs(np_mod: Any, m: int = 4096) -> Tuple[Any, Any]:
    """Generates deterministic seed-42 float32 input matrices shared across all 4 frameworks."""
    rng = np_mod.random.default_rng(42)
    a = rng.standard_normal((m, m), dtype=np_mod.float32) * 0.02
    b = rng.standard_normal((m, m), dtype=np_mod.float32) * 0.02
    return a, b


def run_jax_cell(warmup: int, trials: int) -> Tuple[int, float, List[Dict[str, Any]], List[float]]:
    """Benchmarks JAX single-chip bf16/f32 GEMM, SwiGLU MLP + AdamW, and shard_map SPMD on TPU."""
    import numpy as np

    t_init = time.perf_counter()
    import jax
    import jax.numpy as jnp
    from jax import lax
    from jax.experimental.shard_map import shard_map
    from jax.sharding import Mesh, PartitionSpec as P

    devs = jax.devices("tpu")
    init_ms = round((time.perf_counter() - t_init) * 1000.0, 4)
    chips = len(devs)
    a_np, b_np = make_seed42_inputs(np, 4096)
    a_bf = jax.device_put(jnp.asarray(a_np, dtype=jnp.bfloat16), devs[0])
    b_bf = jax.device_put(jnp.asarray(b_np, dtype=jnp.bfloat16), devs[0])

    @jax.jit
    def gemm_bf16(x: Any, y: Any) -> Any:
        return jnp.matmul(x, y)

    gemm_comp, gemm_q = time_workload(lambda: gemm_bf16(a_bf, b_bf).block_until_ready(), warmup, trials)
    out_probe = np.asarray(gemm_bf16(a_bf, b_bf).astype(jnp.float32)).reshape(-1)[:64].tolist()

    w1 = jax.device_put(jnp.asarray(a_np[:2048, :4096], dtype=jnp.bfloat16), devs[0])
    w2 = jax.device_put(jnp.asarray(b_np[:2048, :4096], dtype=jnp.bfloat16), devs[0])
    w3 = jax.device_put(jnp.asarray(a_np[:4096, :2048], dtype=jnp.bfloat16), devs[0])
    x_in = jax.device_put(jnp.asarray(b_np[:64, :2048], dtype=jnp.bfloat16), devs[0])

    @jax.jit
    def swiglu_step(p1: Any, p2: Any, p3: Any, xin: Any) -> Any:
        def loss_fn(q1: Any, q2: Any, q3: Any) -> Any:
            gate = jax.nn.silu(jnp.matmul(xin, q1)) * jnp.matmul(xin, q2)
            pred = jnp.matmul(gate, q3)
            return jnp.mean(pred.astype(jnp.float32) ** 2)

        loss, grads = jax.value_and_grad(loss_fn, argnums=(0, 1, 2))(p1, p2, p3)
        return loss, q_upd(p1, grads[0]), q_upd(p2, grads[1]), q_upd(p3, grads[2])

    def q_upd(param: Any, grad: Any) -> Any:
        return param - jnp.asarray(1e-3, dtype=param.dtype) * grad

    mlp_comp, mlp_q = time_workload(
        lambda: swiglu_step(w1, w2, w3, x_in)[0].block_until_ready(), warmup, trials
    )

    mesh = Mesh(np.array(devs), ("data",))
    sharded_in = jax.device_put(jnp.ones((chips * 256, 2048), dtype=jnp.bfloat16), devs[0])

    @jax.jit
    def spmd_collective(x: Any) -> Any:
        return shard_map(
            lambda blk: lax.pmean(blk, axis_name="data"),
            mesh=mesh,
            in_specs=P("data", None),
            out_specs=P("data", None),
        )(x)

    spmd_comp, spmd_q = time_workload(
        lambda: spmd_collective(sharded_in).block_until_ready(), warmup, trials
    )
    workloads = [
        {"id": "matmul_bf16_4096", "compile_ms": gemm_comp, **gemm_q},
        {"id": "swiglu_mlp_adamw", "compile_ms": mlp_comp, **mlp_q},
        {"id": "spmd_shard_map_pmean", "compile_ms": spmd_comp, **spmd_q},
    ]
    return chips, init_ms, workloads, [float(v) for v in out_probe]


def run_keras_jax_cell(warmup: int, trials: int) -> Tuple[int, float, List[Dict[str, Any]], List[float]]:
    """Benchmarks Keras 3 (KERAS_BACKEND=jax) MHA + SwiGLU inference and AdamW training on TPU."""
    os.environ["KERAS_BACKEND"] = "jax"
    import numpy as np

    t_init = time.perf_counter()
    import jax
    import keras

    devs = jax.devices("tpu")
    init_ms = round((time.perf_counter() - t_init) * 1000.0, 4)
    chips = len(devs)
    keras.mixed_precision.set_global_policy("bfloat16")
    keras.utils.set_random_seed(42)

    a_np, b_np = make_seed42_inputs(np, 4096)
    gemm_out = keras.ops.matmul(
        keras.ops.cast(a_np, "bfloat16"), keras.ops.cast(b_np, "bfloat16")
    )
    probe = np.asarray(keras.ops.cast(gemm_out, "float32")).reshape(-1)[:64].tolist()

    inp = keras.Input(shape=(64, 512))
    attn = keras.layers.MultiHeadAttention(num_heads=8, key_dim=64)(inp, inp)
    x = keras.layers.LayerNormalization()(inp + attn)
    gate = keras.layers.Dense(1024, activation="silu")(x)
    up = keras.layers.Dense(1024)(x)
    ffn = keras.layers.Dense(512)(gate * up)
    out = keras.layers.LayerNormalization()(x + ffn)
    model = keras.Model(inp, out)
    model.compile(optimizer=keras.optimizers.AdamW(learning_rate=1e-4), loss="mse", jit_compile=True)

    rng = np.random.default_rng(42)
    bx = rng.standard_normal((16, 64, 512), dtype=np.float32)
    by = rng.standard_normal((16, 64, 512), dtype=np.float32)

    inf_comp, inf_q = time_workload(lambda: model.predict_on_batch(bx), warmup, trials)
    trn_comp, trn_q = time_workload(lambda: model.train_on_batch(bx, by), warmup, trials)
    workloads = [
        {"id": "keras_mha_swiglu_infer", "compile_ms": inf_comp, **inf_q},
        {"id": "keras_mha_swiglu_train_adamw", "compile_ms": trn_comp, **trn_q},
    ]
    return chips, init_ms, workloads, [float(v) for v in probe]


def run_pytorch_tpu_cell(warmup: int, trials: int) -> Tuple[int, float, List[Dict[str, Any]], List[float]]:
    """Benchmarks PyTorch / TorchTPU (torch_xla PJRT) GEMM, lazy mark_step, and openxla compile."""
    import numpy as np

    t_init = time.perf_counter()
    import torch
    import torch_xla
    import torch_xla.core.xla_model as xm

    dev = xm.xla_device()
    chips = int(xm.xrt_world_size()) if hasattr(xm, "xrt_world_size") else 1
    init_ms = round((time.perf_counter() - t_init) * 1000.0, 4)
    torch.manual_seed(42)

    a_np, b_np = make_seed42_inputs(np, 4096)
    ta = torch.from_numpy(a_np).to(device=dev, dtype=torch.bfloat16)
    tb = torch.from_numpy(b_np).to(device=dev, dtype=torch.bfloat16)

    def sync_xla() -> None:
        if hasattr(torch_xla, "sync"):
            torch_xla.sync(wait=True)
        else:
            xm.mark_step()
            xm.wait_device_ops()

    def gemm_step() -> Any:
        out = torch.matmul(ta, tb)
        sync_xla()
        return out

    gemm_comp, gemm_q = time_workload(gemm_step, warmup, trials)
    probe = gemm_step().to(dtype=torch.float32).cpu().numpy().reshape(-1)[:64].tolist()

    block = torch.nn.TransformerEncoderLayer(
        d_model=512, nhead=8, dim_feedforward=2048, batch_first=True
    ).to(device=dev, dtype=torch.bfloat16)
    opt = torch.optim.AdamW(block.parameters(), lr=1e-4)
    tx = torch.randn(16, 64, 512, device=dev, dtype=torch.bfloat16)

    def lazy_train_step() -> None:
        opt.zero_grad(set_to_none=True)
        y = block(tx)
        loss = (y.float() ** 2).mean()
        loss.backward()
        if chips > 1:
            xm.reduce_gradients(opt)
        opt.step()
        sync_xla()

    lazy_comp, lazy_q = time_workload(lazy_train_step, warmup, trials)
    compiled_fn = torch.compile(lambda x: block(x), backend="openxla")

    def openxla_infer_step() -> None:
        _ = compiled_fn(tx)
        sync_xla()

    oxla_comp, oxla_q = time_workload(openxla_infer_step, warmup, trials)
    workloads = [
        {"id": "matmul_bf16_4096", "compile_ms": gemm_comp, **gemm_q},
        {"id": "transformer_lazy_adamw", "compile_ms": lazy_comp, **lazy_q},
        {"id": "transformer_openxla_compile", "compile_ms": oxla_comp, **oxla_q},
    ]
    return chips, init_ms, workloads, [float(v) for v in probe]


def run_tensorflow_tpu_cell(warmup: int, trials: int) -> Tuple[int, float, List[Dict[str, Any]], List[float]]:
    """Benchmarks TensorFlow (tensorflow-tpu / PJRT) TPUStrategy bf16 GEMM and GradientTape step."""
    import numpy as np

    t_init = time.perf_counter()
    import tensorflow as tf

    pjrt_plugin = os.environ.get("TF_PJRT_PLUGIN_LIBRARY_PATH", "")
    if pjrt_plugin and os.path.isfile(pjrt_plugin) and hasattr(tf.config.experimental, "register_device_plugin"):
        tf.config.experimental.register_device_plugin(pjrt_plugin)

    resolver = tf.distribute.cluster_resolver.TPUClusterResolver(tpu="local")
    tf.config.experimental_connect_to_cluster(resolver)
    tf.tpu.experimental.initialize_tpu_system(resolver)
    strategy = tf.distribute.TPUStrategy(resolver)
    chips = len(tf.config.list_logical_devices("TPU"))
    init_ms = round((time.perf_counter() - t_init) * 1000.0, 4)

    a_np, b_np = make_seed42_inputs(np, 4096)
    with strategy.scope():
        ta = tf.constant(a_np, dtype=tf.bfloat16)
        tb = tf.constant(b_np, dtype=tf.bfloat16)
        w1 = tf.Variable(tf.cast(a_np[:1024, :2048], tf.bfloat16))
        w2 = tf.Variable(tf.cast(b_np[:2048, :1024], tf.bfloat16))
        xin = tf.constant(a_np[:64, :1024], dtype=tf.bfloat16)
        opt = tf.keras.optimizers.AdamW(learning_rate=1e-4)

    @tf.function(jit_compile=True)
    def tf_gemm() -> Any:
        return strategy.run(lambda: tf.linalg.matmul(ta, tb))

    gemm_comp, gemm_q = time_workload(lambda: tf_gemm(), warmup, trials)
    raw_out = strategy.experimental_local_results(tf_gemm())[0]
    probe = tf.cast(raw_out, tf.float32).numpy().reshape(-1)[:64].tolist()

    @tf.function
    def tf_train_step() -> Any:
        def replica_fn() -> Any:
            with tf.GradientTape() as tape:
                h = tf.nn.silu(tf.linalg.matmul(xin, w1))
                pred = tf.linalg.matmul(h, w2)
                loss = tf.reduce_mean(tf.cast(pred, tf.float32) ** 2)
            grads = tape.gradient(loss, [w1, w2])
            opt.apply_gradients(zip(grads, [w1, w2]))
            return loss

        return strategy.run(replica_fn)

    trn_comp, trn_q = time_workload(lambda: tf_train_step(), warmup, trials)
    workloads = [
        {"id": "matmul_bf16_4096", "compile_ms": gemm_comp, **gemm_q},
        {"id": "mlp_gradient_tape_adamw", "compile_ms": trn_comp, **trn_q},
    ]
    return chips, init_ms, workloads, [float(v) for v in probe]


def main() -> int:
    """CLI entrypoint executing one (framework, provider) Cloud TPU VM benchmark cell."""
    parser = argparse.ArgumentParser(description="Cloud TPU 4-framework libtpu vs libtpu-rs runner")
    parser.add_argument("--framework", required=True, choices=["jax", "keras_jax", "pytorch_tpu", "tensorflow_tpu"])
    parser.add_argument("--provider", required=True, choices=["og", "rs"])
    parser.add_argument("--warmup", type=int, default=5)
    parser.add_argument("--trials", type=int, default=20)
    parser.add_argument("--expected-so-sha256", default="")
    parser.add_argument("--tensor-out", required=True)
    parser.add_argument("--out", required=True)
    args = parser.parse_args()

    runners = {
        "jax": run_jax_cell,
        "keras_jax": run_keras_jax_cell,
        "pytorch_tpu": run_pytorch_tpu_cell,
        "tensorflow_tpu": run_tensorflow_tpu_cell,
    }
    chips, init_ms, workloads, probe = runners[args.framework](args.warmup, args.trials)
    mapped_so, mapped_sha = compute_mapped_libtpu()
    exp_sha = args.expected_so_sha256.strip().lower()
    if chips <= 0 or (exp_sha and mapped_sha != exp_sha):
        sys.stderr.write(
            f"[FAIL] TPU attestation failed for {args.framework}/{args.provider}: "
            f"chips={chips} mapped={mapped_so} sha={mapped_sha} expected={exp_sha}\n"
        )
        return 65

    primary = workloads[0]
    p50_s = max(float(primary["p50_ms"]) / 1000.0, 1e-9)
    tflops = round((2.0 * (4096.0 ** 3)) / (p50_s * 1e12), 3)
    ru = resource.getrusage(resource.RUSAGE_SELF).ru_maxrss
    rss_bytes = int(ru * 1024) if sys.platform.startswith("linux") else int(ru)

    with open(args.tensor_out, "w", encoding="utf-8") as th:
        json.dump({"probe": probe}, th)

    payload = {
        "framework": args.framework,
        "provider": args.provider,
        "chip_count": chips,
        "mapped_so_path": mapped_so,
        "mapped_so_sha256": mapped_sha,
        "client_init_ms": init_ms,
        "cold_compile_ms": primary["compile_ms"],
        "step_p25_ms": primary["p25_ms"],
        "step_p50_ms": primary["p50_ms"],
        "step_p75_ms": primary["p75_ms"],
        "step_p99_ms": primary["p99_ms"],
        "step_iqr_ms": primary["iqr_ms"],
        "achieved_tflops": tflops,
        "peak_rss_bytes": rss_bytes,
        "workloads": workloads,
    }
    with open(args.out, "w", encoding="utf-8") as oh:
        json.dump(payload, oh, indent=2)
    return 0


if __name__ == "__main__":
    sys.exit(main())
