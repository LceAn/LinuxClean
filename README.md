# 🐧 LinuxClean

> 🔧 一键清理 Linux 系统垃圾，释放磁盘空间

[![GitHub license](https://img.shields.io/github/license/LceAn/LinuxClean)](https://github.com/LceAn/LinuxClean/blob/main/LICENSE)
[![GitHub issues](https://img.shields.io/github/issues/LceAn/LinuxClean)](https://github.com/LceAn/LinuxClean/issues)
[![GitHub stars](https://img.shields.io/github/stars/LceAn/LinuxClean)](https://github.com/LceAn/LinuxClean/stargazers)
[![GitHub forks](https://img.shields.io/github/forks/LceAn/LinuxClean)](https://github.com/LceAn/LinuxClean/network)
![GitHub last commit](https://img.shields.io/github/last-commit/LceAn/LinuxClean)
![Shell](https://img.shields.io/badge/Shell-100%25-brightgreen)

---

## 📖 目录

- [功能特性](#-功能特性)
- [快速开始](#-快速开始)
- [清理模式](#-清理模式)
- [功能说明](#-功能说明)
- [常见问题](#-常见问题)
- [更新日志](#-更新日志)
- [贡献](#-贡献)

---

## ✨ 功能特性

| 功能 | 描述 | 状态 |
|------|------|------|
| 🖥️ 系统信息检测 | 显示 OS、CPU、内存、硬盘使用情况 | ✅ |
| 🗑️ 旧内核清理 | 安全移除旧内核，保留当前内核 | ✅ |
| 📁 临时文件清理 | 清理 /tmp 目录 | ✅ |
| 📦 APT 缓存清理 | 清理已下载的包文件 | ✅ |
| 👤 用户缓存清理 | 清理 ~/.cache 目录 | ✅ |
| 📋 系统日志清理 | 清理 systemd 日志，可指定保留大小 | ✅ |
| 🎯 多种清理模式 | 快速/标准/完全/自定义 | ✅ |
| 🎨 彩色输出 | 清晰的彩色终端输出 | ✅ |
| ⚠️ 安全确认 | 每步操作前都会确认 | ✅ |

---

## 🚀 快速开始

### 1️⃣ 下载脚本

```bash
# 方式 1：Git 克隆
git clone https://github.com/LceAn/LinuxClean.git
cd LinuxClean

# 方式 2：直接下载
wget https://raw.githubusercontent.com/LceAn/LinuxClean/main/LinuxClean.sh
```

### 2️⃣ 赋予执行权限

```bash
chmod +x LinuxClean.sh
```

### 3️⃣ 运行脚本

```bash
# 使用 sudo 运行
sudo ./LinuxClean.sh

# 或切换到 root 用户后运行
su -
./LinuxClean.sh
```

---

## 🎯 清理模式

### 模式对比

| 模式 | 清理内容 | 推荐场景 | 预计释放 |
|------|---------|---------|---------|
| **快速清理** | 临时文件 + APT 缓存 | 日常维护 | 100MB - 1GB |
| **标准清理** | 快速清理 + 用户缓存 + 日志 | 月度清理 | 500MB - 5GB |
| **完全清理** | 标准清理 + 旧内核 | 季度大扫除 | 1GB - 10GB+ |
| **自定义清理** | 自选清理项目 | 特定需求 | 视选择而定 |

### 模式说明

#### 1) 快速清理
- 清理 `/tmp` 临时文件
- 清理 APT 缓存

**适用场景：** 磁盘空间不足时的快速释放

#### 2) 标准清理
- 包含快速清理所有项目
- 清理用户缓存 `~/.cache`
- 清理 systemd 日志

**适用场景：** 定期系统维护

#### 3) 完全清理
- 包含标准清理所有项目
- 清理旧内核包
- 清理残留配置文件

**适用场景：** 系统升级后、季度大扫除

#### 4) 自定义清理
- 自由选择清理项目
- 灵活配置

**适用场景：** 特定需求的清理

---

## 📋 功能说明

### 系统信息检测

脚本启动时自动显示：
- 操作系统版本
- 登录用户名
- CPU 核心数
- 内存使用情况
- 硬盘使用情况
- 系统运行时间

### 旧内核清理

**安全机制：**
- ✅ 自动检测当前运行内核
- ✅ 保留当前内核
- ✅ 用户确认后才删除
- ✅ 自动更新 GRUB
- ✅ 清理残留配置

**示例输出：**
```
步骤 1：清理旧的内核包和残留配置文件

  当前内核：6.5.0-42-generic
  已安装内核：3 个
  将移除：2 个旧内核
    - linux-image-6.5.0-35-generic
    - linux-image-6.5.0-38-generic
  是否确认移除？[y/N]: y
```

### 临时文件清理

清理 `/tmp` 目录下的所有文件和空目录。

### APT 缓存清理

清理 `/var/cache/apt/archives` 目录，释放已下载包的缓存空间。

### 用户缓存清理

清理当前用户的 `~/.cache` 目录，包括：
- 浏览器缓存
- 应用程序缓存
- 缩略图缓存

### 系统日志清理

使用 `journalctl --vacuum-size` 清理 systemd 日志：
- 显示当前日志占用
- 可指定保留大小（如 100M、1G）
- 安全清理，不会删除所有日志

---

## ❓ 常见问题

### Q: 脚本安全吗？

**A:** 非常安全！
- ✅ 每步操作前都会提示确认
- ✅ 不会删除当前运行的内核
- ✅ 不会删除重要系统文件
- ✅ 所有操作都可手动跳过

### Q: 会删除我的个人文件吗？

**A:** 不会！
- 只清理系统缓存和临时文件
- 不会触碰 `/home` 下的个人文件
- 不会删除文档、图片等用户数据

### Q: 多久运行一次？

**A:** 建议频率：
- 快速清理：每周
- 标准清理：每月
- 完全清理：每季度或系统升级后

### Q: 清理后系统出问题了怎么办？

**A:** 
1. 至少保留一个旧内核（完全清理时会提示）
2. 用户缓存清理后，应用首次启动可能稍慢（会重新生成缓存）
3. 系统日志清理不会影响系统运行

### Q: 支持哪些发行版？

**A:** 
- ✅ Ubuntu 及衍生版
- ✅ Debian
- ✅ Linux Mint
- ✅ Kali Linux
- ⚠️ 其他发行版（部分功能可能不适用）

### Q: 如何取消操作？

**A:** 
- 每个步骤都可以选择 `N` 跳过
- 随时按 `Ctrl+C` 终止脚本

---

## 📝 更新日志

### v2.0 - 2026-03-03
- ✨ 新增多种清理模式（快速/标准/完全/自定义）
- ✨ 新增彩色终端输出
- ✨ 新增系统运行时间显示
- 🐛 优化内核检测逻辑
- 🐛 改进错误处理
- 📖 重写 README 文档

### v1.1 - 2024-12-28
- 📖 更新 README 文档
- 🐛 修复小问题

### v1.0 - 2024-10-04
- ✨ 初始版本发布
- ✨ 基础清理功能
- ✨ 交互式操作

---

## 🤝 贡献

欢迎贡献！

- 🐛 发现 Bug？[提交 Issue](https://github.com/LceAn/LinuxClean/issues)
- 💡 有新功能？[提交 PR](https://github.com/LceAn/LinuxClean/pulls)
- ⭐ 喜欢这个项目？给个 Star 吧！

---

## 📄 许可证

MIT License © 2024-2026 [LceAn](https://github.com/LceAn)

---

## 🔗 相关链接

- [GitHub 仓库](https://github.com/LceAn/LinuxClean)
- [提交 Issue](https://github.com/LceAn/LinuxClean/issues)
- [作者主页](https://github.com/LceAn)

---

<p align="center">
  <b>如果对你有帮助，请给个 ⭐ Star 吧！</b>
</p>
