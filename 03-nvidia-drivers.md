# 03 — Display Driver and NVIDIA Setup

At this stage only the **GT1030** is installed. The Tesla M10 is added in [06-adding-tesla-m10.md](06-adding-tesla-m10.md).

## Install NVIDIA Driver

Use Ubuntu's package manager for the recommended production driver. Driver 535.x supports both Pascal (GT1030) and Maxwell (Tesla M10).

```bash
sudo apt install -y ubuntu-drivers-common
ubuntu-drivers devices          # confirm driver recommendation
sudo apt install -y nvidia-driver-535
sudo reboot
```

---

## Verify GT1030 is Detected

After reboot:

```bash
nvidia-smi
```

Expected output (GT1030 only at this stage):

```
+-----------------------------------------------------------------------------+
| NVIDIA-SMI 535.x    Driver Version: 535.x    CUDA Version: 12.x            |
|-------------------------------+----------------------+----------------------+
| GPU  Name        Persistence-M| Bus-Id        Disp.A | Volatile Uncorr. ECC |
|   0  NVIDIA GeForce GT 1030  |  00000000:01:00.0 On |                  N/A |
+-----------------------------------------------------------------------------+
```

---

## Enable Persistence Mode

Persistence mode keeps the driver loaded between jobs, reducing startup latency. Create a systemd service:

```bash
sudo nano /etc/systemd/system/nvidia-persistenced.service
```

```ini
[Unit]
Description=NVIDIA Persistence Daemon
After=network.target

[Service]
Type=forking
ExecStart=/usr/bin/nvidia-persistenced --user root
ExecStopPost=/bin/rm -rf /var/run/nvidia-persistenced

[Install]
WantedBy=multi-user.target
```

```bash
sudo systemctl enable --now nvidia-persistenced
```

---

## Configure X11 for Headless Operation

The GT1030 drives the display but the server runs headless for day-to-day use. Install a minimal display server so CUDA context creation works correctly with the GT1030 as primary:

```bash
sudo apt install -y xorg
```

Generate a base config:

```bash
sudo nvidia-xconfig --no-composite --allow-empty-initial-configuration
```

This creates `/etc/X11/xorg.conf` but typically without a `BusID` entry. Add it manually so X11 binds to the GT1030 specifically, not whichever GPU it enumerates first.

Find the GT1030 PCI address:

```bash
lspci | grep -i nvidia
```

Example output:
```
01:00.0 VGA compatible controller: NVIDIA Corporation GP108 [GeForce GT 1030]
02:00.0 3D controller: NVIDIA Corporation GM204GL [Tesla M10]
```

The GT1030 address here is `01:00.0`. Convert it to xorg format (`PCI:1:0:0`) and insert it into the `Device` section of `/etc/X11/xorg.conf`:

```bash
sudo nano /etc/X11/xorg.conf
```

```
Section "Device"
    Identifier     "Device0"
    Driver         "nvidia"
    VendorName     "NVIDIA Corporation"
    BusID          "PCI:1:0:0"
EndSection
```

Replace `PCI:1:0:0` with the value matching your GT1030's address — the format converts `BB:DD.F` from `lspci` to `PCI:BB:DD:F`.

---

## Verify CUDA Context

```bash
# Quick sanity check — should report CUDA capability
nvidia-smi -q | grep -E "CUDA|Compute"
```

Continue to [04-cuda-toolkit.md](04-cuda-toolkit.md).
