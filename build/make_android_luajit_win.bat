@echo off
setlocal enabledelayedexpansion
:: ============================================================
:: Build libxlua.so for Android armeabi-v7a (32-bit ARM)
:: with LuaJIT 2.1.0-beta3 - Pure Windows, NO make required
:: Uses Unity 2022.3 bundled NDK r23b
::
:: IMPORTANT:
::   - ARM64 (arm64-v8a) build requires Linux/macOS environment
::     due to MSVC limitation. Use: make_android_luajit_ndk23.sh
::   - For ARM64 bytecode: use tools\win64_gc64\luajit.exe -b
::   - For ARMv7 bytecode: use tools\win64\luajit.exe -b
:: ============================================================

:: --- Configuration ---
set ANDROID_NDK=C:\Program Files\Unity\Hub\Editor\2022.3.62f2\Editor\Data\PlaybackEngines\AndroidPlayer\NDK
set NDKABI=21
set TOOLCHAIN=%ANDROID_NDK%\toolchains\llvm\prebuilt\windows-x86_64

:: Verify NDK
if not exist "%TOOLCHAIN%\bin\clang.exe" (
    echo ERROR: NDK not found at: %TOOLCHAIN%
    pause
    exit /b 1
)

:: --- Visual Studio ---
set VSFOUND=0
for %%E in (Enterprise Professional Community BuildTools) do (
    if exist "C:\Program Files\Microsoft Visual Studio\2022\%%E\VC\Auxiliary\Build\vcvars64.bat" (
        call "C:\Program Files\Microsoft Visual Studio\2022\%%E\VC\Auxiliary\Build\vcvars64.bat"
        set VSFOUND=1
        goto :VS_DONE
    )
)
for %%E in (Enterprise Professional Community BuildTools) do (
    if exist "C:\Program Files (x86)\Microsoft Visual Studio\2019\%%E\VC\Auxiliary\Build\vcvars64.bat" (
        call "C:\Program Files (x86)\Microsoft Visual Studio\2019\%%E\VC\Auxiliary\Build\vcvars64.bat"
        set VSFOUND=1
        goto :VS_DONE
    )
)
if %VSFOUND%==0 (echo ERROR: VS not found! & pause & exit /b 1)
:VS_DONE

cd /d %~dp0
set BUILD_DIR=%~dp0
set LUAJIT_SRC=%BUILD_DIR%luajit-2.1.0b3\src

echo ============================================================
echo  Building Android armeabi-v7a xlua with LuaJIT 2.1.0-beta3
echo ============================================================

:: --- Step 1: Build host tools for ARM32 target ---
echo.
echo [Step 1] Building host tools (minilua + buildvm for ARM32) ...
cd /d "%LUAJIT_SRC%"

del /q *.obj *.o *.exe *.lib *.exp *.manifest 2>nul
del /q host\buildvm_arch.h lj_bcdef.h lj_ffdef.h lj_libdef.h lj_recdef.h lj_folddef.h lj_vm.S 2>nul

set LJCOMPILE=cl /nologo /c /O2 /W3 /D_CRT_SECURE_NO_DEPRECATE /D_CRT_STDIO_INLINE=__declspec(dllexport)__inline
set LJLINK=link /nologo
set DASMDIR=..\dynasm
set DASM=%DASMDIR%\dynasm.lua
set ALL_LIB=lib_base.c lib_math.c lib_bit.c lib_string.c lib_table.c lib_io.c lib_os.c lib_package.c lib_debug.c lib_jit.c lib_ffi.c
set AR="%TOOLCHAIN%\bin\llvm-ar.exe"

:: Build minilua
%LJCOMPILE% host\minilua.c
%LJLINK% /out:minilua.exe minilua.obj
if errorlevel 1 goto :FAIL

:: DynASM for ARM32 (DUALNUM, FPU, no P64, no HFABI for softfp)
set DASMFLAGS=-D JIT -D FFI -D DUALNUM -D FPU -D VER=70
minilua %DASM% -LN %DASMFLAGS% -o host\buildvm_arch.h vm_arm.dasc
if errorlevel 1 goto :FAIL

:: Build buildvm for ARM target (LUAJIT_ARCH_ARM=3, LUAJIT_OS_LINUX=1)
%LJCOMPILE% /I "." /I %DASMDIR% /DLUAJIT_TARGET=3 /DLJ_ARCH_HASFPU=1 /DLJ_ABI_SOFTFP=1 /DLUAJIT_OS=1 host\buildvm*.c
if errorlevel 1 goto :FAIL
%LJLINK% /out:buildvm.exe buildvm*.obj
if errorlevel 1 goto :FAIL

:: Generate VM assembly and headers
buildvm -m elfasm -o lj_vm.S
if errorlevel 1 goto :FAIL
buildvm -m bcdef -o lj_bcdef.h %ALL_LIB%
buildvm -m ffdef -o lj_ffdef.h %ALL_LIB%
buildvm -m libdef -o lj_libdef.h %ALL_LIB%
buildvm -m recdef -o lj_recdef.h %ALL_LIB%
buildvm -m vmdef -o jit\vmdef.lua %ALL_LIB%
buildvm -m folddef -o lj_folddef.h lj_opt_fold.c
if errorlevel 1 goto :FAIL
echo [OK] Host tools + headers done

del /q *.obj minilua.exe buildvm.exe *.manifest 2>nul

:: --- Step 2: Cross-compile LuaJIT with NDK Clang ---
echo.
echo [Step 2] Cross-compiling LuaJIT for ARMv7a ...

set CC="%TOOLCHAIN%\bin\armv7a-linux-androideabi%NDKABI%-clang.cmd"
set CFLAGS=-O2 -fPIC -DLUAJIT_TARGET=3 -DLJ_ABI_SOFTFP=1 -DLJ_ARCH_HASFPU=1 -march=armv7-a -mfloat-abi=softfp -I.

%CC% %CFLAGS% -c -o lj_vm.o lj_vm.S
if errorlevel 1 goto :FAIL

set LJ_SOURCES=lj_alloc.c lj_api.c lj_asm.c lj_bc.c lj_bcread.c lj_bcwrite.c lj_buf.c lj_carith.c lj_ccall.c lj_ccallback.c lj_cconv.c lj_cdata.c lj_char.c lj_clib.c lj_cparse.c lj_crecord.c lj_ctype.c lj_debug.c lj_dispatch.c lj_err.c lj_ffrecord.c lj_func.c lj_gc.c lj_gdbjit.c lj_ir.c lj_lex.c lj_lib.c lj_load.c lj_mcode.c lj_meta.c lj_obj.c lj_opt_dce.c lj_opt_fold.c lj_opt_loop.c lj_opt_mem.c lj_opt_narrow.c lj_opt_sink.c lj_opt_split.c lj_parse.c lj_profile.c lj_record.c lj_snap.c lj_state.c lj_str.c lj_strfmt.c lj_strfmt_num.c lj_strscan.c lj_tab.c lj_trace.c lj_udata.c lj_vmevent.c lj_vmmath.c
set LIB_SOURCES=lib_aux.c lib_base.c lib_bit.c lib_debug.c lib_ffi.c lib_init.c lib_io.c lib_jit.c lib_math.c lib_os.c lib_package.c lib_string.c lib_table.c

for %%f in (%LJ_SOURCES%) do (
    %CC% %CFLAGS% -c -o %%~nf.o %%f
    if errorlevel 1 goto :FAIL
)
for %%f in (%LIB_SOURCES%) do (
    %CC% %CFLAGS% -c -o %%~nf.o %%f
    if errorlevel 1 goto :FAIL
)

echo [Step 2a] Creating libluajit.a ...
%AR% rcus libluajit.a lj_vm.o lj_alloc.o lj_api.o lj_asm.o lj_bc.o lj_bcread.o lj_bcwrite.o lj_buf.o lj_carith.o lj_ccall.o lj_ccallback.o lj_cconv.o lj_cdata.o lj_char.o lj_clib.o lj_cparse.o lj_crecord.o lj_ctype.o lj_debug.o lj_dispatch.o lj_err.o lj_ffrecord.o lj_func.o lj_gc.o lj_gdbjit.o lj_ir.o lj_lex.o lj_lib.o lj_load.o lj_mcode.o lj_meta.o lj_obj.o lj_opt_dce.o lj_opt_fold.o lj_opt_loop.o lj_opt_mem.o lj_opt_narrow.o lj_opt_sink.o lj_opt_split.o lj_parse.o lj_profile.o lj_record.o lj_snap.o lj_state.o lj_str.o lj_strfmt.o lj_strfmt_num.o lj_strscan.o lj_tab.o lj_trace.o lj_udata.o lj_vmevent.o lj_vmmath.o lib_aux.o lib_base.o lib_bit.o lib_debug.o lib_ffi.o lib_init.o lib_io.o lib_jit.o lib_math.o lib_os.o lib_package.o lib_string.o lib_table.o
if errorlevel 1 goto :FAIL

del /q *.o 2>nul
echo [OK] libluajit.a for ARMv7a done

:: --- Step 3: Build xlua.so via CMake ---
echo.
echo [Step 3] Building xlua.so for armeabi-v7a ...
cd /d "%BUILD_DIR%"
if exist build_android_arm32 rmdir /s /q build_android_arm32

cmake -S "%BUILD_DIR%" -B "%BUILD_DIR%build_android_arm32" -DUSING_LUAJIT=ON -DANDROID_ABI=armeabi-v7a -DANDROID_PLATFORM=android-%NDKABI% -DCMAKE_TOOLCHAIN_FILE="%ANDROID_NDK%\build\cmake\android.toolchain.cmake" -DANDROID_TOOLCHAIN=clang -DANDROID_STL=c++_static -G "NMake Makefiles"
if errorlevel 1 goto :FAIL

cmake --build "%BUILD_DIR%build_android_arm32" --config Release
if errorlevel 1 goto :FAIL

md plugin_luajit\Plugins\Android\libs\armeabi-v7a 2>nul
copy /Y build_android_arm32\libxlua.so plugin_luajit\Plugins\Android\libs\armeabi-v7a\libxlua.so

echo.
echo ============================================================
echo BUILD SUCCESS
echo   armeabi-v7a -^> plugin_luajit\Plugins\Android\libs\armeabi-v7a\libxlua.so
echo.
echo For arm64-v8a, use Linux/macOS:
echo   bash make_android_luajit_ndk23.sh
echo.
echo Bytecode tools:
echo   ARMv7a: tools\win64\luajit.exe -b input.lua output.bytes
echo   ARM64:  tools\win64_gc64\luajit.exe -b input.lua output.bytes
echo ============================================================
pause
exit /b 0

:FAIL
echo.
echo *** BUILD FAILED ***
pause
exit /b 1
