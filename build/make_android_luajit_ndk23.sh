#!/bin/bash
# ============================================================
# Build libxlua.so for Android with LuaJIT 2.1.0-beta3
# Compatible with Android NDK r23b (Unity 2022.3 LTS)
# Supports: arm64-v8a, armeabi-v7a, x86
# 
# Usage: 
#   export ANDROID_NDK=/path/to/ndk
#   bash make_android_luajit_ndk23.sh
#
# NDK r23b uses LLVM/Clang toolchain (GCC standalone toolchains removed)
# ============================================================

set -e

# --- NDK Path ---
if [ -z "$ANDROID_NDK" ]; then
    # Try common paths
    if [ -d "$HOME/android-ndk-r23b" ]; then
        export ANDROID_NDK="$HOME/android-ndk-r23b"
    elif [ -d "/opt/android-ndk-r23b" ]; then
        export ANDROID_NDK="/opt/android-ndk-r23b"
    else
        echo "ERROR: ANDROID_NDK environment variable not set!"
        echo "Usage: export ANDROID_NDK=/path/to/android-ndk-r23b"
        exit 1
    fi
fi

echo "Using Android NDK: $ANDROID_NDK"

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
SRCDIR=$DIR/luajit-2.1.0b3

OS=$(uname -s)
PREBUILT_PLATFORM=linux-x86_64
if [[ "$OS" == "Darwin" ]]; then
    PREBUILT_PLATFORM=darwin-x86_64
fi

# NDK r23b toolchain paths
TOOLCHAIN=$ANDROID_NDK/toolchains/llvm/prebuilt/$PREBUILT_PLATFORM
NDKABI=21

echo "============================================================"
echo "  Building Android xlua plugins with LuaJIT 2.1.0-beta3"
echo "  NDK: r23b (LLVM/Clang)"
echo "  API Level: $NDKABI"
echo "============================================================"

# ============================================================
# arm64-v8a
# ============================================================
echo ""
echo ">>> Building arm64-v8a (LuaJIT) ..."

cd "$SRCDIR"
make clean

# NDK r23b: use clang directly, no standalone toolchain needed
# CROSS prefix for LuaJIT Makefile: need to point to the llvm binutils
# LuaJIT cross-compilation with NDK r23b uses the clang compiler directly
make -j$(nproc) \
    HOST_CC="gcc" \
    CROSS="$TOOLCHAIN/bin/aarch64-linux-android-" \
    STATIC_CC="$TOOLCHAIN/bin/aarch64-linux-android${NDKABI}-clang" \
    DYNAMIC_CC="$TOOLCHAIN/bin/aarch64-linux-android${NDKABI}-clang -fPIC" \
    TARGET_LD="$TOOLCHAIN/bin/aarch64-linux-android${NDKABI}-clang" \
    TARGET_AR="$TOOLCHAIN/bin/llvm-ar rcus" \
    TARGET_STRIP="$TOOLCHAIN/bin/llvm-strip" \
    TARGET_SYS=Linux \
    TARGET_FLAGS="-DLJ_ABI_SOFTFP=0 -DLJ_ARCH_HASFPU=1 -DLUAJIT_ENABLE_GC64=0"

cd "$DIR"
mkdir -p build_lj_v8a && cd build_lj_v8a
cmake -DUSING_LUAJIT=ON \
      -DANDROID_ABI=arm64-v8a \
      -DANDROID_PLATFORM=android-$NDKABI \
      -DCMAKE_TOOLCHAIN_FILE=$ANDROID_NDK/build/cmake/android.toolchain.cmake \
      -DANDROID_TOOLCHAIN=clang \
      -DANDROID_STL=c++_static \
      ../

cd "$DIR"
cmake --build build_lj_v8a --config Release
mkdir -p plugin_luajit/Plugins/Android/libs/arm64-v8a/
cp build_lj_v8a/libxlua.so plugin_luajit/Plugins/Android/libs/arm64-v8a/libxlua.so

echo ">>> arm64-v8a DONE"

# ============================================================
# armeabi-v7a
# ============================================================
echo ""
echo ">>> Building armeabi-v7a (LuaJIT) ..."

cd "$SRCDIR"
make clean

make -j$(nproc) \
    HOST_CC="gcc -m32" \
    CROSS="$TOOLCHAIN/bin/arm-linux-androideabi-" \
    STATIC_CC="$TOOLCHAIN/bin/armv7a-linux-androideabi${NDKABI}-clang" \
    DYNAMIC_CC="$TOOLCHAIN/bin/armv7a-linux-androideabi${NDKABI}-clang -fPIC" \
    TARGET_LD="$TOOLCHAIN/bin/armv7a-linux-androideabi${NDKABI}-clang" \
    TARGET_AR="$TOOLCHAIN/bin/llvm-ar rcus" \
    TARGET_STRIP="$TOOLCHAIN/bin/llvm-strip" \
    TARGET_SYS=Linux \
    TARGET_FLAGS="-march=armv7-a -mfloat-abi=softfp"

cd "$DIR"
mkdir -p build_lj_v7a && cd build_lj_v7a
cmake -DUSING_LUAJIT=ON \
      -DANDROID_ABI=armeabi-v7a \
      -DANDROID_PLATFORM=android-$NDKABI \
      -DCMAKE_TOOLCHAIN_FILE=$ANDROID_NDK/build/cmake/android.toolchain.cmake \
      -DANDROID_TOOLCHAIN=clang \
      -DANDROID_STL=c++_static \
      ../

cd "$DIR"
cmake --build build_lj_v7a --config Release
mkdir -p plugin_luajit/Plugins/Android/libs/armeabi-v7a/
cp build_lj_v7a/libxlua.so plugin_luajit/Plugins/Android/libs/armeabi-v7a/libxlua.so

echo ">>> armeabi-v7a DONE"

# ============================================================
# x86 (for emulator)
# ============================================================
echo ""
echo ">>> Building x86 (LuaJIT) ..."

cd "$SRCDIR"
make clean

make -j$(nproc) \
    HOST_CC="gcc -m32" \
    CROSS="$TOOLCHAIN/bin/i686-linux-android-" \
    STATIC_CC="$TOOLCHAIN/bin/i686-linux-android${NDKABI}-clang" \
    DYNAMIC_CC="$TOOLCHAIN/bin/i686-linux-android${NDKABI}-clang -fPIC" \
    TARGET_LD="$TOOLCHAIN/bin/i686-linux-android${NDKABI}-clang" \
    TARGET_AR="$TOOLCHAIN/bin/llvm-ar rcus" \
    TARGET_STRIP="$TOOLCHAIN/bin/llvm-strip" \
    TARGET_SYS=Linux \
    TARGET_FLAGS=""

cd "$DIR"
mkdir -p build_lj_x86 && cd build_lj_x86
cmake -DUSING_LUAJIT=ON \
      -DANDROID_ABI=x86 \
      -DANDROID_PLATFORM=android-$NDKABI \
      -DCMAKE_TOOLCHAIN_FILE=$ANDROID_NDK/build/cmake/android.toolchain.cmake \
      -DANDROID_TOOLCHAIN=clang \
      -DANDROID_STL=c++_static \
      ../

cd "$DIR"
cmake --build build_lj_x86 --config Release
mkdir -p plugin_luajit/Plugins/Android/libs/x86/
cp build_lj_x86/libxlua.so plugin_luajit/Plugins/Android/libs/x86/libxlua.so

echo ">>> x86 DONE"

# ============================================================
echo ""
echo "============================================================"
echo "BUILD SUCCESS - Android LuaJIT xlua plugins"
echo "  arm64-v8a   -> plugin_luajit/Plugins/Android/libs/arm64-v8a/libxlua.so"
echo "  armeabi-v7a -> plugin_luajit/Plugins/Android/libs/armeabi-v7a/libxlua.so"
echo "  x86         -> plugin_luajit/Plugins/Android/libs/x86/libxlua.so"
echo ""
echo "NOTE: For bytecode compilation, use the HOST luajit executable"
echo "      (built by make_win64_luajit.bat or make_linux64_luajit.sh)"
echo "============================================================"
