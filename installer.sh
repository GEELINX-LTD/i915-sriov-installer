#!/bin/bash

BRAND_NAME="Geelinx"

C_RESET='\e[0m'
C_BOLD='\e[1m'
C_DIM='\e[2m'
C_RED='\e[31m'
C_GREEN='\e[32m'
C_YELLOW='\e[33m'
C_BLUE='\e[34m'
C_CYAN='\e[36m'

LOG_FILE="/tmp/vgpu_deploy.log"

print_banner() {
    clear
    echo -e "${C_CYAN}${C_BOLD}"
    echo "  ██╗   ██╗ ██████╗ ██████╗ ██╗   ██╗"
    echo "  ██║   ██║██╔════╝ ██╔══██╗██║   ██║"
    echo "  ██║   ██║██║  ███╗██████╔╝██║   ██║"
    echo "  ╚██╗ ██╔╝██║   ██║██╔═══╝ ██║   ██║"
    echo "   ╚████╔╝ ╚██████╔╝██║     ╚██████╔╝"
    echo "    ╚═══╝   ╚═════╝ ╚═╝      ╚═════╝"
    echo -e "${C_RESET}"
    echo -e "  ${C_BOLD}$BRAND_NAME | vGPU Driver Deployment Utility${C_RESET}\n"
    > "$LOG_FILE"
}

print_info()    { echo -e "  ${C_BLUE}[ ℹ ]${C_RESET} $1"; }
print_warn()    { echo -e "  ${C_YELLOW}[ ⚠ ]${C_RESET} $1"; }
print_error()   { echo -e "  ${C_RED}[ ✖ ]${C_RESET} $1"; echo -e "        ${C_DIM}详细日志: $LOG_FILE${C_RESET}"; exit 1; }
print_success() { echo -e "  ${C_GREEN}[ ✔ ]${C_RESET} $1"; }

run_with_spinner() {
    local msg="$1"
    shift
    "$@" >> "$LOG_FILE" 2>&1 &
    local pid=$!
    local spin='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
    local i=0

    tput civis
    while kill -0 $pid 2>/dev/null; do
        i=$(( (i+1) % 10 ))
        printf "\r  ${C_CYAN}[ %c ]${C_RESET} ${C_BOLD}%s${C_RESET} ${C_DIM}正在处理...${C_RESET}" "${spin:$i:1}" "$msg"
        sleep 0.1
    done
    tput cnorm

    wait $pid
    local exit_code=$?
    printf "\r\033[K"

    if [ $exit_code -eq 0 ]; then
        print_success "$msg"
    else
        print_error "$msg 失败"
    fi
    return $exit_code
}

print_banner

if [ "$EUID" -ne 0 ]; then
    print_error "权限不足。请以 root 身份执行此脚本 (sudo bash $0)"
fi

if ! command -v apt &> /dev/null; then
    print_error "不受支持的发行版。此工具仅适用于基于 APT 的系统 (Ubuntu / Debian)。"
fi

KERNEL_FULL=$(uname -r)
KERNEL_MAJOR=$(echo "$KERNEL_FULL" | cut -d'.' -f1)
KERNEL_MINOR=$(echo "$KERNEL_FULL" | cut -d'.' -f2)

print_info "当前内核版本: ${C_BOLD}$KERNEL_FULL${C_RESET}"

if [ "$KERNEL_MAJOR" -ne 6 ]; then
    print_error "不受支持的内核版本 ($KERNEL_FULL)。要求 6.8 – 6.19。"
fi

if [ "$KERNEL_MINOR" -ge 8 ] && [ "$KERNEL_MINOR" -lt 12 ]; then
    BRANCH="2025.07.22"
    print_info "驱动分支: ${C_BOLD}$BRANCH (适配内核 6.8 – 6.11)${C_RESET}"
elif [ "$KERNEL_MINOR" -ge 12 ] && [ "$KERNEL_MINOR" -le 19 ]; then
    BRANCH="2026.02.09"
    print_info "驱动分支: ${C_BOLD}$BRANCH (适配内核 6.12 – 6.19)${C_RESET}"
else
    print_error "不受支持的内核子版本 ($KERNEL_FULL)。要求 6.8 – 6.19。"
fi

echo ""

export DEBIAN_FRONTEND=noninteractive
run_with_spinner "更新系统软件源" apt update -y
run_with_spinner "安装编译环境及驱动工具链" apt install -y git build-essential dkms linux-headers-"$(uname -r)" intel-media-va-driver-non-free vainfo intel-gpu-tools ffmpeg

if dkms status | grep -q "i915-sriov-dkms"; then
    print_warn "检测到已有 DKMS 记录，正在清理..."
    OLD_VERSIONS=$(dkms status | grep "i915-sriov-dkms" | awk '{print $2}' | tr -d ',:')
    for OV in $OLD_VERSIONS; do
        dkms remove -m i915-sriov-dkms -v "$OV" --all >> "$LOG_FILE" 2>&1 || true
    done
    rm -rf /usr/src/i915-sriov-dkms-*
fi

WORK_DIR=$(mktemp -d)
cd "$WORK_DIR"
run_with_spinner "获取 i915-sriov-dkms 驱动源码 (分支: $BRANCH)" git clone -b "$BRANCH" https://github.com/strongtz/i915-sriov-dkms.git
cd i915-sriov-dkms
cp -a . /usr/src/i915-sriov-dkms-"$BRANCH"

run_with_spinner "注册 DKMS 模块" dkms add -m i915-sriov-dkms -v "$BRANCH"
run_with_spinner "编译内核驱动模块 (预计 3–5 分钟)" dkms build -m i915-sriov-dkms -v "$BRANCH"
run_with_spinner "安装 DKMS 驱动模块" dkms install -m i915-sriov-dkms -v "$BRANCH"

run_with_spinner "重建 initramfs 引导镜像" update-initramfs -u

rm -rf "$WORK_DIR"

echo ""
echo -e "${C_CYAN}╭─────────────────────────────────────────────────────────╮${C_RESET}"
echo -e "${C_CYAN}│${C_RESET}                                                         ${C_CYAN}│${C_RESET}"
echo -e "${C_CYAN}│${C_RESET}  ${C_GREEN}✔ vGPU 驱动部署完成${C_RESET}                                    ${C_CYAN}│${C_RESET}"
echo -e "${C_CYAN}│${C_RESET}  内核驱动模块、DKMS 及媒体编解码组件已全部就绪。        ${C_CYAN}│${C_RESET}"
echo -e "${C_CYAN}│${C_RESET}                                                         ${C_CYAN}│${C_RESET}"
echo -e "${C_CYAN}│${C_RESET}  ${C_DIM}后续操作:${C_RESET}                                                ${C_CYAN}│${C_RESET}"
echo -e "${C_CYAN}│${C_RESET}  1. 重启服务器以加载内核驱动模块。                      ${C_CYAN}│${C_RESET}"
echo -e "${C_CYAN}│${C_RESET}  2. 执行 ${C_BOLD}vainfo${C_RESET} 确认硬件编解码支持。                    ${C_CYAN}│${C_RESET}"
echo -e "${C_CYAN}│${C_RESET}  3. 执行 ${C_BOLD}intel_gpu_top${C_RESET} 查看 GPU 实时状态。             ${C_CYAN}│${C_RESET}"
echo -e "${C_CYAN}│${C_RESET}                                                         ${C_CYAN}│${C_RESET}"
echo -e "${C_CYAN}╰─────────────────────────────────────────────────────────╯${C_RESET}"
echo ""

read -r -p "$(echo -e "${C_YELLOW}  ? 是否立即重启服务器？ [y/N] ${C_RESET}")" response
if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
    print_info "正在执行重启..."
    reboot
else
    print_info "部署完成。请在需要时手动执行 reboot。"
fi