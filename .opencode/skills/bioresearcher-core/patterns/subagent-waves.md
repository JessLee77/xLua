# Subagent Waves Pattern

Process multiple items with parallel subagents organized in waves.

## Overview

Use this pattern when you need to process many items in parallel while controlling concurrency.

## Requirements

> **CRITICAL:** This pattern requires the `Task` tool to be available in your environment.
> 
> - If the Task tool is not available, **subagent waves are not possible**
> - Alternative: Process items sequentially or use external batch processing
> - Check tool availability before implementing this pattern
> 
> To verify Task tool availability, check your environment's tool list.

## Pattern Algorithm

```
1. Calculate total items and wave_size
2. Group items into waves of wave_size items each
3. For each wave:
   a. Launch wave_size subagents in parallel via Task tool
   b. Wait for all subagents to complete
   c. Track progress (use progress pattern)
   d. Validate outputs using jsonExtract + jsonValidate
   e. Collect validated outputs
4. Handle failed items (use retry pattern)
5. Combine all outputs using jsonExtract or table tools
```

## Parameters

| Parameter | Default | Description |
|-----------|---------|-------------|
| `wave_size` | 3 | Number of parallel subagents per wave |
| `subagent_type` | "general" | Type of subagent to launch |

## Key Principles

1. **File-based prompts**: Subagents read prompt files, not inline prompts
2. **File-based outputs**: Subagents write to output files as JSON
3. **Schema validation**: Every output validated before processing
4. **Wave coordination**: Wait for entire wave before starting next
5. **Progress tracking**: Report after each wave completes

## Tool: Task

```
task(
  subagent_type: string,
  description: string,
  prompt: string
)
```

## Example: Launch Wave of 3 Subagents

```typescript
// Wave 1 - Launch 3 subagents in parallel
task(
  subagent_type="general",
  description="Process batch 001",
  prompt="Read your prompt from ./.work/batch001.md and perform the task described there exactly as written."
)
task(
  subagent_type="general",
  description="Process batch 002",
  prompt="Read your prompt from ./.work/batch002.md and perform the task described there exactly as written."
)
task(
  subagent_type="general",
  description="Process batch 003",
  prompt="Read your prompt from ./.work/batch003.md and perform the task described there exactly as written."
)
// Wait for all 3 to complete before Wave 2
```

## Example: Full Wave Processing Workflow

```
# Configuration
total_items = 12
wave_size = 3
total_waves = ceil(total_items / wave_size)  # 4 waves

# Create prompt files first (using template.py)
uv run python <skill_path>/python/template.py generate-batches \
  --template template.md \
  --contexts contexts.json \
  --output-dir ./prompts

# Process in waves
for wave_num in range(1, total_waves + 1):
    # Launch wave
    start_idx = (wave_num - 1) * wave_size + 1
    end_idx = min(wave_num * wave_size, total_items)
    
    for batch_num in range(start_idx, end_idx + 1):
        task(
            subagent_type="general",
            description=f"Process batch {batch_num:03d}",
            prompt=f"Read your prompt from ./prompts/batch{batch_num:03d}.md and perform the task."
        )
    
    # Wait for wave completion
    # (Task tool handles this - next task call waits)
    
    # Report progress
    completed = end_idx
    percent = calculator(formula=f"({completed} / {total_items}) * 100")
    report(f"Progress: {completed}/{total_items} batches ({percent}%)")
```

## Output Validation

After each wave, validate outputs:

```
# For each output file
result = jsonExtract(file_path="./outputs/batch001.md")
if not result.success:
    log_error("Failed to extract JSON from batch001.md")
    continue

# Validate against schema
validation = jsonValidate(
    data=json.dumps(result.data),
    schema=expected_schema
)
if not validation.valid:
    log_error(f"Schema validation failed for batch001.md: {validation.errors}")
    continue

# Collect valid output
valid_outputs.append(result.data)
```

## Handling Failed Batches

After all waves complete:

```
# Check for missing outputs
expected_files = [f"batch{i:03d}.md" for i in range(1, total_items + 1)]
missing = [f for f in expected_files if not exists(f"./outputs/{f}")]

if missing:
    # Use retry pattern
    for batch_file in missing:
        retry_subagent(batch_file, max_attempts=3, delay=2)
```

## Combining Outputs

For small batches (<10 files), use table tools:

```
# Extract all JSON
all_data = []
for file in output_files:
    result = jsonExtract(file_path=file)
    if result.success:
        all_data.extend(result.data["summaries"])

# Create combined Excel
tableCreateFile(
    file_path="./combined.xlsx",
    sheet_name="Results",
    data=all_data
)
```

For large batches (>10 files), use Python script for efficiency.

## Best Practices

1. **Verify Task tool availability** before implementing this pattern
2. **Keep wave_size reasonable**: 3-5 subagents per wave
3. **Use descriptive descriptions**: "Process batch 001" not "Batch 1"
4. **Always use file-based prompts**: Never inline large prompts
5. **Validate every output**: Don't skip schema validation
6. **Report progress after waves**: Not during individual completions
7. **Have fallback plan**: If Task tool unavailable, use sequential processing
