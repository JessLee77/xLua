---
name: bioresearcher-tests
description: Comprehensive tests for bioresearcher plugin tools and skills
allowedTools:
  - Bash
  - Read
  - Write
  - jsonExtract
  - jsonValidate
  - jsonInfer
  - tableListSheets
  - tableGetSheetPreview
  - tableGetHeaders
  - tableGetRange
  - tableGetCell
  - tableFilterRows
  - tableSearch
  - tableSummarize
  - tableGroupBy
  - tablePivotSummary
  - tableAppendRows
  - tableUpdateCell
  - tableCreateFile
  - blockingTimer
  - calculator
  - parse_pubmed_articleSet
  - parse_obo_file
  - skill
  - Question
---

# BioResearcher Plugin Tests

Comprehensive test suite for bioresearcher plugin tools and skills.

## Test Scope

| Category | Tools | Status |
|----------|-------|--------|
| Parser | `parse_pubmed_articleSet`, `parse_obo_file` | Full tests |
| Table | All 13 `table*` tools | Full tests + negative tests + hardening tests + large table tests |
| JSON | `jsonExtract`, `jsonValidate`, `jsonInfer` | Full tests |
| Misc | `blockingTimer`, `calculator` | Full tests |
| Skills | `demo-skill` | Full execution |
| Skills | `bioresearcher-core` | Metadata only |
| Skills | With Question tool | Metadata only |
| **Database** | `dbQuery`, `dbListTables`, `dbDescribeTable` | **NOT TESTED** |

> **Note:** Database tools are not tested because they require a live database connection configured via `env.jsonc`. These tools should be tested separately with a proper database environment.

## Workflow

### Step 1: Extract Skill Path

After loading this skill, extract `<skill_path>` from the `<skill_files>` section. Use this path in subsequent steps.

### Step 2: Prepare Test Workspace

Create workspace and extract all gzipped resources using Python (cross-platform):

```python
python -c "
import gzip, shutil
from pathlib import Path
resources = Path('<skill_path>/resources')
workspace = Path('.bioresearcher-tests/workspace')
(workspace / 'json_samples').mkdir(parents=True, exist_ok=True)
files = [
    ('pubmed_sample.xml.gz', 'pubmed_sample.xml'),
    ('obo_sample.obo.gz', 'obo_sample.obo'),
    ('table_sample.xlsx.gz', 'table_sample.xlsx'),
    ('json_samples/simple_object.json.gz', 'json_samples/simple_object.json'),
    ('json_samples/simple_array.json.gz', 'json_samples/simple_array.json'),
    ('json_samples/nested_object.json.gz', 'json_samples/nested_object.json'),
    ('json_samples/in_markdown.md.gz', 'json_samples/in_markdown.md'),
    ('json_samples/schema_draft7.json.gz', 'json_samples/schema_draft7.json'),
]
for src, dst in files:
    with gzip.open(resources / src, 'rb') as f_in:
        with open(workspace / dst, 'wb') as f_out:
            shutil.copyfileobj(f_in, f_out)
print('Workspace prepared successfully')
"
```

### Step 3: Run Parser Tests

Execute tests from `<skill_path>/test_cases/parser_tests.md`:

1. **PubMed XML - Single Mode**: Call `parse_pubmed_articleSet` with `filePath`, `outputMode: "single"`
2. **PubMed XML - Excel Mode**: Call with `outputMode: "excel"`
3. **PubMed XML - Individual Mode**: Call with `outputMode: "individual"`
4. **OBO - Basic Parsing**: Call `parse_obo_file` with sample OBO
5. **PubMed - Nonexistent File**: Test error handling

Record pass/fail for each test.

### Step 4: Run Table Tests

Execute tests from `<skill_path>/test_cases/table_tests.md` in order:

**Basic functionality (13 tests):**
1. `tableListSheets` - List sheets in sample Excel
2. `tableGetSheetPreview` - Get first 6 rows
3. `tableGetHeaders` - Get column headers
4. `tableGetCell` - Get specific cell value
5. `tableGetRange` - Get A1:C3 range
6. `tableFilterRows` - Filter by Age > 25 (verify new `total_matches_found` + `returned_count` fields)
7. `tableSearch` - Search for "Active"
8. `tableSummarize` - Get stats for numeric columns
9. `tableGroupBy` - Group by Category
10. `tableCreateFile` - Create new Excel file
11. `tableAppendRows` - Append row to file
12. `tableUpdateCell` - Update cell A1
13. `tablePivotSummary` - Create pivot table

**Error / negative tests (5 tests):**
14. Nonexistent File - error handling
15. Invalid Cell Address - descriptive error message
16. Invalid Filter Operator - error handling
17. Nonexistent Column - graceful handling
18. Out of Bounds Range - empty data

**Phase 2 correctness tests (10 tests):**
19. Pivot Avg Numeric-Only Denominator - Setup (create test file)
20. Pivot Avg Numeric-Only Denominator - Verify (avg = 20.0, not 10.0)
21. Pivot Max Handles Negative Values - Setup (create test file)
22. Pivot Max Handles Negative Values - Verify (max = 3, not 0)
23. CreateFile Overwrite Guard - rejects without `overwrite: true`
24. CreateFile Overwrite Succeeds - works with `overwrite: true`
25. FilterRows New Response Fields - `total_matches_found` + `returned_count`
26. UpdateCell Invalid Address Path Traversal - rejects `../../etc/passwd`
27. UpdateCell Null Value - accepts null without error
28. CreateFile Invalid Data Schema - rejects non-array data

**Hardening feature tests (8 tests):**
29. Force Parameter - Filter Rows (regression check)
30. Force Parameter - Summarize (regression check)
31. File Size Limit - Reject Large File (generate 55MB via `dd`)
32. File Size Limit - Bypass With Force (same file, `force: true`)
33. Range Limit - Reject Oversized Range (`A1:ZZZ1000`)
34. Range Limit - Bypass With Force
35. Error Sanitization - No Resolved Paths (no `/home/`, `/root/`, `/tmp/`)
36. Error Sanitization - Uses Original Path

**Large table tests (8 tests):**
37. Large Table - Generate Via Python (`openpyxl` row duplication, 150K+ rows)
38. Large Table - Filter Rows Truncation (verify `truncated: true`)
39. Large Table - Filter Rows With Force (no truncation)
40. Large Table - Summarize Truncation
41. Large Table - Search Truncation
42. Large Table - GroupBy Truncation
43. Large Table - PivotSummary Truncation
44. Large Table - Cleanup (remove all generated test files)

> **Important:** The large table tests (35-42) require `openpyxl` to be installed. If not available, install with `pip install openpyxl`. The large table is generated during the test and cleaned up afterward - no large files are shipped with the plugin.

Record pass/fail for each test.

### Step 5: Run JSON Tests

Execute tests from `<skill_path>/test_cases/json_tests.md`:

1. `jsonExtract` - Simple object
2. `jsonExtract` - Array
3. `jsonExtract` - Nested object
4. `jsonExtract` - JSON in markdown code block
5. `jsonExtract` - Return all mode
6. `jsonExtract` - File not found error
7. `jsonValidate` - Valid data
8. `jsonValidate` - Invalid data
9. `jsonValidate` - Schema from file
10. `jsonInfer` - Object inference
11. `jsonInfer` - Array inference
12. `jsonInfer` - Strict mode

Record pass/fail for each test.

### Step 6: Run Misc Tests

Execute tests from `<skill_path>/test_cases/misc_tests.md`:

1. `blockingTimer` - 1 second delay
2. `blockingTimer` - Zero delay
3. `calculator` - Basic arithmetic (2 + 3 * 4)
4. `calculator` - Power (2 ^ 10)
5. `calculator` - Brackets ((2 + 3) * 4)
6. `calculator` - Scientific notation (1e3 + 500)
7. `calculator` - Division by zero
8. `calculator` - Invalid syntax (2(3))
9. `calculator` - Precision (10 / 3 with precision 2)

Record pass/fail for each test.

### Step 7: Run Skill Tests

Execute tests from `<skill_path>/test_cases/skill_tests.md`:

1. Load `demo-skill` - Verify content returned
2. Load `bioresearcher-core` - Verify allowedTools present
3. Execute demo-skill script (no Question tool)
4. Test nonexistent skill error

**Skip these skills (use Question tool):**
- `python-setup-uv`
- `long-table-summary`
- `env-jsonc-setup`
- `pubmed-weekly`

### Step 8: Generate Report

Create `.bioresearcher-tests/test_report.md` with:

```markdown
# BioResearcher Plugin Test Report

**Run Date:** <timestamp>
**Total Tests:** <count>
**Passed:** <count>
**Failed:** <count>

## Summary by Category

| Category | Passed | Failed |
|----------|--------|--------|
| Parser   | X/Y    | Z      |
| Table    | X/Y    | Z      |
| JSON     | X/Y    | Z      |
| Misc     | X/Y    | Z      |
| Skills   | X/Y    | Z      |

## Skipped Tests

### Database Tools (Not Tested)
- `dbQuery` - Requires live database connection
- `dbListTables` - Requires live database connection
- `dbDescribeTable` - Requires live database connection

### Skills with User Interaction (Metadata Only)
- `python-setup-uv` - Uses Question tool
- `long-table-summary` - Uses Question tool
- `env-jsonc-setup` - Uses Question tool
- `pubmed-weekly` - Uses Question tool

## Failed Tests

<For each failed test:>
### <Category>: <Test Name>
- **Tool:** `<tool_name>`
- **Expected:** <expected>
- **Actual:** <actual>
- **Error:** <error if any>

## Detailed Results

| Test | Tool | Status |
|------|------|--------|
| <name> | `<tool>` | PASS/FAIL |
```

## Test Case Format

Each test case follows this format:

```markdown
## Test: <test_name>
- Tool: <tool_name>
- Input:
  ```json
  {<input_params>}
  ```
- Validators:
  - <validation_rule>
- Expected: <expected_outcome>
```

## Validation Rules

| Rule | Description |
|------|-------------|
| `success_is_true` | Result has `success: true` |
| `success_is_false` | Result has `success: false` |
| `file_exists` | Output file exists |
| `json_valid` | Output is valid JSON |
| `stats.total === N` | Stats total equals N |
| `array_length >= N` | Array has at least N items |
| `contains_string("x")` | Output contains string |
| `error.code === "X"` | Error has specific code |
| `result === N` | Result equals N |

### Step 9: Cleanup (Optional)

Remove test workspace:

```bash
rm -rf .bioresearcher-tests/
```
