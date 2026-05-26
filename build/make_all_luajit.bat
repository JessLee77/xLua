@echo off
REM =============================================================================
REM xLua LuaJIT 统一一键构建脚本
REM 
REM 功能:
REM   1. Windows x64 plugin (标准模式) + luajit.exe bytecode 工具
REM   2. Windows x64 GC64 luajit.exe bytecode 工具
REM   3. Windows x86 plugin (标准模式) + luajit.exe bytecode 工具
REM   4. Android (arm64-v8a + armeabi-v7a + x86) via WSL (NDK r23b)
REM   5. iOS 提示 (需 macOS 环境)
REM
REM 前置要求:
REM   - Visual Studio 2019 或 2022 (含 C++ 桌面开发工作负载)
REM   - CMake (VS自带或单独安装, 需在PATH中)
REM   - WSL + Ubuntu (用于 Android 构建)
REM   - Android NDK r23b (WSL中可访问)
REM
REM 用法: 在 build/ 目录下运行此脚本
REM =============================================================================

setlocal enabledelayedexpansion

echo.
echo ======================================================================
echo   xLua LuaJIT - Unified Build Script
echo   Platforms: Windows x64/x86, Android (arm64-v8a, armeabi-v7a, x86)
echo   Tools: luajit.exe (standard + GC64)
echo ======================================================================
echo.

REM --- 检测 Visual Studio ---
set "VCVARS64="
set "VCVARS32="
set "CMAKE_GENERATOR="

REM 优先检测 VS2022
if exist "C:\Program Files\Microsoft Visual Studio\2022\Community\VC\Auxiliary\Build\vcvars64.bat" (
    set "VCVARS64=C:\Program Files\Microsoft Visual Studio\2022\Community\VC\Auxiliary\Build\vcvars64.bat"
    set "VCVARS32=C:\Program Files\Microsoft Visual Studio\2022\Community\VC\Auxiliary\Build\vcvars32.bat"
    set "CMAKE_GENERATOR=Visual Studio 17 2022"
    echo [OK] Found Visual Studio 2022 Community
    goto :VS_FOUND
)
if exist "C:\Program Files\Microsoft Visual Studio\2022\Professional\VC\Auxiliary\Build\vcvars64.bat" (
    set "VCVARS64=C:\Program Files\Microsoft Visual Studio\2022\Professional\VC\Auxiliary\Build\vcvars64.bat"
    set "VCVARS32=C:\Program Files\Microsoft Visual Studio\2022\Professional\VC\Auxiliary\Build\vcvars32.bat"
    set "CMAKE_GENERATOR=Visual Studio 17 2022"
    echo [OK] Found Visual Studio 2022 Professional
    goto :VS_FOUND
)
if exist "C:\Program Files\Microsoft Visual Studio\2022\Enterprise\VC\Auxiliary\Build\vcvars64.bat" (
    set "VCVARS64=C:\Program Files\Microsoft Visual Studio\2022\Enterprise\VC\Auxiliary\Build\vcvars64.bat"
    set "VCVARS32=C:\Program Files\Microsoft Visual Studio\2022\Enterprise\VC\Auxiliary\Build\vcvars32.bat"
    set "CMAKE_GENERATOR=Visual Studio 17 2022"
    echo [OK] Found Visual Studio 2022 Enterprise
    goto :VS_FOUND
)

REM 检测 VS2019
if exist "C:\Program Files (x86)\Microsoft Visual Studio\2019\Community\VC\Auxiliary\Build\vcvars64.bat" (
    set "VCVARS64=C:\Program Files (x86)\Microsoft Visual Studio\2019\Community\VC\Auxiliary\Build\vcvars64.bat"
    set "VCVARS32=C:\Program Files (x86)\Microsoft Visual Studio\2019\Community\VC\Auxiliary\Build\vcvars32.bat"
    set "CMAKE_GENERATOR=Visual Studio 16 2019"
    echo [OK] Found Visual Studio 2019 Community
    goto :VS_FOUND
)
if exist "C:\Program Files (x86)\Microsoft Visual Studio\2019\Professional\VC\Auxiliary\Build\vcvars64.bat" (
    set "VCVARS64=C:\Program Files (x86)\Microsoft Visual Studio\2019\Professional\VC\Auxiliary\Build\vcvars64.bat"
    set "VCVARS32=C:\Program Files (x86)\Microsoft Visual Studio\2019\Professional\VC\Auxiliary\Build\vcvars32.bat"
    set "CMAKE_GENERATOR=Visual Studio 16 2019"
    echo [OK] Found Visual Studio 2019 Professional
    goto :VS_FOUND
)
if exist "C:\Program Files (x86)\Microsoft Visual Studio\2019\Enterprise\VC\Auxiliary\Build\vcvars64.bat" (
    set "VCVARS64=C:\Program Files (x86)\Microsoft Visual Studio\2019\Enterprise\VC\Auxiliary\Build\vcvars64.bat"
    set "VCVARS32=C:\Program Files (x86)\Microsoft Visual Studio\2019\Enterprise\VC\Auxiliary\Build\vcvars32.bat"
    set "CMAKE_GENERATOR=Visual Studio 16 2019"
    echo [OK] Found Visual Studio 2019 Enterprise
    goto :VS_FOUND
)

echo [ERROR] Visual Studio 2019 or 2022 not found!
echo         Please install Visual Studio with C++ Desktop Development workload.
goto :END

:VS_FOUND
echo         Generator: %CMAKE_GENERATOR%
echo.

REM --- 设置工作目录 ---
set "BUILD_DIR=%~dp0"
cd /d "%BUILD_DIR%"

REM =============================================================================
REM Step 1: Windows x64 - 标准模式 (非GC64)
REM   产出: plugin_luajit/Plugins/x86_64/xlua.dll
REM         tools/win64/luajit.exe
REM =============================================================================
echo.
echo ======================================================================
echo   [1/4] Building Windows x64 - Standard Mode
echo ======================================================================
echo.

REM 启动 x64 编译环境 (在子进程中执行, 避免环境污染)
cmd /c ""%VCVARS64%" && cd /d "%BUILD_DIR%luajit-2.1.0b3\src" && call msvcbuild_mt.bat static"
if errorlevel 1 (
    echo [ERROR] LuaJIT x64 standard build failed!
    goto :END
)

REM 保存 luajit.exe 和 jit/*.lua 到 tools/win64/
echo [INFO] Deploying luajit.exe (standard) to tools/win64/ ...
md tools\win64\lua\jit 2>nul
copy /Y luajit-2.1.0b3\src\luajit.exe tools\win64\luajit.exe >nul
copy /Y luajit-2.1.0b3\src\lua51.lib tools\win64\lua51.lib >nul
xcopy /Y /Q luajit-2.1.0b3\src\jit\*.lua tools\win64\lua\jit\ >nul
echo [OK] tools/win64/luajit.exe (standard mode)

REM 构建 xlua.dll x64
if exist build_lj64 rmdir /s /q build_lj64
mkdir build_lj64
cmd /c ""%VCVARS64%" && cd /d "%BUILD_DIR%" && cd build_lj64 && cmake -DUSING_LUAJIT=ON -G "%CMAKE_GENERATOR%" -A x64 .. && cd .. && cmake --build build_lj64 --config Release"
if errorlevel 1 (
    echo [ERROR] xlua.dll x64 build failed!
    goto :END
)
md plugin_luajit\Plugins\x86_64 2>nul
copy /Y build_lj64\Release\xlua.dll plugin_luajit\Plugins\x86_64\xlua.dll >nul
echo [OK] plugin_luajit/Plugins/x86_64/xlua.dll

REM =============================================================================
REM Step 2: Windows x64 - GC64 模式 (仅 luajit.exe 工具)
REM   产出: tools/win64_gc64/luajit.exe
REM =============================================================================
echo.
echo ======================================================================
echo   [2/4] Building Windows x64 - GC64 Mode (bytecode tool only)
echo ======================================================================
echo.

REM 清理 LuaJIT 中间文件后重新编译 GC64 版本
cmd /c ""%VCVARS64%" && cd /d "%BUILD_DIR%luajit-2.1.0b3\src" && call msvcbuild_mt.bat gc64 static"
if errorlevel 1 (
    echo [ERROR] LuaJIT x64 GC64 build failed!
    goto :END
)

REM 保存 GC64 版 luajit.exe
echo [INFO] Deploying luajit.exe (GC64) to tools/win64_gc64/ ...
md tools\win64_gc64\lua\jit 2>nul
copy /Y luajit-2.1.0b3\src\luajit.exe tools\win64_gc64\luajit.exe >nul
copy /Y luajit-2.1.0b3\src\lua51.lib tools\win64_gc64\lua51.lib >nul
xcopy /Y /Q luajit-2.1.0b3\src\jit\*.lua tools\win64_gc64\lua\jit\ >nul
echo [OK] tools/win64_gc64/luajit.exe (GC64 mode)

REM =============================================================================
REM Step 3: Windows x86 - 标准模式
REM   产出: plugin_luajit/Plugins/x86/xlua.dll
REM         tools/win32/luajit.exe
REM =============================================================================
echo.
echo ======================================================================
echo   [3/4] Building Windows x86 - Standard Mode
echo ======================================================================
echo.

REM 清理后用 x86 环境重新编译
cmd /c ""%VCVARS32%" && cd /d "%BUILD_DIR%luajit-2.1.0b3\src" && call msvcbuild_mt.bat static"
if errorlevel 1 (
    echo [ERROR] LuaJIT x86 build failed!
    goto :END
)

REM 保存 x86 版 luajit.exe
echo [INFO] Deploying luajit.exe (x86) to tools/win32/ ...
md tools\win32\lua\jit 2>nul
copy /Y luajit-2.1.0b3\src\luajit.exe tools\win32\luajit.exe >nul
copy /Y luajit-2.1.0b3\src\lua51.lib tools\win32\lua51.lib >nul
xcopy /Y /Q luajit-2.1.0b3\src\jit\*.lua tools\win32\lua\jit\ >nul
echo [OK] tools/win32/luajit.exe (x86 standard mode)

REM 构建 xlua.dll x86
if exist build_lj32 rmdir /s /q build_lj32
mkdir build_lj32
cmd /c ""%VCVARS32%" && cd /d "%BUILD_DIR%" && cd build_lj32 && cmake -DUSING_LUAJIT=ON -G "%CMAKE_GENERATOR%" -A Win32 .. && cd .. && cmake --build build_lj32 --config Release"
if errorlevel 1 (
    echo [ERROR] xlua.dll x86 build failed!
    goto :END
)
md plugin_luajit\Plugins\x86 2>nul
copy /Y build_lj32\Release\xlua.dll plugin_luajit\Plugins\x86\xlua.dll >nul
echo [OK] plugin_luajit/Plugins/x86/xlua.dll

REM =============================================================================
REM Step 4: Android (via WSL) - arm64-v8a + armeabi-v7a + x86
REM   产出: plugin_luajit/Plugins/Android/libs/{abi}/libxlua.so
REM =============================================================================
echo.
echo ======================================================================
echo   [4/4] Building Android via WSL (NDK r23b)
echo ======================================================================
echo.

REM 检测 WSL 是否可用
wsl --status >nul 2>&1
if errorlevel 1 (
    echo [WARNING] WSL is not available. Skipping Android build.
    echo           To install WSL, run in PowerShell (Admin):
    echo             wsl --install -d Ubuntu
    echo           Then restart your computer and re-run this script.
    echo.
    echo           Alternatively, run on Linux/macOS:
    echo             bash make_android_luajit_ndk23.sh
    goto :SKIP_ANDROID
)

REM 将 Windows 路径转换为 WSL 路径
set "WSL_BUILD_DIR=%BUILD_DIR:\=/%"
set "WSL_BUILD_DIR=/mnt/%WSL_BUILD_DIR:~0,1%%WSL_BUILD_DIR:~2%"
REM 转为小写盘符
for %%a in (a b c d e f g h i j k l m n o p q r s t u v w x y z) do (
    set "WSL_BUILD_DIR=!WSL_BUILD_DIR:/mnt/%%a=/mnt/%%a!"
)
REM 手动处理常见盘符大写转小写
set "WSL_BUILD_DIR=%WSL_BUILD_DIR:/mnt/C=/mnt/c%"
set "WSL_BUILD_DIR=%WSL_BUILD_DIR:/mnt/D=/mnt/d%"
set "WSL_BUILD_DIR=%WSL_BUILD_DIR:/mnt/E=/mnt/e%"
set "WSL_BUILD_DIR=%WSL_BUILD_DIR:/mnt/F=/mnt/f%"

echo [INFO] WSL build path: %WSL_BUILD_DIR%

REM 确保 shell 脚本有执行权限并运行
wsl bash -c "cd '%WSL_BUILD_DIR%' && chmod +x make_android_luajit_ndk23.sh && bash make_android_luajit_ndk23.sh"
if errorlevel 1 (
    echo [ERROR] Android build failed!
    echo         Please check WSL environment and NDK path.
    echo         You can also run manually in WSL:
    echo           cd %WSL_BUILD_DIR%
    echo           export ANDROID_NDK=/path/to/android-ndk-r23b
    echo           bash make_android_luajit_ndk23.sh
) else (
    echo [OK] Android build completed
)

:SKIP_ANDROID

REM =============================================================================
REM iOS 提示
REM =============================================================================
echo.
echo ======================================================================
echo   iOS Build Note
echo ======================================================================
echo.
echo   iOS build requires macOS + Xcode. Please run on a Mac:
echo     cd build
echo     bash make_ios_luajit.sh
echo   Output: plugin_luajit/Plugins/iOS/libxlua.a
echo.

REM =============================================================================
REM 构建完成总结
REM =============================================================================
echo.
echo ======================================================================
echo   BUILD SUMMARY
echo ======================================================================
echo.
echo   Plugins:
echo     [Windows x64]  plugin_luajit/Plugins/x86_64/xlua.dll
echo     [Windows x86]  plugin_luajit/Plugins/x86/xlua.dll
echo     [Android]      plugin_luajit/Plugins/Android/libs/arm64-v8a/libxlua.so   (GC64)
echo                    plugin_luajit/Plugins/Android/libs/armeabi-v7a/libxlua.so (standard)
echo                    plugin_luajit/Plugins/Android/libs/x86/libxlua.so         (standard)
echo     [iOS]          (requires macOS build)
echo.
echo   Bytecode Tools:
echo     [Standard]     tools/win64/luajit.exe       - for x86/x64/ARMv7 targets
echo     [GC64]         tools/win64_gc64/luajit.exe  - for ARM64 targets
echo     [x86]          tools/win32/luajit.exe       - 32-bit standard mode
echo.
echo   Usage:
echo     Standard bytecode:  tools\win64\luajit.exe -b input.lua output.bytes
echo     GC64 bytecode:      tools\win64_gc64\luajit.exe -b input.lua output.bytes
echo.
echo ======================================================================
echo.

:END
endlocal
pause
