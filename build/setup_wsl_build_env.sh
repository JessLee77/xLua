#!/bin/bash
# =============================================================================
# xLua 构建环境 - WSL Ubuntu 初始化脚本
# 用法: 在 WSL Ubuntu 中运行此脚本安装构建依赖
#   wsl -d Ubuntu-24.04 -- bash setup_wsl_build_env.sh
# =============================================================================

set -e

echo "=========================================="
echo "  xLua WSL Build Environment Setup"
echo "=========================================="
echo ""

# 安装基础编译工具
echo "[1/3] Installing build tools..."
sudo apt-get update -q
sudo apt-get install -y --no-install-recommends \
    build-essential \
    cmake \
    gcc-multilib \
    g++-multilib \
    unzip \
    wget

# 检查 Android NDK
echo ""
echo "[2/3] Checking Android NDK r23b..."

NDK_FOUND=0

# 检查常见位置
NDK_PATHS=(
    "$HOME/android-ndk-r23b"
    "/mnt/c/Users/$USER/android-ndk-r23b"
    "$ANDROID_NDK"
    "$ANDROID_NDK_HOME"
)

for p in "${NDK_PATHS[@]}"; do
    if [ -n "$p" ] && [ -d "$p" ]; then
        echo "  Found NDK at: $p"
        NDK_FOUND=1
        break
    fi
done

if [ $NDK_FOUND -eq 0 ]; then
    echo "  Android NDK r23b not found."
    echo ""
    echo "  To download and install:"
    echo "    cd ~"
    echo "    wget -q https://dl.google.com/android/repository/android-ndk-r23b-linux.zip"
    echo "    unzip -q android-ndk-r23b-linux.zip"
    echo "    export ANDROID_NDK=~/android-ndk-r23b"
    echo ""
    read -p "  Download and install NDK r23b now? [y/N]: " answer
    if [[ "$answer" == "y" || "$answer" == "Y" ]]; then
        echo "  Downloading NDK r23b (this may take a while)..."
        cd ~
        wget -q --show-progress https://dl.google.com/android/repository/android-ndk-r23b-linux.zip
        echo "  Extracting..."
        unzip -q android-ndk-r23b-linux.zip
        rm android-ndk-r23b-linux.zip
        export ANDROID_NDK=~/android-ndk-r23b
        echo "  NDK installed at: ~/android-ndk-r23b"
    fi
fi

# 写入环境变量
echo ""
echo "[3/3] Setting up environment variables..."

PROFILE="$HOME/.bashrc"
if ! grep -q "ANDROID_NDK" "$PROFILE" 2>/dev/null; then
    echo "" >> "$PROFILE"
    echo "# Android NDK for xLua build" >> "$PROFILE"
    echo "export ANDROID_NDK=\$HOME/android-ndk-r23b" >> "$PROFILE"
    echo "  Added ANDROID_NDK to $PROFILE"
else
    echo "  ANDROID_NDK already in $PROFILE"
fi

echo ""
echo "=========================================="
echo "  Setup Complete!"
echo ""
echo "  To build Android plugins:"
echo "    cd /mnt/d/Github/xLua/build"
echo "    export ANDROID_NDK=~/android-ndk-r23b"
echo "    bash make_android_luajit_ndk23.sh"
echo "=========================================="
echo ""
