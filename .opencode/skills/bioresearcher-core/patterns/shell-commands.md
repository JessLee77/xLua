# Shell Commands Pattern

Generate shell commands using forward slashes for cross-platform compatibility.

## Overview

Forward slashes (`/`) work on all major platforms:
- Unix-like (Linux, macOS): Native support
- Windows (Git Bash): Native support
- Windows (Python): Native support via `os.path`
- Windows (cmd.exe): Supported in most contexts

## Recommendation

**Use forward slashes (`/`) universally** for maximum compatibility.

## Examples

### Python Script Execution
```bash
uv run python <skill_path>/script.py --input ./data/file.csv --output ./results/output.xlsx
```

### Directory Creation
```bash
mkdir -p .work/subdir1 .work/subdir2
```

### File Listing
```bash
ls -la ./work/outputs/
```

### For Loop
```bash
for file in file1.txt file2.txt file3.txt; do
  uv run python <skill_path>/process.py "$file"
done
```

### JSON String Arguments
```bash
uv run python script.py --data '{"key": "value"}'
```

### Environment Variables
```bash
export MY_VAR=value
uv run python script.py
```

## Windows Edge Cases

In rare cases, Windows cmd.exe may not support forward slashes:

| Command | Forward Slash | Alternative |
|---------|---------------|-------------|
| `dir` | Works | `dir ./folder` |
| `mkdir` | `mkdir -p` fails | Use Python: `python -c "import os; os.makedirs('./folder', exist_ok=True)"` |
| `copy` | Works | `copy ./src/file.txt ./dest/` |
| `del` | Works | `del ./folder/file.txt` |

> **Note:** If using pure cmd.exe (not Git Bash), the `-p` flag for `mkdir` is not supported. Use Python's `os.makedirs()` instead.

## Path Handling Guidelines

1. **Always use forward slashes** (`/`) in paths
2. **Quote paths with spaces** in all contexts
3. **Use relative paths** from project root when possible
4. **Python paths**: Forward slashes work on all platforms
5. **Skill path placeholder**: Replace `<skill_path>` with actual path from skill tool output

## Best Practices

1. **Default to forward slashes** - works 99% of the time
2. **Test on target platform** if edge cases suspected
3. **Use Python alternatives** for complex file operations
4. **Quote all paths** to handle spaces safely
5. **Avoid cmd.exe-specific syntax** (like `^` line continuation)
