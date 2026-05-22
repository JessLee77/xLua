---
name: bioresearcher-core
description: Core patterns and utilities for BioResearcher skills
allowedTools:
  - Read
  - Write
  - Bash
  - jsonExtract
  - jsonValidate
  - jsonInfer
  - blockingTimer
  - calculator
  - tableCreateFile
  - tableAppendRows
  - Question
  - Task
---

# BioResearcher Core

This skill provides reusable patterns and utilities for BioResearcher skills.

## Pattern Organization

This skill organizes patterns into:

### Shared Patterns (Available to All Agents)
- `patterns/retry.md` - Retry with backoff using blockingTimer
- `patterns/progress.md` - Progress tracking
- `patterns/subagent-waves.md` - Parallel subagent processing
- `patterns/shell-commands.md` - Unix/Windows command generation
- `patterns/user-confirmation.md` - User confirmation
- `patterns/rate-limiting.md` - API rate limiting between calls
- `patterns/json-tools.md` - Using jsonExtract/jsonValidate/jsonInfer
- `patterns/table-tools.md` - Combining outputs with table tools
- `patterns/data-exchange.md` - Main/subagent data exchange protocol
- `patterns/calculator.md` - In-workflow calculations
- `patterns/citations.md` - Citation formatting and bibliography management

### Agent-Specific Patterns

#### BioResearcher Patterns (patterns/bioresearcher/)
The following patterns are dedicated to the bioresearcher agent ONLY:
- `patterns/bioresearcher/tool-selection.md` - Decision trees for choosing correct tools (database, table, web, biomcp, parser)
- `patterns/bioresearcher/analysis-methods.md` - Decision criteria for choosing analysis methods (table tools vs long-table-summary skill vs custom Python)
- `patterns/bioresearcher/report-template.md` - Structured report template with data provenance requirements
- `patterns/bioresearcher/python-standards.md` - DRY principle and documentation requirements for Python scripts
- `patterns/bioresearcher/best-practices.md` - Upfront filtering, validation, error handling, and performance optimization

**Note:** The above patterns are NOT available to bioresearcherDR or bioresearcherDR_worker. They are specific to the bioresearcher agent's tool selection, analysis method choice, and report writing workflows.

#### BioresearcherDR Patterns (Not Implemented)
The bioresearcherDR orchestrator uses only shared patterns (citations, rate-limiting, retry) and does not have dedicated patterns at this time.

#### BioresearcherDR_Worker Patterns (Not Implemented)
The bioresearcherDR_worker subagent uses only shared patterns (citations, rate-limiting, retry) and does not have dedicated patterns at this time.

## Quick Start

### Step 1: Load This Skill
```
skill bioresearcher-core
```

### Step 2: Extract Skill Path
From the `<skill_files>` section in the skill tool output, extract the `<skill_path>` value.

### Step 3: Use Resources
- Read pattern: `Read <skill_path>/patterns/retry.md`
- Run script: `uv run python <skill_path>/python/template.py ...`

## Available Patterns

### Shared Patterns (Available to All Agents)
- `patterns/retry.md` - Retry with backoff using blockingTimer
- `patterns/progress.md` - Progress tracking
- `patterns/subagent-waves.md` - Parallel subagent processing
- `patterns/shell-commands.md` - Unix/Windows command generation
- `patterns/user-confirmation.md` - User confirmation
- `patterns/rate-limiting.md` - API rate limiting between calls

### Data Handling
- `patterns/json-tools.md` - Using jsonExtract/jsonValidate/jsonInfer
- `patterns/table-tools.md` - Combining outputs with table tools
- `patterns/data-exchange.md` - Main/subagent data exchange protocol
- `patterns/calculator.md` - In-workflow calculations

### Research Standards
- `patterns/citations.md` - Citation formatting and bibliography management

### Agent Best Practices
- `patterns/bioresearcher/best-practices.md` - Upfront filtering, validation, error handling, performance optimization

### Agent Best Practices
- `patterns/bioresearcher/best-practices.md` - Upfront filtering, validation, error handling, performance

## Python Utilities
- `python/template.md` - Template generation documentation

## Direct Tools (No Loading Needed)

These tools are always available without loading pattern files:

### JSON Tools
- `jsonExtract` - Extract JSON from files (handles markdown code blocks, raw JSON)
- `jsonValidate` - Validate JSON against schemas (Draft-4, Draft-7, Draft-2020-12)
- `jsonInfer` - Infer schemas from JSON data

### Utility Tools
- `blockingTimer` - Blocking delays (0-300 seconds)
- `calculator` - Mathematical expressions (+, -, *, /, ^, brackets)

### Table Tools
- `tableCreateFile` - Create Excel/CSV files from data
- `tableAppendRows` - Append rows to existing tables

## Tool Signatures

### jsonExtract
```
jsonExtract(file_path: string, return_all: boolean = false)
Returns: { success, data, metadata: { method, dataType, fileSize } }
```

### jsonValidate
```
jsonValidate(data: string, schema: string)
Returns: { success, valid, errors?, metadata: { errorCount, schemaFeatures } }
```

### jsonInfer
```
jsonInfer(data: string, strict: boolean = false)
Returns: { success, data: JSONSchema, metadata: { inferredType, strictMode } }
```

### blockingTimer
```
blockingTimer(delay: number)
Returns: "Timer completed: waited X seconds (actual elapsed: Ys)"
```

### calculator
```
calculator(formula: string, precision: number = 3)
Returns: { formula, result }
```

### tableCreateFile
```
tableCreateFile(file_path: string, sheet_name: string = "Sheet1", data: array)
Returns: { success, file_path, sheet_name, rows_created }
```

### tableAppendRows
```
tableAppendRows(file_path: string, sheet_name: string?, rows: array)
Returns: { success, rows_appended }
```

## When to Use Each Pattern

### Shared Patterns (All Agents)
| Use Case | Pattern File |
|----------|-------------|
| Network/API failures | `patterns/retry.md` |
| Batch processing progress | `patterns/progress.md` |
| Parallel subagent execution | `patterns/subagent-waves.md` |
| Cross-platform commands | `patterns/shell-commands.md` |
| Destructive operations | `patterns/user-confirmation.md` |
| API rate limiting | `patterns/rate-limiting.md` |
| JSON data extraction | `patterns/json-tools.md` |
| Combining batch outputs | `patterns/table-tools.md` |
| Subagent communication | `patterns/data-exchange.md` |
| Progress calculations | `patterns/calculator.md` |
| Citation formatting | `patterns/citations.md` |

### BioResearcher Agent Only
| Use Case | Pattern File |
|----------|-------------|
| Choosing correct tool | `patterns/bioresearcher/tool-selection.md` |
| Deciding analysis method | `patterns/bioresearcher/analysis-methods.md` |
| Writing reference-based reports | `patterns/bioresearcher/report-template.md` |
| Writing Python scripts | `patterns/bioresearcher/python-standards.md` |
| Data analysis best practices | `patterns/bioresearcher/best-practices.md` |
