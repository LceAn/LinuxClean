# 🐧 LinuxClean

> 🔧 One-click Linux system cleaner to free up disk space

[![GitHub license](https://img.shields.io/github/license/LceAn/LinuxClean)](https://github.com/LceAn/LinuxClean/blob/main/LICENSE)
[![GitHub issues](https://img.shields.io/github/issues/LceAn/LinuxClean)](https://github.com/LceAn/LinuxClean/issues)
[![GitHub stars](https://img.shields.io/github/stars/LceAn/LinuxClean)](https://github.com/LceAn/LinuxClean/stargazers)
[![GitHub forks](https://img.shields.io/github/forks/LceAn/LinuxClean)](https://github.com/LceAn/LinuxClean/network)
![GitHub last commit](https://img.shields.io/github/last-commit/LceAn/LinuxClean)
![Shell](https://img.shields.io/badge/Shell-100%25-brightgreen)

---

**🌍 Read this in other languages:** [English](README.md) | [中文](README_zh.md)

---

## 📖 Table of Contents

- [Features](#-features)
- [Quick Start](#-quick-start)
- [Cleanup Modes](#-cleanup-modes)
- [Function Details](#-function-details)
- [Internationalization](#-internationalization)
- [FAQ](#-faq)
- [Changelog](#-changelog)
- [Contributing](#-contributing)

---

## ✨ Features

| Feature | Description | Status |
|---------|-------------|--------|
| 🖥️ System Info | Display OS, CPU, memory, disk usage | ✅ |
| 🗑️ Old Kernel Cleanup | Safely remove old kernels, keep current | ✅ |
| 📁 Temp File Cleanup | Clean /tmp directory | ✅ |
| 📦 APT Cache Cleanup | Clean downloaded package files | ✅ |
| 👤 User Cache Cleanup | Clean ~/.cache directory | ✅ |
| 📋 System Log Cleanup | Clean systemd logs with size limit | ✅ |
| 🎯 Multiple Modes | Quick/Standard/Full/Custom | ✅ |
| 🎨 Color Output | Clear colored terminal output | ✅ |
| ⚠️ Safety Confirmations | Confirm before each operation | ✅ |
| 🌍 i18n Support | Auto-detect language, EN/ZH support | ✅ |

---

## 🚀 Quick Start

### 1️⃣ Download Script

```bash
# Method 1: Git clone
git clone https://github.com/LceAn/LinuxClean.git
cd LinuxClean

# Method 2: Direct download
wget https://raw.githubusercontent.com/LceAn/LinuxClean/main/LinuxClean.sh
```

### 2️⃣ Make Executable

```bash
chmod +x LinuxClean.sh
```

### 3️⃣ Run Script

```bash
# Run with sudo
sudo ./LinuxClean.sh

# Or switch to root user
su -
./LinuxClean.sh

# Specify language
LANG=zh_CN.UTF-8 sudo ./LinuxClean.sh  # Chinese
LANG=en_US.UTF-8 sudo ./LinuxClean.sh  # English
```

---

## 🌍 Internationalization

The script automatically detects your system language and displays the interface accordingly.

**Supported Languages:**
- 🇺🇸 **English (en)** - Default
- 🇨🇳 **中文 (zh)** - Auto-detected when `LANG=zh_*`

**Manual Language Selection:**

```bash
# Force Chinese
export LANG=zh_CN.UTF-8
sudo ./LinuxClean.sh

# Force English
export LANG=en_US.UTF-8
sudo ./LinuxClean.sh
```

**Test Language Detection:**

```bash
# Run i18n test script
./test-i18n.sh
```

---

## 🎯 Cleanup Modes

### Mode Comparison

| Mode | Cleanup Content | Recommended Scenario | Estimated Space |
|------|----------------|---------------------|-----------------|
| **Quick** | Temp Files + APT Cache | Daily maintenance | 100MB - 1GB |
| **Standard** | Quick + User Cache + Logs | Monthly cleanup | 500MB - 5GB |
| **Full** | Standard + Old Kernels | Quarterly deep clean | 1GB - 10GB+ |
| **Custom** | Choose items | Specific needs | Varies |

### Mode Details

#### 1) Quick Clean
- Clean `/tmp` temporary files
- Clean APT cache

**Best for:** Quick space recovery when disk is full

#### 2) Standard Clean
- Includes all Quick Clean items
- Clean user cache `~/.cache`
- Clean systemd logs

**Best for:** Regular system maintenance

#### 3) Full Clean
- Includes all Standard Clean items
- Clean old kernel packages
- Clean residual config files

**Best for:** After system upgrades, quarterly deep clean

#### 4) Custom Clean
- Choose cleanup items freely
- Flexible configuration

**Best for:** Specific cleanup requirements

---

## 📋 Function Details

### System Information Detection

Auto-displays on startup:
- OS version
- Logged-in username
- CPU cores
- Memory usage
- Disk usage
- System uptime

### Old Kernel Cleanup

**Safety Mechanisms:**
- ✅ Auto-detect current running kernel
- ✅ Keep current kernel
- ✅ User confirmation before deletion
- ✅ Auto-update GRUB
- ✅ Clean residual configs

**Example Output:**
```
Step 1: Clean old kernel packages and residual configs

  Current Kernel: 6.5.0-42-generic
  Installed Kernels: 3
  Will Remove: 2 old kernels
    - linux-image-6.5.0-35-generic
    - linux-image-6.5.0-38-generic
  Confirm removal? [y/N]: y
```

### Temp File Cleanup

Clean all files and empty directories in `/tmp`.

### APT Cache Cleanup

Clean `/var/cache/apt/archives` directory to free up package cache space.

### User Cache Cleanup

Clean current user's `~/.cache` directory, including:
- Browser cache
- Application cache
- Thumbnail cache

### System Log Cleanup

Use `journalctl --vacuum-size` to clean systemd logs:
- Show current log size
- Specify retention size (e.g., 100M, 1G)
- Safe cleanup, won't delete all logs

---

## ❓ FAQ

### Q: Is this script safe?

**A:** Very safe!
- ✅ Confirms before each operation
- ✅ Won't delete currently running kernel
- ✅ Won't delete important system files
- ✅ All operations can be skipped manually

### Q: Will it delete my personal files?

**A:** No!
- Only cleans system cache and temp files
- Won't touch personal files in `/home`
- Won't delete documents, photos, or user data

### Q: How often should I run it?

**A:** Recommended frequency:
- Quick Clean: Weekly
- Standard Clean: Monthly
- Full Clean: Quarterly or after system upgrades

### Q: What if system has issues after cleanup?

**A:** 
1. At least one old kernel is kept (prompted during full clean)
2. User cache cleanup may slow first app launch (cache regenerates)
3. System log cleanup doesn't affect system operation

### Q: Which distributions are supported?

**A:** 
- ✅ Ubuntu and derivatives
- ✅ Debian
- ✅ Linux Mint
- ✅ Kali Linux
- ⚠️ Other distributions (some features may not apply)

### Q: How to cancel an operation?

**A:** 
- Each step can be skipped with `N`
- Press `Ctrl+C` anytime to terminate

---

## 📝 Changelog

### v2.1 - 2026-03-10
- ✨ Added internationalization (i18n) support
- ✨ Auto-detect system language (Chinese/English)
- ✨ Complete bilingual translations
- 🐛 Optimized text output format
- 📖 Added language selection feature

### v2.0 - 2026-03-03
- ✨ Added multiple cleanup modes (Quick/Standard/Full/Custom)
- ✨ Added colored terminal output
- ✨ Added system uptime display
- 🐛 Optimized kernel detection logic
- 🐛 Improved error handling
- 📖 Rewrote README documentation

### v1.1 - 2024-12-28
- 📖 Updated README documentation
- 🐛 Fixed minor issues

### v1.0 - 2024-10-04
- ✨ Initial release
- ✨ Basic cleanup features
- ✨ Interactive operations

---

## 🤝 Contributing

Contributions are welcome!

- 🐛 Found a Bug? [Submit an Issue](https://github.com/LceAn/LinuxClean/issues)
- 💡 Have a feature? [Submit a PR](https://github.com/LceAn/LinuxClean/pulls)
- ⭐ Like this project? Give it a Star!

---

## 📄 License

MIT License © 2024-2026 [LceAn](https://github.com/LceAn)

---

## 🔗 Related Links

- [GitHub Repository](https://github.com/LceAn/LinuxClean)
- [Submit Issue](https://github.com/LceAn/LinuxClean/issues)
- [Author's Profile](https://github.com/LceAn)

---

<p align="center">
  <b>If this helped you, please give a ⭐ Star!</b>
</p>
