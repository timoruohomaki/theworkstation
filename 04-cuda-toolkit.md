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

### Compile and Run the CUDA Sample

```bash
# Install sample programs
sudo apt install -y cuda-samples-12-6

cd /usr/local/cuda/samples/1_Utilities/deviceQuery
sudo make
./deviceQuery
```

With GT1030 installed, expected output includes:
```
Device 0: "NVIDIA GeForce GT 1030"
  CUDA Capability Major/Minor version number: 6.1
  ...
Result = PASS
```

After adding the Tesla M10, you will see four additional devices each reporting:
```
CUDA Capability Major/Minor version number: 5.2
```

---

## Maxwell Architecture Note (sm_52)

The Tesla M10 is a **Maxwell** GPU (compute capability 5.2). CUDA 12.x still compiles for sm_52, but you must specify it explicitly when building code:

```bash
nvcc -arch=sm_52 -o my_program my_program.cu
```

For Python/PyTorch workloads this is handled automatically, but see [05-ml-stack.md](05-ml-stack.md) for framework-specific version pins.

---

## Check NVML (Management Library)

```bash
nvidia-smi --query-gpu=name,memory.total,compute_cap --format=csv
```

This confirms the management layer works correctly, which Ollama and PyTorch rely on for device enumeration.

Continue to [05-ml-stack.md](05-ml-stack.md).
