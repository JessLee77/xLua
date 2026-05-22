#!/bin/bash
# ============================================================
# LuaJIT Bytecode Compiler Tool
# Converts .lua source files to LuaJIT bytecode
#
# Usage:
#   ./compile_lua.sh <input_dir> <output_dir>
#   ./compile_lua.sh <input_file.lua> <output_file.bytes>
#   ./compile_lua.sh <input_dir>               (output to same dir)
#
# Examples:
#   ./compile_lua.sh Assets/Lua Assets/LuaBytes
#   ./compile_lua.sh test.lua test.bytes
#   ./compile_lua.sh Assets/Lua
#
# Based on LuaJIT 2.1.0-beta3 (standard mode, non-GC64)
# ============================================================

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Auto-detect platform and luajit path
OS=$(uname -s)
ARCH=$(uname -m)

if [[ "$OS" == "Darwin" ]]; then
    if [[ "$ARCH" == "arm64" ]]; then
        LUAJIT="$SCRIPT_DIR/tools/osx_silicon/luajit"
    else
        LUAJIT="$SCRIPT_DIR/tools/osx/luajit"
    fi
elif [[ "$OS" == "Linux" ]]; then
    LUAJIT="$SCRIPT_DIR/tools/linux64/luajit"
else
    echo "ERROR: Unsupported platform: $OS"
    exit 1
fi

# Check if luajit exists
if [ ! -x "$LUAJIT" ]; then
    echo "ERROR: luajit not found at: $LUAJIT"
    echo "Please build it first with the appropriate make_*_luajit.sh script."
    exit 1
fi

# Set LUA_PATH so jit.bcsave module can be found from any working directory
LUAJIT_DIR=$(dirname "$LUAJIT")
export LUA_PATH="$LUAJIT_DIR/lua/?.lua;;"

# Parse arguments
INPUT="$1"
OUTPUT="$2"

if [ -z "$INPUT" ]; then
    echo "Usage:"
    echo "  $0 <input_dir> <output_dir>"
    echo "  $0 <input_file.lua> <output_file.bytes>"
    echo "  $0 <input_dir>"
    exit 1
fi

if [ -d "$INPUT" ]; then
    # Input is a directory - batch mode
    [ -z "$OUTPUT" ] && OUTPUT="$INPUT"
    
    echo "============================================================"
    echo "  LuaJIT Bytecode Compiler - Batch Mode"
    echo "  Input:  $INPUT"
    echo "  Output: $OUTPUT"
    echo "============================================================"
    echo ""
    
    COUNT=0
    ERRORS=0
    
    while IFS= read -r -d '' file; do
        RELPATH="${file#$INPUT}"
        OUTFILE="${OUTPUT}${RELPATH%.lua}.bytes"
        OUTDIR=$(dirname "$OUTFILE")
        
        mkdir -p "$OUTDIR"
        
        echo "Compiling: $file"
        if "$LUAJIT" -b "$file" "$OUTFILE"; then
            COUNT=$((COUNT + 1))
        else
            echo "  FAILED: $file"
            ERRORS=$((ERRORS + 1))
        fi
    done < <(find "$INPUT" -name "*.lua" -type f -print0)
    
    echo ""
    echo "============================================================"
    echo "  Done: $COUNT files compiled, $ERRORS errors"
    echo "============================================================"
elif [ -f "$INPUT" ]; then
    # Input is a single file
    [ -z "$OUTPUT" ] && OUTPUT="${INPUT%.lua}.bytes"
    
    echo "Compiling: $INPUT -> $OUTPUT"
    "$LUAJIT" -b "$INPUT" "$OUTPUT"
    echo "Done."
else
    echo "ERROR: Input not found: $INPUT"
    exit 1
fi
