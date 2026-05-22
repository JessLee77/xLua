# Progress Pattern

Track and report progress at configurable intervals during batch operations.

## Overview

Use this pattern when processing multiple items to provide user feedback on completion status.

## Pattern Algorithm

```
1. Initialize: total = N, completed = 0, report_interval = M
2. For each item:
   a. Process item
   b. completed += 1
   c. If completed % report_interval == 0 OR completed == total:
      - Use calculator: percent = (completed / total) * 100
      - Report: "Progress: X/Y (Z%)"
```

## Parameters

| Parameter | Default | Description |
|-----------|---------|-------------|
| `total` | Required | Total number of items to process |
| `completed` | 0 | Items processed so far |
| `report_interval` | 3 | Report every N items |

## Tool: calculator

```
calculator(formula: string, precision: number = 3)
```

- Supported: +, -, *, /, ^, brackets, scientific notation
- **MUST** use explicit * for multiplication: `2*(3)` not `2(3)`

## Example: Batch Processing Progress

```
# Configuration
total = 100
completed = 0
report_interval = 10

# Processing loop
for item in items:
    process(item)
    completed += 1
    
    if completed % report_interval == 0 or completed == total:
        percent = calculator(formula="(completed / total) * 100", precision=1)
        report("Progress: {completed}/{total} ({percent}%)")
```

## Example: Wave-Based Progress

For subagent waves (3 subagents per wave):

```
# Configuration
total_waves = 4
completed_waves = 0
total_batches = 12
completed_batches = 0

# After each wave completes
completed_waves += 1
completed_batches += 3
percent = calculator(formula="({completed_batches} / {total_batches}) * 100")

report("Progress: {completed_batches}/{total_batches} batches ({percent}%)")
```

## Progress Report Format

Standard format for consistency:

```
Progress: X/Y batches completed (Z%)
```

Examples:
- "Progress: 3/10 batches completed (30%)"
- "Progress: 6/10 batches completed (60%)"
- "Progress: 10/10 batches completed (100%)"

## Percentage Calculation

Use the calculator tool:

```
calculator(formula="(45 / 100) * 100", precision=1)
# Returns: { "formula": "(45 / 100) * 100", "result": 45 }
```

## Example: Time Estimation

```
# Track start time and items per minute
start_time = current_time()
items_per_minute = 10

# Calculate remaining time
remaining_items = total - completed
remaining_minutes = calculator(
    formula="remaining_items / items_per_minute",
    precision=0
)

report("Progress: {completed}/{total} ({percent}%) - ~{remaining_minutes} min remaining")
```

## Integration with Other Patterns

| Pattern | Integration |
|---------|-------------|
| `retry.md` | Count retries in progress |
| `subagent-waves.md` | Report after each wave |
| `calculator.md` | Calculate percentages |

## Best Practices

1. **Report at meaningful intervals**: Not too frequent (spam) or too sparse (silent)
2. **Include totals**: Always show X/Y format
3. **Round percentages**: Use precision=0 or precision=1
4. **Final report**: Always report 100% completion
