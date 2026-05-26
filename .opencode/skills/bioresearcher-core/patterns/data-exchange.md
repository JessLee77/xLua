# Data Exchange Pattern

Standardized protocol for data exchange between main agent and subagents.

## Overview

This pattern ensures reliable communication between main agent and subagents using:
- File-based prompts with embedded schemas
- JSON output files with validation
- Schema-first design for type safety

## Data Exchange Protocol

```
Main Agent                          Subagent
    |                                   |
    |--- Write prompt file ----------->|
    |   (with embedded schema)          |
    |                                   |
    |                                   |--- Read prompt
    |                                   |--- Process data
    |                                   |--- Write output JSON
    |                                   |
    |<-- Write output file -------------|
    |   (JSON matching schema)          |
    |                                   |
    |--- jsonExtract ------------------>|
    |--- jsonValidate ----------------->|
    |--- Process validated data         |
```

## Main Agent Responsibilities

### 1. Create Prompt File with Embedded Schema

Include the output schema directly in the prompt:

```markdown
# Task Description

Process the data and output results.

## Output Format

Your output must be valid JSON matching this schema:

```json
{
  "batch_number": <integer>,
  "row_count": <integer>,
  "summaries": [
    {
      "row_number": <integer>,
      "field1": "<string>",
      "field2": "<string>"
    }
  ]
}
```

Write your output to: {output_file}

**CRITICAL:** Write ONLY the JSON object, no additional text.
```

### 2. Launch Subagent with File Reference

```
task(
  subagent_type="general",
  description="Process batch 001",
  prompt="Read your prompt from ./prompts/batch001.md and perform the task exactly as written."
)
```

### 3. Validate Subagent Output

```python
# Extract JSON from output file
result = jsonExtract(file_path="./outputs/batch001.md")

if not result.success:
    log_error(f"Failed to extract JSON")
    handle_failure()

# Validate against expected schema
validation = jsonValidate(
    data=json.dumps(result.data),
    schema=expected_schema
)

if not validation.valid:
    log_error(f"Validation failed: {validation.errors}")
    handle_failure()

# Process validated data
process(result.data)
```

## Subagent Responsibilities

### 1. Read Prompt File

The subagent reads the prompt file to understand:
- Task description
- Input data location
- Output format (schema)
- Output file path

### 2. Process and Generate Output

The subagent:
- Reads input data using available tools
- Processes according to instructions
- Generates output matching the schema exactly

### 3. Write Output File

Write ONLY valid JSON to the specified output file:

```json
{
  "batch_number": 1,
  "row_count": 30,
  "summaries": [
    {"row_number": 2, "field1": "value1", "field2": "value2"},
    {"row_number": 3, "field1": "value3", "field2": "value4"}
  ]
}
```

## Schema Definition Guidelines

### Basic Schema Example

```json
{
  "batch_number": <integer>,
  "row_count": <integer>,
  "summaries": [
    {
      "row_number": <integer>,
      "field_name": "<type_description>"
    }
  ]
}
```

### Type Annotations in Schema

Use clear type annotations in markdown:

| Annotation | Type |
|------------|------|
| `<integer>` | Integer number |
| `<number>` | Any number |
| `<string>` | Text string |
| `<boolean>` | true or false |
| `<array>` | JSON array |
| `<object>` | JSON object |

### Enum Values

Specify allowed values:

```json
{
  "status": "<one of: active/inactive/pending>"
}
```

### Optional Fields

Mark optional fields clearly:

```json
{
  "required_field": "<string>",
  "optional_field?": "<string or null>"
}
```

## Validation Flow

### Step 1: Infer Schema from First Output

```python
# Get first output
first_result = jsonExtract(file_path="./outputs/batch001.md")

# Infer schema
schema_result = jsonInfer(
    data=json.dumps(first_result.data),
    strict=true
)

# Store schema for validation
expected_schema = json.dumps(schema_result.data)
```

### Step 2: Validate All Outputs

```python
for file_path in output_files:
    # Extract
    result = jsonExtract(file_path=file_path)
    if not result.success:
        log_error(f"Extraction failed: {file_path}")
        continue
    
    # Validate
    validation = jsonValidate(
        data=json.dumps(result.data),
        schema=expected_schema
    )
    
    if not validation.valid:
        log_error(f"Validation failed: {file_path}")
        log_error(validation.errors)
        continue
    
    # Collect valid data
    valid_outputs.append(result.data)
```

## Error Handling

### Error Structures

#### jsonExtract Error Response
```json
{
  "success": false,
  "data": null,
  "metadata": {
    "error": {
      "code": "NO_JSON_FOUND",
      "message": "No valid JSON found in file"
    }
  }
}
```

#### Error Codes
| Code | Description |
|------|-------------|
| `FILE_NOT_FOUND` | File does not exist |
| `FILE_TOO_LARGE` | File exceeds 200MB limit |
| `BINARY_FILE` | File is binary format |
| `EMPTY_FILE` | File has no content |
| `NO_JSON_FOUND` | No valid JSON found |

#### jsonValidate Error Response
```json
{
  "success": true,
  "valid": false,
  "errors": [
    {
      "path": "summaries.0.row_number",
      "message": "Expected number, received string",
      "code": "invalid_type",
      "expected": "number",
      "received": "string"
    }
  ]
}
```

### Extraction Failures

```python
if not result.success:
    error_code = result.metadata.get("error", {}).get("code", "UNKNOWN")
    if error_code == "NO_JSON_FOUND":
        log_error("Subagent did not output valid JSON")
        log_error("Check subagent output for errors")
    retry_or_skip()
```

### Validation Failures

```python
if not validation.valid:
    for error in validation.errors:
        log_error(f"Field {error['path']}: {error['message']}")
        if error['code'] == "invalid_type":
            log_error(f"  Expected: {error['expected']}")
            log_error(f"  Received: {error['received']}")
```

### Subagent Execution Failures

Beyond output validation, subagents may fail during execution:

| Failure Type | Detection | Recovery |
|--------------|-----------|----------|
| Timeout | Task exceeds time limit | Retry with smaller batch |
| Crash | No output file created | Retry or skip |
| Partial output | Incomplete JSON | Retry or use partial data |
| Wrong format | JSON doesn't match schema | Re-prompt with clearer instructions |

### Failure Handling Pattern

```python
# After launching subagent wave
failed_batches = []

for batch_file in expected_outputs:
    if not file_exists(batch_file):
        log_error(f"Subagent failed to create output: {batch_file}")
        failed_batches.append(batch_file)
        continue
    
    result = jsonExtract(file_path=batch_file)
    if not result.success:
        log_error(f"Failed to extract JSON: {batch_file}")
        failed_batches.append(batch_file)
        continue
    
    validation = jsonValidate(data=json.dumps(result.data), schema=expected_schema)
    if not validation.valid:
        log_error(f"Validation failed: {batch_file}")
        failed_batches.append(batch_file)
        continue
    
    valid_outputs.append(result.data)

# Retry failed batches using retry.md pattern
if failed_batches:
    for batch in failed_batches:
        retry_subagent(batch, max_attempts=3, delay=5)
```

> **Note:** Reference `patterns/retry.md` for implementing retry logic with exponential backoff.

## Complete Example

### Main Agent: Create Prompt

```markdown
# Gene Classification Task

## Input
- File: ./data/genes.xlsx
- Sheet: Sheet1
- Rows: 2-31

## Instructions
For each row, classify the gene by species and function.

## Output Format
Write JSON to: ./outputs/batch001.md

```json
{
  "batch_number": 1,
  "row_count": 30,
  "summaries": [
    {
      "row_number": <integer>,
      "gene_name": "<string>",
      "species": "<one of: human/mouse/other>",
      "function": "<string>"
    }
  ]
}
```
```

### Subagent: Write Output

```json
{
  "batch_number": 1,
  "row_count": 30,
  "summaries": [
    {"row_number": 2, "gene_name": "BRAF", "species": "human", "function": "Kinase"},
    {"row_number": 3, "gene_name": "TP53", "species": "human", "function": "Tumor suppressor"}
  ]
}
```

### Main Agent: Validate

```python
# Extract
result = jsonExtract(file_path="./outputs/batch001.md")

# Validate
validation = jsonValidate(
    data=json.dumps(result.data),
    schema='{"type":"object","properties":{"batch_number":{"type":"integer"},"summaries":{"type":"array"}}}'
)

if validation.valid:
    process(result.data)
```

## Best Practices

1. **Embed schema in prompt**: Don't rely on external schema files
2. **Use strict typing**: Specify exact types and allowed values
3. **Validate every output**: Never skip validation
4. **Handle errors gracefully**: Log and continue with other outputs
5. **Keep schemas simple**: Avoid complex nested structures
