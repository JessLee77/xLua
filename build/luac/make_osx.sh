#!/bin/bash
# =============================================================================
# xLua Lua 5.3 - macOS luac/lua bytecode tools build
#
# Builds universal (arm64 + x86_64) luac and lua for macOS.
# Output: ../tools/lua53/osx/luac, ../tools/lua53/osx/lua
#
# LUAC_COMPATIBLE_FORMAT=ON makes bytecode portable across 32/64-bit platforms,
# so a single .bytes file produced here loads on iOS/Android/Windows too.
#
# Requirements:
#   - macOS with Xcode command line tools (Xcode 12+ for universal arm64+x86_64)
#   - CMake (install via `brew install cmake` if missing)
#
# Usage: run this script on a Mac:
#   bash luac/make_osx.sh
#
# NOTE: If you only need the native architecture of your Mac (e.g. an older
# Intel Mac without arm64 toolchain), drop the CMAKE_OSX_ARCHITECTURES line
# below to build for the current arch only.
# =============================================================================
set -e

cd "$(dirname "$0")"

echo ""
echo "======================================================================"
echo "  Building luac/lua for macOS (universal: arm64 + x86_64)"
echo "  LUAC_COMPATIBLE_FORMAT=ON (cross-platform bytecode)"
echo "======================================================================"
echo ""

rm -rf build_osx
mkdir -p build_osx && cd build_osx
cmake -DLUAC_COMPATIBLE_FORMAT=ON \
      -DCMAKE_OSX_ARCHITECTURES="arm64;x86_64" \
      -G "Unix Makefiles" \
      ../
cd ..
cmake --build build_osx --config Release

mkdir -p ../tools/lua53/osx
cp -f build_osx/luac ../tools/lua53/osx/luac
cp -f build_osx/lua  ../tools/lua53/osx/lua
chmod +x ../tools/lua53/osx/luac ../tools/lua53/osx/lua

echo ""
echo "[OK] tools/lua53/osx/luac"
echo "[OK] tools/lua53/osx/lua"
echo ""
echo "Usage:"
echo "  tools/lua53/osx/luac -o output.bytes input.lua"
echo "  tools/lua53/osx/luac -o combined.bytes file1.lua file2.lua"
echo "  tools/lua53/osx/luac -p input.lua  (syntax check only)"
echo ""
