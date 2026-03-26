#!/bin/bash

# ============================================================================
# 硬件信息 & BIOS 信息收集脚本
# 独立运行，无需额外依赖
# 用法: bash collect-hardware-info.sh [输出文件路径]
# ============================================================================

set -euo pipefail

# ---- 颜色定义 ----
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# ---- 输出文件 ----
DEFAULT_OUTPUT="hardware_info_$(hostname)_$(date +%Y%m%d_%H%M%S).txt"
OUTPUT_FILE="${1:-$DEFAULT_OUTPUT}"

# ---- 辅助函数 ----
print_info()    { echo -e "${CYAN}[INFO]${NC} $*"; }
print_success() { echo -e "${GREEN}[OK]${NC} $*"; }
print_warning() { echo -e "${YELLOW}[WARN]${NC} $*"; }
print_error()   { echo -e "${RED}[ERROR]${NC} $*"; }

command_exists() { command -v "$1" &>/dev/null; }

# 安全执行命令并写入报告（命令不存在或失败时给出提示）
run_cmd() {
    local label="$1"
    shift
    echo "--- $label ---" >> "$OUTPUT_FILE"
    if command_exists "$1"; then
        "$@" >> "$OUTPUT_FILE" 2>&1 || echo "(命令执行失败: $*)" >> "$OUTPUT_FILE"
    else
        echo "(命令不可用: $1)" >> "$OUTPUT_FILE"
    fi
    echo "" >> "$OUTPUT_FILE"
}

# 安全读取文件并写入报告
read_sys_file() {
    local label="$1"
    local filepath="$2"
    echo "--- $label ---" >> "$OUTPUT_FILE"
    if [[ -r "$filepath" ]]; then
        cat "$filepath" >> "$OUTPUT_FILE" 2>&1
    else
        echo "(文件不可读或不存在: $filepath)" >> "$OUTPUT_FILE"
    fi
    echo "" >> "$OUTPUT_FILE"
}

# 写入分隔标题
section() {
    local title="$1"
    {
        echo ""
        echo "========================================================================"
        echo "  $title"
        echo "========================================================================"
        echo ""
    } >> "$OUTPUT_FILE"
    print_info "正在收集: $title ..."
}

# ---- 检查运行环境 ----
check_environment() {
    if [[ "$(uname -s)" != "Linux" ]]; then
        print_error "此脚本仅支持 Linux 系统（当前系统: $(uname -s)）"
        exit 1
    fi

    if [[ $EUID -ne 0 ]]; then
        print_warning "建议以 root 权限运行以获取完整信息（当前为普通用户）"
        print_warning "可使用: sudo bash $0 $*"
        echo ""
    fi
}

# ---- 信息收集函数 ----

collect_basic_info() {
    section "基本系统信息"
    {
        echo "--- 主机名 ---"
        hostname
        echo ""
        echo "--- 内核版本 ---"
        uname -a
        echo ""
        echo "--- 发行版信息 ---"
    } >> "$OUTPUT_FILE"

    if [[ -f /etc/os-release ]]; then
        cat /etc/os-release >> "$OUTPUT_FILE"
    elif [[ -f /etc/redhat-release ]]; then
        cat /etc/redhat-release >> "$OUTPUT_FILE"
    elif command_exists lsb_release; then
        lsb_release -a >> "$OUTPUT_FILE" 2>&1
    else
        echo "(无法获取发行版信息)" >> "$OUTPUT_FILE"
    fi
    echo "" >> "$OUTPUT_FILE"

    run_cmd "系统运行时间" uptime
    run_cmd "当前日期时间" date
}

collect_cpu_info() {
    section "CPU 信息"
    read_sys_file "CPU 详细信息 (/proc/cpuinfo)" /proc/cpuinfo

    run_cmd "CPU 架构信息 (lscpu)" lscpu

    # CPU 摘要
    echo "--- CPU 摘要 ---" >> "$OUTPUT_FILE"
    if [[ -r /proc/cpuinfo ]]; then
        local cpu_model cpu_cores cpu_threads
        cpu_model=$(grep -m1 'model name' /proc/cpuinfo | cut -d: -f2 | xargs)
        cpu_cores=$(grep -c '^processor' /proc/cpuinfo)
        cpu_threads=$(grep 'cpu cores' /proc/cpuinfo | head -1 | cut -d: -f2 | xargs)
        {
            echo "型号:     $cpu_model"
            echo "逻辑CPU:  $cpu_cores"
            echo "每颗物理核心: ${cpu_threads:-N/A}"
        } >> "$OUTPUT_FILE"
    fi
    echo "" >> "$OUTPUT_FILE"
}

collect_memory_info() {
    section "内存信息"
    read_sys_file "内存使用概况 (/proc/meminfo)" /proc/meminfo
    run_cmd "内存概要 (free -h)" free -h

    # 内存硬件详情（需要 root）
    run_cmd "内存插槽详情 (dmidecode -t memory)" dmidecode -t memory
}

collect_disk_info() {
    section "磁盘/存储信息"
    run_cmd "块设备列表 (lsblk)" lsblk -o NAME,SIZE,TYPE,FSTYPE,MOUNTPOINT,MODEL,SERIAL
    run_cmd "磁盘分区表 (fdisk -l)" fdisk -l
    run_cmd "磁盘使用情况 (df -hT)" df -hT
    run_cmd "SCSI 设备" lsscsi

    # 磁盘 SMART 信息
    if command_exists smartctl; then
        echo "--- 磁盘 SMART 信息 ---" >> "$OUTPUT_FILE"
        for disk in $(lsblk -dno NAME 2>/dev/null | grep -E '^(sd|nvme|vd)'); do
            echo ">> /dev/$disk" >> "$OUTPUT_FILE"
            smartctl -i "/dev/$disk" >> "$OUTPUT_FILE" 2>&1 || true
            echo "" >> "$OUTPUT_FILE"
        done
    else
        echo "--- 磁盘 SMART 信息 ---" >> "$OUTPUT_FILE"
        echo "(smartctl 不可用，可安装 smartmontools)" >> "$OUTPUT_FILE"
        echo "" >> "$OUTPUT_FILE"
    fi

    # NVMe 设备
    run_cmd "NVMe 设备列表" nvme list
}

collect_pci_info() {
    section "PCI 设备信息"
    run_cmd "PCI 设备列表 (lspci)" lspci -v
    run_cmd "PCI 设备树 (lspci -t)" lspci -t
}

collect_usb_info() {
    section "USB 设备信息"
    run_cmd "USB 设备列表 (lsusb)" lsusb
    run_cmd "USB 设备详情 (lsusb -v 摘要)" lsusb -t
}

collect_network_info() {
    section "网络硬件信息"
    run_cmd "网络接口列表 (ip link)" ip link show
    run_cmd "网络接口地址 (ip addr)" ip addr show

    # 网卡详细信息
    if command_exists ethtool; then
        echo "--- 网卡详细信息 (ethtool) ---" >> "$OUTPUT_FILE"
        for iface in $(ip -o link show | awk -F': ' '{print $2}' | grep -v lo); do
            echo ">> $iface" >> "$OUTPUT_FILE"
            ethtool "$iface" >> "$OUTPUT_FILE" 2>&1 || true
            ethtool -i "$iface" >> "$OUTPUT_FILE" 2>&1 || true
            echo "" >> "$OUTPUT_FILE"
        done
    else
        echo "--- 网卡详细信息 (ethtool) ---" >> "$OUTPUT_FILE"
        echo "(ethtool 不可用)" >> "$OUTPUT_FILE"
        echo "" >> "$OUTPUT_FILE"
    fi
}

collect_gpu_info() {
    section "GPU / 显卡信息"
    run_cmd "VGA 控制器 (lspci | grep VGA)" bash -c "lspci | grep -i vga"
    run_cmd "3D 控制器 (lspci | grep 3D)" bash -c "lspci | grep -i 3d"
    run_cmd "NVIDIA GPU 信息 (nvidia-smi)" nvidia-smi
    run_cmd "AMD GPU 信息 (radeontop)" bash -c "radeontop -d - -l 1 2>/dev/null | head -5"
}

collect_bios_info() {
    section "BIOS / UEFI 信息"
    run_cmd "BIOS 信息 (dmidecode -t bios)" dmidecode -t bios

    # 从 sysfs 读取 BIOS 信息
    echo "--- BIOS 信息 (/sys/class/dmi/id/) ---" >> "$OUTPUT_FILE"
    local dmi_dir="/sys/class/dmi/id"
    if [[ -d "$dmi_dir" ]]; then
        for f in bios_vendor bios_version bios_date bios_release; do
            if [[ -r "$dmi_dir/$f" ]]; then
                printf "%-20s: %s\n" "$f" "$(cat "$dmi_dir/$f" 2>/dev/null)" >> "$OUTPUT_FILE"
            fi
        done
    else
        echo "(DMI sysfs 目录不可用)" >> "$OUTPUT_FILE"
    fi
    echo "" >> "$OUTPUT_FILE"

    run_cmd "UEFI 固件信息" bash -c "ls /sys/firmware/efi 2>/dev/null && echo 'UEFI 模式' || echo '非 UEFI 模式（Legacy BIOS）'"
    run_cmd "UEFI 变量" bash -c "efibootmgr -v 2>/dev/null || echo '(efibootmgr 不可用或非 UEFI 模式)'"
}

collect_motherboard_info() {
    section "主板 / 底板信息"
    run_cmd "主板信息 (dmidecode -t baseboard)" dmidecode -t baseboard

    # 从 sysfs 读取主板信息
    echo "--- 主板信息 (/sys/class/dmi/id/) ---" >> "$OUTPUT_FILE"
    local dmi_dir="/sys/class/dmi/id"
    if [[ -d "$dmi_dir" ]]; then
        for f in board_vendor board_name board_version board_serial; do
            if [[ -r "$dmi_dir/$f" ]]; then
                printf "%-20s: %s\n" "$f" "$(cat "$dmi_dir/$f" 2>/dev/null)" >> "$OUTPUT_FILE"
            fi
        done
    else
        echo "(DMI sysfs 目录不可用)" >> "$OUTPUT_FILE"
    fi
    echo "" >> "$OUTPUT_FILE"
}

collect_chassis_info() {
    section "机箱 / 系统封装信息"
    run_cmd "机箱信息 (dmidecode -t chassis)" dmidecode -t chassis
    run_cmd "系统信息 (dmidecode -t system)" dmidecode -t system

    # 从 sysfs 读取系统信息
    echo "--- 系统信息 (/sys/class/dmi/id/) ---" >> "$OUTPUT_FILE"
    local dmi_dir="/sys/class/dmi/id"
    if [[ -d "$dmi_dir" ]]; then
        for f in sys_vendor product_name product_version product_serial product_uuid chassis_type chassis_vendor; do
            if [[ -r "$dmi_dir/$f" ]]; then
                printf "%-20s: %s\n" "$f" "$(cat "$dmi_dir/$f" 2>/dev/null)" >> "$OUTPUT_FILE"
            fi
        done
    else
        echo "(DMI sysfs 目录不可用)" >> "$OUTPUT_FILE"
    fi
    echo "" >> "$OUTPUT_FILE"
}

collect_slot_info() {
    section "系统插槽信息"
    run_cmd "系统插槽 (dmidecode -t slot)" dmidecode -t slot
    run_cmd "处理器插槽 (dmidecode -t processor)" dmidecode -t processor
}

collect_power_info() {
    section "电源信息"
    run_cmd "电源/电池信息 (dmidecode -t 39)" dmidecode -t 39

    # IPMI 信息
    run_cmd "IPMI 传感器信息" ipmitool sensor list
    run_cmd "IPMI 系统事件日志 (最近10条)" bash -c "ipmitool sel list 2>/dev/null | tail -10"
}

collect_thermal_info() {
    section "温度 / 传感器信息"
    run_cmd "温度传感器 (sensors)" sensors

    # 从 sysfs 读取温度
    echo "--- CPU 温度 (/sys/class/thermal/) ---" >> "$OUTPUT_FILE"
    if [[ -d /sys/class/thermal ]]; then
        for tz in /sys/class/thermal/thermal_zone*; do
            if [[ -r "$tz/type" ]] && [[ -r "$tz/temp" ]]; then
                local tz_type tz_temp
                tz_type=$(cat "$tz/type" 2>/dev/null)
                tz_temp=$(cat "$tz/temp" 2>/dev/null)
                if [[ -n "$tz_temp" ]]; then
                    printf "%-20s: %s°C\n" "$tz_type" "$(echo "scale=1; $tz_temp/1000" | bc 2>/dev/null || echo "$tz_temp")" >> "$OUTPUT_FILE"
                fi
            fi
        done
    else
        echo "(thermal sysfs 目录不可用)" >> "$OUTPUT_FILE"
    fi
    echo "" >> "$OUTPUT_FILE"
}

collect_kernel_modules() {
    section "内核模块 / 驱动信息"
    run_cmd "已加载内核模块 (lsmod)" lsmod
    run_cmd "内核版本" uname -r
    run_cmd "内核命令行参数" cat /proc/cmdline
}

collect_full_dmidecode() {
    section "完整 DMI/SMBIOS 表 (dmidecode)"
    run_cmd "完整 DMI 信息" dmidecode
}

# ---- 主函数 ----
main() {
    echo ""
    echo -e "${BOLD}============================================${NC}"
    echo -e "${BOLD}   Linux 硬件信息 & BIOS 信息收集工具${NC}"
    echo -e "${BOLD}============================================${NC}"
    echo ""

    check_environment

    # 初始化输出文件
    {
        echo "============================================================"
        echo "  硬件信息 & BIOS 信息收集报告"
        echo "  主机名:   $(hostname)"
        echo "  生成时间: $(date '+%Y-%m-%d %H:%M:%S')"
        echo "  执行用户: $(whoami)"
        echo "  内核版本: $(uname -r)"
        echo "============================================================"
    } > "$OUTPUT_FILE"

    print_info "输出文件: $OUTPUT_FILE"
    echo ""

    # 逐项收集
    collect_basic_info
    collect_cpu_info
    collect_memory_info
    collect_disk_info
    collect_pci_info
    collect_usb_info
    collect_network_info
    collect_gpu_info
    collect_bios_info
    collect_motherboard_info
    collect_chassis_info
    collect_slot_info
    collect_power_info
    collect_thermal_info
    collect_kernel_modules
    collect_full_dmidecode

    # 写入结尾
    {
        echo ""
        echo "============================================================"
        echo "  报告生成完毕"
        echo "  生成时间: $(date '+%Y-%m-%d %H:%M:%S')"
        echo "============================================================"
    } >> "$OUTPUT_FILE"

    echo ""
    print_success "信息收集完成！"
    print_success "报告已保存至: ${BOLD}$OUTPUT_FILE${NC}"
    echo ""

    # 显示文件大小
    local file_size
    file_size=$(du -h "$OUTPUT_FILE" | cut -f1)
    print_info "文件大小: $file_size"
    echo ""
}

main "$@"
