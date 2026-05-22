@echo off
setlocal
:: ============================================================
:: Build libxlua.so for Android with LuaJIT 2.1.0-beta3
:: Windows host version - uses NDK r23b cmake directly
:: Only builds the xlua.so (LuaJIT pre-compiled on Linux/WSL)
::
:: NOTE: LuaJIT itself must be cross-compiled on Linux/WSL first.
::       This script assumes libluajit.a already exists.
::       Use WSL: wsl bash make_android_luajit_ndk23.sh
::
:: Alternative: Run this in Git Bash or WSL directly.
:: ============================================================

echo ============================================================
echo  Android xlua build requires a POSIX environment for LuaJIT
echo  cross-compilation. Please use one of:
echo.
echo  Option 1 (Recommended): Run in WSL
echo    wsl bash make_android_luajit_ndk23.sh
echo.
echo  Option 2: Run in Git Bash
echo    "C:\Program Files\Git\bin\bash.exe" make_android_luajit_ndk23.sh
echo.
echo  Make sure ANDROID_NDK is set to your NDK r23b path.
echo ============================================================
pause
