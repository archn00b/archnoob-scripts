# ArchN00B GPU Driver

An automated **NVIDIA GPU driver detection and installation tool for Arch Linux**.

`driver-detect.sh` identifies the NVIDIA GPU hardware, determines its architecture, selects the appropriate NVIDIA driver branch, and installs the required packages.

The goal is simple:

> **Detect the hardware. Choose the correct driver. Install it safely. Verify it.**

---

## 🚀 Features

* 🔍 Automatic NVIDIA GPU detection
* 🧩 Hardware-family detection
* 🏗️ GPU architecture detection
* 🎯 Automatic driver-branch selection
* 📦 Automatic driver package selection
* 🐧 Arch Linux focused
* 🔧 DKMS support
* 🧠 Automatic kernel detection
* 📋 Automatic kernel-header detection
* 🔀 Multilib detection
* 🖥️ NVIDIA kernel-module detection
* 🆕 `nouveau` detection
* 🔐 Secure Boot / kernel-lockdown detection
* 🧰 Initramfs detection
* 🔄 Automatic initramfs rebuilding
* 💾 Configuration backups
* 📝 Installation logging
* 🔒 Lock-file protection
* 🧪 Dry-run support
* 🔎 Detection-only mode
* ✅ Post-install verification
* 🗑️ NVIDIA driver removal
* 🏗️ AUR support for legacy NVIDIA drivers
* ⚙️ Non-interactive installation mode

---

# 📁 Repository

**GitHub Repository**

[github.com/archn00b/GPU-Driver](https://github.com/archn00b/GPU-Driver?utm_source=chatgpt.com)

Repository name:

```text
GPU-Driver
```

Main script:

```text
driver-detect.sh
```

---

# 🖥️ How It Works

The installer does not simply look for a GPU marketing name.

Instead, it attempts to determine the underlying NVIDIA hardware family and architecture.

For example, a GTX 1080 Ti can be identified as:

```text
GTX 1080 Ti
      ↓
    GP102
      ↓
   Pascal
      ↓
  580xx Legacy
```

The driver selection is therefore based on the GPU's hardware generation rather than requiring a hardcoded check for:

```text
"GTX 1080 Ti"
```

---

# 🔍 Example Detection

Running:

```bash
sudo ./driver-detect.sh --detect
```

on a Pascal-based NVIDIA GPU may produce:

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

The important part is that the user does not need to manually tell the script what GPU they have.

The script determines the hardware and selects the driver branch automatically.

---

# 📦 Installation

Clone the repository:

```bash
git clone https://github.com/archn00b/GPU-Driver.git
```

Enter the repository:

```bash
cd GPU-Driver
```

Make the script executable:

```bash
chmod +x driver-detect.sh
```

---

# 🔎 Detect GPU

Before installing anything, you can run the detection process:

```bash
sudo ./driver-detect.sh --detect
```

This displays the detected:

* GPU
* PCI device
* Hardware family
* Architecture
* Driver branch
* Driver type
* Kernel package
* Utility package
* Multilib status

Detection mode does **not** install the NVIDIA driver.

---

# 🚀 Install NVIDIA Driver

Once you are satisfied with the detection results:

```bash
sudo ./driver-detect.sh --install
```

The installer will automatically determine the appropriate driver branch and install the required packages.

---

# ⚡ Automatic Installation

For installations where you do not want confirmation prompts:

```bash
sudo ./driver-detect.sh --install --yes
```

This is useful for automated Arch Linux installation scripts
