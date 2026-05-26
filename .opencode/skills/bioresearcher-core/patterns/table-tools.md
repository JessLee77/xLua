# Table Tools Pattern

Guide for combining subagent outputs using table tools.

## Overview

Table tools can be used to combine JSON outputs into Excel/CSV files without Python scripts for small batches.

## When to Use Table Tools vs Python

| Scenario | Use Table Tools | Use Python Script |
|----------|-----------------|-------------------|
| Files to combine | <10 files | >=10 files |
| Data size | Small (<1000 rows total) | Large (>1000 rows) |
| Complexity | Simple merge | Complex transformations |
| Performance | Acceptable overhead | Need efficiency |

## Tool: tableCreateFile

Create a new Excel/CSV file from data.

### Signature
```
tableCreateFile(
  file_path: string,
  sheet_name: string = "Sheet1",
  data: array  // Array of arrays OR array of objects
)
```

### Return Format
```json
{
  "success": true,
  "file_path": "./output.xlsx",
  "sheet_name": "Sheet1",
  "rows_created": 100,
  "message": "Successfully created Excel file with 100 rows"
}
```

### Examples

```
# Create from array of objects
tableCreateFile(
  file_path="./output.xlsx",
  sheet_name="Results",
  data=[
    {"row_number": 1, "name": "Alice", "score": 95},
    {"row_number": 2, "name": "Bob", "score": 87}
  ]
)

# Create from array of arrays
tableCreateFile(
  file_path="./output.csv",
  sheet_name="Sheet1",
  data=[
    ["row_number", "name", "score"],
    [1, "Alice", 95],
    [2, "Bob", 87]
  ]
)
```

## Tool: tableAppendRows

Append rows to an existing table file.

### Signature
```
tableAppendRows(
  file_path: string,
  sheet_name: string?,  // Optional, uses first sheet
  rows: array  // Array of arrays OR array of objects
)
```

### Return Format
```json
{
  "success": true,
  "file_path": "./output.xlsx",
  "sheet_name": "Sheet1",
  "rows_appended": 50,
  "message": "Successfully appended 50 rows"
}
```

### Examples

**RECOMMENDED: Append using array-of-arrays format (no header duplication):**
```
tableAppendRows(
  file_path="./output.xlsx",
  rows=[
    [3, "Charlie", 92],
    [4, "Diana", 88]
  ]
)
```

**Alternative: Append using objects (may duplicate headers):**
```
tableAppendRows(
  file_path="./output.xlsx",
  rows=[
    {"row_number": 3, "name": "Charlie", "score": 92}
  ]
)
```

> **Note:** When appending object-format data, some implementations may insert a duplicate header row. For reliable results, use array-of-arrays format for append operations.

## Combining JSON Outputs Workflow

### Step 1: Extract All JSON

```
# Extract JSON from each output file
all_rows = []

for batch_num in range(1, num_batches + 1):
    file_path = f"./outputs/batch{batch_num:03d}.md"
    result = jsonExtract(file_path=file_path)
    
    if result.success:
        # Assuming data has "summaries" array
        summaries = result.data.get("summaries", [])
        all_rows.extend(summaries)
    else:
        log_error(f"Failed to extract from {file_path}")
```

### Step 2: Create Combined File

```
# Create Excel file with all rows
tableCreateFile(
  file_path="./combined_summary.xlsx",
  sheet_name="Summary",
  data=all_rows
)
```

### Step 3: Append Additional Data (Optional)

```
# If processing in chunks, append to existing file using array format
# First, get headers from the created file
headers = list(all_rows[0].keys()) if all_rows else []

for chunk in chunks:
    rows = extract_rows(chunk)
    # Convert to arrays to avoid header duplication
    rows_as_arrays = [[item.get(h) for h in headers] for item in rows]
    tableAppendRows(
      file_path="./combined_summary.xlsx",
      rows=rows_as_arrays
    )
```

## Complete Example: Combining Batch Outputs

```
# Configuration
output_dir = "./outputs"
num_batches = 9
combined_file = "./combined_summary.xlsx"

# Collect all rows
all_rows = []
failed_batches = []

for batch_num in range(1, num_batches + 1):
    file_path = f"{output_dir}/batch{batch_num:03d}.md"
    
    # Extract JSON
    result = jsonExtract(file_path=file_path)
    
    if not result.success:
        failed_batches.append(batch_num)
        continue
    
    # Get summaries from batch output
    summaries = result.data.get("summaries", [])
    all_rows.extend(summaries)

# Report failures
if failed_batches:
    log_error(f"Failed batches: {failed_batches}")

# Sort by row_number
all_rows.sort(key=lambda x: x.get("row_number", 0))

# Create combined Excel
result = tableCreateFile(
  file_path=combined_file,
  sheet_name="Combined",
  data=all_rows
)

# Report result
report(f"Created {combined_file} with {result.rows_created} rows")
```

## Incremental Append Strategy

For large datasets, append incrementally using array-of-arrays format:

```
# Get column headers from first batch
first_batch = jsonExtract(file_path="./outputs/batch001.md")
headers = ["row_number", "field1", "field2"]  # Define your headers

# Create file with first batch (using objects for auto-headers)
tableCreateFile(
  file_path="./combined.xlsx",
  sheet_name="Data",
  data=first_batch.data.get("summaries", [])
)

# Get header order for array format
headers = list(first_batch.data.get("summaries", [{}])[0].keys())

# Append remaining batches using array format
for batch_num in range(2, num_batches + 1):
    file_path = f"./outputs/batch{batch_num:03d}.md"
    result = jsonExtract(file_path=file_path)
    
    if result.success:
        # Convert objects to arrays to avoid header duplication
        rows_as_arrays = [
            [item.get(h) for h in headers]
            for item in result.data.get("summaries", [])
        ]
        tableAppendRows(
          file_path="./combined.xlsx",
          rows=rows_as_arrays
        )
```

## Supported File Formats

| Format | Extension | Notes |
|--------|-----------|-------|
| Excel | .xlsx | Recommended |
| Excel (Legacy) | .xls | Limited support |
| ODS | .ods | OpenDocument Spreadsheet |
| CSV | .csv | Text-based, no sheets |

## Best Practices

1. **Sort before writing**: Sort rows by key field before creating file
2. **Handle failures gracefully**: Log failed extractions, continue with others
3. **Use object format for creation**: Array of objects auto-generates headers
4. **Use array format for appends**: Prefer array-of-arrays when using tableAppendRows to avoid potential header duplication
5. **Check row counts**: Verify expected vs actual row counts
6. **For large batches**: Use Python script for better performance
