# theworkstation

A step-by-step guide to building an AI development workstation on recycled enterprise PC hardware using an NVIDIA Tesla M10 GPU.

## Philosophy

This build prioritises **zero GPU licensing cost** by running Ubuntu Server bare-metal, exposing all four Tesla M10 sub-GPUs directly as CUDA devices — no vGPU, no GRID/vGPU software license required.

## Hardware Bill of Materials

| Component | Model | Notes |
|-----------|-------|-------|
| Workstation | HP Z240 Tower | PCIe Gen3 x16 slot required |
| CPU | Intel Xeon E3-1230 v5 @ 3.40 GHz | ECC memory support |
| RAM | DDR4-3200 CL16 SDRAM | 2 * 16 GB |
| Storage | Kingston 1000G NV3 M.2 2280 PCIe 4.0 NVMe SSD | M.2 slot on Z240 motherboard, Up to 6,000MB/s read, 4,000MB/s write |
| Display GPU | Asus GT1030 | Headless display adapter; frees M10 for compute |
| Compute GPU | NVIDIA Tesla M10 | 4× Maxwell GPUs, 32 GB GDDR5, 2 560 CUDA cores |
| PSU | Gigabyte Aorus Elite P1000W (GP-AE1000PM) | 80+ Platinum, fully modular, ATX 3.1; stock 400 W insufficient for M10 |

## Software Stack

- **OS**: Ubuntu Server 24.04 LTS
- **GPU drivers**: NVIDIA 535.x (supports Maxwell sm_52 and Pascal)
- **Compute**: CUDA Toolkit 12.x
- **ML runtime**: PyTorch 2.1 with CUDA 12.1
- **LLM serving**: Ollama
- **Development**: JupyterLab + Python virtual environments

## Installation Guide

Follow the documents in order:

1. [Hardware Setup](01-hardware.md)
2. [Ubuntu Server Installation](02-ubuntu-install.md)
3. [Display Driver and NVIDIA Setup](03-nvidia-drivers.md)
4. [CUDA Toolkit](04-cuda-toolkit.md)
5. [ML Stack — JupyterLab, PyTorch, Ollama](05-ml-stack.md)
6. [Adding the Tesla M10](06-adding-tesla-m10.md)

## Architecture Overview

```
┌─────────────────────────────────────────────────────┐
│  HP Z240 Tower — Ubuntu Server 24.04 LTS            │
│                                                     │
│  GT1030 ──► Display output (PCIe x4 slot)          │
│                                                     │
│  Tesla M10 ──► 4× CUDA devices (PCIe x16 slot)     │
│    ├── GPU 0  640 cores  8 GB VRAM                  │
│    ├── GPU 1  640 cores  8 GB VRAM                  │
│    ├── GPU 2  640 cores  8 GB VRAM                  │
│    └── GPU 3  640 cores  8 GB VRAM                  │
│                                                     │
│  JupyterLab ─────────────────────► browser access  │
│  Ollama (llama.cpp backend) ──────► API :11434      │
└─────────────────────────────────────────────────────┘
```

## License

MIT — see [LICENSE](LICENSE)
