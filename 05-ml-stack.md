# 05 — ML Stack

## Compatibility Notice

> ⚠️ **Maxwell version ceiling**: NVIDIA dropped Maxwell (sm_50, sm_52) from CUDA 13.0, and PyTorch dropped it from builds targeting CUDA 12.8+. The versions pinned below are the **tested ceiling** for this hardware. Do not upgrade CUDA or PyTorch beyond these pins without verifying Maxwell support first.

| Component | Pinned version | Reason |
|-----------|---------------|--------|
| CUDA Toolkit | 12.6 | Last with full Maxwell library support |
| PyTorch | cu126 build | Last build series with sm_50 (Maxwell) wheels |
| Ollama | latest | Builds against system CUDA; fine with 12.6 |

---

## Python Environment

Ubuntu 24.04 ships Python 3.12. Use virtual environments to isolate project dependencies.

```bash
sudo apt install -y python3-pip python3-venv python3-dev
```

Create and activate the base ML environment:

```bash
python3 -m venv ~/envs/ml
source ~/envs/ml/bin/activate
pip install --upgrade pip wheel setuptools
```

> **All remaining steps in this document assume the `ml` environment is active.** Your prompt will show `(ml)` when it is. If you open a new shell session, reactivate before running any `pip`, `python3`, or `jupyter` commands:
> ```bash
> source ~/envs/ml/bin/activate
> ```
> Ollama and Open WebUI are the only exceptions — they are system-level and do not use the venv.

---

## PyTorch with CUDA 12.6

Install the PyTorch build targeting CUDA 12.6, which includes sm_50 (Maxwell) wheels:

```bash
pip install torch torchvision torchaudio \
    --index-url https://download.pytorch.org/whl/cu126
```

> **Do not use cu128 or later index URLs** — Maxwell support was removed from those builds.

Verify:

```bash
python3 -c "
import torch
print('PyTorch:', torch.__version__)
print('CUDA available:', torch.cuda.is_available())
print('Architectures:', torch.cuda.get_arch_list())
for i in range(torch.cuda.device_count()):
    print(f'  GPU {i}:', torch.cuda.get_device_name(i))
"
```

The `get_arch_list()` output must include `sm_50`. PyTorch compiles one set of Maxwell kernels targeting sm_50 — these run on any compute capability 5.x device, including the M10's sm_52, via binary compatibility within the same major architecture. A separate sm_52 entry will not appear and is not required.

Expected output with K2200:
```
PyTorch: 2.x.x+cu126
CUDA available: True
Architectures: ['sm_50', 'sm_60', 'sm_70', 'sm_75', 'sm_80', 'sm_86', 'sm_90']
  GPU 0: Quadro K2200
```

---

## JupyterLab

```bash
pip install jupyterlab ipywidgets
```

### Configure JupyterLab as a System Service

Generate a config file:

```bash
jupyter lab --generate-config
```

Set a password:

```bash
jupyter lab password
```

Create a systemd service so JupyterLab starts on boot. The `ExecStart` path points directly into the venv so the service runs with the correct Python and packages regardless of the user's active shell environment:

```bash
sudo nano /etc/systemd/system/jupyterlab.service
```

```ini
[Unit]
Description=JupyterLab
After=network.target

[Service]
Type=simple
User=YOUR_USERNAME
WorkingDirectory=/home/YOUR_USERNAME
ExecStart=/home/YOUR_USERNAME/envs/ml/bin/jupyter lab \
    --no-browser \
    --ip=0.0.0.0 \
    --port=8888
Restart=on-failure

[Install]
WantedBy=multi-user.target
```

```bash
sudo systemctl enable --now jupyterlab
```

Access JupyterLab from any machine on your LAN at `http://WORKSTATION_IP:8888`.

---

## Ollama (LLM Serving)

Ollama is a system-level binary installed to `/usr/local/bin` and does **not** interact with the `ml` venv in any way. The venv only affects `python3`, `pip`, and executables installed within it — `ollama` is resolved from the system path regardless of whether the venv is active. There is no need to call `deactivate` before using Ollama.

```bash
curl -fsSL https://ollama.com/install.sh | sh
```

Ollama installs as a systemd service automatically. Verify it sees the GPU:

```bash
ollama run llama3.2   # pulls and runs a 3B model as a smoke test
```

```bash
nvidia-smi dmon -s u  # watch GPU utilisation while a model runs
```

### Useful Ollama Commands

```bash
ollama list           # list downloaded models
ollama pull mistral   # download a model
ollama rm mistral     # remove a model
```

The Ollama API is available at `http://WORKSTATION_IP:11434` for use with Open WebUI or any OpenAI-compatible client.

---

## Optional: Open WebUI (Chat Interface)

Open WebUI runs in Docker and does not use the `ml` venv. No need to call `deactivate` before running Docker commands.

```bash
docker run -d \
    --network=host \
    --gpus all \
    -v open-webui:/app/backend/data \
    --name open-webui \
    --restart always \
    ghcr.io/open-webui/open-webui:main
```

Requires Docker with NVIDIA Container Toolkit — see below.

### Install NVIDIA Container Toolkit

```bash
curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | \
    sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg

curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list | \
    sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
    sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list

sudo apt update && sudo apt install -y nvidia-container-toolkit
sudo nvidia-ctk runtime configure --runtime=docker
sudo systemctl restart docker
```

Continue to [06-adding-tesla-m10.md](06-adding-tesla-m10.md) once the PSU is upgraded.
