# Data Exchange Example

This example demonstrates the complete main/subagent data exchange workflow.

## Scenario

Main agent needs to process a large table (90 rows) in 3 batches of 30 rows each.

## Step 1: Main Agent Creates Prompt Files

### Template (subagent_template.md)

```markdown
# Batch Processing Task

## Input
- File: {file_path}
- Sheet: {sheet_name}
- Rows: {row_start} to {row_end}

## Output Format
Write JSON to: {output_file}

```json
{
  "batch_number": {batch_number},
  "row_count": <integer>,
  "summaries": [
    {
      "row_number": <integer>,
      "status": "<success/failure>",
      "result": "<string>"
    }
  ]
}
```
```

### Generate Prompts

```bash
uv run python <skill_path>/python/template.py generate-batches \
  --template subagent_template.md \
  --contexts batch_contexts.json \
  --output-dir ./prompts \
  --filename-pattern "batch{index:03d}.md"
```

### Contexts (batch_contexts.json)

```json
[
  {
    "file_path": "/data/table.xlsx",
    "sheet_name": "Data",
    "batch_number": 1,
    "row_start": 2,
    "row_end": 31,
    "output_file": "./outputs/batch001.md"
  },
  {
    "file_path": "/data/table.xlsx",
    "sheet_name": "Data",
    "batch_number": 2,
    "row_start": 32,
    "row_end": 61,
    "output_file": "./outputs/batch002.md"
  },
  {
    "file_path": "/data/table.xlsx",
    "sheet_name": "Data",
    "batch_number": 3,
    "row_start": 62,
    "row_end": 91,
    "output_file": "./outputs/batch003.md"
  }
]
```

## Step 2: Main Agent Launches Subagents

### Wave 1 (All 3 batches)

```
task(
  subagent_type="general",
  description="Process batch 001",
  prompt="Read your prompt from ./prompts/batch001.md and perform the task exactly as written."
)

task(
  subagent_type="general",
  description="Process batch 002",
  prompt="Read your prompt from ./prompts/batch002.md and perform the task exactly as written."
)

task(
  subagent_type="general",
  description="Process batch 003",
  prompt="Read your prompt from ./prompts/batch003.md and perform the task exactly as written."
)
```

## Step 3: Subagent Processes and Writes Output

### Subagent reads prompt
```
Read ./prompts/batch001.md
```

### Subagent processes data
```
tableGetRange(file_path="/data/table.xlsx", sheet_name="Data", range="A2:Z31")
```

### Subagent writes output (./outputs/batch001.md)

```json
{
  "batch_number": 1,
  "row_count": 30,
  "summaries": [
    {"row_number": 2, "status": "success", "result": "Processed OK"},
    {"row_number": 3, "status": "success", "result": "Processed OK"},
    {"row_number": 4, "status": "failure", "result": "Missing data"},
    "..."
  ]
}
```

## Step 4: Main Agent Validates Outputs

### Extract JSON

```
jsonExtract(file_path="./outputs/batch001.md")
```

Returns:
```json
{
  "success": true,
  "data": {
    "batch_number": 1,
    "row_count": 30,
    "summaries": [...]
  },
  "metadata": {
    "method": "object",
    "dataType": "object"
  }
}
```

### Infer Schema from First Output

```
jsonInfer(
  data='{"batch_number": 1, "row_count": 30, "summaries": [{"row_number": 2, "status": "success", "result": "OK"}]}',
  strict=true
)
```

Returns:
```json
{
  "success": true,
  "data": {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "type": "object",
    "properties": {
      "batch_number": {"type": "integer"},
      "row_count": {"type": "integer"},
      "summaries": {
        "type": "array",
        "items": {
          "type": "object",
          "properties": {
            "row_number": {"type": "integer"},
            "status": {"type": "string"},
            "result": {"type": "string"}
          },
          "required": ["row_number", "status", "result"]
        }
      }
    },
    "required": ["batch_number", "row_count", "summaries"]
  }
}
```

### Validate Other Outputs

```
jsonValidate(
  data='{"batch_number": 2, "row_count": 30, "summaries": [...]}',
  schema='<inferred_schema>'
)
```

Returns:
```json
{
  "success": true,
  "valid": true,
  "data": {...}
}
```

## Step 5: Main Agent Combines Outputs

### Collect All Summaries

```
all_rows = []

for batch in [1, 2, 3]:
    result = jsonExtract(file_path=f"./outputs/batch{batch:03d}.md")
    if result.success:
        all_rows.extend(result.data["summaries"])
```

### Create Combined Excel

```
tableCreateFile(
  file_path="./combined_results.xlsx",
  sheet_name="Results",
  data=all_rows
)
```

## Complete Workflow Summary

1. **Template**: Defines output format with schema
2. **Contexts**: Provides batch-specific values
3. **Generation**: Creates prompt files from template + contexts
4. **Subagents**: Read prompts, process, write JSON outputs
5. **Extraction**: jsonExtract parses JSON from outputs
6. **Validation**: jsonValidate ensures schema compliance
7. **Combination**: tableCreateFile merges all results

## Error Handling Examples

### Missing Output File

```
jsonExtract(file_path="./outputs/batch002.md")
```

Returns:
```json
{
  "success": false,
  "error": {
    "code": "FILE_NOT_FOUND",
    "message": "File not found: ./outputs/batch002.md"
  }
}
```

### Invalid JSON in Output

```
jsonExtract(file_path="./outputs/batch003.md")
```

Returns:
```json
{
  "success": false,
  "error": {
    "code": "NO_JSON_FOUND",
    "message": "No valid JSON found in file"
  }
}
```

### Schema Validation Failure

```
jsonValidate(
  data='{"batch_number": "one", "summaries": []}',
  schema='{"properties": {"batch_number": {"type": "integer"}}}'
)
```

Returns:
```json
{
  "success": true,
  "valid": false,
  "errors": [
    {
      "path": "batch_number",
      "message": "Expected number, received string",
      "code": "invalid_type",
      "expected": "number",
      "received": "string"
    }
  ]
}
```
