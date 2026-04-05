# 04 — CUDA Toolkit

## Install CUDA 12.x

Use the NVIDIA package repository for the most reliable CUDA installation:

```bash
# Add NVIDIA CUDA repository
wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2404/x86_64/cuda-keyring_1.1-1_all.deb
sudo dpkg -i cuda-keyring_1.1-1_all.deb
sudo apt update
sudo apt install -y cuda-toolkit-12-6
rm cuda-keyring_1.1-1_all.deb
```

> **Note**: Check [https://developer.nvidia.com/cuda-downloads](https://developer.nvidia.com/cuda-downloads) for the latest 12.x keyring package URL before installing.

---

## Configure Environment

Add CUDA paths to your shell profile:

```bash
cat >> ~/.bashrc << 'EOF'

# CUDA Toolkit
export PATH=/usr/local/cuda/bin:$PATH
export LD_LIBRARY_PATH=/usr/local/cuda/lib64:$LD_LIBRARY_PATH
export CUDA_HOME=/usr/local/cuda
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
Built on ...
Cuda compilation tools, release 12.x
```

### Compile and Run the Device Query Example

The `cuda-samples` apt package no longer exists in the NVIDIA repository. Use the device query example from this repo instead:

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

Both the Quadro K2200 (sm_50) and the Tesla M10 (sm_52) are **Maxwell** GPUs, so the same driver generation covers the entire system. CUDA 12.x compiles for both, but you must specify the architecture explicitly when building code:

```bash
nvcc -arch=sm_52 -o my_program my_program.cu   # target M10
nvcc -arch=sm_50 -o my_program my_program.cu   # target K2200
```

The `device_query` Makefile compiles for both sm_50 and sm_52 in one binary. For Python/PyTorch workloads this is handled automatically — see [05-ml-stack.md](05-ml-stack.md) for framework-specific version pins.

---

## Check NVML (Management Library)

```bash
nvidia-smi --query-gpu=name,memory.total,compute_cap --format=csv
```

This confirms the management layer works correctly, which Ollama and PyTorch rely on for device enumeration.

Continue to [05-ml-stack.md](05-ml-stack.md).
