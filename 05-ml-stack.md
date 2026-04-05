# 05 — ML Stack

## Python Environment

Ubuntu 24.04 ships Python 3.12. Use virtual environments to isolate project dependencies.

```bash
sudo apt install -y python3-pip python3-venv python3-dev
```

Create a base ML environment:

```bash
python3 -m venv ~/envs/ml
source ~/envs/ml/bin/activate
pip install --upgrade pip wheel setuptools
```

Add activation to `.bashrc` or activate per session.

---

## PyTorch with CUDA

Install the PyTorch build that matches CUDA 12.1 and includes sm_52 (Maxwell) support:

```bash
pip install torch==2.1.2 torchvision==0.16.2 torchaudio==2.1.2 \
    --index-url https://download.pytorch.org/whl/cu121
```

> **Version pin**: PyTorch 2.1.x is the last confirmed release with sm_52 (Maxwell) in the pre-built wheels. Newer versions may require building from source. Check [https://pytorch.org/get-started/previous-versions/](https://pytorch.org/get-started/previous-versions/) before upgrading.

Verify:

```bash
python3 -c "
import torch
print('PyTorch:', torch.__version__)
print('CUDA available:', torch.cuda.is_available())
print('Device count:', torch.cuda.device_count())
for i in range(torch.cuda.device_count()):
    print(f'  GPU {i}:', torch.cuda.get_device_name(i))
"
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

Create a systemd service so JupyterLab starts on boot:

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

Ollama uses llama.cpp as its backend and auto-detects CUDA GPUs.

```bash
curl -fsSL https://ollama.com/install.sh | sh
```

Ollama installs as a systemd service automatically. Verify it sees the GPU:

```bash
ollama serve &      # if not already running as service
ollama run llama3.2 # pulls and runs a 3B model as a smoke test
```

Check which GPU Ollama is using:

```bash
nvidia-smi dmon -s u    # watch GPU utilisation while a model runs
```

### Useful Ollama Commands

```bash
ollama list             # list downloaded models
ollama pull mistral     # download a model
ollama rm mistral       # remove a model
```

The Ollama API is available at `http://WORKSTATION_IP:11434` for use with Open WebUI or any OpenAI-compatible client.

---

## Optional: Open WebUI (Chat Interface)

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
