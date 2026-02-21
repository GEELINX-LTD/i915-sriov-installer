# i915-sriov-installer

**[English](README.md)**

适用于 Linux VPS 的 Intel i915 SR-IOV vGPU 驱动一键安装工具。

## 背景

搭载 Xe 核显的 Intel 处理器支持 **SR-IOV**（单根 I/O 虚拟化），可将一块物理 GPU 拆分为多个虚拟 GPU（vGPU）并分配给虚拟机。VPS 供应商通常为每台宿主机分配最多 **7 个 vGPU**，用于租户的硬件加速视频编解码及计算任务。

然而，租户在虚拟机内手动安装或错误配置 GPU 驱动，可能导致 **直接寻址宿主机 GPU**，造成宿主机 **锁死或宕机**，影响同主机所有虚拟机。本安装工具通过预验证的自动化部署流程消除此风险。

## Windows 用户

如果您的 VPS 运行的是 **Windows** 系统，本脚本不适用。请直接下载安装 Intel 官方 GPU 驱动：

👉 **[Intel 显卡驱动 Windows 版 (101.7084)](https://downloadmirror.intel.com/873460/gfx_win_101.7084.exe)**

## 系统要求

| 要求 | 说明 |
|---|---|
| **操作系统** | Ubuntu 24.04 及以上 或 Debian 13 及以上 |
| **内核** | Linux 6.8 – 6.19（标准 generic/amd64 内核；**不支持** cloud 内核变体） |
| **显卡** | 需存在 Intel 集成/独立 GPU（vendor `8086`） |
| **权限** | Root（`sudo`） |
| **网络** | 需要互联网连接（用于安装软件包和获取源码） |

## 快速开始

```bash
sudo bash -c "$(curl -fsSL https://raw.githubusercontent.com/GEELINX-LTD/i915-sriov-installer/main/installer.sh)"
```

## 执行流程

安装工具将自动完成以下步骤：

1. **语言选择** — 提示用户选择中文或英文界面。
2. **前置检查** — 验证 root 权限、APT 可用性及 Intel GPU 存在性（通过 `lspci` 检测）。
3. **内核检测** — 识别当前内核版本并选择对应的驱动分支。
4. **依赖安装** — 安装编译工具、DKMS、内核头文件及 Intel 媒体组件（`intel-media-va-driver-non-free`、`vainfo`、`intel-gpu-tools`、`ffmpeg`）。
5. **清理残留** — 移除已安装的 `i915-sriov-dkms` 模块以避免冲突。
6. **源码获取** — 从 [i915-sriov-dkms](https://github.com/strongtz/i915-sriov-dkms) 仓库克隆对应分支。
7. **DKMS 编译与安装** — 注册、编译并安装内核驱动模块。
8. **引导镜像重建** — 更新 initramfs 以包含新驱动。
9. **重启提示** — 询问是否立即重启以激活驱动。

### 内核分支对应关系

| 内核范围 | 驱动分支 |
|---|---|
| 6.8 – 6.11 | `2025.07.22` |
| 6.12 – 6.19 | `2026.02.09` |

## 安装后验证

重启后，验证驱动是否已生效：

```bash
# 查看 VA-API 编解码支持
vainfo

# 实时监控 GPU 使用状态
intel_gpu_top
```

## 日志文件

所有编译输出记录在 `/tmp/vgpu_deploy.log`。如安装过程中遇到错误，请查阅此文件。

## 许可证

本项目采用 [GNU 通用公共许可证 v2.0](LICENSE) 授权，与上游 [i915-sriov-dkms](https://github.com/strongtz/i915-sriov-dkms) 项目保持一致。
