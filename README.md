# i915-sriov-installer

One-click Intel i915 SR-IOV vGPU driver installer for Ubuntu VPS instances.

## Background

Modern Intel CPUs with Xe integrated graphics support **SR-IOV** (Single Root I/O Virtualization), allowing a single physical GPU to be partitioned into multiple virtual GPUs (vGPUs) and assigned to virtual machines. This is critical for VPS providers who allocate GPU resources — typically up to **7 vGPUs per host** — to tenants for hardware-accelerated video encoding/decoding and compute workloads.

However, tenants who manually install or misconfigure GPU drivers inside their VMs risk **addressing the host GPU directly**, which can cause the host machine to **lock up or crash**, affecting all co-located VMs. This installer eliminates that risk by providing a pre-validated, automated deployment path.

## Requirements

| Requirement | Detail |
|---|---|
| **OS** | Ubuntu 24.04 (or other APT-based distributions) |
| **Kernel** | Linux 6.8 – 6.19 |
| **Privileges** | Root (`sudo`) |
| **Network** | Internet access (for package installation and source retrieval) |

## Quick Start

```bash
sudo bash -c "$(curl -fsSL https://raw.githubusercontent.com/GEELINX-LTD/i915-sriov-installer/main/installer.sh)"
```

> [!NOTE]
> Replace the URL above with your actual repository URL if different.

## What It Does

The installer performs the following steps automatically:

1. **Kernel Detection** — Identifies the running kernel version and selects the appropriate driver branch.
2. **Dependency Installation** — Installs build tools, DKMS, kernel headers, and Intel media packages (`intel-media-va-driver-non-free`, `vainfo`, `intel-gpu-tools`, `ffmpeg`).
3. **Cleanup** — Removes any previously installed `i915-sriov-dkms` modules to avoid conflicts.
4. **Source Retrieval** — Clones the [i915-sriov-dkms](https://github.com/strongtz/i915-sriov-dkms) repository at the matched branch.
5. **DKMS Build & Install** — Registers, compiles, and installs the kernel module via DKMS.
6. **Initramfs Rebuild** — Updates the boot image to include the new driver.
7. **Reboot Prompt** — Offers to reboot the system to activate the driver.

### Kernel Branch Mapping

| Kernel Range | Driver Branch |
|---|---|
| 6.8 – 6.11 | `2025.07.22` |
| 6.12 – 6.19 | `2026.02.09` |

## Post-Installation Verification

After rebooting, verify that the driver is active:

```bash
# Check VA-API codec support
vainfo

# Monitor GPU utilization in real time
intel_gpu_top
```

## Log File

All build output is written to `/tmp/vgpu_deploy.log`. If the installer encounters an error, check this file for details.

## License

[MIT](LICENSE)
