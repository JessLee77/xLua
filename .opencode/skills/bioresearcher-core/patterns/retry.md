# Retry Pattern

Retry failed operations with configurable delays and backoff.

## Overview

Use this pattern when operations may fail transiently (network issues, API rate limits, temporary resource unavailability).

## Pattern Algorithm

```
1. Initialize: attempts = 0, max_attempts = N, delay = D, backoff_factor = B
2. Attempt operation
3. If success -> continue with workflow
4. If failure:
   a. attempts += 1
   b. If attempts < max_attempts:
      - Use blockingTimer(delay=D)
      - delay = delay * backoff_factor
      - Retry from step 2
   c. If attempts >= max_attempts:
      - Report failure or ask user via question tool
```

## Parameters

| Parameter | Default | Description |
|-----------|---------|-------------|
| `max_attempts` | 3 | Maximum retry attempts |
| `delay` | 2 | Initial wait time in seconds |
| `backoff_factor` | 1 | Multiply delay after each failure (1 = constant delay) |

## Tool: blockingTimer

```
blockingTimer(delay: number)
```

- Maximum delay: 300 seconds
- Returns: "Timer completed: waited X seconds (actual elapsed: Ys)"

## Example: Constant Delay Retry

```
# Retry configuration
max_attempts = 3
delay = 2
attempts = 0

# Attempt loop
while attempts < max_attempts:
    result = attempt_operation()
    if result.success:
        break
    attempts += 1
    if attempts < max_attempts:
        blockingTimer(delay=2)  # Wait 2 seconds
```

## Example: Exponential Backoff Retry

```
# Retry configuration
max_attempts = 4
delay = 1
backoff_factor = 2
attempts = 0

# Attempt loop
while attempts < max_attempts:
    result = attempt_operation()
    if result.success:
        break
    attempts += 1
    if attempts < max_attempts:
        blockingTimer(delay=delay)
        delay = delay * backoff_factor  # 1, 2, 4, 8...
```

## When to Use

| Scenario | delay | backoff_factor | max_attempts |
|----------|-------|----------------|--------------|
| Network timeout | 2 | 1 | 3 |
| API rate limit | 5 | 2 | 4 |
| File lock | 1 | 1 | 5 |
| Resource unavailable | 2 | 2 | 4 |

## User Notification on Persistent Failure

After all retries exhausted, use `question` tool:

```
question(questions=[{
  "header": "Retry failed",
  "question": "Operation failed after 3 attempts. How would you like to proceed?",
  "options": [
    {"label": "Retry now", "description": "Try one more time immediately"},
    {"label": "Skip", "description": "Skip this item and continue"},
    {"label": "Abort", "description": "Stop the entire workflow"}
  ]
}])
```

## Important Notes

1. **Maximum delay**: blockingTimer caps at 300 seconds
2. **Backoff calculation**: Use `calculator` tool if needed
3. **State tracking**: Track attempts in your workflow state
4. **Error logging**: Log failure reasons for debugging
