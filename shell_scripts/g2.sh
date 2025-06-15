#!/bin/bash

# GPU Driver Check Script for Arch Linux
# 检测显卡驱动安装状态并提供安装建议

set -euo pipefail # 严格模式

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 全局变量
QUIET_MODE=false
VERBOSE_MODE=false
DETECTED_GPUS=()
INSTALLED_PACKAGES=""

show_help()
{
  cat << EOF
GPU Driver Check Script for Arch Linux

使用方法: $0 [选项]

选项:
    -h, --help      显示此帮助信息
    -q, --quiet     静默模式，只显示错误和警告
    -v, --verbose   详细模式，显示更多调试信息

示例:
    $0              # 标准检测
    $0 -v           # 详细检测
    $0 -q           # 静默检测

EOF
}

parse_args()
{
  while [[ $# -gt 0 ]]; do
    case $1 in
      -h | --help)
        show_help
        exit 0
        ;;
      -q | --quiet)
        QUIET_MODE=true
        shift
        ;;
      -v | --verbose)
        VERBOSE_MODE=true
        shift
        ;;
      *)
        echo "未知选项: $1"
        show_help
        exit 1
        ;;
    esac
  done
}

# 缓存已安装包列表以提高性能
get_installed_packages()
{
  if [[ -z $INSTALLED_PACKAGES ]]; then
    if ! INSTALLED_PACKAGES=$(pacman -Qq 2> /dev/null); then
      echo -e "${RED}❌ 无法获取已安装包列表${NC}"
      exit 1
    fi
  fi
}

is_package_installed()
{
  local package="$1"
  echo "$INSTALLED_PACKAGES" | grep -qx "$package"
}

check_driver_status()
{
  local driver_name="$1"
  local package_name="$2"

  if is_package_installed "$package_name"; then
    echo -e "${GREEN}✅ 已安装 $driver_name: $package_name${NC}"
    return 0
  else
    echo -e "${RED}❌ 缺失 $driver_name: $package_name${NC}"
    return 1
  fi
}

check_gpu()
{
  [[ $QUIET_MODE == false ]] && echo -e "${YELLOW}------ 显卡检测 ------${NC}"

  # 检测所有显卡相关设备
  local gpu_info
  if ! gpu_info=$(lspci 2> /dev/null | grep -E "(VGA|3D|Display)"); then
    echo -e "${RED}❌ 无法获取显卡信息或未检测到显卡设备${NC}"
    return 1
  fi

  # 检测Intel显卡
  if echo "$gpu_info" | grep -qi "Intel"; then
    DETECTED_GPUS+=("intel")
    [[ $QUIET_MODE == false ]] && {
      echo -e "${GREEN}✅ 检测到Intel显卡:${NC}"
      echo "$gpu_info" | grep -i "Intel" | while read -r line; do
        echo -e "   ${GREEN}• $line${NC}"
      done
    }
  fi

  # 检测AMD显卡
  if echo "$gpu_info" | grep -qiE "(AMD|ATI)"; then
    DETECTED_GPUS+=("amd")
    [[ $QUIET_MODE == false ]] && {
      echo -e "${GREEN}✅ 检测到AMD显卡:${NC}"
      echo "$gpu_info" | grep -iE "(AMD|ATI)" | while read -r line; do
        echo -e "   ${GREEN}• $line${NC}"
      done
    }
  fi

  # 检测NVIDIA显卡
  if echo "$gpu_info" | grep -qi "NVIDIA"; then
    DETECTED_GPUS+=("nvidia")
    [[ $QUIET_MODE == false ]] && {
      echo -e "${GREEN}✅ 检测到NVIDIA显卡:${NC}"
      echo "$gpu_info" | grep -i "NVIDIA" | while read -r line; do
        echo -e "   ${GREEN}• $line${NC}"
      done
    }
  fi

  # 检测其他显卡
  local other_gpu
  if other_gpu=$(echo "$gpu_info" | grep -viE "(Intel|AMD|ATI|NVIDIA)"); then
    [[ $QUIET_MODE == false ]] && {
      echo -e "${YELLOW}⚠️ 检测到其他显卡:${NC}"
      echo "$other_gpu" | while read -r line; do
        echo -e "   ${YELLOW}• $line${NC}"
      done
    }
  fi

  [[ $QUIET_MODE == false ]] && echo ""
  return 0
}

# 驱动定义
declare -A intel_drivers=(
  ["OpenGL支持"]="mesa"
  ["32bit OpenGL支持"]="lib32-mesa"
  ["Vulkan支持"]="vulkan-intel"
  ["32bit Vulkan支持"]="lib32-vulkan-intel"
  ["Xorg Server支持"]="xorg-server"
)

intel_order=("OpenGL支持" "32bit OpenGL支持" "Vulkan支持" "32bit Vulkan支持" "Xorg Server支持")

declare -A amd_drivers=(
  ["AMD开源驱动"]="xf86-video-amdgpu"
  ["AMD老驱动(GCN架构)"]="xf86-video-ati"
  ["OpenGL支持"]="mesa"
  ["32bit OpenGL支持"]="lib32-mesa"
  ["Vulkan支持"]="vulkan-radeon"
  ["32bit Vulkan支持"]="lib32-vulkan-radeon"
)

amd_order=("AMD开源驱动" "AMD老驱动(GCN架构)" "OpenGL支持" "32bit OpenGL支持" "Vulkan支持" "32bit Vulkan支持")

declare -A nvidia_drivers=(
  ["NVIDIA专有驱动"]="nvidia"
  ["NVIDIA专有驱动(LTS内核)"]="nvidia-lts"
  ["NVIDIA开源驱动"]="nvidia-open"
  ["NVIDIA老显卡驱动(390xx)"]="nvidia-390xx"
  ["NVIDIA老显卡驱动(470xx)"]="nvidia-470xx"
  ["NVIDIA开源驱动(不建议)"]="xf86-video-nouveau"
)

nvidia_order=("NVIDIA专有驱动" "NVIDIA专有驱动(LTS内核)" "NVIDIA开源驱动" "NVIDIA老显卡驱动(390xx)" "NVIDIA老显卡驱动(470xx)" "NVIDIA开源驱动(不建议)")

check_intel()
{
  echo -e "\n${YELLOW}------ Intel驱动检测 ------${NC}"

  for driver in "${intel_order[@]}"; do
    check_driver_status "$driver" "${intel_drivers[$driver]}"
  done

  if is_package_installed 'xf86-video-intel'; then
    echo -e "${YELLOW}⚠️ 检测到已安装 xf86-video-intel，该驱动较旧且有bug，建议卸载${NC}"
  fi
}

check_amd()
{
  echo -e "\n${YELLOW}------ AMD驱动检测 ------${NC}"

  for driver in "${amd_order[@]}"; do
    check_driver_status "$driver" "${amd_drivers[$driver]}"
  done
}

check_nvidia()
{
  echo -e "\n${YELLOW}------ NVIDIA驱动检测 ------${NC}"

  for driver in "${nvidia_order[@]}"; do
    check_driver_status "$driver" "${nvidia_drivers[$driver]}"
  done

  # 检查NVIDIA驱动冲突
  local nvidia_count=0
  for pkg in nvidia nvidia-lts nvidia-open nvidia-390xx nvidia-470xx; do
    if is_package_installed "$pkg"; then
      ((nvidia_count++))
    fi
  done

  if [[ $nvidia_count -gt 1 ]]; then
    echo -e "${YELLOW}⚠️ 检测到多个NVIDIA驱动，可能存在冲突${NC}"
  fi
}

check_xorg()
{
  echo -e "\n${YELLOW}------ Xorg通用驱动检测 ------${NC}"

  if is_package_installed 'xf86-video-vesa'; then
    echo -e "${GREEN}✅ 已安装 xf86-video-vesa${NC}"
  else
    echo -e "${RED}❌ 未安装 xf86-video-vesa${NC}"
  fi
}

smart_check_drivers()
{
  get_installed_packages

  for gpu_type in "${DETECTED_GPUS[@]}"; do
    case "$gpu_type" in
      "intel")
        check_intel
        ;;
      "amd")
        check_amd
        ;;
      "nvidia")
        check_nvidia
        ;;
    esac
  done

  check_xorg
}

generate_install_suggestions()
{
  [[ $QUIET_MODE == true ]] && return

  echo -e "\n${BLUE}------ 安装建议 ------${NC}"

  local missing_packages=()

  for gpu_type in "${DETECTED_GPUS[@]}"; do
    case "$gpu_type" in
      "intel")
        for driver in "${intel_order[@]}"; do
          if ! is_package_installed "${intel_drivers[$driver]}"; then
            missing_packages+=("${intel_drivers[$driver]}")
          fi
        done
        ;;
      "amd")
        for driver in "${amd_order[@]}"; do
          if ! is_package_installed "${amd_drivers[$driver]}"; then
            missing_packages+=("${amd_drivers[$driver]}")
          fi
        done
        ;;
      "nvidia")
        # NVIDIA建议安装专有驱动
        if ! is_package_installed "nvidia" && ! is_package_installed "nvidia-lts" && ! is_package_installed "nvidia-open"; then
          missing_packages+=("nvidia")
        fi
        ;;
    esac
  done

  # 检查通用驱动
  if ! is_package_installed "xf86-video-vesa"; then
    missing_packages+=("xf86-video-vesa")
  fi

  if [[ ${#missing_packages[@]} -gt 0 ]]; then
    echo -e "${YELLOW}建议安装以下包:${NC}"
    printf '%s\n' "${missing_packages[@]}" | sort -u | while read -r pkg; do
      echo -e "  • $pkg"
    done
    echo -e "\n${BLUE}安装命令:${NC}"
    echo -e "sudo pacman -S $(printf '%s ' "${missing_packages[@]}" | sort -u | tr '\n' ' ')"
  else
    echo -e "${GREEN}所有必需的驱动都已安装！${NC}"
  fi
}

main()
{
  parse_args "$@"

  [[ $QUIET_MODE == false ]] && echo -e "${BLUE}=== GPU 驱动检测工具 ===${NC}\n"

  if ! check_gpu; then
    exit 1
  fi

  if [[ ${#DETECTED_GPUS[@]} -eq 0 ]]; then
    echo -e "${YELLOW}未检测到支持的显卡，将检查所有驱动${NC}"
    get_installed_packages
    check_intel
    check_amd
    check_nvidia
    check_xorg
  else
    smart_check_drivers
    generate_install_suggestions
  fi

  [[ $QUIET_MODE == false ]] && echo -e "\n${BLUE}检测完成！${NC}"
}

main "$@"
