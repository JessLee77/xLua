#!/bin/bash
# ============================================================
# Build xlua.bundle (Intel x86_64) + luajit executable
# with LuaJIT 2.1.0-beta3 for macOS Intel
# ============================================================

set -e

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$DIR"

echo "============================================================"
echo "  Building macOS Intel xlua plugin + luajit tool"
echo "============================================================"

# --- Step 1: Build LuaJIT native (for luajit -b tool) ---
echo ""
echo ">>> Step 1: Building native LuaJIT (for bytecode tool) ..."
cd luajit-2.1.0b3
make clean
make -j$(sysctl -n hw.ncpu) MACOSX_DEPLOYMENT_TARGET=10.12
cd "$DIR"

# --- Step 2: Copy luajit tool BEFORE CMake overwrites anything ---
echo ""
echo ">>> Step 2: Saving luajit tool ..."
mkdir -p tools/osx/lua/jit
cp luajit-2.1.0b3/src/luajit tools/osx/luajit
chmod +x tools/osx/luajit
cp luajit-2.1.0b3/src/jit/*.lua tools/osx/lua/jit/

# Create wrapper script for easy use from any directory
cat > tools/osx/luajit_bytecode.sh << 'WRAPPER'
#!/bin/bash
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
export LUA_PATH="$SCRIPT_DIR/lua/?.lua;;"
exec "$SCRIPT_DIR/luajit" "$@"
WRAPPER
chmod +x tools/osx/luajit_bytecode.sh

# --- Step 3: Build xlua.bundle via CMake ---
echo ""
echo ">>> Step 3: Building xlua.bundle ..."
mkdir -p build_lj_osx && cd build_lj_osx
cmake -DUSING_LUAJIT=ON -GXcode ../
cd "$DIR"
cmake --build build_lj_osx --config Release

# --- Step 4: Copy xlua plugin ---
echo ""
echo ">>> Step 4: Copying xlua plugin ..."
mkdir -p plugin_luajit/Plugins/xlua.bundle/Contents/MacOS/
cp build_lj_osx/Release/xlua.bundle/Contents/MacOS/xlua plugin_luajit/Plugins/xlua.bundle/Contents/MacOS/xlua

echo ""
echo "============================================================"
echo "BUILD SUCCESS"
echo "  xlua.bundle -> plugin_luajit/Plugins/xlua.bundle/"
echo "  luajit      -> tools/osx/luajit"
echo ""
echo "Usage: tools/osx/luajit -b input.lua output.bytes"
echo "============================================================"
