#!/bin/bash

# ============================================================================
# 云主机硬件信息收集脚本（精简版）
# 适用于快速查询客户云主机的 CPU、内存、磁盘、网络及 BIOS 信息
# 独立运行，无需额外依赖
# 用法: bash collect-hardware-info-lite.sh [输出文件路径]
# ============================================================================

set -euo pipefail

# ---- 颜色 ----
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
RED='\033[0;31m'
BOLD='\033[1m'
NC='\033[0m'

# ---- 输出文件 ----
DEFAULT_OUTPUT="hwinfo_lite_$(hostname)_$(date +%Y%m%d_%H%M%S).txt"
OUTPUT_FILE="${1:-$DEFAULT_OUTPUT}"

# ---- 辅助函数 ----
info()  { echo -e "${CYAN}[INFO]${NC} $*"; }
ok()    { echo -e "${GREEN}[OK]${NC} $*"; }
warn()  { echo -e "${YELLOW}[WARN]${NC} $*"; }

cmd_ok() { command -v "$1" &>/dev/null; }

# 写入分隔标题
title() {
    printf '\n%s\n  %s\n%s\n\n' \
        "================================================================" \
        "$1" \
        "================================================================" >> "$OUTPUT_FILE"
    info "收集: $1"
}

# 安全执行命令写入报告
run() {
    local label="$1"; shift
    echo "--- $label ---" >> "$OUTPUT_FILE"
    if cmd_ok "$1"; then
        "$@" >> "$OUTPUT_FILE" 2>&1 || echo "(执行失败: $*)" >> "$OUTPUT_FILE"
    else
        echo "(不可用: $1)" >> "$OUTPUT_FILE"
    fi
    echo "" >> "$OUTPUT_FILE"
}

# ---- 环境检查 ----
if [[ "$(uname -s)" != "Linux" ]]; then
    echo -e "${RED}[ERROR]${NC} 仅支持 Linux（当前: $(uname -s)）"; exit 1
fi
if [[ $EUID -ne 0 ]]; then
    warn "建议 root 运行以获取完整信息: sudo bash $0 $*"
fi

# ---- 报告头部 ----
{
    echo "============================================================"
    echo "  云主机硬件信息报告（精简版）"
    echo "  主机名:   $(hostname)"
    echo "  时间:     $(date '+%Y-%m-%d %H:%M:%S')"
    echo "  用户:     $(whoami)"
    echo "  内核:     $(uname -r)"
    echo "============================================================"
} > "$OUTPUT_FILE"

echo ""
echo -e "${BOLD}  云主机硬件信息收集（精简版）${NC}"
echo ""
info "输出文件: $OUTPUT_FILE"
echo ""

# ==========================================================================
# 1. 系统概况
# ==========================================================================
title "系统概况"
{
    echo "主机名:     $(hostname)"
    echo "内核:       $(uname -r)"
    echo "架构:       $(uname -m)"
    echo "运行时间:   $(uptime -p 2>/dev/null || uptime)"
    echo ""
    echo "--- 发行版 ---"
} >> "$OUTPUT_FILE"

if [[ -f /etc/os-release ]]; then
    grep -E '^(NAME|VERSION|ID)=' /etc/os-release >> "$OUTPUT_FILE"
elif [[ -f /etc/redhat-release ]]; then
    cat /etc/redhat-release >> "$OUTPUT_FILE"
fi
echo "" >> "$OUTPUT_FILE"

# ==========================================================================
# 2. CPU 信息
# ==========================================================================
title "CPU 信息"

echo "--- CPU 摘要 ---" >> "$OUTPUT_FILE"
if [[ -r /proc/cpuinfo ]]; then
    cpu_model=$(grep -m1 'model name' /proc/cpuinfo | cut -d: -f2 | xargs 2>/dev/null || echo "N/A")
    cpu_logical=$(grep -c '^processor' /proc/cpuinfo 2>/dev/null || echo "N/A")
    cpu_sockets=$(grep 'physical id' /proc/cpuinfo | sort -u | wc -l 2>/dev/null || echo "N/A")
    cpu_cores_per=$(grep -m1 'cpu cores' /proc/cpuinfo | cut -d: -f2 | xargs 2>/dev/null || echo "N/A")
    cpu_freq=$(grep -m1 'cpu MHz' /proc/cpuinfo | cut -d: -f2 | xargs 2>/dev/null || echo "N/A")
    cpu_cache=$(grep -m1 'cache size' /proc/cpuinfo | cut -d: -f2 | xargs 2>/dev/null || echo "N/A")
    cpu_flags_virt=""
    grep -qm1 ' vmx ' /proc/cpuinfo 2>/dev/null && cpu_flags_virt="VMX(Intel VT-x)"
    grep -qm1 ' svm ' /proc/cpuinfo 2>/dev/null && cpu_flags_virt="SVM(AMD-V)"
    {
        printf "%-16s: %s\n" "型号" "$cpu_model"
        printf "%-16s: %s\n" "物理CPU数" "$cpu_sockets"
        printf "%-16s: %s\n" "每CPU核心数" "$cpu_cores_per"
        printf "%-16s: %s\n" "逻辑CPU总数" "$cpu_logical"
        printf "%-16s: %s MHz\n" "当前频率" "$cpu_freq"
        printf "%-16s: %s\n" "缓存大小" "$cpu_cache"
        printf "%-16s: %s\n" "虚拟化支持" "${cpu_flags_virt:-无}"
    } >> "$OUTPUT_FILE"
else
    echo "(无法读取 /proc/cpuinfo)" >> "$OUTPUT_FILE"
fi
echo "" >> "$OUTPUT_FILE"

run "lscpu 输出" lscpu

# ==========================================================================
# 3. 内存信息
# ==========================================================================
title "内存信息"

echo "--- 内存摘要 ---" >> "$OUTPUT_FILE"
if [[ -r /proc/meminfo ]]; then
    mem_total=$(awk '/^MemTotal/ {printf "%.1f GB", $2/1024/1024}' /proc/meminfo)
    mem_free=$(awk '/^MemAvailable/ {printf "%.1f GB", $2/1024/1024}' /proc/meminfo)
    swap_total=$(awk '/^SwapTotal/ {printf "%.1f GB", $2/1024/1024}' /proc/meminfo)
    {
        printf "%-16s: %s\n" "总内存" "$mem_total"
        printf "%-16s: %s\n" "可用内存" "$mem_free"
        printf "%-16s: %s\n" "Swap 总量" "$swap_total"
    } >> "$OUTPUT_FILE"
fi
echo "" >> "$OUTPUT_FILE"

run "free -h" free -h
run "内存插槽详情 (dmidecode)" dmidecode -t memory

# ==========================================================================
# 4. 磁盘信息
# ==========================================================================
title "磁盘信息"

run "块设备 (lsblk)" lsblk -o NAME,SIZE,TYPE,FSTYPE,MOUNTPOINT,MODEL
run "磁盘使用 (df -hT)" df -hT
run "磁盘分区 (fdisk -l)" fdisk -l

# ==========================================================================
# 5. 网络信息
# ==========================================================================
title "网络信息"

run "网卡列表 (ip addr)" ip addr show

echo "--- 网卡摘要 ---" >> "$OUTPUT_FILE"
if cmd_ok ip; then
    ip -o link show | awk -F': ' '{print $2}' | grep -v lo | while read -r iface; do
        mac=$(ip link show "$iface" 2>/dev/null | awk '/link\/ether/ {print $2}')
        ipv4=$(ip -4 addr show "$iface" 2>/dev/null | awk '/inet / {print $2}')
        state=$(ip link show "$iface" 2>/dev/null | awk '/state/ {for(i=1;i<=NF;i++) if($i=="state") print $(i+1)}')
        printf "%-14s  MAC=%-18s  IP=%-18s  状态=%s\n" "$iface" "${mac:-N/A}" "${ipv4:-N/A}" "${state:-N/A}" >> "$OUTPUT_FILE"
    done
fi
echo "" >> "$OUTPUT_FILE"

# ==========================================================================
# 6. BIOS / UEFI 信息
# ==========================================================================
title "BIOS / UEFI 信息"

# sysfs 快速读取（无需 root 也可能读到）
echo "--- BIOS 基本信息 (/sys/class/dmi/id/) ---" >> "$OUTPUT_FILE"
dmi="/sys/class/dmi/id"
if [[ -d "$dmi" ]]; then
    for key in bios_vendor bios_version bios_date bios_release; do
        [[ -r "$dmi/$key" ]] && printf "%-20s: %s\n" "$key" "$(cat "$dmi/$key" 2>/dev/null)" >> "$OUTPUT_FILE"
    done
else
    echo "(DMI sysfs 不可用)" >> "$OUTPUT_FILE"
fi
echo "" >> "$OUTPUT_FILE"

run "BIOS 详情 (dmidecode -t bios)" dmidecode -t bios

echo "--- 启动模式 ---" >> "$OUTPUT_FILE"
if [[ -d /sys/firmware/efi ]]; then
    echo "UEFI 模式" >> "$OUTPUT_FILE"
else
    echo "Legacy BIOS 模式" >> "$OUTPUT_FILE"
fi
echo "" >> "$OUTPUT_FILE"

# ==========================================================================
# 7. 系统/主板/机箱信息
# ==========================================================================
title "系统 / 主板 / 机箱信息"

echo "--- 系统信息 (/sys/class/dmi/id/) ---" >> "$OUTPUT_FILE"
if [[ -d "$dmi" ]]; then
    for key in sys_vendor product_name product_version product_serial \
               board_vendor board_name board_version \
               chassis_type chassis_vendor; do
        [[ -r "$dmi/$key" ]] && printf "%-20s: %s\n" "$key" "$(cat "$dmi/$key" 2>/dev/null)" >> "$OUTPUT_FILE"
    done
fi
echo "" >> "$OUTPUT_FILE"

run "系统信息 (dmidecode -t system)" dmidecode -t system
run "主板信息 (dmidecode -t baseboard)" dmidecode -t baseboard

# ==========================================================================
# 8. 虚拟化检测
# ==========================================================================
title "虚拟化检测"

echo "--- 虚拟化类型 ---" >> "$OUTPUT_FILE"
if cmd_ok systemd-detect-virt; then
    virt_type=$(systemd-detect-virt 2>/dev/null || echo "none")
    echo "systemd-detect-virt: $virt_type" >> "$OUTPUT_FILE"
fi
# 从 DMI 判断常见云厂商
if [[ -r "$dmi/sys_vendor" ]]; then
    vendor=$(cat "$dmi/sys_vendor" 2>/dev/null)
    product=$(cat "$dmi/product_name" 2>/dev/null || echo "")
    echo "厂商: $vendor / $product" >> "$OUTPUT_FILE"
    case "$vendor" in
        *Tencent*|*tencent*)  echo "云平台: 腾讯云" >> "$OUTPUT_FILE" ;;
        *Alibaba*|*alibaba*)  echo "云平台: 阿里云" >> "$OUTPUT_FILE" ;;
        *Amazon*|*amazon*)    echo "云平台: AWS"    >> "$OUTPUT_FILE" ;;
        *Microsoft*|*Hyper*)  echo "云平台: Azure"  >> "$OUTPUT_FILE" ;;
        *Google*|*google*)    echo "云平台: GCP"    >> "$OUTPUT_FILE" ;;
        *HUAWEI*|*huawei*)    echo "云平台: 华为云" >> "$OUTPUT_FILE" ;;
        *QEMU*|*KVM*)         echo "虚拟化: KVM/QEMU" >> "$OUTPUT_FILE" ;;
        *VMware*)             echo "虚拟化: VMware" >> "$OUTPUT_FILE" ;;
        *Xen*)                echo "虚拟化: Xen"    >> "$OUTPUT_FILE" ;;
        *)                    echo "云平台: 未识别"  >> "$OUTPUT_FILE" ;;
    esac
fi
echo "" >> "$OUTPUT_FILE"

run "Hypervisor 信息 (dmidecode -t system 摘要)" bash -c "dmidecode -t system 2>/dev/null | grep -iE 'manufacturer|product|version|serial|uuid'"

# ==========================================================================
# 报告结尾
# ==========================================================================
{
    echo ""
    echo "============================================================"
    echo "  报告完毕 — $(date '+%Y-%m-%d %H:%M:%S')"
    echo "============================================================"
} >> "$OUTPUT_FILE"

echo ""
ok "收集完成！"
ok "报告: ${BOLD}$OUTPUT_FILE${NC}"
file_size=$(du -h "$OUTPUT_FILE" | cut -f1)
info "大小: $file_size"
echo ""
