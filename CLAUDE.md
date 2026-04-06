# CLAUDE.md — theworkstation

Context for Claude Code sessions on this repository.

## Project Purpose

Step-by-step installation guide and CUDA example programs for building an AI
development workstation on an HP Z240 Tower using a Tesla M10 GPU, targeting
zero GPU licensing cost through bare-metal Ubuntu Server.

## Hardware

| Component | Model | Key detail |
|-----------|-------|-----------|
| Workstation | HP Z240 Tower | Standard ATX PSU, PCIe Gen3 x16 |
| CPU | Intel Xeon E3-1230 v5 | No integrated graphics |
| RAM | 32 GB DDR4-3200 ECC | |
| Storage | Kingston 1000G NV3 NVMe | M.2 slot |
| Display GPU | NVIDIA Quadro K2200 | Maxwell sm_50, 4 GB; display only |
| Compute GPU | NVIDIA Tesla M10 | Maxwell sm_52, 4× 8 GB; not yet installed (awaiting PSU) |
| PSU | Gigabyte Aorus Elite P1000W (GP-AE1000PM) | Replacing stock 400 W; not yet installed |

The M10 has a **single 8-pin PCIe power connector** (not two). The three-beep
POST error observed was caused by the underpowered stock PSU, not a connector
issue.

## Critical Version Pins

Maxwell GPUs (sm_50, sm_52) are dropped in CUDA 13.0 and PyTorch cu128+ builds.
Do not suggest upgrading beyond these:

| Component | Version | Reason |
|-----------|---------|--------|
| CUDA Toolkit | 12.6 (held via apt-mark) | Last release with Maxwell library support |
| PyTorch | cu126 index | Last wheel set with sm_50 kernels |
| NVIDIA driver | 535.x | Covers both K2200 and M10 |

PyTorch cu126 wheels include `sm_50` but not a separate `sm_52` entry.
This is correct — sm_50 cubins run on all compute capability 5.x hardware
via binary compatibility. Do not flag the absence of sm_52 as an error.

## Repository Structure

```
/
├── 01-hardware.md          Physical setup, PSU upgrade, BIOS settings
├── 02-ubuntu-install.md    Ubuntu Server 24.04 LTS installation
├── 03-nvidia-drivers.md    NVIDIA 535.x driver + X11 BusID config
├── 04-cuda-toolkit.md      CUDA 12.6 install, version lock rationale
├── 05-ml-stack.md          PyTorch, JupyterLab, Ollama (ml venv scope)
├── 06-adding-tesla-m10.md  M10 physical install and CUDA_VISIBLE_DEVICES
└── examples/
    ├── device_query/       CUDA C — GPU enumeration (Makefile, sm_50+sm_52)
    ├── cuda_bench/         CUDA C — memory bandwidth + GEMM GFLOPS (JSON out)
    └── torch_bench/        Python — matmul TFLOPS, Conv2d, bandwidth (JSON out)
```

Docs live at repo root (not in a docs/ subfolder).

## Architecture Decisions

- **Bare-metal Ubuntu Server**, not Proxmox or VMware, because the goal is
  JupyterLab access to all four M10 sub-GPUs without any vGPU licensing.
- **Quadro K2200** handles display output (Xeon E3 has no iGPU). GT1030 was
  the original plan but did not fit physically.
- **CUDA_VISIBLE_DEVICES** used to exclude the K2200 from ML workloads once
  the M10 is installed; exact indices depend on PCI enumeration at that time.
- **JupyterLab systemd service** uses the full venv path in ExecStart so it
  works without the venv being activated in the shell.
- **Ollama** is a system-level binary; it does not use the ml venv and does
  not require deactivate before calling it.
- **Benchmark JSON files** are timestamped to allow before/after M10 comparison;
  make clean in cuda_bench deletes them.

## ml Venv Scope

All pip, python3, and jupyter commands in docs/05 run inside ~/envs/ml.
Ollama and Docker/Open WebUI are system-level and venv-independent.

## X11 BusID

nvidia-xconfig does not insert BusID automatically. It must be added manually
to the Device section of /etc/X11/xorg.conf using the PCI address from
`lspci | grep -i nvidia`, converting BB:DD.F format to PCI:BB:DD:F.

## Current Build Status

- Ubuntu Server 24.04 LTS: installed
- NVIDIA driver 535.x + K2200: working
- CUDA 12.6: installed and held
- PyTorch cu126: installed, sm_50 confirmed in arch list
- JupyterLab: installed
- Ollama: installed
- New PSU + Tesla M10: pending — doc 06 covers this step
