#!/usr/bin/env bash

################################################################################
# LinuxClean - safe Linux maintenance and cleanup utility
# Version: 3.0
################################################################################

set -Eeuo pipefail
IFS=$'\n\t'

VERSION="3.0"
SCRIPT_NAME="LinuxClean"
KEEP_DAYS=7
MAX_PREVIEW_ITEMS=20
JOURNAL_LIMIT="100M"
MODE=""
TARGET_USER=""
DRY_RUN=0
ASSUME_YES=0
COLOR=1
LOG_FILE=""
LOCK_DIR="/run/lock/linuxclean.lock"
CURRENT_LANG="en"
TOTAL_RELEASED=0
ESTIMATED_RELEASED=0
PLANNED_ACTIONS=0
SCAN_COUNT=0
SCAN_BYTES=0

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

declare -A TEXT_EN=(
    [banner_title]='LinuxClean - Linux System Cleaner v%s'
    [sys_info_title]='System Information:'
    [sys_os]='OS'
    [sys_user]='User'
    [sys_cpu]='CPU Cores'
    [sys_mem]='Memory'
    [sys_disk]='Disk'
    [sys_uptime]='Uptime'
    [sys_used]='Used'
    [run_profile]='Cleanup plan:'
    [profile_mode]='Mode'
    [profile_age]='File retention'
    [profile_age_value]='%s days'
    [profile_journal]='Journal limit'
    [profile_users]='Cache users'
    [profile_users_all]='root + regular local users'
    [profile_state]='Execution'
    [profile_preview]='preview only'
    [profile_live]='changes enabled'
    [mode_name_quick]='Quick'
    [mode_name_standard]='Standard'
    [mode_name_full]='Full'
    [mode_name_custom]='Custom'
    [mode_title]='Select cleanup mode:'
    [mode_quick]='Quick clean (safe temporary files + APT cache)'
    [mode_standard]='Standard clean (quick + user caches + journal)'
    [mode_full]='Full clean (standard + safe old kernel packages)'
    [mode_custom]='Custom clean (choose items)'
    [mode_exit]='Exit'
    [mode_prompt]='Enter choice [0-4]'
    [tmp_step]='Step 1: Clean old files in /tmp'
    [tmp_current]='Current size'
    [tmp_prompt]='Clean files older than %s days?'
    [tmp_cleaning]='Cleaning old temporary files...'
    [tmp_done]='Temporary files cleaned (removed: %s)'
    [tmp_skipped]='Skipped'
    [candidate_summary]='Candidates: %s item(s), %s'
    [candidate_none]='No eligible files found'
    [preview_omitted]='%s additional candidate(s) not shown; use --max-items to adjust'
    [planned_reclaim]='Planned reclaim: %s'
    [apt_step]='Step 2: Clean APT package cache'
    [apt_current]='Current size'
    [apt_prompt]='Clean APT cache?'
    [apt_cleaning]='Cleaning APT cache...'
    [apt_done]='APT cache cleaned (removed: %s)'
    [apt_skipped]='Skipped'
    [apt_unavailable]='APT is not available; skipped'
    [cache_step]='Step 3: Clean user caches'
    [cache_current]='Current size'
    [cache_prompt]='Clean files older than %s days?'
    [cache_cleaning]='Cleaning old user cache files...'
    [cache_done]='User caches cleaned (removed: %s)'
    [cache_none]='No eligible user cache directories found'
    [journal_step]='Step 4: Vacuum systemd journal'
    [journal_current]='Current size'
    [journal_target]='Target size'
    [journal_prompt]='Vacuum journal to %s?'
    [journal_cleaning]='Vacuuming journal (retaining %s)...'
    [journal_done]='Journal vacuum completed (current: %s)'
    [journal_within_limit]='Journal is already within the requested limit'
    [journal_unavailable]='systemd journal is not available; skipped'
    [kernel_step]='Step 5: Remove safely detected old kernels'
    [kernel_current]='Running kernel'
    [kernel_installed]='Installed kernel packages'
    [kernel_fallback]='Protected fallback kernel'
    [kernel_remove]='Candidates (running kernel + newest fallback are protected)'
    [kernel_prompt]='Purge these packages?'
    [kernel_cleaning]='Purging old kernel packages...'
    [kernel_done]='Old kernel cleanup completed'
    [kernel_none]='No removable old kernel packages found'
    [residual_cleaning]='Purging residual package configurations...'
    [residual_candidates]='Residual configurations: %s package(s)'
    [residual_prompt]='Purge %s residual package configuration(s)?'
    [residual_done]='Residual configurations purged: %s'
    [complete_title]='System cleanup completed'
    [preview_title]='Preview completed; no changes were made'
    [complete_disk]='Disk usage after cleanup:'
    [preview_disk]='Current disk usage:'
    [complete_root]='Root'
    [summary]='Released space: %s'
    [estimated_summary]='Estimated reclaimable space: %s across %s action(s)'
    [estimate_note]='Estimates may differ from the final package/journal result.'
    [dry_run]='DRY-RUN: no changes will be made'
    [label_ok]='OK'
    [label_skip]='SKIP'
    [label_plan]='PLAN'
    [label_info]='INFO'
    [confirm]='Continue?'
    [skipped]='Skipped'
    [error_root]='Error: please run as root (or with sudo)'
    [error_usage]='Usage: sudo %s [options]'
    [error_unknown_option]='Unknown option: %s'
    [error_bad_mode]='Invalid mode: %s'
    [error_bad_days]='--keep-days must be a non-negative integer'
    [error_bad_items]='--max-items must be a non-negative integer'
    [error_bad_size]='--journal-size must look like 100M, 1G, etc.'
    [error_noninteractive]='A mode is required when stdin is not a terminal (use --mode)'
    [error_log]='Unable to initialize log file: %s'
    [error_lock]='Unable to create the cleanup lock'
    [error_purge]='Some residual package configurations could not be purged'
    [help_title]='Usage'
    [help_options]='Options:'
    [help_mode]='Modes: quick, standard, full, custom'
    [help_examples]='Examples:'
    [lang_auto]='Language: %s'
)

declare -A TEXT_ZH=(
    [banner_title]='LinuxClean - Linux 系统清理工具 v%s'
    [sys_info_title]='系统信息：'
    [sys_os]='操作系统'
    [sys_user]='登录用户'
    [sys_cpu]='CPU 核心'
    [sys_mem]='内存'
    [sys_disk]='磁盘'
    [sys_uptime]='运行时间'
    [sys_used]='已用'
    [run_profile]='执行计划：'
    [profile_mode]='模式'
    [profile_age]='文件保留时间'
    [profile_age_value]='%s 天'
    [profile_journal]='日志上限'
    [profile_users]='缓存用户范围'
    [profile_users_all]='root + 普通本地用户'
    [profile_state]='执行状态'
    [profile_preview]='仅预览'
    [profile_live]='允许修改'
    [mode_name_quick]='快速'
    [mode_name_standard]='标准'
    [mode_name_full]='完全'
    [mode_name_custom]='自定义'
    [mode_title]='请选择清理模式：'
    [mode_quick]='快速清理（安全临时文件 + APT 缓存）'
    [mode_standard]='标准清理（快速 + 用户缓存 + 系统日志）'
    [mode_full]='完全清理（标准 + 安全旧内核）'
    [mode_custom]='自定义清理（逐项选择）'
    [mode_exit]='退出'
    [mode_prompt]='请输入选项 [0-4]'
    [tmp_step]='步骤 1：清理 /tmp 中的旧文件'
    [tmp_current]='当前大小'
    [tmp_prompt]='清理超过 %s 天的文件？'
    [tmp_cleaning]='正在清理旧临时文件……'
    [tmp_done]='临时文件清理完成（释放：%s）'
    [tmp_skipped]='已跳过'
    [candidate_summary]='候选项：%s 个，%s'
    [candidate_none]='没有找到符合条件的文件'
    [preview_omitted]='另有 %s 个候选项未显示，可使用 --max-items 调整'
    [planned_reclaim]='预计释放：%s'
    [apt_step]='步骤 2：清理 APT 软件包缓存'
    [apt_current]='当前大小'
    [apt_prompt]='清理 APT 缓存？'
    [apt_cleaning]='正在清理 APT 缓存……'
    [apt_done]='APT 缓存清理完成（释放：%s）'
    [apt_skipped]='已跳过'
    [apt_unavailable]='未找到 APT，已跳过'
    [cache_step]='步骤 3：清理用户缓存'
    [cache_current]='当前大小'
    [cache_prompt]='清理超过 %s 天的文件？'
    [cache_cleaning]='正在清理旧用户缓存文件……'
    [cache_done]='用户缓存清理完成（释放：%s）'
    [cache_none]='没有找到可清理的用户缓存目录'
    [journal_step]='步骤 4：清理 systemd 日志'
    [journal_current]='当前大小'
    [journal_target]='目标大小'
    [journal_prompt]='将日志清理到 %s？'
    [journal_cleaning]='正在清理日志（保留 %s）……'
    [journal_done]='日志清理完成（当前：%s）'
    [journal_within_limit]='日志占用已低于指定上限'
    [journal_unavailable]='systemd 日志不可用，已跳过'
    [kernel_step]='步骤 5：安全移除旧内核包'
    [kernel_current]='当前运行内核'
    [kernel_installed]='已安装内核包'
    [kernel_fallback]='受保护的备用内核'
    [kernel_remove]='候选包（当前内核和最新备用内核已保护）'
    [kernel_prompt]='确认清除这些包？'
    [kernel_cleaning]='正在清除旧内核包……'
    [kernel_done]='旧内核清理完成'
    [kernel_none]='没有找到可移除的旧内核包'
    [residual_cleaning]='正在清理残留包配置……'
    [residual_candidates]='残留配置：%s 个软件包'
    [residual_prompt]='清理 %s 个残留软件包配置？'
    [residual_done]='已清理残留配置：%s'
    [complete_title]='系统清理完成'
    [preview_title]='预览完成，未对系统执行任何修改'
    [complete_disk]='清理后的磁盘使用情况：'
    [preview_disk]='当前磁盘使用情况：'
    [complete_root]='根目录'
    [summary]='释放空间：%s'
    [estimated_summary]='预计可释放：%s，共 %s 项操作'
    [estimate_note]='软件包和日志的最终释放量可能与估算值不同。'
    [dry_run]='演练模式：不会执行任何修改'
    [label_ok]='完成'
    [label_skip]='跳过'
    [label_plan]='计划'
    [label_info]='信息'
    [confirm]='继续？'
    [skipped]='已跳过'
    [error_root]='错误：请以 root 身份运行（或使用 sudo）'
    [error_usage]='用法：sudo %s [选项]'
    [error_unknown_option]='未知选项：%s'
    [error_bad_mode]='无效模式：%s'
    [error_bad_days]='--keep-days 必须是非负整数'
    [error_bad_items]='--max-items 必须是非负整数'
    [error_bad_size]='--journal-size 应类似 100M、1G 等格式'
    [error_noninteractive]='非交互模式必须指定 --mode'
    [error_log]='无法初始化日志文件：%s'
    [error_lock]='无法创建清理锁'
    [error_purge]='部分残留包配置无法清理'
    [help_title]='用法'
    [help_options]='选项：'
    [help_mode]='模式：quick、standard、full、custom'
    [help_examples]='示例：'
    [lang_auto]='语言：%s'
)

say() { printf '%s\n' "$*"; }
msg() {
    local key="$1"; shift || true
    local text
    if [[ "$CURRENT_LANG" == zh ]]; then text="${TEXT_ZH[$key]:-${TEXT_EN[$key]:-[$key]}}"; else text="${TEXT_EN[$key]:-[$key]}"; fi
    if (($#)); then printf "$text\n" "$@"; else printf '%s\n' "$text"; fi
}

if [[ ! -t 1 || -n "${NO_COLOR:-}" ]]; then COLOR=0; fi
paint() { local color="$1"; shift; if ((COLOR)); then printf '%b%s%b\n' "$color" "$*" "$NC"; else printf '%s\n' "$*"; fi; }
info() { paint "$BLUE" "$*"; }
success() { paint "$GREEN" "$*"; }
warn() { paint "$YELLOW" "$*"; }
error() { paint "$RED" "$*" >&2; }
rule() { info '───────────────────────────────────────────────────────────'; }
section() { printf '\n'; rule; info "$*"; rule; }
ok() { success "  [$(msg label_ok)] $*"; }
skip() { warn "  [$(msg label_skip)] $*"; }
plan() { paint "$CYAN" "  [$(msg label_plan)] $*"; }
note() { info "  [$(msg label_info)] $*"; }

detect_language() {
    local value="${LC_ALL:-${LANG:-${LANGUAGE:-en}}}"
    value="${value%%:*}"
    value="${value%%[.@_-]*}"
    [[ "$value" == zh ]] && CURRENT_LANG=zh || CURRENT_LANG=en
}

usage() {
    msg help_title
    printf '  %s\n\n' "$(msg error_usage "$SCRIPT_NAME.sh")"
    msg help_options
    cat <<'EOF'
  -m, --mode MODE          quick, standard, full, or custom
  -y, --yes                do not ask for confirmations
      --dry-run            show what would be cleaned without changing files
      --keep-days N        only remove files older than N days (default: 7)
      --max-items N        show at most N file candidates in previews (default: 20)
      --journal-size SIZE  journal target such as 100M or 1G (default: 100M)
      --user USER          limit cache cleanup to one local user
      --language LANG      en or zh (also respects LC_ALL/LANG)
      --no-color           disable ANSI colors
      --log-file FILE      append a timestamped log to FILE
  -h, --help               show this help
  -V, --version            show version
EOF
    msg help_mode
    msg help_examples
    cat <<'EOF'
  sudo ./LinuxClean.sh --mode quick --yes
  sudo ./LinuxClean.sh --mode standard --keep-days 14 --dry-run
  sudo ./LinuxClean.sh --mode full --journal-size 1G
EOF
}

die() { error "$*"; exit 1; }
require_root() { ((EUID == 0)) || { msg error_root >&2; exit 1; }; }
command_exists() { command -v "$1" >/dev/null 2>&1; }

parse_args() {
    while (($#)); do
        case "$1" in
            -m|--mode) (($# >= 2)) || die "$(msg error_unknown_option "$1")"; MODE="$2"; shift 2 ;;
            -y|--yes) ASSUME_YES=1; shift ;;
            --dry-run) DRY_RUN=1; shift ;;
            --keep-days) (($# >= 2)) || die "$(msg error_bad_days)"; KEEP_DAYS="$2"; shift 2 ;;
            --max-items) (($# >= 2)) || die "$(msg error_bad_items)"; MAX_PREVIEW_ITEMS="$2"; shift 2 ;;
            --journal-size) (($# >= 2)) || die "$(msg error_bad_size)"; JOURNAL_LIMIT="$2"; shift 2 ;;
            --user) (($# >= 2)) || die "$(msg error_unknown_option "$1")"; TARGET_USER="$2"; shift 2 ;;
            --language) (($# >= 2)) || die "$(msg error_unknown_option "$1")"; CURRENT_LANG="${2,,}"; shift 2 ;;
            --no-color) COLOR=0; shift ;;
            --log-file) (($# >= 2)) || die "$(msg error_unknown_option "$1")"; LOG_FILE="$2"; shift 2 ;;
            -h|--help) usage; exit 0 ;;
            -V|--version) printf '%s %s\n' "$SCRIPT_NAME" "$VERSION"; exit 0 ;;
            --) shift; (($# == 0)) || die "$(msg error_unknown_option "$1")" ;;
            -*) die "$(msg error_unknown_option "$1")" ;;
            *) [[ -z "$MODE" ]] && MODE="$1" || die "$(msg error_unknown_option "$1")"; shift ;;
        esac
    done
    [[ "$CURRENT_LANG" == en || "$CURRENT_LANG" == zh ]] || CURRENT_LANG=en
    [[ "$KEEP_DAYS" =~ ^[0-9]+$ ]] || die "$(msg error_bad_days)"
    [[ "$MAX_PREVIEW_ITEMS" =~ ^[0-9]+$ ]] || die "$(msg error_bad_items)"
    [[ "$JOURNAL_LIMIT" =~ ^[0-9]+([KMGTP]B?|B)$ ]] || die "$(msg error_bad_size)"
    case "$MODE" in ''|quick|standard|full|custom) ;; *) die "$(msg error_bad_mode "$MODE")" ;; esac
}

confirm() {
    local prompt="${1:-$(msg confirm)}"
    ((ASSUME_YES || DRY_RUN)) && return 0
    local answer
    read -r -p "$prompt [y/N] " answer || return 1
    [[ "$answer" =~ ^[Yy]([Ee][Ss])?$ ]]
}

bytes_for() {
    local path="$1" value
    [[ -e "$path" ]] || { printf '0'; return; }
    value=$(du -sxB1 -- "$path" 2>/dev/null | awk 'NR==1 {print $1}') || value=0
    [[ "$value" =~ ^[0-9]+$ ]] && printf '%s' "$value" || printf '0'
}
human_bytes() {
    local n="${1:-0}"; awk -v n="$n" 'BEGIN { split("B KiB MiB GiB TiB",u); i=1; while(n>=1024 && i<5){n/=1024;i++} printf (i==1 ? "%.0f %s" : "%.1f %s"),n,u[i] }'
}
size_to_bytes() {
    local raw="${1^^}" number unit factor=1
    if [[ "$raw" =~ ([0-9]+([.][0-9]+)?)[[:space:]]*([KMGTP]?)(I?B)? ]]; then
        number="${BASH_REMATCH[1]}"; unit="${BASH_REMATCH[3]}"
        case "$unit" in K) factor=1024 ;; M) factor=$((1024**2)) ;; G) factor=$((1024**3)) ;; T) factor=$((1024**4)) ;; P) factor=$((1024**5)) ;; esac
        awk -v n="$number" -v f="$factor" 'BEGIN {printf "%.0f", n*f}'
    else
        printf '0'
    fi
}
scan_old_files() {
    local path="$1" show_files="${2:-0}" file size quoted entry shown
    local -a entries=() top=()
    SCAN_COUNT=0; SCAN_BYTES=0
    while IFS= read -r -d '' file; do
        size=$(stat -c '%s' -- "$file" 2>/dev/null || printf '0')
        [[ "$size" =~ ^[0-9]+$ ]] || size=0
        SCAN_COUNT=$((SCAN_COUNT + 1)); SCAN_BYTES=$((SCAN_BYTES + size))
        if ((show_files)); then printf -v quoted '%q' "$file"; entries+=("$size"$'\t'"$quoted"); fi
    done < <(find "$path" -xdev -mindepth 1 -type f -mtime +"$KEEP_DAYS" -print0 2>/dev/null)
    if ((show_files && MAX_PREVIEW_ITEMS > 0 && ${#entries[@]} > 0)); then
        mapfile -t top < <(printf '%s\n' "${entries[@]}" | sort -nr -k1,1 | sed -n "1,${MAX_PREVIEW_ITEMS}p")
        for entry in "${top[@]}"; do
            size="${entry%%$'\t'*}"; quoted="${entry#*$'\t'}"; plan "$(human_bytes "$size")  $quoted"
        done
    fi
    shown=$((SCAN_COUNT < MAX_PREVIEW_ITEMS ? SCAN_COUNT : MAX_PREVIEW_ITEMS))
    if ((show_files && SCAN_COUNT > shown)); then note "$(msg preview_omitted "$((SCAN_COUNT - shown))")"; fi
}
add_estimate() {
    local bytes="${1:-0}" actions="${2:-1}"
    ESTIMATED_RELEASED=$((ESTIMATED_RELEASED + bytes))
    PLANNED_ACTIONS=$((PLANNED_ACTIONS + actions))
}
mode_name() {
    case "$MODE" in 1|quick) msg mode_name_quick ;; 2|standard) msg mode_name_standard ;; 3|full) msg mode_name_full ;; 4|custom) msg mode_name_custom ;; *) printf '%s\n' "$MODE" ;; esac
}
run_cmd() {
    if ((DRY_RUN)); then printf '  +'; printf ' %q' "$@"; printf '\n'; return 0; fi
    "$@"
}

setup_logging() {
    [[ -z "$LOG_FILE" ]] && return
    mkdir -p "$(dirname -- "$LOG_FILE")" 2>/dev/null || die "$(msg error_log "$LOG_FILE")"
    { printf '\n[%s] %s %s\n' "$(date -Is)" "$SCRIPT_NAME" "$VERSION"; } >>"$LOG_FILE" || die "$(msg error_log "$LOG_FILE")"
    exec > >(tee -a "$LOG_FILE") 2>&1
}
setup_lock() {
    ((DRY_RUN)) && return
    mkdir -p "$(dirname -- "$LOCK_DIR")" 2>/dev/null || die "$(msg error_lock)"
    if ! mkdir "$LOCK_DIR" 2>/dev/null; then die 'another LinuxClean process is already running'; fi
    trap 'rmdir -- "$LOCK_DIR" 2>/dev/null || true' EXIT
}

show_banner() {
    info '═══════════════════════════════════════════════════════════'
    paint "$CYAN" "  $(msg banner_title "$VERSION")"
    info '═══════════════════════════════════════════════════════════'
    if ((DRY_RUN)); then warn "  $(msg dry_run)"; fi
}
show_system_info() {
    local distro username cpu total_mem used_mem mem_percent disk_total disk_used disk_percent uptime_info
    if [[ -r /etc/os-release ]]; then
        distro=$( . /etc/os-release; printf '%s' "${PRETTY_NAME:-${NAME:-Linux}}" )
    else
        distro=$(uname -s)
    fi
    username="${SUDO_USER:-${USER:-root}}"
    cpu=$(command_exists nproc && nproc || getconf _NPROCESSORS_ONLN 2>/dev/null || printf '?')
    if command_exists free; then
        # Use the second line instead of matching the translated "Mem:" label.
        IFS=' ' read -r total_mem used_mem mem_percent < <(free -b | awk 'NR==2 {printf "%s %s %.1f\n",$2,$3,($2 ? $3/$2*100 : 0)}')
    else total_mem=0; used_mem=0; mem_percent=0; fi
    local disk_total_k disk_used_k
    IFS=' ' read -r disk_total_k disk_used_k disk_percent < <(df -Pk / | awk 'NR==2 {print $2,$3,$5}')
    disk_total=$(human_bytes "$((disk_total_k * 1024))")
    disk_used=$(human_bytes "$((disk_used_k * 1024))")
    uptime_info=$(uptime -p 2>/dev/null || awk '{print int($1) " seconds"}' /proc/uptime 2>/dev/null || printf '?')
    section "$(msg sys_info_title)"
    printf '  %-10s %s\n' "$(msg sys_os):" "$distro"
    printf '  %-10s %s\n' "$(msg sys_user):" "$username"
    printf '  %-10s %s\n' "$(msg sys_cpu):" "$cpu"
    printf '  %-10s %s (%s: %s, %.1f%%)\n' "$(msg sys_mem):" "$(human_bytes "$total_mem")" "$(msg sys_used)" "$(human_bytes "$used_mem")" "$mem_percent"
    printf '  %-10s %s (%s: %s, %s)\n' "$(msg sys_disk):" "$disk_total" "$(msg sys_used)" "$disk_used" "$disk_percent"
    printf '  %-10s %s\n' "$(msg sys_uptime):" "$uptime_info"
}
show_run_profile() {
    local state users
    if ((DRY_RUN)); then state="$(msg profile_preview)"; else state="$(msg profile_live)"; fi
    if [[ -n "$TARGET_USER" ]]; then users="$TARGET_USER"; else users="$(msg profile_users_all)"; fi
    section "$(msg run_profile)"
    printf '  %-14s %s\n' "$(msg profile_mode):" "$(mode_name)"
    printf '  %-14s %s\n' "$(msg profile_age):" "$(msg profile_age_value "$KEEP_DAYS")"
    printf '  %-14s %s\n' "$(msg profile_journal):" "$JOURNAL_LIMIT"
    printf '  %-14s %s\n' "$(msg profile_users):" "$users"
    printf '  %-14s %s\n' "$(msg profile_state):" "$state"
}

clean_tmp() {
    local before after removed
    section "$(msg tmp_step)"
    before=$(bytes_for /tmp); printf '  %-18s %s\n' "$(msg tmp_current):" "$(human_bytes "$before")"
    scan_old_files /tmp "$DRY_RUN"
    note "$(msg candidate_summary "$SCAN_COUNT" "$(human_bytes "$SCAN_BYTES")")"
    if ((SCAN_COUNT == 0)); then skip "$(msg candidate_none)"; return; fi
    if ((DRY_RUN)); then add_estimate "$SCAN_BYTES"; plan "$(msg planned_reclaim "$(human_bytes "$SCAN_BYTES")")"; return; fi
    if ! confirm "$(msg tmp_prompt "$KEEP_DAYS")"; then skip "$(msg tmp_skipped)"; return; fi
    info "  $(msg tmp_cleaning)"
    find /tmp -xdev -mindepth 1 -type f -mtime +"$KEEP_DAYS" -delete 2>/dev/null || true
    find /tmp -xdev -depth -mindepth 1 -type d -empty -delete 2>/dev/null || true
    after=$(bytes_for /tmp); removed=$((before > after ? before-after : 0)); ok "$(msg tmp_done "$(human_bytes "$removed")")"; TOTAL_RELEASED=$((TOTAL_RELEASED + removed))
}

clean_apt_cache() {
    local before after removed
    section "$(msg apt_step)"
    if ! command_exists apt-get; then skip "$(msg apt_unavailable)"; return; fi
    before=$(bytes_for /var/cache/apt/archives); printf '  %-18s %s\n' "$(msg apt_current):" "$(human_bytes "$before")"
    if ((before <= 4096)); then skip "$(msg candidate_none)"; return; fi
    if ((DRY_RUN)); then add_estimate "$before"; plan "$(msg planned_reclaim "$(human_bytes "$before")")"; run_cmd apt-get -qq clean; return; fi
    if ! confirm "$(msg apt_prompt)"; then skip "$(msg apt_skipped)"; return; fi
    info "  $(msg apt_cleaning)"
    run_cmd apt-get -qq clean
    after=$(bytes_for /var/cache/apt/archives); removed=$((before > after ? before-after : 0)); ok "$(msg apt_done "$(human_bytes "$removed")")"; TOTAL_RELEASED=$((TOTAL_RELEASED + removed))
}

user_database() {
    if command_exists getent; then
        getent passwd
    elif [[ -r /etc/passwd ]]; then
        cat /etc/passwd
    fi
}
user_homes() {
    if [[ -n "$TARGET_USER" ]]; then
        user_database | awk -F: -v user="$TARGET_USER" '$1 == user && $6 != "" {print $6}'
    else
        user_database | awk -F: '($3 == 0 || ($3 >= 1000 && $3 < 60000)) && $6 ~ /^\// {print $6}'
    fi
}
clean_user_cache() {
    local home cache before after removed total_before=0 total_count=0 total_bytes=0 found=0
    local -a homes=()
    section "$(msg cache_step)"
    mapfile -t homes < <(user_homes)
    for home in "${homes[@]}"; do
        cache="$home/.cache"; [[ -d "$cache" ]] || continue
        found=1; before=$(bytes_for "$cache"); total_before=$((total_before + before)); printf '  %-18s %s\n' "$cache:" "$(human_bytes "$before")"
        scan_old_files "$cache" "$DRY_RUN"
        total_count=$((total_count + SCAN_COUNT)); total_bytes=$((total_bytes + SCAN_BYTES))
    done
    if ((found == 0)); then skip "$(msg cache_none)"; return; fi
    note "$(msg candidate_summary "$total_count" "$(human_bytes "$total_bytes")")"
    if ((total_count == 0)); then skip "$(msg candidate_none)"; return; fi
    if ((DRY_RUN)); then add_estimate "$total_bytes"; plan "$(msg planned_reclaim "$(human_bytes "$total_bytes")")"; return; fi
    if ! confirm "$(msg cache_prompt "$KEEP_DAYS")"; then skip "$(msg skipped)"; return; fi
    info "  $(msg cache_cleaning)"
    for home in "${homes[@]}"; do
        cache="$home/.cache"; [[ -d "$cache" ]] || continue
        find "$cache" -xdev -mindepth 1 -type f -mtime +"$KEEP_DAYS" -delete 2>/dev/null || true
        find "$cache" -xdev -depth -mindepth 1 -type d -empty -delete 2>/dev/null || true
    done
    after=0
    for home in "${homes[@]}"; do
        cache="$home/.cache"
        if [[ -d "$cache" ]]; then after=$((after + $(bytes_for "$cache"))); fi
    done
    removed=$((total_before > after ? total_before-after : 0)); TOTAL_RELEASED=$((TOTAL_RELEASED + removed)); ok "$(msg cache_done "$(human_bytes "$removed")")"
}

validate_journal_size() { [[ "$1" =~ ^[0-9]+([KMGTP]B?|B)$ ]]; }
clean_journal() {
    local current_raw new_raw current_bytes limit_bytes new_bytes estimate removed
    section "$(msg journal_step)"
    if ! command_exists journalctl; then skip "$(msg journal_unavailable)"; return; fi
    current_raw=$(journalctl --disk-usage 2>/dev/null | tail -1); current_bytes=$(size_to_bytes "${current_raw:-0}"); limit_bytes=$(size_to_bytes "$JOURNAL_LIMIT")
    printf '  %-18s %s\n' "$(msg journal_current):" "$(human_bytes "$current_bytes")"
    printf '  %-18s %s\n' "$(msg journal_target):" "$(human_bytes "$limit_bytes")"
    validate_journal_size "$JOURNAL_LIMIT" || { skip "$(msg error_bad_size)"; return; }
    estimate=$((current_bytes > limit_bytes ? current_bytes-limit_bytes : 0))
    if ((estimate == 0)); then skip "$(msg journal_within_limit)"; return; fi
    if ((DRY_RUN)); then add_estimate "$estimate"; plan "$(msg planned_reclaim "$(human_bytes "$estimate")")"; run_cmd journalctl --vacuum-size="$JOURNAL_LIMIT"; return; fi
    if ! confirm "$(msg journal_prompt "$JOURNAL_LIMIT")"; then skip "$(msg skipped)"; return; fi
    info "  $(msg journal_cleaning "$JOURNAL_LIMIT")"
    run_cmd journalctl --vacuum-size="$JOURNAL_LIMIT"
    new_raw=$(journalctl --disk-usage 2>/dev/null | tail -1); new_bytes=$(size_to_bytes "${new_raw:-0}"); removed=$((current_bytes > new_bytes ? current_bytes-new_bytes : 0)); TOTAL_RELEASED=$((TOTAL_RELEASED + removed)); ok "$(msg journal_done "$(human_bytes "$new_bytes")")"
}

installed_kernel_packages() {
    local pkg
    while IFS=$'\t' read -r pkg status; do
        [[ "$status" == 'install ok installed' ]] || continue
        [[ "$pkg" =~ ^linux-image-(unsigned-)?[0-9] ]] || continue
        printf '%s\n' "$pkg"
    done < <(dpkg-query -W -f='${binary:Package}\t${Status}\n' 'linux-image*' 2>/dev/null || true)
}
package_size_bytes() {
    local kib
    kib=$(dpkg-query -W -f='${Installed-Size}' "$1" 2>/dev/null || printf '0')
    [[ "$kib" =~ ^[0-9]+$ ]] || kib=0
    printf '%s' "$((kib * 1024))"
}
clean_residual_configs() {
    local -a residual=()
    mapfile -t residual < <(dpkg-query -W -f='${binary:Package}\t${Status}\n' 2>/dev/null | awk -F'\t' '$2 == "deinstall ok config-files" {print $1}')
    ((${#residual[@]})) || return 0
    note "$(msg residual_candidates "${#residual[@]}")"
    if ((DRY_RUN)); then add_estimate 0; printf '  + dpkg --purge'; printf ' %q' "${residual[@]}"; printf '\n'; return; fi
    if ! confirm "$(msg residual_prompt "${#residual[@]}")"; then skip "$(msg skipped)"; return; fi
    info "  $(msg residual_cleaning)"
    if dpkg --purge "${residual[@]}" >/dev/null 2>&1; then
        ok "$(msg residual_done "${#residual[@]}")"
    else
        warn "$(msg error_purge)"
    fi
}
clean_old_kernels() {
    local current="$(uname -r)" pkg fallback='' pkg_bytes total_bytes=0
    local -a installed=() others=() sorted=() candidates=()
    section "$(msg kernel_step)"; printf '  %-28s %s\n' "$(msg kernel_current):" "$current"
    if ! command_exists dpkg-query || ! command_exists apt-get; then skip "$(msg kernel_none)"; return; fi
    mapfile -t installed < <(installed_kernel_packages)
    for pkg in "${installed[@]}"; do [[ "$pkg" == *"$current"* ]] || others+=("$pkg"); done
    if ((${#others[@]})); then mapfile -t sorted < <(printf '%s\n' "${others[@]}" | sort -V); fallback="${sorted[-1]}"; fi
    if ((${#sorted[@]} > 1)); then candidates=("${sorted[@]:0:${#sorted[@]}-1}"); fi
    printf '  %-28s %d\n' "$(msg kernel_installed):" "${#installed[@]}"
    [[ -n "$fallback" ]] && printf '  %-28s %s\n' "$(msg kernel_fallback):" "$fallback"
    if ((${#candidates[@]} == 0)); then skip "$(msg kernel_none)"; clean_residual_configs; return; fi
    printf '  %s: %d\n' "$(msg kernel_remove)" "${#candidates[@]}"
    for pkg in "${candidates[@]}"; do pkg_bytes=$(package_size_bytes "$pkg"); total_bytes=$((total_bytes + pkg_bytes)); plan "$(human_bytes "$pkg_bytes")  $pkg"; done
    note "$(msg candidate_summary "${#candidates[@]}" "$(human_bytes "$total_bytes")")"
    if ((DRY_RUN)); then add_estimate "$total_bytes"; plan "$(msg planned_reclaim "$(human_bytes "$total_bytes")")"; run_cmd apt-get -y purge "${candidates[@]}"; clean_residual_configs; return; fi
    if ! confirm "$(msg kernel_prompt)"; then skip "$(msg skipped)"; return; fi
    info "  $(msg kernel_cleaning)"; run_cmd apt-get -y purge "${candidates[@]}"; TOTAL_RELEASED=$((TOTAL_RELEASED + total_bytes)); ok "$(msg kernel_done)"; clean_residual_configs
}

run_custom() {
    local choice
    while :; do
        printf '\n1) %s\n2) %s\n3) %s\n4) %s\n0) %s\n' "$(msg tmp_step)" "$(msg apt_step)" "$(msg cache_step)" "$(msg journal_step) / $(msg kernel_step)" "$(msg mode_exit)"
        read -r -p "$(msg mode_prompt): " choice || return
        case "$choice" in
            1) clean_tmp ;; 2) clean_apt_cache ;; 3) clean_user_cache ;; 4) clean_journal; clean_old_kernels ;; 0) return ;; *) warn "$(msg mode_prompt)" ;;
        esac
    done
}

show_summary() {
    if ((DRY_RUN)); then section "$(msg preview_title)"; else section "$(msg complete_title)"; fi
    if ((DRY_RUN)); then msg preview_disk; else msg complete_disk; fi
    df -Pk / | awk -v label="$(msg complete_root)" 'NR==2 {printf "  %s: %.1f GiB / %.1f GiB (%s)\n", label, $3/1048576, $2/1048576, $5}'
    if ((DRY_RUN)); then
        plan "$(msg estimated_summary "$(human_bytes "$ESTIMATED_RELEASED")" "$PLANNED_ACTIONS")"
        note "$(msg estimate_note)"
    else
        ok "$(msg summary "$(human_bytes "$TOTAL_RELEASED")")"
    fi
}
main() {
    detect_language
    parse_args "$@"
    require_root
    setup_logging
    setup_lock
    show_banner
    show_system_info
    if [[ -z "$MODE" ]]; then
        [[ -t 0 ]] || die "$(msg error_noninteractive)"
        section "$(msg mode_title)"; printf '  1) %s\n  2) %s\n  3) %s\n  4) %s\n  0) %s\n' "$(msg mode_quick)" "$(msg mode_standard)" "$(msg mode_full)" "$(msg mode_custom)" "$(msg mode_exit)"
        read -r -p "$(msg mode_prompt): " MODE || MODE=0
    fi
    if [[ "$MODE" == 0 || "$MODE" == exit ]]; then return 0; fi
    show_run_profile
    case "$MODE" in
        1|quick) clean_tmp; clean_apt_cache ;;
        2|standard) clean_tmp; clean_apt_cache; clean_user_cache; clean_journal ;;
        3|full) clean_tmp; clean_apt_cache; clean_user_cache; clean_journal; clean_old_kernels ;;
        4|custom) ((DRY_RUN)) || [[ -t 0 ]] || die "$(msg error_noninteractive)"; run_custom ;;
        0|exit) return 0 ;;
        *) die "$(msg error_bad_mode "$MODE")" ;;
    esac
    show_summary
}

main "$@"
