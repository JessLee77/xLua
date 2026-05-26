#!/bin/bash
# =============================================================================
# xLua Lua 5.3 Android 构建脚本 (NDK r23b)
# 支持 ABI: arm64-v8a, armeabi-v7a, x86
# 特性: -DLUAC_COMPATIBLE_FORMAT=ON (跨平台 bytecode 兼容)
# 用法: bash make_android_lua53_ndk23.sh
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
    elif [ -d "/mnt/c/Program Files/Unity/Hub/Editor/2022.3.62f2/Editor/Data/PlaybackEngines/AndroidPlayer/NDK" ]; then
        NDK="/mnt/c/Program Files/Unity/Hub/Editor/2022.3.62f2/Editor/Data/PlaybackEngines/AndroidPlayer/NDK"
    else
        # 自动搜索 Unity NDK
        UNITY_NDK=$(find "/mnt/c/Program Files/Unity/Hub/Editor" -maxdepth 5 -type f -name "source.properties" -path "*/AndroidPlayer/NDK/*" 2>/dev/null | head -1 | xargs dirname 2>/dev/null)
        if [ -n "$UNITY_NDK" ] && [ -d "$UNITY_NDK" ]; then
            NDK="$UNITY_NDK"
        else
            echo "ERROR: Please set ANDROID_NDK or ANDROID_NDK_HOME to your NDK r23b root."
            echo "  Example: export ANDROID_NDK=~/android-ndk-r23b"
            echo "  Or:      export ANDROID_NDK='/mnt/c/Program Files/Unity/Hub/Editor/<version>/Editor/Data/PlaybackEngines/AndroidPlayer/NDK'"
            exit 1
        fi
    fi
fi

if [ ! -d "$NDK" ]; then
    echo "ERROR: NDK directory not found: $NDK"
    exit 1
fi

# 如果路径包含空格, 创建符号链接到无空格路径
if [[ "$NDK" == *" "* ]]; then
    NDK_LINK="/tmp/android-ndk"
    rm -f "$NDK_LINK"
    ln -sf "$NDK" "$NDK_LINK"
    NDK="$NDK_LINK"
    echo "NDK path contains spaces, using symlink: $NDK_LINK"
fi

echo "Using Android NDK: $NDK"

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$DIR"

API=21

function build() {
    local ABI=$1
    local BUILD_PATH="build53.Android.ndk23.${ABI}"

    echo ""
    echo "================================================================"
    echo "  Building Lua 5.3 for Android $ABI"
    echo "  LUAC_COMPATIBLE_FORMAT=ON"
    echo "================================================================"
    echo ""

    cmake -H. -B${BUILD_PATH} \
        -DLUAC_COMPATIBLE_FORMAT=ON \
        -DANDROID_ABI=${ABI} \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_TOOLCHAIN_FILE="${NDK}/build/cmake/android.toolchain.cmake" \
        -DANDROID_NATIVE_API_LEVEL=android-${API} \
        -DANDROID_TOOLCHAIN=clang

    cmake --build ${BUILD_PATH} --config Release

    mkdir -p plugin_lua53/Plugins/Android/libs/${ABI}/
    cp ${BUILD_PATH}/libxlua.so plugin_lua53/Plugins/Android/libs/${ABI}/libxlua.so
    echo "  -> $ABI: OK"
}

echo ""
echo "╔══════════════════════════════════════════════════════════════════╗"
echo "║  xLua Lua 5.3 Android Build (NDK r23b)                        ║"
echo "║  LUAC_COMPATIBLE_FORMAT=ON                                     ║"
echo "║  Target ABIs: arm64-v8a, armeabi-v7a, x86                     ║"
echo "╚══════════════════════════════════════════════════════════════════╝"
echo ""

build armeabi-v7a
build arm64-v8a
build x86

echo ""
echo "================================================================"
echo "  All Android Lua 5.3 builds completed!"
echo "  Output: plugin_lua53/Plugins/Android/libs/"
echo "    - arm64-v8a/libxlua.so"
echo "    - armeabi-v7a/libxlua.so"
echo "    - x86/libxlua.so"
echo "  All built with LUAC_COMPATIBLE_FORMAT=ON"
echo "================================================================"
echo ""
