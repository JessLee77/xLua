#!/bin/bash
# ============================================================
# Build libxlua.a (iOS arm64) with LuaJIT 2.1.0-beta3
# Cross-compilation target - no luajit executable produced
# (Use the macOS luajit for bytecode compilation)
# ============================================================

set -e

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$DIR"

echo "============================================================"
echo "  Building iOS xlua static library with LuaJIT 2.1.0-beta3"
echo "============================================================"

LIPO="xcrun -sdk iphoneos lipo"
STRIP="xcrun -sdk iphoneos strip"

IXCODE=$(xcode-select -print-path)
ISDK=$IXCODE/Platforms/iPhoneOS.platform/Developer
ISDKVER=iPhoneOS.sdk
ISDKP=$IXCODE/usr/bin/

# Ensure ar/ranlib/strip exist in Xcode toolchain
if [ ! -e $ISDKP/ar ]; then 
  sudo cp /usr/bin/ar $ISDKP
fi

if [ ! -e $ISDKP/ranlib ]; then
  sudo cp /usr/bin/ranlib $ISDKP
fi

if [ ! -e $ISDKP/strip ]; then
  sudo cp /usr/bin/strip $ISDKP
fi

cd luajit-2.1.0b3

# --- Build arm64 ---
echo ""
echo ">>> Building LuaJIT for iOS arm64 ..."
make clean
ISDKF="-arch arm64 -isysroot $ISDK/SDKs/$ISDKVER -miphoneos-version-min=11.0"
make HOST_CC="gcc -std=c99" TARGET_FLAGS="$ISDKF" TARGET=arm64 TARGET_SYS=iOS LUAJIT_A=libxlua64.a

cd src
mv libxlua64.a libluajit.a
cd ../..

# --- Build xlua static library via CMake ---
echo ""
echo ">>> Building xlua static library ..."
mkdir -p build_lj_ios && cd build_lj_ios
cmake -DUSING_LUAJIT=ON \
      -DCMAKE_TOOLCHAIN_FILE=../cmake/ios.toolchain.cmake \
      -DPLATFORM=OS64 \
      -GXcode ../
cd "$DIR"
cmake --build build_lj_ios --config Release

# --- Merge static libraries ---
echo ""
echo ">>> Merging static libraries ..."
mkdir -p plugin_luajit/Plugins/iOS/
libtool -static -o plugin_luajit/Plugins/iOS/libxlua.a \
    build_lj_ios/Release-iphoneos/libxlua.a \
    luajit-2.1.0b3/src/libluajit.a

echo ""
echo "============================================================"
echo "BUILD SUCCESS"
echo "  libxlua.a -> plugin_luajit/Plugins/iOS/libxlua.a"
echo ""
echo "NOTE: For bytecode compilation, use the macOS luajit:"
echo "  tools/osx/luajit -b input.lua output.bytes"
echo "  (or tools/osx_silicon/luajit on Apple Silicon)"
echo "============================================================"
