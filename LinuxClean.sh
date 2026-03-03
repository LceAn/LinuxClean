#!/bin/bash

################################################################################
#
# 脚本名称：LinuxClean - Linux 系统清理工具
# 版本：v2.0
# 作者：LceAn
# 描述：清理 Linux 系统中的临时文件、缓存和旧内核，释放磁盘空间
# 使用方式：sudo ./LinuxClean.sh
#
################################################################################

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 脚本版本
VERSION="2.0"
SCRIPT_NAME="LinuxClean"

# 检查是否以 root 身份运行
check_root() {
    if [ "$EUID" -ne 0 ]; then
        echo -e "${RED}错误：请使用 sudo 或以 root 身份运行此脚本${NC}"
        echo "用法：sudo $0"
        exit 1
    fi
}

# 显示横幅
show_banner() {
    echo -e "${BLUE}"
    echo "╔══════════════════════════════════════════════════════════╗"
    echo "║           LinuxClean - Linux 系统清理工具 v${VERSION}              ║"
    echo "╚══════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

# 显示系统信息
show_system_info() {
    echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}系统信息：${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
    
    # 获取当前 Linux 发行版
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        distro="$NAME $VERSION"
    else
        distro=$(uname -s)
    fi
    echo -e "  操作系统：${GREEN}$distro${NC}"
    
    # 获取登录的用户名
    username=${SUDO_USER:-$(logname)}
    echo -e "  登录用户：${GREEN}$username${NC}"
    
    # 获取 CPU 数量
    cpu_count=$(nproc)
    echo -e "  CPU 核心：${GREEN}$cpu_count${NC}"
    
    # 获取内存大小和使用率
    total_mem=$(free -h | awk '/Mem:/ {print $2}')
    used_mem=$(free -h | awk '/Mem:/ {print $3}')
    mem_percent=$(free | awk '/Mem:/ {printf("%.1f"), $3/$2 * 100}')
    echo -e "  内    存：${GREEN}$total_mem${NC} (已用：${YELLOW}$used_mem ($mem_percent%)${NC})"
    
    # 获取硬盘大小和使用率
    disk_total=$(df -h / | awk 'NR==2 {print $2}')
    disk_used=$(df -h / | awk 'NR==2 {print $3}')
    disk_percent=$(df -h / | awk 'NR==2 {print $5}')
    echo -e "  硬    盘：${GREEN}$disk_total${NC} (已用：${YELLOW}$disk_used ($disk_percent)${NC})"
    
    # 获取系统运行时间
    uptime_info=$(uptime -p 2>/dev/null || uptime | awk -F'up ' '{print $2}' | awk -F',' '{print $1}')
    echo -e "  运行时间：${GREEN}$uptime_info${NC}"
    
    echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
    echo ""
}

# 清理旧内核
clean_old_kernels() {
    echo -e "${YELLOW}步骤 1：清理旧的内核包和残留配置文件${NC}"
    echo ""
    
    # 获取当前正在运行的内核版本
    current_kernel=$(uname -r)
    echo -e "  当前内核：${GREEN}$current_kernel${NC}"
    
    # 获取已安装的内核包列表
    mapfile -t installed_kernels < <(dpkg --list 2>/dev/null | grep 'linux-image-[0-9]' | awk '/^ii/{print $2}')
    
    if [ ${#installed_kernels[@]} -eq 0 ]; then
        echo -e "  ${GREEN}✓ 没有检测到已安装的内核包${NC}"
        return
    fi
    
    echo -e "  已安装内核：${GREEN}${#installed_kernels[@]}${NC} 个"
    
    # 筛选需要移除的旧内核包
    remove_kernels=()
    for kernel in "${installed_kernels[@]}"; do
        if [[ "$kernel" != *"$current_kernel"* ]]; then
            remove_kernels+=("$kernel")
        fi
    done
    
    # 显示将要移除的内核包
    if [ ${#remove_kernels[@]} -eq 0 ]; then
        echo -e "  ${GREEN}✓ 没有需要移除的旧内核${NC}"
    else
        echo -e "  将移除：${YELLOW}${#remove_kernels[@]}${NC} 个旧内核"
        for kernel in "${remove_kernels[@]}"; do
            echo -e "    - $kernel"
        done
        
        # 提示用户确认
        read -p "  是否确认移除？[y/N]: " confirm
        if [[ "$confirm" =~ ^[Yy]$ ]]; then
            echo -e "  ${BLUE}正在移除旧内核包...${NC}"
            apt remove --purge -y "${remove_kernels[@]}" 2>/dev/null
            
            echo -e "  ${BLUE}自动清理不需要的依赖项...${NC}"
            apt autoremove --purge -y 2>/dev/null
            
            echo -e "  ${BLUE}更新 GRUB 引导菜单...${NC}"
            update-grub 2>/dev/null
            
            echo -e "  ${GREEN}✓ 旧内核包已移除${NC}"
        else
            echo -e "  ${YELLOW}⊘ 已跳过旧内核清理${NC}"
        fi
    fi
    
    # 清理残留的配置文件
    echo -e "  ${BLUE}清理残留配置文件...${NC}"
    dpkg -l 2>/dev/null | awk '/^rc/{print $2}' | xargs dpkg --purge 2>/dev/null
    echo -e "  ${GREEN}✓ 配置文件已清理${NC}"
    echo ""
}

# 清理临时文件
clean_tmp() {
    echo -e "${YELLOW}步骤 2：清理 /tmp 目录${NC}"
    
    tmp_size=$(du -sh /tmp 2>/dev/null | awk '{print $1}')
    echo -e "  当前大小：${GREEN}$tmp_size${NC}"
    
    read -p "  是否清理 /tmp 目录？[y/N]: " confirm
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        echo -e "  ${BLUE}正在清理...${NC}"
        find /tmp -type f -delete 2>/dev/null
        find /tmp -type d -empty -delete 2>/dev/null
        echo -e "  ${GREEN}✓ /tmp 已清理${NC}"
    else
        echo -e "  ${YELLOW}⊘ 已跳过${NC}"
    fi
    echo ""
}

# 清理 APT 缓存
clean_apt_cache() {
    echo -e "${YELLOW}步骤 3：清理 APT 缓存${NC}"
    
    apt_cache_size=$(du -sh /var/cache/apt/archives 2>/dev/null | awk '{print $1}')
    echo -e "  当前大小：${GREEN}${apt_cache_size:-0}${NC}"
    
    read -p "  是否清理 APT 缓存？[y/N]: " confirm
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        echo -e "  ${BLUE}正在清理...${NC}"
        apt clean 2>/dev/null
        echo -e "  ${GREEN}✓ APT 缓存已清理${NC}"
    else
        echo -e "  ${YELLOW}⊘ 已跳过${NC}"
    fi
    echo ""
}

# 清理用户缓存
clean_user_cache() {
    echo -e "${YELLOW}步骤 4：清理用户缓存目录${NC}"
    
    user_home="/home/$SUDO_USER"
    cache_size=$(du -sh "$user_home/.cache" 2>/dev/null | awk '{print $1}')
    echo -e "  当前大小：${GREEN}${cache_size:-0}${NC}"
    
    read -p "  是否清理用户缓存？[y/N]: " confirm
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        echo -e "  ${BLUE}正在清理...${NC}"
        rm -rf "$user_home/.cache"/* 2>/dev/null
        echo -e "  ${GREEN}✓ 用户缓存已清理${NC}"
    else
        echo -e "  ${YELLOW}⊘ 已跳过${NC}"
    fi
    echo ""
}

# 清理 systemd 日志
clean_journal() {
    echo -e "${YELLOW}步骤 5：清理 systemd 日志${NC}"
    
    if [ -d "/var/log/journal" ]; then
        journal_size=$(journalctl --disk-usage 2>/dev/null | awk '{print $NF}')
        echo -e "  当前大小：${GREEN}${journal_size:-未知}${NC}"
        
        read -p "  是否清理日志？[y/N]: " confirm
        if [[ "$confirm" =~ ^[Yy]$ ]]; then
            read -p "  保留大小 (例如 100M, 1G): " journal_limit
            journal_limit=${journal_limit:-100M}
            
            echo -e "  ${BLUE}正在清理，保留 $journal_limit...${NC}"
            journalctl --vacuum-size="$journal_limit" 2>/dev/null
            
            new_size=$(journalctl --disk-usage 2>/dev/null | awk '{print $NF}')
            echo -e "  ${GREEN}✓ 日志已清理 (当前：$new_size)${NC}"
        else
            echo -e "  ${YELLOW}⊘ 已跳过${NC}"
        fi
    else
        echo -e "  ${YELLOW}⊘ 未启用持久化日志${NC}"
    fi
    echo ""
}

# 显示清理完成信息
show_complete() {
    echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}✓ 系统清理完成！${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
    echo ""
    
    # 显示清理后的磁盘使用情况
    echo -e "${YELLOW}清理后磁盘使用：${NC}"
    df -h / | awk 'NR==2 {print "  根目录：已用 "$3" / 总计 "$2" ("$5")"}'
    echo ""
}

# 主函数
main() {
    check_root
    show_banner
    show_system_info
    
    echo -e "${YELLOW}请选择清理模式：${NC}"
    echo "  1) 快速清理 (临时文件 + APT 缓存)"
    echo "  2) 标准清理 (快速清理 + 用户缓存 + 日志)"
    echo "  3) 完全清理 (标准清理 + 旧内核)"
    echo "  4) 自定义清理"
    echo "  0) 退出"
    echo ""
    
    read -p "请输入选项 [0-4]: " mode
    
    case $mode in
        1)
            clean_tmp
            clean_apt_cache
            ;;
        2)
            clean_tmp
            clean_apt_cache
            clean_user_cache
            clean_journal
            ;;
        3)
            clean_old_kernels
            clean_tmp
            clean_apt_cache
            clean_user_cache
            clean_journal
            ;;
        4)
            read -p "  清理旧内核？[y/N]: " k && [[ "$k" =~ ^[Yy]$ ]] && clean_old_kernels
            read -p "  清理临时文件？[y/N]: " t && [[ "$t" =~ ^[Yy]$ ]] && clean_tmp
            read -p "  清理 APT 缓存？[y/N]: " a && [[ "$a" =~ ^[Yy]$ ]] && clean_apt_cache
            read -p "  清理用户缓存？[y/N]: " u && [[ "$u" =~ ^[Yy]$ ]] && clean_user_cache
            read -p "  清理系统日志？[y/N]: " j && [[ "$j" =~ ^[Yy]$ ]] && clean_journal
            ;;
        *)
            echo -e "${YELLOW}已退出${NC}"
            exit 0
            ;;
    esac
    
    show_complete
}

# 运行主函数
main "$@"
