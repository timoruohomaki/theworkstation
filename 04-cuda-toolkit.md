# 04 — CUDA Toolkit

## Maxwell and CUDA Version Lock

> ⚠️ **Important**: CUDA 12.x is the **last toolkit series that supports Maxwell GPUs** (sm_50, sm_52). CUDA 13.0, released in 2025, dropped Maxwell, Pascal, and Volta entirely. **Do not upgrade to CUDA 13.x** — the M10 and K2200 will not function as compute devices.

---

## Install CUDA 12.6

CUDA 12.6 is the recommended version for this build: it is the last 12.x release with full Maxwell library support, and it is the baseline that PyTorch's Maxwell-compatible wheels target.

```bash
# Add NVIDIA CUDA repository
wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2404/x86_64/cuda-keyring_1.1-1_all.deb
sudo dpkg -i cuda-keyring_1.1-1_all.deb
sudo apt update
sudo apt install -y cuda-toolkit-12-6
rm cuda-keyring_1.1-1_all.deb
```

Pin the package to prevent accidental upgrade to CUDA 13:

```bash
sudo apt-mark hold cuda-toolkit-12-6
```

---

## Configure Environment

Add CUDA paths to your shell profile:

```bash
cat >> ~/.bashrc << 'EOF'

# CUDA Toolkit — pinned to 12.6 for Maxwell (sm_50/sm_52) support
export PATH=/usr/local/cuda-12.6/bin:$PATH
export LD_LIBRARY_PATH=/usr/local/cuda-12.6/lib64:$LD_LIBRARY_PATH
export CUDA_HOME=/usr/local/cuda-12.6
EOF

source ~/.bashrc
```

---

## Verify CUDA Installation

```bash
nvcc --version
```

Expected:
```
nvcc: NVIDIA (R) Cuda compiler driver
Cuda compilation tools, release 12.6
```

### Compile and Run the Device Query Example

```bash
cd examples/device_query
make
./device_query
```

With the Quadro K2200 installed, expected output:
```
CUDA devices found: 1

GPU 0: Quadro K2200
  Compute capability : sm_50
  Total VRAM         : 4096 MB
  Multiprocessors    : 5
  Clock rate         : 1124 MHz
  ECC enabled        : no
```

After adding the Tesla M10, you will see four additional devices:
```
CUDA devices found: 5

GPU 0: Quadro K2200
  Compute capability : sm_50
  Total VRAM         : 4096 MB
  ...
GPU 1: Tesla M10
  Compute capability : sm_52
  Total VRAM         : 8192 MB
  ECC enabled        : yes
...
```

---

## Maxwell Architecture Note

Both the Quadro K2200 (sm_50) and the Tesla M10 (sm_52) are **Maxwell** GPUs. CUDA 12.6 compiles for both, but you must specify the architecture explicitly when building CUDA C code:

```bash
nvcc -arch=sm_52 -o my_program my_program.cu   # target M10
nvcc -arch=sm_50 -o my_program my_program.cu   # target K2200
```

The `device_query` Makefile compiles a single binary for both architectures. For Python/PyTorch workloads see the version pins in [05-ml-stack.md](05-ml-stack.md).

---

## Check NVML (Management Library)

```bash
nvidia-smi --query-gpu=name,memory.total,compute_cap --format=csv
```

This confirms the management layer works correctly, which Ollama and PyTorch rely on for device enumeration.

Continue to [05-ml-stack.md](05-ml-stack.md).
