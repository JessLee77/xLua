# User Confirmation Pattern

Request user confirmation before destructive or significant operations.

## Overview

Use this pattern before operations that:
- Delete or modify files
- Make network requests
- Incur costs (API calls, cloud resources)
- Take significant time
- Cannot be easily undone

## Tool: question

> **Note:** The tool is invoked as `question` (lowercase). Some documentation may reference `Question` (capitalized) but both refer to the same tool.

```
question(questions: [{
  header: string,      // Short label (max 30 chars)
  question: string,    // Complete question
  options: [{
    label: string,     // Display text (1-5 words)
    description: string // Explanation of choice
  }],
  multiple: boolean    // Allow multiple selections (default: false)
}])
```

## Example: Before Destructive Operation

```
question(questions=[{
  "header": "Delete files",
  "question": "This will delete 15 files in ./temp/. Continue?",
  "options": [
    {"label": "Yes, delete", "description": "Permanently delete all 15 files"},
    {"label": "No, cancel", "description": "Keep files and stop this operation"}
  ]
}])
```

## Example: Continue After Failures

```
question(questions=[{
  "header": "Retry failed",
  "question": "3 batches failed after all retry attempts. How would you like to proceed?",
  "options": [
    {"label": "Continue", "description": "Skip failed batches and continue with remaining"},
    {"label": "Retry now", "description": "Try failed batches one more time"},
    {"label": "Abort", "description": "Stop the entire workflow"}
  ]
}])
```

## Example: Configuration Choice

```
question(questions=[{
  "header": "Batch size",
  "question": "How many rows should each batch contain?",
  "options": [
    {"label": "30 rows (Recommended)", "description": "Balanced for most use cases"},
    {"label": "50 rows", "description": "Fewer batches, larger context per subagent"},
    {"label": "10 rows", "description": "More batches, smaller context per subagent"}
  ]
}])
```

## Example: Multiple Selection

```
question(questions=[{
  "header": "Select sheets",
  "question": "Which sheets should be processed?",
  "options": [
    {"label": "Sheet1", "description": "Main data sheet (1000 rows)"},
    {"label": "Sheet2", "description": "Secondary data (500 rows)"},
    {"label": "Summary", "description": "Pre-computed summaries (50 rows)"}
  ],
  "multiple": true
}])
```

## When to Ask for Confirmation

| Operation Type | Confirmation Needed |
|---------------|---------------------|
| Read file | No |
| Write new file | No |
| Overwrite existing file | Yes |
| Delete file | Yes |
| Delete directory | Yes |
| API call (free) | No |
| API call (paid) | Yes |
| Long operation (>5 min) | Yes |
| Network upload | Yes |
| Network download | No (usually) |

## Response Handling

The question tool returns selected option labels as an array:

```
# Single selection
response = question(...)
if response[0] == "Yes, delete":
    proceed_with_deletion()
else:
    cancel_operation()

# Multiple selection
response = question(..., multiple=true)
selected_sheets = response  # ["Sheet1", "Sheet2"]
```

## Example: Conditional Logic Flow

```
# Ask for confirmation
response = question(questions=[{
  "header": "Overwrite",
  "question": "File 'output.xlsx' already exists. Overwrite?",
  "options": [
    {"label": "Overwrite", "description": "Replace existing file"},
    {"label": "Append", "description": "Add to existing file"},
    {"label": "Cancel", "description": "Don't modify the file"}
  ]
}])

# Handle response
if response[0] == "Overwrite":
    write_file(mode="write")
elif response[0] == "Append":
    write_file(mode="append")
else:
    report("Operation cancelled by user")
```

## Best Practices

1. **Clear header**: Max 30 chars, summarize the decision
2. **Descriptive question**: Explain what will happen
3. **Helpful options**: Include descriptions that guide the user
4. **Recommended option**: Mark with "(Recommended)" in label
5. **Safe default**: Put safer option first
6. **Cancel option**: Always include a way to abort

## Timeout and No-Response Handling

When users don't respond to confirmation prompts, implement a default behavior:

### Default After Timeout

```python
# If no response after reasonable time, default to safe option
# Most patterns should default to "cancel" for safety

if no_response_after(timeout=60):
    log("No user response, defaulting to cancel")
    cancel_operation()
```

### Integration with Retry Pattern

For critical operations requiring user input:
1. Ask for confirmation
2. If no response, wait and retry with `blockingTimer`
3. After N attempts, use safe default or abort

```python
attempts = 0
max_attempts = 3
while attempts < max_attempts:
    response = question(...)
    if response:
        handle_response(response)
        break
    attempts += 1
    if attempts < max_attempts:
        blockingTimer(delay=10)  # Wait before re-prompting

# Default to safe option if no response
if attempts >= max_attempts:
    cancel_operation()
```
