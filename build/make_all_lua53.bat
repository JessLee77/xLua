@echo off
REM =============================================================================
REM xLua Lua 5.3 Unified Build Script
REM
REM Targets:
REM   1. Windows x64 plugin (xlua.dll) - LUAC_COMPATIBLE_FORMAT=ON
REM   2. Windows x86 plugin (xlua.dll) - LUAC_COMPATIBLE_FORMAT=ON
REM   3. luac.exe x64 bytecode compiler
REM   4. luac.exe x86 bytecode compiler (32-bit)
REM   5. Android (arm64-v8a + armeabi-v7a + x86) via WSL (NDK r23b)
REM
REM Requirements:
REM   - Visual Studio 2019 or 2022 (C++ Desktop workload)
REM   - CMake (bundled with VS or standalone, must be in PATH)
REM   - WSL + Ubuntu (for Android build, optional)
REM   - Android NDK r23b (accessible in WSL, optional)
REM
REM Usage: Run this script from the build/ directory
REM =============================================================================

setlocal enabledelayedexpansion

echo.
echo ======================================================================
echo   xLua Lua 5.3 - Unified Build Script
echo   LUAC_COMPATIBLE_FORMAT=ON (cross-platform bytecode)
echo   Platforms: Windows x64/x86, Android (arm64-v8a, armeabi-v7a, x86)
echo   Tools: luac.exe (bytecode compiler)
echo ======================================================================
echo.

REM --- Detect Visual Studio (using vswhere) ---
set "__VS=Visual Studio 16 2019"
set "__VSWhere=%ProgramFiles(x86)%\Microsoft Visual Studio\Installer\vswhere.exe"
set "__VSDISPLAY="
set "__VSVER="

if exist "%__VSWhere%" (
    for /f "tokens=*" %%p in (
        '"%__VSWhere%" -latest -property catalog_productLineVersion'
    ) do set __VSDISPLAY=%%p

    for /f "tokens=*" %%p in (
        '"%__VSWhere%" -latest -property catalog_productDisplayVersion'
    ) do set __VSVER=%%p
)

if "%__VSVER%" neq "" (
    set "__VS=Visual Studio %__VSVER:~0,2% %__VSDISPLAY%"
)

echo [OK] Using CMake Generator: %__VS%
echo.

REM --- Set working directory ---
set "BUILD_DIR=%~dp0"
cd /d "%BUILD_DIR%"

REM =============================================================================
REM Step 1: Windows x64 plugin
REM =============================================================================
echo.
echo ======================================================================
echo   [1/5] Building Windows x64 - Lua 5.3 Plugin
echo ======================================================================
echo.

if exist build64 rmdir /s /q build64
mkdir build64 & pushd build64
cmake -DLUAC_COMPATIBLE_FORMAT=ON -G "%__VS%" -A x64 ..
IF %ERRORLEVEL% NEQ 0 (
    echo [ERROR] CMake configure failed for x64!
    popd
    goto :END
)
popd
cmake --build build64 --config Release
IF %ERRORLEVEL% NEQ 0 (
    echo [ERROR] Build failed for x64!
    goto :END
)
md plugin_lua53\Plugins\x86_64 2>nul
copy /Y build64\Release\xlua.dll plugin_lua53\Plugins\x86_64\xlua.dll >nul
echo [OK] plugin_lua53/Plugins/x86_64/xlua.dll

REM =============================================================================
REM Step 2: Windows x86 plugin
REM =============================================================================
echo.
echo ======================================================================
echo   [2/5] Building Windows x86 - Lua 5.3 Plugin
echo ======================================================================
echo.

if exist build32 rmdir /s /q build32
mkdir build32 & pushd build32
cmake -DLUAC_COMPATIBLE_FORMAT=ON -G "%__VS%" -A Win32 ..
IF %ERRORLEVEL% NEQ 0 (
    echo [ERROR] CMake configure failed for x86!
    popd
    goto :END
)
popd
cmake --build build32 --config Release
IF %ERRORLEVEL% NEQ 0 (
    echo [ERROR] Build failed for x86!
    goto :END
)
md plugin_lua53\Plugins\x86 2>nul
copy /Y build32\Release\xlua.dll plugin_lua53\Plugins\x86\xlua.dll >nul
echo [OK] plugin_lua53/Plugins/x86/xlua.dll

REM =============================================================================
REM Step 3: luac.exe x64 (bytecode compiler)
REM =============================================================================
echo.
echo ======================================================================
echo   [3/5] Building luac.exe x64 (bytecode compiler)
echo ======================================================================
echo.

pushd luac
if exist build64 rmdir /s /q build64
mkdir build64 & pushd build64
cmake -DLUAC_COMPATIBLE_FORMAT=ON -G "%__VS%" -A x64 ..
IF %ERRORLEVEL% NEQ 0 (
    echo [ERROR] CMake configure failed for luac x64!
    popd & popd
    goto :END
)
popd
cmake --build build64 --config Release
IF %ERRORLEVEL% NEQ 0 (
    echo [ERROR] Build failed for luac x64!
    popd
    goto :END
)
popd

md tools\lua53\win64 2>nul
copy /Y luac\build64\Release\luac.exe tools\lua53\win64\luac.exe >nul
copy /Y luac\build64\Release\lua.exe tools\lua53\win64\lua.exe >nul
echo [OK] tools/lua53/win64/luac.exe
echo [OK] tools/lua53/win64/lua.exe

REM =============================================================================
REM Step 4: luac.exe x86 (bytecode compiler, 32-bit)
REM =============================================================================
echo.
echo ======================================================================
echo   [4/5] Building luac.exe x86 (bytecode compiler, 32-bit)
echo ======================================================================
echo.

pushd luac
if exist build32 rmdir /s /q build32
mkdir build32 & pushd build32
cmake -DLUAC_COMPATIBLE_FORMAT=ON -G "%__VS%" -A Win32 ..
IF %ERRORLEVEL% NEQ 0 (
    echo [ERROR] CMake configure failed for luac x86!
    popd & popd
    goto :END
)
popd
cmake --build build32 --config Release
IF %ERRORLEVEL% NEQ 0 (
    echo [ERROR] Build failed for luac x86!
    popd
    goto :END
)
popd

md tools\lua53\win32 2>nul
copy /Y luac\build32\Release\luac.exe tools\lua53\win32\luac.exe >nul
copy /Y luac\build32\Release\lua.exe tools\lua53\win32\lua.exe >nul
echo [OK] tools/lua53/win32/luac.exe
echo [OK] tools/lua53/win32/lua.exe

REM =============================================================================
REM Step 5: Android (via WSL) - arm64-v8a + armeabi-v7a + x86
REM =============================================================================
echo.
echo ======================================================================
echo   [5/5] Building Android via WSL (NDK r23b)
echo ======================================================================
echo.

REM Check WSL availability
wsl --status >nul 2>&1
if errorlevel 1 (
    echo [WARNING] WSL is not available. Skipping Android build.
    echo           To install WSL, run in PowerShell as Admin:
    echo             wsl --install -d Ubuntu
    echo           Then restart and re-run this script.
    echo.
    echo           Or run on Linux/macOS directly:
    echo             bash make_android_lua53_ndk23.sh
    goto :SKIP_ANDROID
)

REM Detect available Linux distribution
wsl -d Ubuntu-24.04 -- echo "ok" >nul 2>&1
if errorlevel 1 (
    wsl -d Ubuntu -- echo "ok" >nul 2>&1
    if errorlevel 1 (
        echo [WARNING] No suitable WSL Linux distribution found. Skipping Android build.
        echo           Install Ubuntu: wsl --install -d Ubuntu-24.04
        goto :SKIP_ANDROID
    )
    set "WSL_DISTRO=Ubuntu"
) else (
    set "WSL_DISTRO=Ubuntu-24.04"
)

REM Convert Windows path to WSL path
set "WSL_BUILD_DIR=%BUILD_DIR:\=/%"
set "WSL_BUILD_DIR=/mnt/%WSL_BUILD_DIR:~0,1%%WSL_BUILD_DIR:~2%"
set "WSL_BUILD_DIR=%WSL_BUILD_DIR:/mnt/C=/mnt/c%"
set "WSL_BUILD_DIR=%WSL_BUILD_DIR:/mnt/D=/mnt/d%"
set "WSL_BUILD_DIR=%WSL_BUILD_DIR:/mnt/E=/mnt/e%"
set "WSL_BUILD_DIR=%WSL_BUILD_DIR:/mnt/F=/mnt/f%"

echo [INFO] WSL distro: %WSL_DISTRO%
echo [INFO] WSL build path: %WSL_BUILD_DIR%

wsl -d %WSL_DISTRO% -- bash -c "export ANDROID_NDK=~/android-ndk-r23b && cd '%WSL_BUILD_DIR%' && chmod +x make_android_lua53_ndk23.sh && bash make_android_lua53_ndk23.sh"
if errorlevel 1 (
    echo [ERROR] Android build failed!
    echo         Please check WSL environment and NDK path.
    echo         You can run manually in WSL:
    echo           cd %WSL_BUILD_DIR%
    echo           export ANDROID_NDK=~/android-ndk-r23b
    echo           bash make_android_lua53_ndk23.sh
) else (
    echo [OK] Android build completed
)

:SKIP_ANDROID

REM =============================================================================
REM iOS / macOS Note
REM =============================================================================
echo.
echo ======================================================================
echo   iOS / macOS Build Note
echo ======================================================================
echo.
echo   These builds require macOS + Xcode. Run on a Mac:
echo     cd build
echo     bash make_ios_lua53.sh
echo     bash make_osx_lua53.sh
echo     bash make_osx_silicon_lua53.sh
echo   All scripts now include -DLUAC_COMPATIBLE_FORMAT=ON
echo.
echo   macOS bytecode tools (luac/lua, universal arm64+x86_64):
echo     cd build/luac
echo     bash make_osx.sh
echo   Output: tools/lua53/osx/luac, tools/lua53/osx/lua
echo.

REM =============================================================================
REM Build Summary
REM =============================================================================
echo.
echo ======================================================================
echo   BUILD SUMMARY - Lua 5.3 (LUAC_COMPATIBLE_FORMAT=ON)
echo ======================================================================
echo.
echo   Plugins:
echo     [Windows x64]  plugin_lua53/Plugins/x86_64/xlua.dll
echo     [Windows x86]  plugin_lua53/Plugins/x86/xlua.dll
echo     [Android]      plugin_lua53/Plugins/Android/libs/arm64-v8a/libxlua.so
echo                    plugin_lua53/Plugins/Android/libs/armeabi-v7a/libxlua.so
echo                    plugin_lua53/Plugins/Android/libs/x86/libxlua.so
echo     [iOS]          (requires macOS build)
echo.
echo   Bytecode Tools:
echo     [Windows x64]  tools/lua53/win64/luac.exe
echo     [Windows x86]  tools/lua53/win32/luac.exe
echo     [macOS]        tools/lua53/osx/luac (requires macOS build: build/luac/make_osx.sh)
echo.
echo   Usage:
echo     tools\lua53\win64\luac.exe -o output.bytes input.lua
echo     tools\lua53\win64\luac.exe -o combined.bytes file1.lua file2.lua
echo     tools\lua53\win64\luac.exe -p input.lua  (syntax check only)
echo.
echo   Note: LUAC_COMPATIBLE_FORMAT makes bytecode portable between
echo         32-bit and 64-bit platforms.
echo.
echo ======================================================================
echo.

:END
endlocal
pause
