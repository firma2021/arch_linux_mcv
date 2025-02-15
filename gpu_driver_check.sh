#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

check_gpu()
{
  gpu_info=$(lspci | grep -i "VGA")

  intel_gpu=$(echo "$gpu_info" | grep -i "Intel")
  amd_gpu=$(echo "$gpu_info" | grep -i "AMD/ATI")
  nvidia_gpu=$(echo "$gpu_info" | grep -i "NVIDIA")

  print_gpu()
  {
    if [ -n "$1" ]; then
      echo -e "${GREEN} 检测到$2显卡: $1 ${NC}"
    fi
  }

  print_gpu "$intel_gpu" "Intel"
  print_gpu "$amd_gpu" "AMD/ATI"
  print_gpu "$nvidia_gpu" "NVIDIA"
}

declare -A intel_drivers=(
  ["OpenGL支持"]="mesa"
  ["32bit OpenGL支持"]="lib32-mesa"
  ["Vulkan支持"]="vulkan-intel"
  ["32bit Vulkan支持"]="lib32-vulkan-intel"
  ["Xorg Server支持"]="xorg-server"
)

declare -A amd_drivers=(
  ["amd开源驱动"]="xf86-video-amdgpu"
  ["老GCN架构显卡"]="xf86-video-ati"
  ["OpenGL支持"]="mesa"
  ["32bit OpenGL支持"]="lib32-mesa"
  ["Vulkan支持"]="vulkan-radeon"
  ["32bit Vulkan支持"]="lib32-vulkan-radeon"
)

declare -A nvidia_drivers=(
  ["NVIDIA老卡驱动"]="xf86-video-nouveau"
  ["NVIDIA开源驱动"]="nvidia-open"
)

check_intel()
{
  echo -e "\n${YELLOW}------ Intel驱动检测 ------${NC}"

  for driver in "${!intel_drivers[@]}"; do
    if pacman -Qs "${intel_drivers[$driver]}" > /dev/null; then
      echo -e "${GREEN}✅ 已安装 $driver: ${intel_drivers[$driver]}${NC}"
    else
      echo -e "${RED}❌ 缺失 $driver: ${intel_drivers[$driver]}${NC}"
    fi
  done

  if pacman -Qs 'xf86-video-intel' > /dev/null; then
    echo -e "${YELLOW}⚠️ 检测到已安装 xf86-video-intel，该驱动较旧且有bug，建议卸载 ${NC}"
  fi
}

check_amd()
{
  echo -e "\n${YELLOW}------ AMD驱动检测 ------${NC}"

  for driver in "${!amd_drivers[@]}"; do
    if pacman -Qs "${amd_drivers[$driver]}" > /dev/null; then
      echo -e "${GREEN}✅ 已安装 $driver: ${amd_drivers[$driver]}${NC}"
    else
      echo -e "${RED}❌ 缺失 $driver: ${amd_drivers[$driver]}${NC}"
    fi
  done
}

check_nvidia()
{
  echo -e "\n${YELLOW}------ NVIDIA驱动检测 ------${NC}"

  for driver in "${!nvidia_drivers[@]}"; do
    if pacman -Qs "${nvidia_drivers[$driver]}" > /dev/null; then
      echo -e "${GREEN}✅ 已安装 $driver: ${nvidia_drivers[$driver]}${NC}"
    else
      echo -e "${RED}❌ 缺失 $driver: ${nvidia_drivers[$driver]}${NC}"
    fi
  done
}

check_xorg()
{
  echo -e "\n${YELLOW}------ xorg通用驱动检测 ------${NC}"
  if pacman -Qs 'xf86-video-vesa' > /dev/null; then
    echo -e "${GREEN}✅ 已安装 xf86-video-vesa ${NC}"
  else
    echo -e "未安装 xf86-video-vesa"
  fi
}

check_gpu
check_intel
check_amd
check_nvidia
