# ArchN00B NVIDIA Driver Installer

A hardware-aware NVIDIA driver installer for **Arch Linux**.

The goal of this project is simple:

> **Detect the NVIDIA GPU automatically, determine the appropriate driver branch, and install the correct driver without requiring the user to know their GPU architecture.**

Instead of relying on GPU marketing names such as `GTX 1080 Ti`, the installer identifies NVIDIA hardware families such as `GP102`, determines the GPU architecture, and selects the appropriate driver branch.

---

## Features

* Automatic NVIDIA GPU detection
* Hardware-family detection
* NVIDIA architecture detection
* Automatic driver-branch selection
* Supports current NVIDIA drivers
* Supports legacy NVIDIA driver branches
* DKMS support
* Automatic kernel detection
* Automatic kernel-header detection
* Multilib detection
* `nouveau` detection
* NVIDIA module verification
* DRM/KMS verification
* `nvidia-smi` verification
* Initramfs detection and rebuilding
* Secure Boot / kernel lockdown detection
* Existing NVIDIA package detection
* Automatic backup support
* Logging
* Lock file protection
* Dry-run mode
* Detection-only mode
* Driver removal mode
* Optional non-interactive installation
* AUR support for legacy driver branches

---

## Why Hardware Detection?

A common approach to NVIDIA driver installation is to check the GPU's model name:

```bash
if [[ "$GPU" == *"GTX 1080 Ti"* ]]; then
    install_driver
fi
```

That works for individual GPUs, but it doesn't scale very well.

This installer instead works toward identifying the underlying NVIDIA hardware family.

For example:

```text
GTX 1080 Ti
      ↓
    GP102
      ↓
   Pascal
      ↓
  580xx legacy
```

This makes the detection logic much more useful across multiple NVIDIA GPU models.

---

## Example Detection

On an NVIDIA GTX 1080 Ti, the installer can report:

```text
GPU:
  Model            : GP102
  PCI device       : 1b06
  Hardware family  : GP102
  Architecture     : Pascal

Driver:
  Branch           : 580xx
  Type             : legacy
  Kernel package   : nvidia-580xx-dkms
  Utilities        : nvidia-580xx-utils
  Multilib         : disabled
```

The important part is that the installer doesn't need to be told:

> "I have a GTX 1080 Ti."

It determines the hardware family and architecture automatically.

---

# Installation

Clone the repository:

```bash
git clone https://github.com/ArchN00b/archn00b-nvidia.git
cd archn00b-nvidia
```

Make the script executable:

```bash
chmod +x archn00b-nvidia.sh
```

Run hardware detection:

```bash
sudo ./archn00b-nvidia.sh --detect
```

If the detected hardware and driver branch are correct, run the installer:

```bash
sudo ./archn00b-nvidia.sh --install
```

For completely non-interactive installation:

```bash
sudo ./archn00b-nvidia.sh --install --yes
```

---

# Commands

## Detect

Detect the NVIDIA GPU and determine the recommended driver:

```bash
sudo ./archn00b-nvidia.sh --detect
```

This mode **does not install anything**.

---

## Install

Automatically detect the GPU and install the appropriate driver:

```bash
sudo ./archn00b-nvidia.sh --install
```

---

## Install Without Prompts

Useful for automated installations:

```bash
sudo ./archn00b-nvidia.sh --install --yes
```

---

## Dry Run

Preview what the installer would do without performing the installation:

```bash
sudo ./archn00b-nvidia.sh --install --dry-run
```

---

## Verify

Check the current NVIDIA installation:

```bash
sudo ./archn00b-nvidia.sh --verify
```

Verification can check things such as:

* NVIDIA kernel modules
* Driver binding
* DRM/KMS
* `nvidia-smi`
* Installed NVIDIA packages

---

## Remove

Remove NVIDIA driver packages installed on the system:

```bash
sudo ./archn00b-nvidia.sh --remove
```

**Review the packages presented by the script before confirming removal.**

---

## Help

```bash
./archn00b-nvidia.sh --help
```

---

# Driver Detection

The installer maps NVIDIA hardware families to the appropriate driver branch.

The general detection logic is:

```text
NVIDIA GPU
    │
    ▼
Hardware Family
    │
    ├── GB → Blackwell
    ├── AD → Ada Lovelace
    ├── GA → Ampere
    ├── TU → Turing
    ├── GV → Volta
    ├── GP → Pascal
    ├── GM → Maxwell
    ├── GK → Kepler
    ├── GF → Fermi
    └── Older families
             │
             ▼
       Legacy branch
```

The exact package selected depends on the detected architecture and current Arch Linux packaging.

---

# Current / Legacy Drivers

Modern NVIDIA GPUs use the current NVIDIA driver packages available from the Arch Linux repositories.

Older GPUs require legacy driver branches.

For example:

```text
Pascal
   ↓
580xx
   ↓
nvidia-580xx-dkms
nvidia-580xx-utils
```

The installer handles this automatically when the hardware can be identified.

---

# DKMS

Legacy NVIDIA drivers are installed using DKMS.

DKMS allows the NVIDIA kernel module to be built for the installed kernel(s).

The installer checks for installed kernels and their corresponding headers before building the driver.

This is particularly useful for systems running multiple kernels.

For example:

```text
linux
linux-lts
```

can both be supported when the appropriate headers are installed.

---

# Multilib

The installer detects whether the Arch Linux `multilib` repository is enabled.

If multilib is enabled, the corresponding 32-bit NVIDIA utilities can be installed.

For example:

```text
lib32-nvidia-utils
```

or the appropriate legacy equivalent.

If multilib is disabled, the installer does not attempt to install 32-bit NVIDIA packages.

---

# Nouveau

The installer checks whether the open-source `nouveau` driver is present or active.

The NVIDIA packages provided by Arch Linux handle the appropriate NVIDIA driver configuration.

The installer does **not** blindly overwrite unrelated graphics configuration files.

---

# Initramfs

The installer detects the initramfs system being used.

Supported systems may include:

* `mkinitcpio`
* `dracut`
* `booster`

After driver installation, the appropriate initramfs is rebuilt when necessary.

---

# Safety

The installer is designed to avoid making unnecessary system changes.

It includes:

* Root privilege checks
* Arch Linux detection
* Command availability checks
* Existing package detection
* Configuration backups
* Installation logging
* Lock-file protection
* Hardware detection before installation
* Driver verification after installation

Backups are stored under:

```text
/var/backups/archn00b-nvidia
```

Logs are stored under:

```text
/var/log/archn00b-nvidia.log
```

---

# AUR and Legacy Drivers

Some older NVIDIA driver branches are no longer available directly from the official Arch Linux repositories.

When a legacy driver requires an AUR package, the installer can use:

1. `paru`
2. `yay`
3. A temporary unprivileged build user

The NVIDIA driver is **not** installed using NVIDIA's upstream `.run` installer.

---

# Requirements

A standard Arch Linux installation with:

* `pacman`
* `systemd`
* Internet access
* Root privileges

The installer can install required supporting packages when needed.

For legacy AUR packages, the system also needs the ability to build Arch packages.

---

# Important Notes

This project is intended for **Arch Linux**.

It is not intended for:

* Ubuntu
* Debian
* Fedora
* openSUSE
* Linux Mint
* Manjaro
* Other distributions

Distribution-specific NVIDIA packaging differs significantly, so this script intentionally focuses on Arch Linux.

---

# Supported Hardware

The installer is designed around NVIDIA GPU hardware families rather than individual GPU marketing names.

Examples include:

* Blackwell
* Ada Lovelace
* Ampere
* Turing
* Volta
* Pascal
* Maxwell
* Kepler
* Fermi
* Older NVIDIA families where supported driver packages are available

If the hardware cannot be confidently identified, the installer should **fail safely rather than guess**.

---

# Example Workflow

Fresh Arch Linux installation:

```bash
git clone https://github.com/ArchN00b/archn00b-nvidia.git
cd archn00b-nvidia
chmod +x archn00b-nvidia.sh
```

First detect the GPU:

```bash
sudo ./archn00b-nvidia.sh --detect
```

Example:

```text
GPU:
  Model            : GP102
  PCI device       : 1b06
  Hardware family  : GP102
  Architecture     : Pascal

Driver:
  Branch           : 580xx
  Type             : legacy
  Kernel package   : nvidia-580xx-dkms
  Utilities        : nvidia-580xx-utils
  Multilib         : disabled
```

Then install:

```bash
sudo ./archn00b-nvidia.sh --install
```

Finally verify:

```bash
sudo ./archn00b-nvidia.sh --verify
```

Reboot when instructed:

```bash
sudo reboot
```

After reboot:

```bash
nvidia-smi
```

---

# Philosophy

This project follows a simple philosophy:

> **Detect first. Understand the hardware. Choose the driver. Make the minimum necessary changes. Verify the result.**

The installer should never blindly install a driver simply because it sees an NVIDIA device.

If the hardware cannot be confidently mapped to a supported driver branch, the safest answer is to stop and tell the user.

---

# Disclaimer

This script modifies system packages and graphics drivers.

Although it includes safety checks and backups, **use it at your own risk**.

Always maintain a working recovery method when modifying graphics drivers on a Linux system.

---

# License

Add your preferred license here.

For example:

```text
MIT License
```

See the `LICENSE` file for details.

---

## Author

**ArchN00B**

GitHub:

https://github.com/ArchN00b

---

### Built for Arch Linux

```text
Arch Linux
   +
NVIDIA
   +
Automation
   =
ArchN00B
```




