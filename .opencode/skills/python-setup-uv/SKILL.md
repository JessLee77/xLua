---
name: python-setup-uv
description: Setup Python environment with uv package manager - download binaries, create symlink, and install packages
allowedTools:
  - Bash
  - Read
---

# Python Environment Setup with uv

This skill sets up a Python environment using the uv package manager.

## Prerequisites
- Internet connection for downloading uv
- Python 3.8+ should be available on PATH (or uv will prompt to install it)

## Steps

**ABSOLUTE RULE:** Follow steps below EXACTLY AS IS. Do NOT skip/modify steps (nor detailed subtasks in each step) nor assume anything based on user platform information. Use URLs below EXACTLY AS IS. Follow steps below INCLUDING ALL DETAILS AND SUBSTEPS EXACTLY AS IS.

### Step 1: Ask user question about which installer to use

Use the question tool to ask which installer should be used:

- Official astral-uv installer (https://astral.sh)
- China mainland uv-custom installer (https://gitee.com/wangnov/uv-custom)

### Step 2: Detect Shell and Download uv Binary

First, detect your shell environment:

```bash
# Detect shell type
# MSYSTEM is set by Git Bash, MINGW_PREFIX by MSYS2
if [ -n "$MSYSTEM" ] || [ -n "$MINGW_PREFIX" ] || command -v curl >/dev/null 2>&1; then
  echo "Unix-like shell detected (Git Bash, bash, zsh, etc.)"
  IS_UNIX_SHELL=true
else
  echo "Windows cmd.exe detected"
  IS_UNIX_SHELL=false
fi
```

Then download uv based on your shell (see below).

Choose the correct `UV_INSTALLER_URL` depending on answer you received in Step 1 from the user:

- If opted "Official astral-uv", UV_INSTALLER_URL should be `https://astral.sh/uv/install.sh` (Unix-like) or `https://astral.sh/uv/install.ps1` (Windows)
- If opted "China mainland uv-custom", UV_INSTALLER_URL should be `https://gitee.com/wangnov/uv-custom/releases/download/latest/uv-installer-custom.sh` (Unix-like) or `https://gitee.com/wangnov/uv-custom/releases/download/latest/uv-installer-custom.ps1` (Windows)

**For Unix-like shells (Git Bash / macOS / Linux; use correct UV_INSTALLER_URL):**
```bash
mkdir -p .uv
curl -LsSf UV_INSTALLER_URL | UV_INSTALL_DIR="$(pwd)/.uv" sh
```

**For Windows cmd.exe (if Git Bash unavailable; use correct UV_INSTALLER_URL):**
```bash
powershell -NoProfile -Command "New-Item -ItemType Directory -Force -Path .uv | Out-Null; $env:UV_INSTALL_DIR = (Get-Location).Path + '\.uv'; Invoke-RestMethod UV_INSTALLER_URL | Invoke-Expression"
```

### Step 3: Create Symlink or Copy uv to Working Directory

**For Unix-like shells (Git Bash / macOS / Linux):**
```bash
ln -sf .uv/uv uv
```

**For Windows cmd.exe:**

Try symlink first, fall back to copy if no Admin rights:
```bash
cmd /c "(mklink uv .uv\uv.exe) 2>nul || copy /Y .uv\uv.exe uv.exe"
```

### Step 4: Create Virtual Environment and Install pandas

NOTE: this step (package installation) may timeout. If timed out, use the question tool to ask if the user would like to retry package installation. If successful, do NOT ask any question and continue to Step 5.

**For Unix-like shells:**
```bash
./uv venv
./uv pip install pandas
```

**For Windows cmd.exe:**
```bash
uv.exe venv
uv.exe pip install pandas
```

### Step 5: Verification

**For Unix-like shells:**
```bash
./uv --version
./uv run python -c "import pandas; print(pandas.__version__)"
```

**For Windows cmd.exe:**
```bash
uv.exe --version
uv.exe run python -c "import pandas; print(pandas.__version__)"
```

### Step 6: Update AGENTS.md

Use the question tool to ask if the user want to update AGENTS.md in WORKING DIRECTORY to "direct agents to use the installed UV Python" (options: "Yes" / "No"). If received no answer, continue to Step 7 (do NOT modify AGENTS.md NOR create directories). If received yes answer, follow steps belows.

1. If AGENTS.md not found in WORKING DIR, create an empty AGENTS.md.
2. Inspect AGENTS.md content. If you do not see the content block below, APPEND EXACTLY AS IS to end of AGENTS.md.
3. Check if `./.code/py` exist. If not, create the directories.

Content block:

```md
## Important note about Python

ALWAYS use the uv package manager available in WORKING DIRECTORY, including `uv add ...` or `uv pip ...` for package management and `uv run ...` to run python package executables.

ALWAYS save python scripts under path `./.code/py/` and run the script with `uv run python ...` whenever your work involves executing python scripts. Your script MUST contain concise docstrings and comments and use good engineering practices including separation of concerns.
```

### Step 7: Return summary to user (Usage After Setup)

**For Unix-like shells:**
```bash
./uv run python your_script.py
```

**For Windows cmd.exe:**
```bash
uv.exe run python your_script.py
```

## Notes
- Add `.uv/` and `.venv/` to `.gitignore`
- `uv run` handles venv activation automatically
- Use `./uv add <package>` (Unix) or `uv.exe add <package>` (Windows cmd.exe) for project dependencies
- Windows with Git Bash: Follow Unix-like shell instructions
- Windows cmd.exe without Admin rights: `uv.exe` is copied instead of symlinked
