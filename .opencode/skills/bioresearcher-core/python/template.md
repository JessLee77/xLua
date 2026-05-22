# Template Engine Documentation

Python script for generating files from templates with placeholder replacement.

## Location

```
<skill_path>/python/template.py
```

## Commands

### fill

Generate a single file from template and context.

**Usage:**
```bash
# Unix-like
uv run python <skill_path>/python/template.py fill \
  --template template.md \
  --context context.json \
  --output output.md

# Windows
uv.exe run python <skill_path>\python\template.py fill ^
  --template template.md ^
  --context context.json ^
  --output output.md
```

**Arguments:**
| Argument | Required | Description |
|----------|----------|-------------|
| `--template` | Yes | Path to template file |
| `--context` | Yes | Path to context JSON file |
| `--output` | Yes | Path for output file |
| `--escape` | No | Escape values for markdown code blocks |

**Output:**
```json
{
  "success": true,
  "output_path": "output.md",
  "template_path": "template.md"
}
```

### generate-batches

Generate multiple files from template and list of contexts.

**Usage:**
```bash
# Unix-like
uv run python <skill_path>/python/template.py generate-batches \
  --template template.md \
  --contexts contexts.json \
  --output-dir ./outputs \
  --filename-pattern "batch{index:03d}.md"

# Windows
uv.exe run python <skill_path>\python\template.py generate-batches ^
  --template template.md ^
  --contexts contexts.json ^
  --output-dir .\outputs ^
  --filename-pattern "batch{index:03d}.md"
```

**Arguments:**
| Argument | Required | Description |
|----------|----------|-------------|
| `--template` | Yes | Path to template file |
| `--contexts` | Yes | Path to contexts JSON file (array) |
| `--output-dir` | Yes | Directory for output files |
| `--filename-pattern` | No | Filename pattern (default: `output_{index:03d}.md`) |
| `--escape` | No | Escape values for markdown |
| `--dry-run` | No | Validate without writing files |
| `--verbose` | No | Print progress |

**Output:**
```json
{
  "success": true,
  "total_contexts": 10,
  "generated_count": 10,
  "output_dir": "./outputs",
  "generated_files": [
    "./outputs/batch001.md",
    "./outputs/batch002.md",
    "..."
  ]
}
```

### escape

Escape text for markdown code blocks.

**Usage:**
```bash
uv run python <skill_path>/python/template.py escape --text "Text with `backticks` and $variables"
```

**Output:**
```json
{
  "success": true,
  "original": "Text with `backticks` and $variables",
  "escaped": "Text with \\`backticks\\` and \\$variables"
}
```

## Template Syntax

### Placeholders

Use `{placeholder_name}` for placeholders:

```markdown
# Task for {name}

Process {count} items from {source_file}.
Output to: {output_file}
```

### Placeholder Rules

1. **Alphanumeric names**: Use letters, numbers, underscores only
2. **Case-sensitive**: `{Name}` != `{name}`
3. **No nesting**: `{outer.{inner}}` not supported
4. **Missing placeholders**: Left unchanged if not in context

## Context Format

### Single Context (for `fill`)

```json
{
  "name": "Batch 001",
  "count": 30,
  "source_file": "./data/input.xlsx",
  "output_file": "./outputs/batch001.md"
}
```

### Multiple Contexts (for `generate-batches`)

```json
[
  {
    "batch_number": 1,
    "row_start": 2,
    "row_end": 31,
    "output_file": "./outputs/batch001.md"
  },
  {
    "batch_number": 2,
    "row_start": 32,
    "row_end": 61,
    "output_file": "./outputs/batch002.md"
  }
]
```

## Escaping for Markdown

When `--escape` flag is used, values are escaped for safe use in markdown code blocks:

| Character | Escaped To |
|-----------|------------|
| `\` | `\\` |
| `` ` `` | `\`` |
| `$` | `\$` |

This prevents:
- Backtick interpretation as code
- Variable substitution in shells
- Escape sequence issues

## Error Handling

### Template Not Found
```json
{
  "success": false,
  "error": "Template file not found: template.md"
}
```

### Context Parse Error
```json
{
  "success": false,
  "error": "Failed to read context file: Expecting value: line 1 column 1 (char 0)"
}
```

### Partial Batch Failure
```json
{
  "success": false,
  "total_contexts": 10,
  "generated_count": 8,
  "error_count": 2,
  "errors": [
    "Failed to write ./outputs/batch005.md: Permission denied",
    "Failed to write ./outputs/batch009.md: Disk full"
  ]
}
```

## Example Workflow

### Step 1: Create Template

```markdown
# Batch {batch_number} Processing

## Input
- File: {input_file}
- Rows: {row_start} to {row_end}

## Output
Write results to: {output_file}
```

### Step 2: Create Contexts

```json
[
  {
    "batch_number": 1,
    "input_file": "./data.xlsx",
    "row_start": 2,
    "row_end": 31,
    "output_file": "./outputs/batch001.md"
  },
  {
    "batch_number": 2,
    "input_file": "./data.xlsx",
    "row_start": 32,
    "row_end": 61,
    "output_file": "./outputs/batch002.md"
  }
]
```

### Step 3: Generate Files

```bash
uv run python <skill_path>/python/template.py generate-batches \
  --template batch_template.md \
  --contexts batch_contexts.json \
  --output-dir ./prompts \
  --filename-pattern "batch{index:03d}.md"
```

### Step 4: Use Generated Files

The generated files can be used as prompts for subagents:

```
task(
  subagent_type="general",
  description="Process batch 001",
  prompt="Read your prompt from ./prompts/batch001.md and perform the task."
)
```

## Dependencies

None - uses only Python standard library.
