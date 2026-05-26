#!/bin/bash
# =============================================================================
# xLua LuaJIT Android 构建脚本 (NDK r23b)
# 支持 ABI: arm64-v8a, armeabi-v7a, x86
# 用法: bash make_android_luajit_ndk23.sh
# 环境变量: ANDROID_NDK 或 ANDROID_NDK_HOME 指向 NDK r23b 根目录
# =============================================================================

set -e

# --- NDK 路径检测 ---
if [ -n "$ANDROID_NDK" ]; then
    NDK="$ANDROID_NDK"
elif [ -n "$ANDROID_NDK_HOME" ]; then
    NDK="$ANDROID_NDK_HOME"
else
    # 尝试常见默认路径
    if [ -d "$HOME/android-ndk-r23b" ]; then
        NDK="$HOME/android-ndk-r23b"
    else
        echo "ERROR: Please set ANDROID_NDK or ANDROID_NDK_HOME to your NDK r23b root."
        echo "  Example: export ANDROID_NDK=~/android-ndk-r23b"
        exit 1
    fi
fi

if [ ! -d "$NDK" ]; then
    echo "ERROR: NDK directory not found: $NDK"
    exit 1
fi

echo "Using Android NDK: $NDK"

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
SRCDIR="$DIR/luajit-2.1.0b3"

# 检测宿主机系统
OS=$(uname -s)
if [[ "$OS" == "Darwin" ]]; then
    HOST_PLATFORM="darwin-x86_64"
    HOST_CC="gcc"
else
    HOST_PLATFORM="linux-x86_64"
    HOST_CC="gcc"
fi

NDKBIN="$NDK/toolchains/llvm/prebuilt/$HOST_PLATFORM/bin"

if [ ! -d "$NDKBIN" ]; then
    echo "ERROR: NDK toolchain not found at: $NDKBIN"
    exit 1
fi

API=21

# =============================================================================
# 构建函数
# =============================================================================

build_luajit_arm64() {
    echo ""
    echo "================================================================"
    echo "  Building LuaJIT for arm64-v8a (GC64 enabled)"
    echo "================================================================"
    echo ""

    cd "$SRCDIR"
    make clean

    make amalg \
        HOST_CC="$HOST_CC" \
        CROSS="$NDKBIN/aarch64-linux-android-" \
        STATIC_CC="$NDKBIN/aarch64-linux-android${API}-clang" \
        DYNAMIC_CC="$NDKBIN/aarch64-linux-android${API}-clang -fPIC" \
        TARGET_LD="$NDKBIN/aarch64-linux-android${API}-clang" \
        TARGET_AR="$NDKBIN/llvm-ar rcus" \
        TARGET_STRIP="$NDKBIN/llvm-strip" \
        TARGET_SYS=Linux \
        TARGET_FLAGS="-DLUAJIT_ENABLE_GC64" \
        CFLAGS="-fPIC" \
        BUILDMODE=static

    cd "$DIR"
    mkdir -p build_lj_ndk23_v8a && cd build_lj_ndk23_v8a
    cmake -DUSING_LUAJIT=ON -DGC64=ON \
        -DANDROID_ABI=arm64-v8a \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_TOOLCHAIN_FILE="$NDK/build/cmake/android.toolchain.cmake" \
        -DANDROID_TOOLCHAIN=clang \
        -DANDROID_NATIVE_API_LEVEL=android-${API} \
        ../
    cd "$DIR"
    cmake --build build_lj_ndk23_v8a --config Release

    mkdir -p plugin_luajit/Plugins/Android/libs/arm64-v8a/
    cp build_lj_ndk23_v8a/libxlua.so plugin_luajit/Plugins/Android/libs/arm64-v8a/libxlua.so
    echo "  -> arm64-v8a: OK"
}

build_luajit_armv7() {
    echo ""
    echo "================================================================"
    echo "  Building LuaJIT for armeabi-v7a (standard mode)"
    echo "================================================================"
    echo ""

    cd "$SRCDIR"
    make clean

    make amalg \
        HOST_CC="$HOST_CC -m32" \
        CROSS="$NDKBIN/arm-linux-androideabi-" \
        STATIC_CC="$NDKBIN/armv7a-linux-androideabi${API}-clang" \
        DYNAMIC_CC="$NDKBIN/armv7a-linux-androideabi${API}-clang -fPIC" \
        TARGET_LD="$NDKBIN/armv7a-linux-androideabi${API}-clang" \
        TARGET_AR="$NDKBIN/llvm-ar rcus" \
        TARGET_STRIP="$NDKBIN/llvm-strip" \
        TARGET_SYS=Linux \
        TARGET_FLAGS="-march=armv7-a -mfloat-abi=softfp" \
        CFLAGS="-fPIC" \
        BUILDMODE=static

    cd "$DIR"
    mkdir -p build_lj_ndk23_v7a && cd build_lj_ndk23_v7a
    cmake -DUSING_LUAJIT=ON \
        -DANDROID_ABI=armeabi-v7a \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_TOOLCHAIN_FILE="$NDK/build/cmake/android.toolchain.cmake" \
        -DANDROID_TOOLCHAIN=clang \
        -DANDROID_NATIVE_API_LEVEL=android-${API} \
        ../
    cd "$DIR"
    cmake --build build_lj_ndk23_v7a --config Release

    mkdir -p plugin_luajit/Plugins/Android/libs/armeabi-v7a/
    cp build_lj_ndk23_v7a/libxlua.so plugin_luajit/Plugins/Android/libs/armeabi-v7a/libxlua.so
    echo "  -> armeabi-v7a: OK"
}

build_luajit_x86() {
    echo ""
    echo "================================================================"
    echo "  Building LuaJIT for x86 (standard mode)"
    echo "================================================================"
    echo ""

    cd "$SRCDIR"
    make clean

    make amalg \
        HOST_CC="$HOST_CC -m32" \
        CROSS="$NDKBIN/i686-linux-android-" \
        STATIC_CC="$NDKBIN/i686-linux-android${API}-clang" \
        DYNAMIC_CC="$NDKBIN/i686-linux-android${API}-clang -fPIC" \
        TARGET_LD="$NDKBIN/i686-linux-android${API}-clang" \
        TARGET_AR="$NDKBIN/llvm-ar rcus" \
        TARGET_STRIP="$NDKBIN/llvm-strip" \
        TARGET_SYS=Linux \
        CFLAGS="-fPIC" \
        BUILDMODE=static

    cd "$DIR"
    mkdir -p build_lj_ndk23_x86 && cd build_lj_ndk23_x86
    cmake -DUSING_LUAJIT=ON \
        -DANDROID_ABI=x86 \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_TOOLCHAIN_FILE="$NDK/build/cmake/android.toolchain.cmake" \
        -DANDROID_TOOLCHAIN=clang \
        -DANDROID_NATIVE_API_LEVEL=android-${API} \
        ../
    cd "$DIR"
    cmake --build build_lj_ndk23_x86 --config Release

    mkdir -p plugin_luajit/Plugins/Android/libs/x86/
    cp build_lj_ndk23_x86/libxlua.so plugin_luajit/Plugins/Android/libs/x86/libxlua.so
    echo "  -> x86: OK"
}

# =============================================================================
# 主流程
# =============================================================================

echo ""
echo "╔══════════════════════════════════════════════════════════════════╗"
echo "║  xLua LuaJIT Android Build (NDK r23b)                         ║"
echo "║  Target ABIs: arm64-v8a, armeabi-v7a, x86                     ║"
echo "╚══════════════════════════════════════════════════════════════════╝"
echo ""

build_luajit_arm64
build_luajit_armv7
build_luajit_x86

echo ""
echo "================================================================"
echo "  All Android builds completed!"
echo "  Output: plugin_luajit/Plugins/Android/libs/"
echo "    - arm64-v8a/libxlua.so   (GC64)"
echo "    - armeabi-v7a/libxlua.so (standard)"
echo "    - x86/libxlua.so         (standard)"
echo "================================================================"
echo ""
