@echo off
setlocal

:: ============================================================
:: Build xlua.dll (x86) + luajit.exe with LuaJIT 2.1.0-beta3
:: Supports VS 2022 / VS 2019 auto-detection
:: ============================================================

:: --- Auto-detect Visual Studio ---
set VSFOUND=0

:: Try VS 2022 first
for %%E in (Enterprise Professional Community BuildTools) do (
    if exist "C:\Program Files\Microsoft Visual Studio\2022\%%E\VC\Auxiliary\Build\vcvars32.bat" (
        call "C:\Program Files\Microsoft Visual Studio\2022\%%E\VC\Auxiliary\Build\vcvars32.bat"
        set VSFOUND=1
        set CMAKE_GEN="Visual Studio 17 2022"
        echo Found VS 2022 %%E
        goto :VS_DONE
    )
)

:: Try VS 2019
for %%E in (Enterprise Professional Community BuildTools) do (
    if exist "C:\Program Files (x86)\Microsoft Visual Studio\2019\%%E\VC\Auxiliary\Build\vcvars32.bat" (
        call "C:\Program Files (x86)\Microsoft Visual Studio\2019\%%E\VC\Auxiliary\Build\vcvars32.bat"
        set VSFOUND=1
        set CMAKE_GEN="Visual Studio 16 2019"
        echo Found VS 2019 %%E
        goto :VS_DONE
    )
)

if %VSFOUND%==0 (
    echo ERROR: Visual Studio 2019 or 2022 not found!
    pause
    exit /b 1
)

:VS_DONE
echo Switch to x86 build env
echo Using CMake Generator: %CMAKE_GEN%

:: --- Step 1: Build LuaJIT static library + luajit.exe ---
cd /d %~dp0\luajit-2.1.0b3\src
call msvcbuild_mt.bat static
if errorlevel 1 (
    echo ERROR: LuaJIT build failed!
    pause
    exit /b 1
)
cd /d %~dp0

:: --- Step 2: Build xlua.dll via CMake ---
mkdir build_lj32 2>nul
pushd build_lj32
cmake -DUSING_LUAJIT=ON -G %CMAKE_GEN% -A Win32 ..
IF %ERRORLEVEL% NEQ 0 cmake -DUSING_LUAJIT=ON -G %CMAKE_GEN% -A Win32 ..
popd
cmake --build build_lj32 --config Release
if errorlevel 1 (
    echo ERROR: xlua.dll build failed!
    pause
    exit /b 1
)

:: --- Step 3: Copy outputs ---
:: xlua plugin
md plugin_luajit\Plugins\x86 2>nul
copy /Y build_lj32\Release\xlua.dll plugin_luajit\Plugins\x86\xlua.dll

:: luajit.exe tool for bytecode compilation
:: jit modules must be in lua\jit\ relative to luajit.exe (Windows LUA_PATH_DEFAULT)
md tools\win32\lua\jit 2>nul
copy /Y luajit-2.1.0b3\src\luajit.exe tools\win32\luajit.exe
xcopy /Y luajit-2.1.0b3\src\jit\*.lua tools\win32\lua\jit\

echo.
echo ============================================================
echo BUILD SUCCESS
echo   xlua.dll   -> plugin_luajit\Plugins\x86\xlua.dll
echo   luajit.exe -> tools\win32\luajit.exe
echo.
echo Usage: tools\win32\luajit.exe -b input.lua output.bytes
echo ============================================================
pause
