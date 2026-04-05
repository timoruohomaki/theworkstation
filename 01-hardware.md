# 01 — Hardware Setup

## Power Supply Upgrade

The stock HP Z240 400 W PSU is **not sufficient** for the Tesla M10 (225 W TDP). Three beeps at POST typically indicates a power fault.

> **Before installing the Tesla M10**, upgrade to a 750 W ATX PSU.

### PSU Compatibility Notes

The HP Z240 Tower uses a **standard 24-pin ATX motherboard connector**, so off-the-shelf ATX PSUs fit without adapters. Verified compatible form factor: standard ATX. Recommended brands with good Z240 reports: Seasonic, be quiet!, Corsair.

The Tesla M10 requires **two 8-pin PCIe power connectors**. Confirm your new PSU has these before purchasing.

### PSU Budget Checklist

- [ ] ≥ 750 W rated output
- [ ] One × 8-pin (or 6+2-pin) PCIe power cable (one is all the M10 needs)
- [ ] Standard ATX 24-pin motherboard connector
- [ ] 80 PLUS Gold or better (efficiency matters at sustained compute load)

---

## Slot Assignment

The HP Z240 Tower has two PCIe x16 mechanical slots. Assign as follows:

| Slot | Card | Reason |
|------|------|--------|
| PCIe x16 (primary, CPU-connected) | Tesla M10 | Full bandwidth for compute |
| PCIe x4 or x1 (secondary) | Asus GT1030 | Display only; low bandwidth sufficient |

The GT1030 is a Pascal card and will handle all display output, keeping the M10 dedicated to CUDA compute. The Xeon E3 does **not** provide integrated graphics, so a display adapter is mandatory.

---

## Physical Installation Order

Install components in this order to avoid unnecessary disassembly:

1. Upgrade PSU
2. Seat NVMe drive in M.2 slot
3. Install GT1030 in secondary PCIe slot
4. Install RAM (fill channels symmetrically for dual-channel)
5. Boot and complete OS installation *(see [02-ubuntu-install.md](02-ubuntu-install.md))*
6. Install and validate GT1030 drivers
7. Install Tesla M10 after OS and drivers are confirmed working *(see [06-adding-tesla-m10.md](06-adding-tesla-m10.md))*

---

## BIOS Settings

Enter BIOS with **F10** at POST. Recommended settings:

| Setting | Value |
|---------|-------|
| Primary Display | PCIe (GT1030 slot) |
| IOMMU / VT-d | Enabled (needed if you later want passthrough) |
| Above 4G Decoding | Enabled |
| Secure Boot | Disabled |
| Fast Boot | Disabled |

Save and exit before proceeding to OS installation.
