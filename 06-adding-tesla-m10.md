# 06 — Adding the Tesla M10

Perform this step only after the 750 W PSU is installed and the base system (steps 01–05) is fully validated.

## Pre-installation Checklist

- [ ] 750 W PSU installed and system boots cleanly
- [ ] Ubuntu Server 24.04 LTS running and updated
- [ ] NVIDIA driver 535.x installed and GT1030 confirmed by `nvidia-smi`
- [ ] CUDA Toolkit 12.x installed and `nvcc --version` working
- [ ] JupyterLab accessible from LAN
- [ ] System powered off and unplugged from mains

---

## Physical Installation

1. Power off and unplug the workstation
2. Seat the Tesla M10 in the **primary PCIe x16 slot** (CPU-direct lanes)
3. Connect **one 8-pin PCIe power cable** from the PSU — the M10 draws its 225 W through the PCIe slot (75 W) and this single cable (150 W). No second connector exists on the board. Missing this cable was likely the cause of the three-beep POST error with the old PSU
4. The GT1030 remains in its secondary slot for display output
5. Power on — the BIOS may POST slightly slower while enumerating the M10

---

## Validate Detection

```bash
nvidia-smi
```

Expected output shows **five GPUs**: GT1030 (display) + four Tesla M10 sub-GPUs:

```
+-----------------------------------------------------------------------------+
| GPU  Name                 | Bus-Id        | Volatile Uncorr. ECC |
|   0  NVIDIA GeForce GT 1030 | 00000000:01:00.0 |               N/A |
|   1  Tesla M10            | 00000000:02:00.0 |                 0 |
|   2  Tesla M10            | 00000000:02:00.1 |                 0 |
|   3  Tesla M10            | 00000000:02:00.2 |                 0 |
|   4  Tesla M10            | 00000000:02:00.3 |                 0 |
+-----------------------------------------------------------------------------+
```

> Each M10 sub-GPU appears as a separate CUDA device with 8 GB VRAM.

---

## Exclude GT1030 from CUDA Workloads

Set the GT1030 aside so ML workloads only use the M10 sub-GPUs:

```bash
# Find the GT1030 CUDA device index
nvidia-smi -L
```

Identify the GT1030 index (typically 0). Then in your ML environment:

```bash
# In ~/.bashrc — use M10 GPUs only (indices 1–4 in example above)
export CUDA_VISIBLE_DEVICES=1,2,3,4
```

Adjust indices to match your actual `nvidia-smi` output.

For Ollama, set the variable in the service unit:

```bash
sudo systemctl edit ollama
```

```ini
[Service]
Environment="CUDA_VISIBLE_DEVICES=1,2,3,4"
```

```bash
sudo systemctl daemon-reload && sudo systemctl restart ollama
```

---

## PyTorch Multi-GPU Verification

```bash
source ~/envs/ml/bin/activate
python3 -c "
import torch
print('GPU count:', torch.cuda.device_count())
for i in range(torch.cuda.device_count()):
    props = torch.cuda.get_device_properties(i)
    print(f'  GPU {i}: {props.name}  '
          f'{props.total_memory // 1024**3} GB  '
          f'sm_{props.major}{props.minor}')
"
```

Expected (with CUDA_VISIBLE_DEVICES set to M10 sub-GPUs):
```
GPU count: 4
  GPU 0: Tesla M10  8 GB  sm_52
  GPU 1: Tesla M10  8 GB  sm_52
  GPU 2: Tesla M10  8 GB  sm_52
  GPU 3: Tesla M10  8 GB  sm_52
```

---

## Thermal Monitoring

The M10 is a passively cooled server card. Ensure the Z240 case fans can exhaust the heat:

```bash
# Monitor all GPU temperatures continuously
watch -n 2 nvidia-smi --query-gpu=index,name,temperature.gpu,power.draw \
    --format=csv,noheader
```

Safe operating temperature for the M10 is below 85 °C under sustained load. If temperatures exceed this, add a 120 mm case fan directed at the card.

---

## Model VRAM Reference

| Model | Quantisation | VRAM Required | Fits on M10 |
|-------|-------------|----------------|-------------|
| Llama 3.2 3B | Q4_K_M | ~2 GB | 1 GPU |
| Mistral 7B | Q4_K_M | ~4,5 GB | 1 GPU |
| Llama 3.1 8B | Q4_K_M | ~5 GB | 1 GPU |
| Llama 3.1 8B | Q8 | ~9 GB | 2 GPUs |
| Llama 3 70B | Q4_K_M | ~40 GB | all 4 GPUs |

Ollama distributes model layers across multiple GPUs automatically.
