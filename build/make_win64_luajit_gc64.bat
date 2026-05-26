@echo off
REM Build LuaJIT GC64 mode for Windows x64
REM Produces: plugin_luajit/Plugins/x86_64/xlua.dll (GC64)
REM           tools/win64_gc64/luajit.exe (GC64 bytecode compiler)

call "C:\Program Files (x86)\Microsoft Visual Studio\2019\Community\VC\Auxiliary\Build\vcvars64.bat"

echo Switch to x64 build env (GC64)
cd %~dp0\luajit-2.1.0b3\src
call msvcbuild_mt.bat gc64 static
cd ..\..

REM Deploy GC64 luajit.exe tool
md tools\win64_gc64\lua\jit 2>nul
copy /Y luajit-2.1.0b3\src\luajit.exe tools\win64_gc64\luajit.exe
xcopy /Y /Q luajit-2.1.0b3\src\jit\*.lua tools\win64_gc64\lua\jit\

mkdir build_lj64_gc64 & pushd build_lj64_gc64
cmake -DUSING_LUAJIT=ON -DGC64=ON -G "Visual Studio 16 2019" -A x64 ..
IF %ERRORLEVEL% NEQ 0 cmake -DUSING_LUAJIT=ON -DGC64=ON -G "Visual Studio 16 2019" -A x64 ..
popd
cmake --build build_lj64_gc64 --config Release
md plugin_luajit\Plugins\x86_64 2>nul
copy /Y build_lj64_gc64\Release\xlua.dll plugin_luajit\Plugins\x86_64\xlua.dll
pause