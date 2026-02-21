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
LANG_CHOICE=""

msg() {
    local key="$1"
    shift
    case "$key" in
        banner_subtitle)
            [[ "$LANG_CHOICE" == "zh" ]] && echo "$BRAND_NAME | vGPU 驱动部署工具" || echo "$BRAND_NAME | vGPU Driver Deployment Utility" ;;
        lang_prompt)
            echo -e "  ${C_CYAN}${C_BOLD}Please select language / 请选择语言:${C_RESET}"
            echo -e "  ${C_BOLD}1)${C_RESET} English"
            echo -e "  ${C_BOLD}2)${C_RESET} 中文" ;;
        lang_invalid)
            echo "  Invalid selection. Defaulting to English. / 无效选择，默认使用英文。" ;;
        err_root)
            [[ "$LANG_CHOICE" == "zh" ]] && echo "权限不足。请以 root 身份执行此脚本 (sudo bash $0)" \
                || echo "Insufficient privileges. Please run this script as root (sudo bash $0)." ;;
        err_apt)
            [[ "$LANG_CHOICE" == "zh" ]] && echo "不受支持的发行版。此工具仅适用于基于 APT 的系统 (Ubuntu / Debian)。" \
                || echo "Unsupported distribution. This tool requires an APT-based system (Ubuntu / Debian)." ;;
        err_no_intel_gpu)
            [[ "$LANG_CHOICE" == "zh" ]] && echo "未检测到 Intel 显卡。此工具需要 Intel 集成/独立 GPU (vendor 8086)。" \
                || echo "No Intel GPU detected. This tool requires an Intel integrated/discrete GPU (vendor 8086)." ;;
        err_kernel_major)
            [[ "$LANG_CHOICE" == "zh" ]] && echo "不受支持的内核版本 ($1)。要求 6.8 – 6.19。" \
                || echo "Unsupported kernel version ($1). Required: 6.8 – 6.19." ;;
        err_kernel_minor)
            [[ "$LANG_CHOICE" == "zh" ]] && echo "不受支持的内核子版本 ($1)。要求 6.8 – 6.19。" \
                || echo "Unsupported kernel minor version ($1). Required: 6.8 – 6.19." ;;
        err_fail_suffix)
            [[ "$LANG_CHOICE" == "zh" ]] && echo "失败" || echo "failed" ;;
        log_detail)
            [[ "$LANG_CHOICE" == "zh" ]] && echo "详细日志: $LOG_FILE" || echo "Details: $LOG_FILE" ;;
        info_kernel)
            [[ "$LANG_CHOICE" == "zh" ]] && echo "当前内核版本: ${C_BOLD}$1${C_RESET}" \
                || echo "Kernel version: ${C_BOLD}$1${C_RESET}" ;;
        info_gpu_detected)
            [[ "$LANG_CHOICE" == "zh" ]] && echo "检测到 Intel GPU: ${C_BOLD}$1${C_RESET}" \
                || echo "Intel GPU detected: ${C_BOLD}$1${C_RESET}" ;;
        info_branch)
            [[ "$LANG_CHOICE" == "zh" ]] && echo "驱动分支: ${C_BOLD}$1 (适配内核 $2)${C_RESET}" \
                || echo "Driver branch: ${C_BOLD}$1 (for kernel $2)${C_RESET}" ;;
        spinner_processing)
            [[ "$LANG_CHOICE" == "zh" ]] && echo "正在处理..." || echo "processing..." ;;
        step_update_apt)
            [[ "$LANG_CHOICE" == "zh" ]] && echo "更新系统软件源" || echo "Updating package sources" ;;
        step_install_deps)
            [[ "$LANG_CHOICE" == "zh" ]] && echo "安装编译环境及驱动工具链" || echo "Installing build environment and driver toolchain" ;;
        step_clone)
            [[ "$LANG_CHOICE" == "zh" ]] && echo "获取 i915-sriov-dkms 驱动源码 (分支: $1)" \
                || echo "Fetching i915-sriov-dkms source (branch: $1)" ;;
        step_dkms_add)
            [[ "$LANG_CHOICE" == "zh" ]] && echo "注册 DKMS 模块" || echo "Registering DKMS module" ;;
        step_dkms_build)
            [[ "$LANG_CHOICE" == "zh" ]] && echo "编译内核驱动模块 (预计 3–5 分钟)" \
                || echo "Compiling kernel driver module (estimated 3–5 min)" ;;
        step_dkms_install)
            [[ "$LANG_CHOICE" == "zh" ]] && echo "安装 DKMS 驱动模块" || echo "Installing DKMS driver module" ;;
        step_initramfs)
            [[ "$LANG_CHOICE" == "zh" ]] && echo "重建 initramfs 引导镜像" || echo "Rebuilding initramfs boot image" ;;
        warn_dkms_cleanup)
            [[ "$LANG_CHOICE" == "zh" ]] && echo "检测到已有 DKMS 记录，正在清理..." \
                || echo "Existing DKMS records detected, cleaning up..." ;;
        done_title)
            [[ "$LANG_CHOICE" == "zh" ]] && echo "✔ vGPU 驱动部署完成" || echo "✔ vGPU driver deployment complete" ;;
        done_desc)
            [[ "$LANG_CHOICE" == "zh" ]] && echo "内核驱动模块、DKMS 及媒体编解码组件已全部就绪。" \
                || echo "Kernel driver module, DKMS, and media codec components are ready." ;;
        done_next)
            [[ "$LANG_CHOICE" == "zh" ]] && echo "后续操作:" || echo "Next steps:" ;;
        done_step1)
            [[ "$LANG_CHOICE" == "zh" ]] && echo "1. 重启服务器以加载内核驱动模块。" \
                || echo "1. Reboot the server to load the kernel driver module." ;;
        done_step2)
            [[ "$LANG_CHOICE" == "zh" ]] && echo "2. 执行 ${C_BOLD}vainfo${C_RESET} 确认硬件编解码支持。" \
                || echo "2. Run ${C_BOLD}vainfo${C_RESET} to confirm hardware codec support." ;;
        done_step3)
            [[ "$LANG_CHOICE" == "zh" ]] && echo "3. 执行 ${C_BOLD}intel_gpu_top${C_RESET} 查看 GPU 实时状态。" \
                || echo "3. Run ${C_BOLD}intel_gpu_top${C_RESET} to monitor GPU utilization." ;;
        prompt_reboot)
            [[ "$LANG_CHOICE" == "zh" ]] && echo "是否立即重启服务器？ [y/N] " \
                || echo "Reboot the server now? [y/N] " ;;
        info_rebooting)
            [[ "$LANG_CHOICE" == "zh" ]] && echo "正在执行重启..." || echo "Rebooting..." ;;
        info_done)
            [[ "$LANG_CHOICE" == "zh" ]] && echo "部署完成。请在需要时手动执行 reboot。" \
                || echo "Deployment complete. Run reboot manually when ready." ;;
    esac
}

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
    > "$LOG_FILE"
}

print_info()    { echo -e "  ${C_BLUE}[ ℹ ]${C_RESET} $1"; }
print_warn()    { echo -e "  ${C_YELLOW}[ ⚠ ]${C_RESET} $1"; }
print_error()   { echo -e "  ${C_RED}[ ✖ ]${C_RESET} $1"; echo -e "        ${C_DIM}$(msg log_detail)${C_RESET}"; exit 1; }
print_success() { echo -e "  ${C_GREEN}[ ✔ ]${C_RESET} $1"; }

run_with_spinner() {
    local msg_text="$1"
    shift
    "$@" >> "$LOG_FILE" 2>&1 &
    local pid=$!
    local spin='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
    local i=0
    local processing
    processing=$(msg spinner_processing)

    tput civis
    while kill -0 $pid 2>/dev/null; do
        i=$(( (i+1) % 10 ))
        printf "\r  ${C_CYAN}[ %c ]${C_RESET} ${C_BOLD}%s${C_RESET} ${C_DIM}%s${C_RESET}" "${spin:$i:1}" "$msg_text" "$processing"
        sleep 0.1
    done
    tput cnorm

    wait $pid
    local exit_code=$?
    printf "\r\033[K"

    if [ $exit_code -eq 0 ]; then
        print_success "$msg_text"
    else
        print_error "$msg_text $(msg err_fail_suffix)"
    fi
    return $exit_code
}

print_banner

echo ""
msg lang_prompt
echo ""
read -r -p "  > " lang_input
case "$lang_input" in
    2) LANG_CHOICE="zh" ;;
    1) LANG_CHOICE="en" ;;
    *) msg lang_invalid; LANG_CHOICE="en" ;;
esac

clear
print_banner
echo -e "  ${C_BOLD}$(msg banner_subtitle)${C_RESET}\n"

if [ "$EUID" -ne 0 ]; then
    print_error "$(msg err_root)"
fi

if ! command -v apt &> /dev/null; then
    print_error "$(msg err_apt)"
fi

INTEL_GPU_COUNT=$(lspci -nn 2>/dev/null | grep -iE "vga|display|3d" | grep -c "\[8086:" || true)
if [ "$INTEL_GPU_COUNT" -lt 1 ]; then
    print_error "$(msg err_no_intel_gpu)"
fi

INTEL_GPU_NAME=$(lspci -nn 2>/dev/null | grep -iE "vga|display|3d" | grep "\[8086:" | head -1 | sed 's/.*: //')
print_info "$(msg info_gpu_detected "$INTEL_GPU_NAME")"

KERNEL_FULL=$(uname -r)
KERNEL_MAJOR=$(echo "$KERNEL_FULL" | cut -d'.' -f1)
KERNEL_MINOR=$(echo "$KERNEL_FULL" | cut -d'.' -f2)

print_info "$(msg info_kernel "$KERNEL_FULL")"

if [ "$KERNEL_MAJOR" -ne 6 ]; then
    print_error "$(msg err_kernel_major "$KERNEL_FULL")"
fi

if [ "$KERNEL_MINOR" -ge 8 ] && [ "$KERNEL_MINOR" -lt 12 ]; then
    BRANCH="2025.07.22"
    print_info "$(msg info_branch "$BRANCH" "6.8 – 6.11")"
elif [ "$KERNEL_MINOR" -ge 12 ] && [ "$KERNEL_MINOR" -le 19 ]; then
    BRANCH="2026.02.09"
    print_info "$(msg info_branch "$BRANCH" "6.12 – 6.19")"
else
    print_error "$(msg err_kernel_minor "$KERNEL_FULL")"
fi

echo ""

export DEBIAN_FRONTEND=noninteractive
run_with_spinner "$(msg step_update_apt)" apt update -y
run_with_spinner "$(msg step_install_deps)" apt install -y git build-essential dkms linux-headers-"$(uname -r)" intel-media-va-driver-non-free vainfo intel-gpu-tools ffmpeg

if dkms status | grep -q "i915-sriov-dkms"; then
    print_warn "$(msg warn_dkms_cleanup)"
    OLD_VERSIONS=$(dkms status | grep "i915-sriov-dkms" | awk '{print $2}' | tr -d ',:')
    for OV in $OLD_VERSIONS; do
        dkms remove -m i915-sriov-dkms -v "$OV" --all >> "$LOG_FILE" 2>&1 || true
    done
    rm -rf /usr/src/i915-sriov-dkms-*
fi

WORK_DIR=$(mktemp -d)
cd "$WORK_DIR"
run_with_spinner "$(msg step_clone "$BRANCH")" git clone -b "$BRANCH" https://github.com/strongtz/i915-sriov-dkms.git
cd i915-sriov-dkms
cp -a . /usr/src/i915-sriov-dkms-"$BRANCH"

run_with_spinner "$(msg step_dkms_add)" dkms add -m i915-sriov-dkms -v "$BRANCH"
run_with_spinner "$(msg step_dkms_build)" dkms build -m i915-sriov-dkms -v "$BRANCH"
run_with_spinner "$(msg step_dkms_install)" dkms install -m i915-sriov-dkms -v "$BRANCH"

run_with_spinner "$(msg step_initramfs)" update-initramfs -u

rm -rf "$WORK_DIR"

echo ""
echo -e "${C_CYAN}╭─────────────────────────────────────────────────────────────╮${C_RESET}"
echo -e "${C_CYAN}│${C_RESET}                                                             ${C_CYAN}│${C_RESET}"
echo -e "${C_CYAN}│${C_RESET}  ${C_GREEN}$(msg done_title)${C_RESET}"
echo -e "${C_CYAN}│${C_RESET}  $(msg done_desc)"
echo -e "${C_CYAN}│${C_RESET}                                                             ${C_CYAN}│${C_RESET}"
echo -e "${C_CYAN}│${C_RESET}  ${C_DIM}$(msg done_next)${C_RESET}"
echo -e "${C_CYAN}│${C_RESET}  $(msg done_step1)"
echo -e "${C_CYAN}│${C_RESET}  $(msg done_step2)"
echo -e "${C_CYAN}│${C_RESET}  $(msg done_step3)"
echo -e "${C_CYAN}│${C_RESET}                                                             ${C_CYAN}│${C_RESET}"
echo -e "${C_CYAN}╰─────────────────────────────────────────────────────────────╯${C_RESET}"
echo ""

read -r -p "$(echo -e "${C_YELLOW}  ? $(msg prompt_reboot)${C_RESET}")" response
if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
    print_info "$(msg info_rebooting)"
    reboot
else
    print_info "$(msg info_done)"
fi