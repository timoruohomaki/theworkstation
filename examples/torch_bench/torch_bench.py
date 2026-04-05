# torch_bench.py
# Measures PyTorch ML-relevant throughput per GPU:
#   - FP32 matrix multiply (matmul) TFLOPS
#   - Conv2d images/sec  (simulates a single CNN layer)
#   - Memory bandwidth GB/s
#
# Writes a timestamped JSON file for before/after comparison.
# Run with the ml venv active: python3 torch_bench.py

import json
import time
import torch
from datetime import datetime, timezone

WARMUP      = 5
ITERATIONS  = 50
MATMUL_SIZE = 2048
CONV_BATCH  = 64

def bench_matmul(device: torch.device) -> float:
    """Returns achieved TFLOPS for FP32 square matmul."""
    a = torch.randn(MATMUL_SIZE, MATMUL_SIZE, device=device)
    b = torch.randn(MATMUL_SIZE, MATMUL_SIZE, device=device)
    for _ in range(WARMUP):
        torch.matmul(a, b)
    torch.cuda.synchronize(device)

    t0 = time.perf_counter()
    for _ in range(ITERATIONS):
        torch.matmul(a, b)
    torch.cuda.synchronize(device)
    elapsed = time.perf_counter() - t0

    flops = 2 * MATMUL_SIZE ** 3 * ITERATIONS
    return flops / elapsed / 1e12

def bench_conv(device: torch.device) -> float:
    """Returns images/sec for a 3x3 Conv2d forward pass."""
    layer = torch.nn.Conv2d(64, 128, kernel_size=3, padding=1).to(device)
    x = torch.randn(CONV_BATCH, 64, 112, 112, device=device)
    with torch.no_grad():
        for _ in range(WARMUP):
            layer(x)
    torch.cuda.synchronize(device)

    t0 = time.perf_counter()
    with torch.no_grad():
        for _ in range(ITERATIONS):
            layer(x)
    torch.cuda.synchronize(device)
    elapsed = time.perf_counter() - t0

    return CONV_BATCH * ITERATIONS / elapsed

def bench_membw(device: torch.device) -> float:
    """Returns memory bandwidth in GB/s using a large tensor copy."""
    size = 128 * 1024 * 1024  # 512 MB as float32
    src = torch.ones(size, device=device)
    for _ in range(WARMUP):
        dst = src.clone()
    torch.cuda.synchronize(device)

    t0 = time.perf_counter()
    for _ in range(ITERATIONS):
        dst = src.clone()
    torch.cuda.synchronize(device)
    elapsed = time.perf_counter() - t0

    bytes_moved = 2 * size * 4 * ITERATIONS  # read + write, float32
    return bytes_moved / elapsed / 1e9

def main():
    if not torch.cuda.is_available():
        print("CUDA not available — is the ml venv active with cu126 PyTorch?")
        return

    ts = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%S")
    results = {"timestamp": ts, "pytorch": torch.__version__, "gpus": []}

    for i in range(torch.cuda.device_count()):
        device = torch.device(f"cuda:{i}")
        props  = torch.cuda.get_device_properties(i)
        name   = props.name
        vram   = props.total_memory / 1024 ** 2

        print(f"\n--- GPU {i}: {name} ({vram:.0f} MB) ---")

        print("  matmul TFLOPS  ... ", end="", flush=True)
        tflops = bench_matmul(device)
        print(f"{tflops:.3f}")

        print("  conv images/s  ... ", end="", flush=True)
        imgs = bench_conv(device)
        print(f"{imgs:.1f}")

        print("  mem bandwidth  ... ", end="", flush=True)
        bw = bench_membw(device)
        print(f"{bw:.2f} GB/s")

        results["gpus"].append({
            "index":                  i,
            "name":                   name,
            "vram_mb":                round(vram),
            "matmul_tflops":          round(tflops, 3),
            "conv_images_per_sec":    round(imgs, 1),
            "memory_bandwidth_gb_s":  round(bw, 2),
        })

    fname = f"bench_{datetime.now().strftime('%Y%m%dT%H%M%S')}.json"
    with open(fname, "w") as f:
        json.dump(results, f, indent=2)
    print(f"\nResults written to {fname}")

if __name__ == "__main__":
    main()
