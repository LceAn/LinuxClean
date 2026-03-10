#!/bin/bash

################################################################################
#
# 脚本名称：LinuxClean - Linux 系统清理工具
# 版本：v2.1
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
VERSION="2.1"
SCRIPT_NAME="LinuxClean"

################################################################################
# 国际化 (i18n) 支持
################################################################################

# 支持的语言
declare -A LANGUAGES=(
    ["en"]="English"
    ["zh"]="中文"
)

# 默认语言（自动检测）
CURRENT_LANG="en"

# 语言包
declare -A TEXT_EN=(
    # 横幅
    ["banner_title"]="LinuxClean - Linux System Cleaner v%s"
    ["banner_separator"]="═══════════════════════════════════════════════════════════"
    
    # 系统信息
    ["sys_info_title"]="System Information:"
    ["sys_os"]="OS"
    ["sys_user"]="User"
    ["sys_cpu"]="CPU Cores"
    ["sys_mem"]="Memory"
    ["sys_disk"]="Disk"
    ["sys_uptime"]="Uptime"
    ["sys_mem_used"]="Used"
    
    # 清理模式
    ["mode_title"]="Select Cleanup Mode:"
    ["mode_quick"]="Quick Clean (Temp Files + APT Cache)"
    ["mode_standard"]="Standard Clean (Quick + User Cache + Logs)"
    ["mode_full"]="Full Clean (Standard + Old Kernels)"
    ["mode_custom"]="Custom Clean (Choose Items)"
    ["mode_exit"]="Exit"
    ["mode_prompt"]="Enter choice [0-4]"
    
    # 内核清理
    ["kernel_step"]="Step 1: Clean old kernel packages and residual configs"
    ["kernel_current"]="Current Kernel"
    ["kernel_installed"]="Installed Kernels"
    ["kernel_remove"]="Will Remove"
    ["kernel_old_count"]="%d old kernel(s)"
    ["kernel_none"]="No kernel packages detected"
    ["kernel_no_old"]="No old kernels to remove"
    ["kernel_confirm"]="Confirm removal?"
    ["kernel_removing"]="Removing old kernel packages..."
    ["kernel_autoremove"]="Auto-cleaning unnecessary dependencies..."
    ["kernel_update_grub"]="Updating GRUB boot menu..."
    ["kernel_done"]="Old kernels removed"
    ["kernel_skipped"]="Skipped old kernel cleanup"
    ["kernel_clean_residual"]="Cleaning residual config files..."
    ["kernel_configs_done"]="Config files cleaned"
    
    # 临时文件清理
    ["tmp_step"]="Step 2: Clean /tmp directory"
    ["tmp_current"]="Current Size"
    ["tmp_clean_prompt"]="Clean /tmp directory?"
    ["tmp_cleaning"]="Cleaning..."
    ["tmp_done"]="/tmp cleaned"
    ["tmp_skipped"]="Skipped"
    
    # APT 缓存清理
    ["apt_step"]="Step 3: Clean APT cache"
    ["apt_current"]="Current Size"
    ["apt_clean_prompt"]="Clean APT cache?"
    ["apt_cleaning"]="Cleaning..."
    ["apt_done"]="APT cache cleaned"
    ["apt_skipped"]="Skipped"
    
    # 用户缓存清理
    ["cache_step"]="Step 4: Clean user cache directory"
    ["cache_current"]="Current Size"
    ["cache_clean_prompt"]="Clean user cache?"
    ["cache_cleaning"]="Cleaning..."
    ["cache_done"]="User cache cleaned"
    ["cache_skipped"]="Skipped"
    
    # 系统日志清理
    ["journal_step"]="Step 5: Clean systemd logs"
    ["journal_current"]="Current Size"
    ["journal_clean_prompt"]="Clean logs?"
    ["journal_retain_prompt"]="Retain size (e.g., 100M, 1G)"
    ["journal_cleaning"]="Cleaning, retaining %s..."
    ["journal_done"]="Logs cleaned (current: %s)"
    ["journal_skipped"]="Skipped"
    ["journal_no_persistent"]="No persistent logs enabled"
    
    # 完成信息
    ["complete_title"]="System cleanup completed!"
    ["complete_disk"]="Disk Usage After Cleanup:"
    ["complete_root"]="Root"
    
    # 错误和提示
    ["error_root"]="Error: Please run with sudo or as root"
    ["error_usage"]="Usage: sudo %s"
    ["lang_select"]="Select Language / 选择语言:"
    ["lang_en"]="English"
    ["lang_zh"]="中文"
    ["lang_prompt"]="Enter choice [1-2]"
    ["lang_auto"]="Auto-detected: %s"
)

declare -A TEXT_ZH=(
    # 横幅
    ["banner_title"]="LinuxClean - Linux 系统清理工具 v%s"
    ["banner_separator"]="═══════════════════════════════════════════════════════════"
    
    # 系统信息
    ["sys_info_title"]="系统信息："
    ["sys_os"]="操作系统"
    ["sys_user"]="登录用户"
    ["sys_cpu"]="CPU 核心"
    ["sys_mem"]="内存"
    ["sys_disk"]="硬盘"
    ["sys_uptime"]="运行时间"
    ["sys_mem_used"]="已用"
    
    # 清理模式
    ["mode_title"]="请选择清理模式："
    ["mode_quick"]="快速清理 (临时文件 + APT 缓存)"
    ["mode_standard"]="标准清理 (快速清理 + 用户缓存 + 日志)"
    ["mode_full"]="完全清理 (标准清理 + 旧内核)"
    ["mode_custom"]="自定义清理"
    ["mode_exit"]="退出"
    ["mode_prompt"]="请输入选项 [0-4]"
    
    # 内核清理
    ["kernel_step"]="步骤 1：清理旧的内核包和残留配置文件"
    ["kernel_current"]="当前内核"
    ["kernel_installed"]="已安装内核"
    ["kernel_remove"]="将移除"
    ["kernel_old_count"]="%d 个旧内核"
    ["kernel_none"]="没有检测到已安装的内核包"
    ["kernel_no_old"]="没有需要移除的旧内核"
    ["kernel_confirm"]="是否确认移除？"
    ["kernel_removing"]="正在移除旧内核包..."
    ["kernel_autoremove"]="自动清理不需要的依赖项..."
    ["kernel_update_grub"]="更新 GRUB 引导菜单..."
    ["kernel_done"]="旧内核包已移除"
    ["kernel_skipped"]="已跳过旧内核清理"
    ["kernel_clean_residual"]="清理残留配置文件..."
    ["kernel_configs_done"]="配置文件已清理"
    
    # 临时文件清理
    ["tmp_step"]="步骤 2：清理 /tmp 目录"
    ["tmp_current"]="当前大小"
    ["tmp_clean_prompt"]="是否清理 /tmp 目录？"
    ["tmp_cleaning"]="正在清理..."
    ["tmp_done"]="/tmp 已清理"
    ["tmp_skipped"]="已跳过"
    
    # APT 缓存清理
    ["apt_step"]="步骤 3：清理 APT 缓存"
    ["apt_current"]="当前大小"
    ["apt_clean_prompt"]="是否清理 APT 缓存？"
    ["apt_cleaning"]="正在清理..."
    ["apt_done"]="APT 缓存已清理"
    ["apt_skipped"]="已跳过"
    
    # 用户缓存清理
    ["cache_step"]="步骤 4：清理用户缓存目录"
    ["cache_current"]="当前大小"
    ["cache_clean_prompt"]="是否清理用户缓存？"
    ["cache_cleaning"]="正在清理..."
    ["cache_done"]="用户缓存已清理"
    ["cache_skipped"]="已跳过"
    
    # 系统日志清理
    ["journal_step"]="步骤 5：清理 systemd 日志"
    ["journal_current"]="当前大小"
    ["journal_clean_prompt"]="是否清理日志？"
    ["journal_retain_prompt"]="保留大小 (例如 100M, 1G)"
    ["journal_cleaning"]="正在清理，保留 %s..."
    ["journal_done"]="日志已清理 (当前：%s)"
    ["journal_skipped"]="已跳过"
    ["journal_no_persistent"]="未启用持久化日志"
    
    # 完成信息
    ["complete_title"]="✓ 系统清理完成！"
    ["complete_disk"]="清理后磁盘使用："
    ["complete_root"]="根目录"
    
    # 错误和提示
    ["error_root"]="错误：请使用 sudo 或以 root 身份运行此脚本"
    ["error_usage"]="用法：sudo %s"
    ["lang_select"]="Select Language / 选择语言："
    ["lang_en"]="English"
    ["lang_zh"]="中文"
    ["lang_prompt"]="Enter choice [1-2]"
    ["lang_auto"]="Auto-detected: %s"
)

# 语言包引用
declare -A TEXT

# 检测系统语言
detect_language() {
    local sys_lang="${LANG%%_*}"
    local sys_lc_all="${LC_ALL%%_*}"
    local sys_language="${LANGUAGE%%_*}"
    
    # 优先级：LC_ALL > LANG > LANGUAGE
    if [ -n "$sys_lc_all" ]; then
        sys_lang="$sys_lc_all"
    elif [ -n "$sys_language" ]; then
        sys_lang="$sys_language"
    fi
    
    # 判断是否为中文
    if [[ "$sys_lang" =~ ^(zh|zh_CN|zh_TW|zh_HK)$ ]]; then
        CURRENT_LANG="zh"
    else
        CURRENT_LANG="en"
    fi
}

# 手动选择语言
select_language() {
    echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${YELLOW}$(get_text "lang_select")${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
    echo "  1) English"
    echo "  2) 中文"
    echo ""
    
    read -p "$(get_text "lang_prompt"): " lang_choice
    
    case $lang_choice in
        1) CURRENT_LANG="en" ;;
        2) CURRENT_LANG="zh" ;;
        *) CURRENT_LANG="en" ;;
    esac
}

# 获取翻译文本
get_text() {
    local key="$1"
    shift
    local args=("$@")
    
    local text=""
    if [ "$CURRENT_LANG" = "zh" ]; then
        text="${TEXT_ZH[$key]}"
    else
        text="${TEXT_EN[$key]}"
    fi
    
    # 如果找不到翻译，回退到英文
    if [ -z "$text" ]; then
        text="${TEXT_EN[$key]}"
    fi
    
    # 处理格式化参数
    if [ ${#args[@]} -gt 0 ]; then
        printf "$text" "${args[@]}"
    else
        echo "$text"
    fi
}

# 加载语言包
load_language() {
    if [ "$CURRENT_LANG" = "zh" ]; then
        TEXT=("${TEXT_ZH[@]}")
    else
        TEXT=("${TEXT_EN[@]}")
    fi
}

# 初始化语言
init_language() {
    detect_language
    load_language
}

# 检查是否以 root 身份运行
check_root() {
    if [ "$EUID" -ne 0 ]; then
        echo -e "${RED}$(get_text "error_root")${NC}"
        printf "$(get_text "error_usage")\n" "$0"
        exit 1
    fi
}

# 显示横幅
show_banner() {
    echo -e "${BLUE}"
    echo "╔══════════════════════════════════════════════════════════╗"
    printf "║           $(get_text "banner_title" "$VERSION")              ║\n"
    echo "╚══════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

# 显示系统信息
show_system_info() {
    echo -e "${BLUE}$(get_text "banner_separator")${NC}"
    echo -e "${BLUE}$(get_text "sys_info_title")${NC}"
    echo -e "${BLUE}$(get_text "banner_separator")${NC}"
    
    # 获取当前 Linux 发行版
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        distro="$NAME $VERSION"
    else
        distro=$(uname -s)
    fi
    printf "  %-8s ${GREEN}%s${NC}\n" "$(get_text "sys_os"):" "$distro"
    
    # 获取登录的用户名
    username=${SUDO_USER:-$(logname)}
    printf "  %-8s ${GREEN}%s${NC}\n" "$(get_text "sys_user"):" "$username"
    
    # 获取 CPU 数量
    cpu_count=$(nproc)
    printf "  %-8s ${GREEN}%s${NC}\n" "$(get_text "sys_cpu"):" "$cpu_count"
    
    # 获取内存大小和使用率
    total_mem=$(free -h | awk '/Mem:/ {print $2}')
    used_mem=$(free -h | awk '/Mem:/ {print $3}')
    mem_percent=$(free | awk '/Mem:/ {printf("%.1f"), $3/$2 * 100}')
    printf "  %-8s ${GREEN}%s${NC} ($(get_text "sys_mem_used")：${YELLOW}%s ($mem_percent%%)${NC})\n" "$(get_text "sys_mem"):" "$total_mem" "$used_mem"
    
    # 获取硬盘大小和使用率
    disk_total=$(df -h / | awk 'NR==2 {print $2}')
    disk_used=$(df -h / | awk 'NR==2 {print $3}')
    disk_percent=$(df -h / | awk 'NR==2 {print $5}')
    printf "  %-8s ${GREEN}%s${NC} ($(get_text "sys_mem_used")：${YELLOW}%s ($disk_percent)${NC})\n" "$(get_text "sys_disk"):" "$disk_total" "$disk_used"
    
    # 获取系统运行时间
    uptime_info=$(uptime -p 2>/dev/null || uptime | awk -F'up ' '{print $2}' | awk -F',' '{print $1}')
    printf "  %-8s ${GREEN}%s${NC}\n" "$(get_text "sys_uptime"):" "$uptime_info"
    
    echo -e "${BLUE}$(get_text "banner_separator")${NC}"
    echo ""
}

# 清理旧内核
clean_old_kernels() {
    echo -e "${YELLOW}$(get_text "kernel_step")${NC}"
    echo ""
    
    # 获取当前正在运行的内核版本
    current_kernel=$(uname -r)
    printf "  %-12s ${GREEN}%s${NC}\n" "$(get_text "kernel_current"):" "$current_kernel"
    
    # 获取已安装的内核包列表
    mapfile -t installed_kernels < <(dpkg --list 2>/dev/null | grep 'linux-image-[0-9]' | awk '/^ii/{print $2}')
    
    if [ ${#installed_kernels[@]} -eq 0 ]; then
        echo -e "  ${GREEN}✓ $(get_text "kernel_none")${NC}"
        return
    fi
    
    printf "  %-12s ${GREEN}%d${NC}\n" "$(get_text "kernel_installed"):" "${#installed_kernels[@]}"
    
    # 筛选需要移除的旧内核包
    remove_kernels=()
    for kernel in "${installed_kernels[@]}"; do
        if [[ "$kernel" != *"$current_kernel"* ]]; then
            remove_kernels+=("$kernel")
        fi
    done
    
    # 显示将要移除的内核包
    if [ ${#remove_kernels[@]} -eq 0 ]; then
        echo -e "  ${GREEN}✓ $(get_text "kernel_no_old")${NC}"
    else
        printf "  %-12s ${YELLOW}%d${NC}\n" "$(get_text "kernel_remove"):" "${#remove_kernels[@]}"
        for kernel in "${remove_kernels[@]}"; do
            echo -e "    - $kernel"
        done
        
        # 提示用户确认
        read -p "  $(get_text "kernel_confirm") [y/N]: " confirm
        if [[ "$confirm" =~ ^[Yy]$ ]]; then
            echo -e "  ${BLUE}$(get_text "kernel_removing")${NC}"
            apt remove --purge -y "${remove_kernels[@]}" 2>/dev/null
            
            echo -e "  ${BLUE}$(get_text "kernel_autoremove")${NC}"
            apt autoremove --purge -y 2>/dev/null
            
            echo -e "  ${BLUE}$(get_text "kernel_update_grub")${NC}"
            update-grub 2>/dev/null
            
            echo -e "  ${GREEN}✓ $(get_text "kernel_done")${NC}"
        else
            echo -e "  ${YELLOW}⊘ $(get_text "kernel_skipped")${NC}"
        fi
    fi
    
    # 清理残留的配置文件
    echo -e "  ${BLUE}$(get_text "kernel_clean_residual")${NC}"
    dpkg -l 2>/dev/null | awk '/^rc/{print $2}' | xargs dpkg --purge 2>/dev/null
    echo -e "  ${GREEN}✓ $(get_text "kernel_configs_done")${NC}"
    echo ""
}

# 清理临时文件
clean_tmp() {
    echo -e "${YELLOW}$(get_text "tmp_step")${NC}"
    
    tmp_size=$(du -sh /tmp 2>/dev/null | awk '{print $1}')
    printf "  %-12s ${GREEN}%s${NC}\n" "$(get_text "tmp_current"):" "$tmp_size"
    
    read -p "  $(get_text "tmp_clean_prompt") [y/N]: " confirm
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        echo -e "  ${BLUE}$(get_text "tmp_cleaning")${NC}"
        find /tmp -type f -delete 2>/dev/null
        find /tmp -type d -empty -delete 2>/dev/null
        echo -e "  ${GREEN}✓ $(get_text "tmp_done")${NC}"
    else
        echo -e "  ${YELLOW}⊘ $(get_text "tmp_skipped")${NC}"
    fi
    echo ""
}

# 清理 APT 缓存
clean_apt_cache() {
    echo -e "${YELLOW}$(get_text "apt_step")${NC}"
    
    apt_cache_size=$(du -sh /var/cache/apt/archives 2>/dev/null | awk '{print $1}')
    printf "  %-12s ${GREEN}%s${NC}\n" "$(get_text "apt_current"):" "${apt_cache_size:-0}"
    
    read -p "  $(get_text "apt_clean_prompt") [y/N]: " confirm
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        echo -e "  ${BLUE}$(get_text "apt_cleaning")${NC}"
        apt clean 2>/dev/null
        echo -e "  ${GREEN}✓ $(get_text "apt_done")${NC}"
    else
        echo -e "  ${YELLOW}⊘ $(get_text "apt_skipped")${NC}"
    fi
    echo ""
}

# 清理用户缓存
clean_user_cache() {
    echo -e "${YELLOW}$(get_text "cache_step")${NC}"
    
    user_home="/home/$SUDO_USER"
    cache_size=$(du -sh "$user_home/.cache" 2>/dev/null | awk '{print $1}')
    printf "  %-12s ${GREEN}%s${NC}\n" "$(get_text "cache_current"):" "${cache_size:-0}"
    
    read -p "  $(get_text "cache_clean_prompt") [y/N]: " confirm
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        echo -e "  ${BLUE}$(get_text "cache_cleaning")${NC}"
        rm -rf "$user_home/.cache"/* 2>/dev/null
        echo -e "  ${GREEN}✓ $(get_text "cache_done")${NC}"
    else
        echo -e "  ${YELLOW}⊘ $(get_text "cache_skipped")${NC}"
    fi
    echo ""
}

# 清理 systemd 日志
clean_journal() {
    echo -e "${YELLOW}$(get_text "journal_step")${NC}"
    
    if [ -d "/var/log/journal" ]; then
        journal_size=$(journalctl --disk-usage 2>/dev/null | awk '{print $NF}')
        printf "  %-12s ${GREEN}%s${NC}\n" "$(get_text "journal_current"):" "${journal_size:-未知}"
        
        read -p "  $(get_text "journal_clean_prompt") [y/N]: " confirm
        if [[ "$confirm" =~ ^[Yy]$ ]]; then
            read -p "  $(get_text "journal_retain_prompt"): " journal_limit
            journal_limit=${journal_limit:-100M}
            
            printf "  ${BLUE}$(get_text "journal_cleaning")${NC}\n" "$journal_limit"
            journalctl --vacuum-size="$journal_limit" 2>/dev/null
            
            new_size=$(journalctl --disk-usage 2>/dev/null | awk '{print $NF}')
            printf "  ${GREEN}✓ $(get_text "journal_done")${NC}\n" "$new_size"
        else
            echo -e "  ${YELLOW}⊘ $(get_text "journal_skipped")${NC}"
        fi
    else
        echo -e "  ${YELLOW}⊘ $(get_text "journal_no_persistent")${NC}"
    fi
    echo ""
}

# 显示清理完成信息
show_complete() {
    echo -e "${BLUE}$(get_text "banner_separator")${NC}"
    echo -e "${GREEN}✓ $(get_text "complete_title")${NC}"
    echo -e "${BLUE}$(get_text "banner_separator")${NC}"
    echo ""
    
    # 显示清理后的磁盘使用情况
    echo -e "${YELLOW}$(get_text "complete_disk")${NC}"
    df -h / | awk -v label="$(get_text "complete_root")" 'NR==2 {print "  " label "：已用 "$3" / 总计 "$2" ("$5")"}'
    echo ""
}

# 主函数
main() {
    # 初始化语言（自动检测）
    init_language
    
    # 可选：手动选择语言（取消注释以下行启用）
    # select_language
    
    check_root
    show_banner
    show_system_info
    
    echo -e "${YELLOW}$(get_text "mode_title")${NC}"
    echo "  1) $(get_text "mode_quick")"
    echo "  2) $(get_text "mode_standard")"
    echo "  3) $(get_text "mode_full")"
    echo "  4) $(get_text "mode_custom")"
    echo "  0) $(get_text "mode_exit")"
    echo ""
    
    read -p "$(get_text "mode_prompt"): " mode
    
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
            read -p "  $(get_text "kernel_confirm") [y/N]: " k && [[ "$k" =~ ^[Yy]$ ]] && clean_old_kernels
            read -p "  $(get_text "tmp_clean_prompt") [y/N]: " t && [[ "$t" =~ ^[Yy]$ ]] && clean_tmp
            read -p "  $(get_text "apt_clean_prompt") [y/N]: " a && [[ "$a" =~ ^[Yy]$ ]] && clean_apt_cache
            read -p "  $(get_text "cache_clean_prompt") [y/N]: " u && [[ "$u" =~ ^[Yy]$ ]] && clean_user_cache
            read -p "  $(get_text "journal_clean_prompt") [y/N]: " j && [[ "$j" =~ ^[Yy]$ ]] && clean_journal
            ;;
        *)
            echo -e "${YELLOW}$(get_text "mode_exit")${NC}"
            exit 0
            ;;
    esac
    
    show_complete
}

# 运行主函数
main "$@"
