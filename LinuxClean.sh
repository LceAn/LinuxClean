#!/bin/bash

# Linux 系统清理脚本

# ===============================
# 功能：
# 1. 显示系统信息
# 2. 清理旧的内核包和残留的配置文件
# 3. 清理 /tmp 目录下的临时文件
# 4. 清理 APT 缓存目录 /var/cache/apt/archives
# 5. 清理用户缓存目录 ~/.cache
# 6. 清理 systemd 日志 /var/log/journal
# ===============================

# 检查是否以 root 身份运行
if [ "$EUID" -ne 0 ]; then
    echo "请使用 sudo 或以 root 身份运行此脚本。"
    exit 1
fi

echo "=============================="
echo "        Linux 系统清理脚本       "
echo "=============================="

# 1. 显示系统信息
echo ""
echo "系统信息："

# 获取当前 Linux 发行版
if [ -f /etc/os-release ]; then
    . /etc/os-release
    distro=$NAME
else
    distro=$(uname -s)
fi
echo "操作系统：$distro"

# 获取登录的用户名
username=$(logname)
echo "登录用户名：$username"

# 获取 CPU 数量
cpu_count=$(nproc)
echo "CPU 数量：$cpu_count"

# 获取内存大小和使用率
total_mem=$(free -h | awk '/Mem:/ {print $2}')
used_mem=$(free -h | awk '/Mem:/ {print $3}')
mem_usage=$(free | awk '/Mem:/ {printf("%.2f"), $3/$2 * 100}')
echo "内存大小：$total_mem"
echo "已用内存：$used_mem ($mem_usage%)"

# 获取硬盘大小和使用率
disk_total=$(df -h / | awk 'NR==2 {print $2}')
disk_used=$(df -h / | awk 'NR==2 {print $3}')
disk_usage=$(df -h / | awk 'NR==2 {print $5}')
echo "硬盘总容量：$disk_total"
echo "已用硬盘：$disk_used ($disk_usage)"

echo "=============================="

# 2. 清理旧的内核包和残留的配置文件
echo ""
echo "步骤 1：清理旧的内核包和残留的配置文件"

# 获取当前正在运行的内核版本
current_kernel=$(uname -r)
echo "当前正在运行的内核版本：$current_kernel"

# 获取已安装的内核包列表
installed_kernels=$(dpkg --list | grep 'linux-image-[0-9]' | awk '/^ii/{print $2}')
echo "已安装的内核包："
echo "$installed_kernels"

# 初始化要移除的内核包列表
remove_kernels=()

# 筛选需要移除的旧内核包
for kernel in $installed_kernels; do
    if [[ "$kernel" != *"$current_kernel"* ]]; then
        remove_kernels+=("$kernel")
    fi
done

# 显示将要移除的内核包
if [ ${#remove_kernels[@]} -eq 0 ]; then
    echo "没有需要移除的旧内核。"
else
    echo "将要移除的旧内核包："
    for kernel in "${remove_kernels[@]}"; do
        echo "$kernel"
    done

    # 提示用户确认
    read -p "是否确认移除以上内核包？[y/N]: " confirm
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        echo "正在移除旧内核包..."
        apt remove --purge -y "${remove_kernels[@]}"

        echo "自动清理不需要的依赖项..."
        apt autoremove --purge -y

        echo "更新 GRUB 引导菜单..."
        update-grub

        echo "旧内核包已成功移除。"
    else
        echo "已跳过旧内核包的清理。"
    fi
fi

# 清理残留的配置文件
echo "正在清理残留的配置文件..."
dpkg -l | awk '/^rc/{print $2}' | xargs dpkg --purge
echo "残留的配置文件已清理。"

# 3. 清理 /tmp 目录下的临时文件
echo ""
echo "步骤 2：清理 /tmp 目录下的临时文件"

# 提示用户确认
read -p "是否清理 /tmp 目录下的所有文件？[y/N]: " confirm_tmp
if [[ "$confirm_tmp" =~ ^[Yy]$ ]]; then
    echo "正在清理 /tmp 目录..."
    rm -rf /tmp/*
    echo "/tmp 目录已清理。"
else
    echo "已跳过 /tmp 目录的清理。"
fi

# 4. 清理 APT 缓存目录 /var/cache/apt/archives
echo ""
echo "步骤 3：清理 APT 缓存目录 /var/cache/apt/archives"

# 显示当前缓存占用空间
apt_cache_size=$(du -sh /var/cache/apt/archives | awk '{print $1}')
echo "APT 缓存当前占用空间：$apt_cache_size"

# 提示用户确认
read -p "是否清理 APT 缓存？这将删除已下载的包文件。[y/N]: " confirm_apt
if [[ "$confirm_apt" =~ ^[Yy]$ ]]; then
    echo "正在清理 APT 缓存..."
    apt clean
    echo "APT 缓存已清理。"
else
    echo "已跳过 APT 缓存的清理。"
fi

# 5. 清理用户缓存目录 ~/.cache
echo ""
echo "步骤 4：清理用户缓存目录 ~/.cache"

# 获取用户的主目录
user_home=$(eval echo "~$SUDO_USER")

# 显示当前缓存占用空间
user_cache_size=$(du -sh "$user_home/.cache" 2>/dev/null | awk '{print $1}')
echo "用户缓存目录当前占用空间：$user_cache_size"

# 提示用户确认
read -p "是否清理用户缓存目录 ~/.cache？[y/N]: " confirm_user_cache
if [[ "$confirm_user_cache" =~ ^[Yy]$ ]]; then
    echo "正在清理用户缓存目录..."
    rm -rf "$user_home/.cache/*"
    echo "用户缓存目录已清理。"
else
    echo "已跳过用户缓存目录的清理。"
fi

# 6. 清理 systemd 日志 /var/log/journal
echo ""
echo "步骤 5：清理 systemd 日志 /var/log/journal"

# 显示当前日志占用空间
journal_size=$(du -sh /var/log/journal 2>/dev/null | awk '{print $1}')
echo "systemd 日志当前占用空间：$journal_size"

if [ -d "/var/log/journal" ]; then
    # 提示用户确认
    read -p "是否清理 systemd 日志？[y/N]: " confirm_journal
    if [[ "$confirm_journal" =~ ^[Yy]$ ]]; then
        echo "请输入要保留的日志大小（例如：100M，1G）："
        read -p "保留大小： " journal_limit

        echo "正在清理 systemd 日志，保留大小为 $journal_limit..."
        journalctl --vacuum-size="$journal_limit"

        echo "systemd 日志已清理。"
    else
        echo "已跳过 systemd 日志的清理。"
    fi
else
    echo "未找到 /var/log/journal 目录，可能未启用持久化日志。"
fi

echo ""
echo "系统清理完成！"
echo "=============================="
