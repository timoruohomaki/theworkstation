# 02 — Ubuntu Server Installation

## Download

Get the latest Ubuntu Server 24.04 LTS ISO from:
```
https://ubuntu.com/download/server
```

Write to a USB stick (≥ 8 GB):
```bash
# On Linux/macOS — replace sdX with your USB device
sudo dd if=ubuntu-24.04-live-server-amd64.iso of=/dev/sdX bs=4M status=progress
sync
```
On Windows use [Rufus](https://rufus.ie) in DD image mode.

---

## Installation Options

Boot from USB (press **F9** on Z240 for boot menu).

In the Ubuntu installer, select:

| Option | Choice |
|--------|--------|
| Installation type | Ubuntu Server (minimised) |
| Storage | Custom — use full NVMe for single partition + EFI |
| OpenSSH server | ✅ Install |
| Featured snaps | None (install packages manually) |

### Suggested Partition Layout

| Partition | Size | Type | Mount |
|-----------|------|------|-------|
| EFI | 512 MB | FAT32 | /boot/efi |
| Root | Remainder | ext4 | / |

No swap partition — use a swapfile post-install if needed. Ubuntu will create one automatically.

---

## First Boot Configuration

After first login, update the system:

```bash
sudo apt update && sudo apt upgrade -y
sudo apt install -y \
    build-essential \
    curl \
    git \
    htop \
    nvme-cli \
    net-tools \
    unzip \
    wget
```

### Set a Static IP (recommended for JupyterLab access)

Find your interface name:
```bash
ip link show
```

Edit Netplan config (file name will vary):
```bash
sudo nano /etc/netplan/00-installer-config.yaml
```

```yaml
network:
  version: 2
  ethernets:
    eno1:                        # replace with your interface name
      dhcp4: false
      addresses:
        - 192.168.1.50/24        # choose a free address on your LAN
      routes:
        - to: default
          via: 192.168.1.1
      nameservers:
        addresses: [8.8.8.8, 1.1.1.1]
```

```bash
sudo netplan apply
```

---

## Disable Nouveau Driver

NVIDIA's open-source Nouveau driver conflicts with the proprietary CUDA driver. Blacklist it before installing NVIDIA drivers:

```bash
echo "blacklist nouveau" | sudo tee /etc/modprobe.d/blacklist-nouveau.conf
echo "options nouveau modeset=0" | sudo tee -a /etc/modprobe.d/blacklist-nouveau.conf
sudo update-initramfs -u
sudo reboot
```

Continue to [03-nvidia-drivers.md](03-nvidia-drivers.md).
