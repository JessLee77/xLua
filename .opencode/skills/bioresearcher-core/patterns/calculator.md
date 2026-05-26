# Calculator Pattern

In-workflow calculations using the calculator tool.

## Overview

Use the calculator tool for arithmetic operations in workflows. It's more reliable than manual calculations and provides consistent precision.

## Tool: calculator

```
calculator(formula: string, precision: number = 3)
```

### Parameters
- `formula`: Mathematical expression (string)
- `precision`: Decimal places for result (0-15, default 3)

### Return Format
```json
{
  "formula": "(45 / 100) * 100",
  "result": 45
}
```

### Supported Operations

| Operation | Symbol | Example |
|-----------|--------|---------|
| Addition | + | `2 + 3` |
| Subtraction | - | `5 - 2` |
| Multiplication | * | `3 * 4` |
| Division | / | `10 / 2` |
| Power | ^ | `2 ^ 3` |
| Brackets | () | `(2 + 3) * 4` |
| Scientific | e/E | `1e5`, `1.5e-3` |

### Important Rules

1. **MUST use explicit * for multiplication**: `2*(3)` NOT `2(3)`
2. **Maximum precision**: 15 decimal places
3. **Default precision**: 3 decimal places
4. **No functions**: ceil, floor, sqrt not supported

## Common Use Cases

### Batch Calculations

```
# Calculate number of batches needed
calculator(formula="ceil(100 / 30)", precision=0)
# Note: ceil not supported, use workaround:
calculator(formula="(100 + 30 - 1) / 30", precision=0)
# Result: 4.333 -> Use ceiling logic in agent
```

### Progress Percentages

```
# Calculate completion percentage
calculator(formula="(45 / 100) * 100", precision=1)
# Result: 45

# With variables in workflow
completed = 67
total = 120
calculator(formula="({completed} / {total}) * 100", precision=1)
# Result: 55.8
```

### Time Estimates

```
# Estimate remaining time
remaining_items = 50
items_per_minute = 10
calculator(formula="50 / 10", precision=0)
# Result: 5 minutes
```

### Data Size Calculations

```
# Calculate total rows across batches
batch_size = 30
num_batches = 4
calculator(formula="30 * 4", precision=0)
# Result: 120
```

## Ceiling/Floor Workarounds

Since ceil/floor are not supported:

### Ceiling
```
# ceil(a / b) = (a + b - 1) / b (for positive integers)
# ceil(100 / 30)
calculator(formula="(100 + 30 - 1) / 30", precision=0)
# Result: 4.333 -> Agent interprets as 5
```

### Floor
```
# floor(a / b) = a / b (truncate decimal)
# floor(100 / 30)
calculator(formula="100 / 30", precision=0)
# Result: 3.333 -> Agent interprets as 3
```

## Example Workflow

### Calculate Batch Configuration

```
# Given
total_rows = 250
batch_size = 30

# Calculate batches needed
# ceil(250 / 30) = 9 batches
batches_needed = calculator(
    formula="(250 + 30 - 1) / 30",
    precision=0
)
# Result: 9.3 -> Agent rounds up to 10

# Calculate rows in last batch
# 250 - (9 * 30) = 250 - 270 = -20 -> use 30
# Actually: 250 - (8 * 30) = 250 - 240 = 10
last_batch_rows = calculator(
    formula="250 - (8 * 30)",
    precision=0
)
# Result: 10
```

### Progress Tracking

```
# During batch processing
completed = 0
total = 10

for batch in batches:
    process(batch)
    completed += 1
    
    # Calculate and report progress
    percent = calculator(
        formula="({completed} / {total}) * 100",
        precision=0
    )
    report(f"Progress: {completed}/{total} ({percent}%)")
```

### Wave Timing

```
# Calculate expected completion time
waves_remaining = 3
seconds_per_wave = 45

estimated_seconds = calculator(
    formula="3 * 45",
    precision=0
)
# Result: 135 seconds

# Convert to minutes
estimated_minutes = calculator(
    formula="135 / 60",
    precision=1
)
# Result: 2.3 minutes
```

## Error Handling

### Invalid Formula
```
# Missing explicit multiplication
calculator(formula="2(3)")
# Error: "CALCULATOR ERROR: Invalid syntax: parentheses-less multiplication not allowed"
```

### Division by Zero
```
calculator(formula="10 / 0")
# Error: "CALCULATOR ERROR: Division by zero"
```

### Invalid Characters
```
calculator(formula="2 + abc")
# Error: "CALCULATOR ERROR: Formula contains invalid characters: a b c"
```

## Integration with Other Patterns

| Pattern | Calculator Usage |
|---------|-----------------|
| `progress.md` | Calculate percentages |
| `retry.md` | Calculate backoff delays |
| `subagent-waves.md` | Calculate wave counts |
| `table-tools.md` | Calculate row counts |

## Best Practices

1. **Use precision=0 for counts**: Integer results
2. **Use precision=1 for percentages**: One decimal place
3. **Always use explicit ***: Never implicit multiplication
4. **Check for division by zero**: Validate divisors
5. **Document formulas**: Explain what calculation does
