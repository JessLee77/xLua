@echo off
setlocal enabledelayedexpansion
:: ============================================================
:: LuaJIT Bytecode Compiler Tool
:: Converts .lua source files to LuaJIT bytecode
::
:: Usage:
::   compile_lua.bat [--gc64] <input_dir> <output_dir>
::   compile_lua.bat [--gc64] <input_file.lua> <output_file.bytes>
::   compile_lua.bat [--gc64] <input_dir>               (output to same dir)
::
:: Options:
::   --gc64    Use GC64 mode (required for ARM64 targets)
::             Without this flag, standard mode is used (x86/x64/ARMv7)
::
:: Examples:
::   compile_lua.bat Assets\Lua Assets\LuaBytes
::   compile_lua.bat --gc64 Assets\Lua Assets\LuaBytes_arm64
::   compile_lua.bat test.lua test.bytes
::
:: Based on LuaJIT 2.1.0-beta3
:: ============================================================

set SCRIPT_DIR=%~dp0

:: Check for --gc64 flag
set GC64_MODE=0
if "%~1"=="--gc64" (
    set GC64_MODE=1
    shift
)

:: Select appropriate luajit executable
if %GC64_MODE%==1 (
    set LUAJIT=%SCRIPT_DIR%tools\win64_gc64\luajit.exe
    echo [GC64 mode - for ARM64 targets]
) else (
    set LUAJIT=%SCRIPT_DIR%tools\win64\luajit.exe
)

:: Check if luajit.exe exists
if not exist "%LUAJIT%" (
    :: Fallback to win32 (standard mode only)
    if %GC64_MODE%==0 set LUAJIT=%SCRIPT_DIR%tools\win32\luajit.exe
)
if not exist "%LUAJIT%" (
    echo ERROR: luajit.exe not found!
    echo Please run make_win64_luajit.bat first to build it.
    exit /b 1
)

:: Set LUA_PATH so jit.bcsave module can be found from any working directory
for %%i in ("%LUAJIT%") do set LUAJIT_DIR=%%~dpi
set LUA_PATH=%LUAJIT_DIR%lua\?.lua;;

:: Parse arguments
if "%~1"=="" (
    echo Usage:
    echo   %~nx0 ^<input_dir^> ^<output_dir^>
    echo   %~nx0 ^<input_file.lua^> ^<output_file.bytes^>
    echo   %~nx0 ^<input_dir^>
    exit /b 1
)

set INPUT=%~1
set OUTPUT=%~2

:: Check if input is a file or directory
if exist "%INPUT%\" (
    :: Input is a directory - batch mode
    if "%OUTPUT%"=="" set OUTPUT=%INPUT%
    
    echo ============================================================
    echo  LuaJIT Bytecode Compiler - Batch Mode
    echo  Input:  %INPUT%
    echo  Output: %OUTPUT%
    echo ============================================================
    echo.
    
    set COUNT=0
    set ERRORS=0
    
    for /r "%INPUT%" %%f in (*.lua) do (
        set "RELPATH=%%f"
        set "RELPATH=!RELPATH:%INPUT%=!"
        set "OUTFILE=%OUTPUT%!RELPATH:.lua=.bytes!"
        
        :: Create output directory if needed
        for %%d in ("!OUTFILE!") do (
            if not exist "%%~dpd" mkdir "%%~dpd"
        )
        
        :: echo Compiling: %%f
        "%LUAJIT%" -b "%%f" "!OUTFILE!"
        if errorlevel 1 (
            echo   FAILED: %%f
            set /a ERRORS+=1
        ) else (
            set /a COUNT+=1
        )
    )
    
    echo.
    echo ============================================================
    echo  Done: !COUNT! files compiled, !ERRORS! errors
    echo ============================================================
) else (
    :: Input is a single file
    if "%OUTPUT%"=="" set OUTPUT=%~dpn1.bytes
    
    echo Compiling: %INPUT% -> %OUTPUT%
    "%LUAJIT%" -b "%INPUT%" "%OUTPUT%"
    if errorlevel 1 (
        echo FAILED!
        exit /b 1
    )
    echo Done.
)
