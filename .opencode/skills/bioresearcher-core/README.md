# BioResearcher Core

Core library skill providing reusable patterns and utilities for BioResearcher skills.

## Overview

BioResearcher Core provides:
- **Workflow patterns** for common operations (retry, progress, subagent waves)
- **Data handling patterns** for JSON and table operations
- **Python utilities** for template generation
- **Tool-first architecture** using existing plugin tools

## Installation

No installation required. This skill uses only:
- Existing plugin tools (jsonExtract, jsonValidate, etc.)
- Python standard library

## Quick Start

### Load the Skill

```
skill bioresearcher-core
```

### Extract Skill Path

From the `<skill_files>` section in the skill tool output, extract the `<skill_path>` value for use in commands.

### Use a Pattern

```
Read <skill_path>/patterns/retry.md
```

### Run Python Script

```bash
uv run python <skill_path>/python/template.py generate-batches \
  --template template.md \
  --contexts contexts.json \
  --output-dir ./outputs
```

## Available Patterns

### Workflow Control

| Pattern | Description | File |
|---------|-------------|------|
| Retry | Retry with backoff using blockingTimer | `patterns/retry.md` |
| Progress | Track and report batch progress | `patterns/progress.md` |
| Subagent Waves | Parallel subagent processing | `patterns/subagent-waves.md` |
| Shell Commands | Cross-platform command generation | `patterns/shell-commands.md` |
| User Confirmation | Request user confirmation | `patterns/user-confirmation.md` |

### Data Handling

| Pattern | Description | File |
|---------|-------------|------|
| JSON Tools | jsonExtract/jsonValidate/jsonInfer | `patterns/json-tools.md` |
| Table Tools | Combine outputs with table tools | `patterns/table-tools.md` |
| Data Exchange | Main/subagent communication | `patterns/data-exchange.md` |
| Calculator | In-workflow calculations | `patterns/calculator.md` |

## Available Tools

These tools are always available without loading pattern files:

### JSON Tools

| Tool | Description |
|------|-------------|
| `jsonExtract` | Extract JSON from files |
| `jsonValidate` | Validate JSON against schemas |
| `jsonInfer` | Infer schemas from data |

### Utility Tools

| Tool | Description |
|------|-------------|
| `blockingTimer` | Blocking delays (0-300 seconds) |
| `calculator` | Mathematical expressions |

### Table Tools

| Tool | Description |
|------|-------------|
| `tableCreateFile` | Create Excel/CSV from data |
| `tableAppendRows` | Append rows to tables |

## Python Utilities

### Template Engine

Location: `python/template.py`

Commands:
- `fill` - Generate single file from template
- `generate-batches` - Generate multiple files from template
- `escape` - Escape text for markdown

See `python/template.md` for full documentation.

## Examples

### Example Files

| File | Description |
|------|-------------|
| `examples/template.md` | Example template with placeholders |
| `examples/contexts.json` | Example contexts for batch generation |
| `examples/data-exchange-example.md` | Complete data exchange workflow |

## Architecture

### Tool-First Design

This skill maximizes use of existing plugin tools:

```
┌─────────────────────────────────────────────────┐
│              BioResearcher Core                  │
├─────────────────────────────────────────────────┤
│  Patterns (markdown)    │  Python Utilities     │
│  - retry.md             │  - template.py        │
│  - progress.md          │                       │
│  - subagent-waves.md    │                       │
│  - json-tools.md        │                       │
│  - table-tools.md       │                       │
│  - data-exchange.md     │                       │
│  - calculator.md        │                       │
│  - shell-commands.md    │                       │
│  - user-confirmation.md │                       │
├─────────────────────────┴───────────────────────┤
│              Plugin Tools                        │
│  jsonExtract │ jsonValidate │ jsonInfer         │
│  blockingTimer │ calculator                      │
│  tableCreateFile │ tableAppendRows              │
└─────────────────────────────────────────────────┘
```

### Pattern Modules

Each pattern is a self-contained markdown file:
- Independent (no dependencies on other patterns)
- Self-documenting (explains itself)
- Minimal loading (agent reads only what it needs)

## Integration with Other Skills

### long-table-summary

BioResearcher Core can be used by long-table-summary:
- Use `jsonExtract` instead of manual JSON parsing
- Use `jsonValidate` for schema validation
- Apply retry/progress patterns
- Use template.py for prompt generation

### pubmed-weekly

BioResearcher Core can be used by pubmed-weekly:
- Apply retry pattern for download failures
- Use shell-commands pattern for cross-platform support

## Design Principles

1. **Tool-first**: Use existing tools before creating Python scripts
2. **Self-contained**: Each pattern is independent
3. **Minimal dependencies**: Only Python standard library
4. **Clear documentation**: Every file documents itself
5. **Standard protocols**: JSON for data exchange

## Directory Structure

```
plugin/skills/bioresearcher-core/
├── SKILL.md                    # Routing document
├── README.md                   # This file
├── patterns/                   # Workflow patterns
│   ├── retry.md
│   ├── progress.md
│   ├── subagent-waves.md
│   ├── shell-commands.md
│   ├── user-confirmation.md
│   ├── json-tools.md
│   ├── table-tools.md
│   ├── data-exchange.md
│   └── calculator.md
├── python/                     # Python utilities
│   ├── template.py
│   └── template.md
└── examples/                   # Example files
    ├── template.md
    ├── contexts.json
    └── data-exchange-example.md
```

## Contributing

When adding new patterns:
1. Create self-contained markdown file in `patterns/`
2. Follow existing pattern structure
3. Include examples and error handling
4. Update SKILL.md with new pattern reference

## License

Part of the BioResearcher plugin ecosystem.
