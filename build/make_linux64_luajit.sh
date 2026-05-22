#!/bin/bash
# ============================================================
# Build libxlua.so (x64) + luajit executable with LuaJIT 2.1.0-beta3
# For Linux x86_64
# ============================================================

set -e

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$DIR"

echo "============================================================"
echo "  Building Linux x64 xlua plugin + luajit tool"
echo "============================================================"

# --- Step 1: Build LuaJIT (static lib + luajit executable) ---
echo ""
echo ">>> Step 1: Building LuaJIT ..."
cd luajit-2.1.0b3
make clean
make -j$(nproc) CFLAGS=-fPIC
cd "$DIR"

# --- Step 2: Build xlua.so via CMake ---
echo ""
echo ">>> Step 2: Building xlua.so ..."
mkdir -p build_linux64_lj && cd build_linux64_lj
cmake -DUSING_LUAJIT=ON ../
cd "$DIR"
cmake --build build_linux64_lj --config Release

# --- Step 3: Copy outputs ---
echo ""
echo ">>> Step 3: Copying outputs ..."

# xlua plugin
mkdir -p plugin_luajit/Plugins/x86_64/
cp build_linux64_lj/libxlua.so plugin_luajit/Plugins/x86_64/libxlua.so

# luajit executable tool for bytecode compilation
# On Unix, LUA_PATH_DEFAULT starts with ./?.lua so we need jit/ beside the exe
# We also create a wrapper script that sets LUA_PATH correctly
mkdir -p tools/linux64/lua/jit
cp luajit-2.1.0b3/src/luajit tools/linux64/luajit
chmod +x tools/linux64/luajit
cp luajit-2.1.0b3/src/jit/*.lua tools/linux64/lua/jit/

# Create wrapper script for easy use from any directory
cat > tools/linux64/luajit_bytecode.sh << 'WRAPPER'
#!/bin/bash
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
export LUA_PATH="$SCRIPT_DIR/lua/?.lua;;"
exec "$SCRIPT_DIR/luajit" "$@"
WRAPPER
chmod +x tools/linux64/luajit_bytecode.sh

echo ""
echo "============================================================"
echo "BUILD SUCCESS"
echo "  libxlua.so -> plugin_luajit/Plugins/x86_64/libxlua.so"
echo "  luajit     -> tools/linux64/luajit"
echo ""
echo "Usage: tools/linux64/luajit -b input.lua output.bytes"
echo "============================================================"
