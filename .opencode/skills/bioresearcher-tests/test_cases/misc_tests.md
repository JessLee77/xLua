# Miscellaneous Tool Tests

## Test: Timer - Short Delay
- Tool: blockingTimer
- Input:
  ```json
  {"delay": 1}
  ```
- Validators:
  - contains_string("Timer completed")
  - contains_string("1 seconds")
- Expected: Timer completed message after 1 second

## Test: Timer - Zero Delay
- Tool: blockingTimer
- Input:
  ```json
  {"delay": 0}
  ```
- Validators:
  - contains_string("Timer completed")
- Expected: Immediate completion

## Test: Timer - Max Exceeded
- Tool: blockingTimer
- Input:
  ```json
  {"delay": 301}
  ```
- Validators:
  - contains_string("300")
  - contains_string("NOT exceed")
- Expected: Error about max delay exceeded

## Test: Calculator - Basic Arithmetic
- Tool: calculator
- Input:
  ```json
  {"formula": "2 + 3 * 4", "precision": 3}
  ```
- Validators:
  - has result
  - result === 14
- Expected: 14 (order of operations: 3*4=12, 2+12=14)

## Test: Calculator - Power
- Tool: calculator
- Input:
  ```json
  {"formula": "2 ^ 10", "precision": 0}
  ```
- Validators:
  - has result
  - result === 1024
- Expected: 1024 (2 to power of 10)

## Test: Calculator - Brackets
- Tool: calculator
- Input:
  ```json
  {"formula": "(2 + 3) * 4", "precision": 3}
  ```
- Validators:
  - has result
  - result === 20
- Expected: 20 (brackets first: 5*4=20)

## Test: Calculator - Scientific Notation
- Tool: calculator
- Input:
  ```json
  {"formula": "1e3 + 500", "precision": 3}
  ```
- Validators:
  - has result
  - result === 1500
- Expected: 1500 (1000 + 500)

## Test: Calculator - Division by Zero
- Tool: calculator
- Input:
  ```json
  {"formula": "1 / 0", "precision": 3}
  ```
- Validators:
  - contains_string("CALCULATOR ERROR")
- Expected: Error about division by zero

## Test: Calculator - Invalid Syntax
- Tool: calculator
- Input:
  ```json
  {"formula": "2(3)", "precision": 3}
  ```
- Validators:
  - contains_string("CALCULATOR ERROR")
  - contains_string("parentheses")
- Expected: Error about implicit multiplication not allowed

## Test: Calculator - Precision
- Tool: calculator
- Input:
  ```json
  {"formula": "10 / 3", "precision": 2}
  ```
- Validators:
  - has result
  - result === 3.33
- Expected: 3.33 (2 decimal places)

## Test: Timer - Exact Boundary
- Tool: blockingTimer
- Input:
  ```json
  {"delay": 300}
  ```
- Validators:
  - contains_string("Timer completed")
- Expected: Timer completes at exact max boundary (300s)

## Test: Calculator - Empty Formula
- Tool: calculator
- Input:
  ```json
  {"formula": "", "precision": 3}
  ```
- Validators:
  - contains_string("CALCULATOR ERROR")
  - contains_string("empty")
- Expected: Error about empty formula

## Test: Calculator - Invalid Characters
- Tool: calculator
- Input:
  ```json
  {"formula": "2 + abc", "precision": 3}
  ```
- Validators:
  - contains_string("CALCULATOR ERROR")
  - contains_string("invalid characters")
- Expected: Error about invalid characters
