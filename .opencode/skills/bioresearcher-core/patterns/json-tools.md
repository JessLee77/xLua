# JSON Tools Pattern

Guide for using JSON tools (jsonExtract, jsonValidate, jsonInfer) in BioResearcher workflows.

## Overview

These tools replace custom Python code for JSON operations:
- **jsonExtract**: Extract JSON from files (handles markdown code blocks, raw JSON)
- **jsonValidate**: Validate JSON against schemas (supports Draft-4, Draft-7, Draft-2020-12)
- **jsonInfer**: Infer schemas from JSON data

## Tool: jsonExtract

Extract JSON from files that may contain extra text.

### Signature
```
jsonExtract(file_path: string, return_all: boolean = false)
```

### Return Format
```json
{
  "success": true,
  "data": { ... } or [ ... ],
  "metadata": {
    "method": "json_code_block" | "code_block" | "object" | "array",
    "dataType": "object" | "array" | "mixed",
    "fileSize": 1234
  }
}
```

### Extraction Methods (in order)
1. **json_code_block**: Content in ```json ... ```
2. **code_block**: Content in ``` ... ```
3. **object**: First {...} with proper brace matching
4. **array**: First [...] with proper bracket matching

### Examples

```
# Extract from markdown with JSON code block
jsonExtract(file_path="outputs/batch001.md")

# Extract all JSON objects from file
jsonExtract(file_path="outputs/all_batches.md", return_all=true)
```

### Error Codes
| Code | Description |
|------|-------------|
| `FILE_NOT_FOUND` | File does not exist |
| `FILE_TOO_LARGE` | File exceeds 200MB limit |
| `BINARY_FILE` | File is binary format |
| `EMPTY_FILE` | File has no content |
| `NO_JSON_FOUND` | No valid JSON found |

## Tool: jsonValidate

Validate JSON data against a JSON Schema.

### Signature
```
jsonValidate(data: string, schema: string)
```

- `data`: JSON string to validate
- `schema`: JSON Schema string OR file path (auto-detected)

### Return Format (Success)
```json
{
  "success": true,
  "data": { ... },
  "valid": true,
  "metadata": {
    "errorCount": 0,
    "schemaFeatures": {
      "validated": ["type", "properties", "required"],
      "ignored": ["uniqueItems"]
    }
  }
}
```

> **Note:** Always check `success` first, then `valid`. If `success` is true and `errorCount` is 0, the validation passed regardless of `valid` field presence.

### Return Format (Validation Errors)
```json
{
  "success": true,
  "data": null,
  "valid": false,
  "errors": [
    {
      "path": "summaries.0.row_number",
      "message": "Expected number, received string",
      "code": "invalid_type",
      "expected": "number",
      "received": "string"
    }
  ],
  "metadata": {
    "errorCount": 1
  }
}
```

### Examples

```
# Validate with inline schema
jsonValidate(
  data='{"name": "test", "age": 30}',
  schema='{"type": "object", "properties": {"name": {"type": "string"}, "age": {"type": "number"}}}'
)

# Validate with schema file
jsonValidate(
  data='{"batch_number": 1, "summaries": [...]}',
  schema='./schemas/batch_output.schema.json'
)
```

### Unsupported Schema Features
- `not`, `unevaluatedItems`, `unevaluatedProperties`
- `if`, `then`, `else`, `dependentSchemas`

### Silently Ignored Features
- `uniqueItems`, `contains`, `minContains`, `maxContains`

## Tool: jsonInfer

Generate a JSON Schema from example data.

### Signature
```
jsonInfer(data: string, strict: boolean = false)
```

- `data`: Example JSON string
- `strict`: If true, all fields required at all levels; if false, only top-level required array is omitted (nested objects may still have required fields)

### Return Format
```json
{
  "success": true,
  "data": {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "type": "object",
    "properties": {
      "name": { "type": "string" },
      "age": { "type": "integer" }
    },
    "required": ["name", "age"]
  },
  "metadata": {
    "inferredType": "object",
    "strictMode": true
  }
}
```

### Examples

```
# Infer schema from example (optional fields)
jsonInfer(data='{"name": "Alice", "age": 30}', strict=false)

# Infer schema with required fields
jsonInfer(data='{"batch_number": 1, "summaries": [{"row": 1, "value": "test"}]}', strict=true)
```

### Warnings
- `MIXED_TYPE_ARRAY`: Array contains multiple types
- `EMPTY_ARRAY`: Cannot infer element type
- `PARTIAL_OBJECT_SCHEMA`: Object has many properties

### Generated Constraints

jsonInfer may add the following constraints automatically:

| Type | Constraint | Value | Purpose |
|------|------------|-------|---------|
| integer | minimum/maximum | ±9007199254740991 | JavaScript safe integer range |

> **Note:** These constraints ensure JSON compatibility but may be overly restrictive for your use case. Remove them from the generated schema if not needed.

## Common Workflows

### Validate Subagent Output

```
# 1. Extract JSON from output file
result = jsonExtract(file_path="./outputs/batch001.md")
if not result.success:
    log_error("Failed to extract JSON")
    return

# 2. Validate against expected schema
validation = jsonValidate(
    data=json.dumps(result.data),
    schema=batch_output_schema
)

if not validation.valid:
    log_error(f"Validation failed: {validation.errors}")
    return

# 3. Process validated data
process(result.data)
```

### Infer Schema from Example

```
# 1. Get first valid output
result = jsonExtract(file_path="./outputs/batch001.md")

# 2. Infer schema from example
schema_result = jsonInfer(
    data=json.dumps(result.data),
    strict=true
)

# 3. Use inferred schema for validation
inferred_schema = json.dumps(schema_result.data)

# 4. Validate other outputs
for file in other_files:
    data = jsonExtract(file_path=file)
    validation = jsonValidate(
        data=json.dumps(data.data),
        schema=inferred_schema
    )
```

### Combine Multiple JSON Files

```
# 1. Extract all JSON objects
all_data = []
for file in output_files:
    result = jsonExtract(file_path=file, return_all=true)
    if result.success:
        all_data.extend(result.data)

# 2. Create combined output
tableCreateFile(
    file_path="./combined.xlsx",
    sheet_name="Results",
    data=all_data
)
```

## Best Practices

1. **Always check success**: Check `result.success` before using `result.data`
2. **Handle errors gracefully**: Log errors and continue with other files
3. **Use strict mode for inference**: When you know all fields are required
4. **Validate early**: Validate before processing to catch errors early
5. **Keep schemas simple**: Avoid unsupported schema features
