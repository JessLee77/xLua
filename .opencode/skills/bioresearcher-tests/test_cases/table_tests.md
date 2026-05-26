# Table Tool Tests

## Basic Functionality Tests

## Test: List Sheets
- Tool: tableListSheets
- Input:
  ```json
  {"file_path": ".bioresearcher-tests/workspace/table_sample.xlsx"}
  ```
- Validators:
  - has sheets array
  - array_length >= 1
- Expected: List of sheet names

## Test: Get Sheet Preview
- Tool: tableGetSheetPreview
- Input:
  ```json
  {"file_path": ".bioresearcher-tests/workspace/table_sample.xlsx"}
  ```
- Validators:
  - has preview array
  - has total_rows
- Expected: First 6 rows preview

## Test: Get Headers
- Tool: tableGetHeaders
- Input:
  ```json
  {"file_path": ".bioresearcher-tests/workspace/table_sample.xlsx"}
  ```
- Validators:
  - has headers array
  - headers includes "Name"
- Expected: Column headers

## Test: Get Cell
- Tool: tableGetCell
- Input:
  ```json
  {"file_path": ".bioresearcher-tests/workspace/table_sample.xlsx", "cell_address": "A1"}
  ```
- Validators:
  - has value
  - has type
- Expected: Cell A1 value

## Test: Get Range
- Tool: tableGetRange
- Input:
  ```json
  {"file_path": ".bioresearcher-tests/workspace/table_sample.xlsx", "range": "A1:C3"}
  ```
- Validators:
  - has data array
  - rows === 3
  - columns === 3
- Expected: 3x3 data array

## Test: Filter Rows
- Tool: tableFilterRows
- Input:
  ```json
  {"file_path": ".bioresearcher-tests/workspace/table_sample.xlsx", "column": "Age", "operator": ">", "value": 25, "max_results": 100}
  ```
- Validators:
  - has matched_rows
  - has total_matches_found
  - has returned_count
- Expected: Filtered rows where Age > 25 with new response fields

## Test: Search
- Tool: tableSearch
- Input:
  ```json
  {"file_path": ".bioresearcher-tests/workspace/table_sample.xlsx", "search_term": "Active", "max_results": 50}
  ```
- Validators:
  - has results array
  - has total_matches_found
  - has returned_count
- Expected: Cells containing "Active" with new response fields

## Test: Summarize
- Tool: tableSummarize
- Input:
  ```json
  {"file_path": ".bioresearcher-tests/workspace/table_sample.xlsx", "columns": ["Age", "Score"]}
  ```
- Validators:
  - has summaries object
- Expected: Statistical summary with sum, avg, min, max, std_dev

## Test: Group By
- Tool: tableGroupBy
- Input:
  ```json
  {"file_path": ".bioresearcher-tests/workspace/table_sample.xlsx", "group_column": "Category", "agg_column": "Score", "agg_type": "avg"}
  ```
- Validators:
  - has groups object
- Expected: Grouped averages by Category

## Test: Create File
- Tool: tableCreateFile
- Input:
  ```json
  {"file_path": ".bioresearcher-tests/workspace/output_created.xlsx", "sheet_name": "TestData", "data": [{"Name": "Alice", "Age": 30}, {"Name": "Bob", "Age": 25}]}
  ```
- Validators:
  - success_is_true
  - rows_created === 2
- Expected: New Excel file created with 2 rows

## Test: Append Rows
- Tool: tableAppendRows
- Prerequisite: Test "Create File" must pass first
- Input:
  ```json
  {"file_path": ".bioresearcher-tests/workspace/output_created.xlsx", "rows": [{"Name": "Charlie", "Age": 35}]}
  ```
- Validators:
  - success_is_true
  - rows_appended === 1
- Expected: Row appended to existing file

## Test: Update Cell
- Tool: tableUpdateCell
- Prerequisite: Test "Create File" must pass first
- Input:
  ```json
  {"file_path": ".bioresearcher-tests/workspace/output_created.xlsx", "cell_address": "A1", "value": "UpdatedName"}
  ```
- Validators:
  - success_is_true
- Expected: Cell A1 updated to "UpdatedName"

## Test: Pivot Summary
- Tool: tablePivotSummary
- Input:
  ```json
  {"file_path": ".bioresearcher-tests/workspace/table_sample.xlsx", "row_field": "Category", "col_field": "Status", "value_field": "Score", "agg": "sum"}
  ```
- Validators:
  - has pivot object
  - has columns array
- Expected: Pivot table with Category rows, Status columns, Score sums

## Error / Negative Tests

## Test: Nonexistent File
- Tool: tableListSheets
- Input:
  ```json
  {"file_path": ".bioresearcher-tests/workspace/nonexistent.xlsx"}
  ```
- Validators:
  - contains_string("Error")
- Expected: Error response for file not found

## Test: Invalid Cell Address
- Tool: tableGetCell
- Input:
  ```json
  {"file_path": ".bioresearcher-tests/workspace/table_sample.xlsx", "cell_address": "INVALID"}
  ```
- Validators:
  - contains_string("Error")
  - contains_string("Invalid cell address")
- Expected: Error response with descriptive message

## Test: No Match Filter
- Tool: tableFilterRows
- Input:
  ```json
  {"file_path": ".bioresearcher-tests/workspace/table_sample.xlsx", "column": "Age", "operator": ">", "value": 999999, "max_results": 100}
  ```
- Validators:
  - has total_matches_found
  - has returned_count
  - has matched_rows
- Expected: Zero matches returned (valid query with no matching rows)

## Test: Nonexistent Column
- Tool: tableSummarize
- Input:
  ```json
  {"file_path": ".bioresearcher-tests/workspace/table_sample.xlsx", "columns": ["NonexistentColumn"]}
  ```
- Validators:
  - has summaries object
- Expected: Empty summaries (graceful handling)

## Test: Out of Bounds Range
- Tool: tableGetRange
- Input:
  ```json
  {"file_path": ".bioresearcher-tests/workspace/table_sample.xlsx", "range": "Z999:ZZ999"}
  ```
- Validators:
  - has data array
- Expected: Empty data array (out of bounds handled)

## Phase 2 Correctness Tests

## Test: Pivot Avg Numeric-Only Denominator - Setup
- Tool: tableCreateFile
- Input:
  ```json
  {"file_path": ".bioresearcher-tests/workspace/pivot_avg_test.xlsx", "sheet_name": "Sheet1", "data": [{"Group": "A", "Type": "X", "Val": 10}, {"Group": "A", "Type": "X", "Val": ""}, {"Group": "A", "Type": "X", "Val": 30}, {"Group": "B", "Type": "Y", "Val": 20}, {"Group": "B", "Type": "Y", "Val": 40}]}
  ```
- Validators:
  - success_is_true
- Expected: File created for pivot avg test

## Test: Pivot Avg Numeric-Only Denominator - Verify
- Tool: tablePivotSummary
- Prerequisite: Test "Pivot Avg Numeric-Only Denominator - Setup" must pass first
- Input:
  ```json
  {"file_path": ".bioresearcher-tests/workspace/pivot_avg_test.xlsx", "row_field": "Group", "col_field": "Type", "value_field": "Val", "agg": "avg"}
  ```
- Validators:
  - has pivot object
- Expected: Group A avg = 20.0 (10+30 divided by 2, not 3)

## Test: Pivot Max Handles Negative Values - Setup
- Tool: tableCreateFile
- Input:
  ```json
  {"file_path": ".bioresearcher-tests/workspace/pivot_neg_test.xlsx", "sheet_name": "Sheet1", "data": [{"Group": "A", "Val": -5}, {"Group": "A", "Val": -10}, {"Group": "A", "Val": 3}]}
  ```
- Validators:
  - success_is_true
- Expected: File created for pivot neg test

## Test: Pivot Max Handles Negative Values - Verify
- Tool: tablePivotSummary
- Prerequisite: Test "Pivot Max Handles Negative Values - Setup" must pass first
- Input:
  ```json
  {"file_path": ".bioresearcher-tests/workspace/pivot_neg_test.xlsx", "row_field": "Group", "col_field": "Group", "value_field": "Val", "agg": "max"}
  ```
- Validators:
  - has pivot object
- Expected: Max is 3, not 0

## Test: CreateFile Overwrite Guard
- Prerequisite: Test "Create File" must pass first (output_created.xlsx exists)
- Tool: tableCreateFile
- Input:
  ```json
  {"file_path": ".bioresearcher-tests/workspace/output_created.xlsx", "sheet_name": "Sheet1", "data": [{"Name": "Override"}]}
  ```
- Validators:
  - contains_string("already exists")
  - contains_string("overwrite: true")
- Expected: Error because file exists and overwrite is not set

## Test: CreateFile Overwrite Succeeds
- Prerequisite: Test "CreateFile Overwrite Guard" must run first
- Tool: tableCreateFile
- Input:
  ```json
  {"file_path": ".bioresearcher-tests/workspace/output_created.xlsx", "sheet_name": "Sheet1", "data": [{"Name": "Overwritten"}], "overwrite": true}
  ```
- Validators:
  - success_is_true
  - rows_created === 1
- Expected: File overwritten successfully

## Test: FilterRows New Response Fields
- Tool: tableFilterRows
- Input:
  ```json
  {"file_path": ".bioresearcher-tests/workspace/table_sample.xlsx", "column": "Age", "operator": ">=", "value": 0, "max_results": 5}
  ```
- Validators:
  - has total_matches_found
  - has returned_count
  - has matched_rows
- Expected: Response includes total_matches_found and returned_count (replaces old total_matches)

## Test: UpdateCell Invalid Address Path Traversal
- Tool: tableUpdateCell
- Input:
  ```json
  {"file_path": ".bioresearcher-tests/workspace/output_created.xlsx", "cell_address": "../../etc/passwd", "value": "test"}
  ```
- Validators:
  - contains_string("Error")
  - contains_string("Invalid cell address")
- Expected: Error response rejecting path traversal in cell address

## Test: UpdateCell Null Value
- Prerequisite: Test "CreateFile Overwrite Succeeds" must pass first
- Tool: tableUpdateCell
- Input:
  ```json
  {"file_path": ".bioresearcher-tests/workspace/output_created.xlsx", "cell_address": "B1", "value": null}
  ```
- Validators:
  - success_is_true
- Expected: Cell updated with null value without error

## Test: CreateFile Invalid Data Schema
- Tool: tableCreateFile
- Input:
  ```json
  {"file_path": ".bioresearcher-tests/workspace/invalid_data.xlsx", "sheet_name": "Sheet1", "data": "not an array"}
  ```
- Validators:
  - contains_string("Error")
  - contains_string("must be an array")
- Expected: Error because data is a string, not an array

## Hardening Feature Tests

## Test: Force Parameter - Filter Rows
- Tool: tableFilterRows
- Input:
  ```json
  {"file_path": ".bioresearcher-tests/workspace/table_sample.xlsx", "column": "Age", "operator": ">", "value": 25, "max_results": 100, "force": true}
  ```
- Validators:
  - has matched_rows
  - has total_matches_found
  - has returned_count
- Expected: Same results as Filter Rows without force (regression check)

## Test: Force Parameter - Summarize
- Tool: tableSummarize
- Input:
  ```json
  {"file_path": ".bioresearcher-tests/workspace/table_sample.xlsx", "columns": ["Age", "Score"], "force": true}
  ```
- Validators:
  - has summaries object
- Expected: Same summaries as Summarize without force (regression check)

## Test: File Size Limit - Reject Large File
- Setup: Run the following Bash command to create a 55MB dummy file:
  ```bash
  dd if=/dev/urandom of=.bioresearcher-tests/workspace/large_dummy.xlsx bs=1M count=55 2>/dev/null && echo "Created large file"
  ```
- Tool: tableListSheets
- Input:
  ```json
  {"file_path": ".bioresearcher-tests/workspace/large_dummy.xlsx"}
  ```
- Validators:
  - contains_string("Error")
  - contains_string("exceeding")
  - contains_string("force: true")
- Expected: Error rejecting file over 50MB limit with guidance to use force

## Test: File Size Limit - Bypass With Force
- Prerequisite: Test "File Size Limit - Reject Large File" must run first (large_dummy.xlsx exists)
- Tool: tableListSheets
- Input:
  ```json
  {"file_path": ".bioresearcher-tests/workspace/large_dummy.xlsx", "force": true}
  ```
- Validators:
  - has sheets array
- Expected: Size check bypassed with force: true; tool processed the file (parser may return partial results for corrupt data)
- Cleanup: Run `rm .bioresearcher-tests/workspace/large_dummy.xlsx`

## Test: Range Limit - Reject Oversized Range
- Tool: tableGetRange
- Input:
  ```json
  {"file_path": ".bioresearcher-tests/workspace/table_sample.xlsx", "range": "A1:ZZZ1000"}
  ```
- Validators:
  - contains_string("Error")
  - contains_string("exceeds")
  - contains_string("force: true")
- Expected: Error rejecting range exceeding 50K cell limit

## Test: Range Limit - Bypass With Force
- Tool: tableGetRange
- Input:
  ```json
  {"file_path": ".bioresearcher-tests/workspace/table_sample.xlsx", "range": "A1:ZZZ1000", "force": true}
  ```
- Validators:
  - has data array
- Expected: Data array returned (mostly empty cells, but range limit bypassed)

## Test: Error Sanitization - No Resolved Paths
- Tool: tableGetCell
- Input:
  ```json
  {"file_path": ".bioresearcher-tests/workspace/nonexistent_file.xlsx", "cell_address": "A1"}
  ```
- Validators:
  - contains_string("Error")
  - not contains_string("/home/")
  - not contains_string("/root/")
  - not contains_string("/tmp/")
- Expected: Error message does not leak absolute filesystem paths

## Test: Error Sanitization - Uses Original Path
- Tool: tableListSheets
- Input:
  ```json
  {"file_path": ".bioresearcher-tests/workspace/nonexistent_file.xlsx"}
  ```
- Validators:
  - contains_string("Error")
  - contains_string(".bioresearcher-tests/workspace/nonexistent_file.xlsx")
- Expected: Error message references the original user-provided file path

## Large Table Tests

## Test: Large Table - Generate Via Python
- Setup: Run the following Python command to generate a table with 150K+ rows by duplicating the sample data:
  ```bash
  pip install openpyxl -q 2>/dev/null; python3 -c "
  import openpyxl
  wb = openpyxl.load_workbook('.bioresearcher-tests/workspace/table_sample.xlsx')
  ws = wb.active
  rows = list(ws.iter_rows(values_only=True))
  data_rows = rows[1:]
  if not data_rows:
      print('ERROR: no data rows found')
  else:
      target = 150000
      for i in range(target // len(data_rows)):
          for row in data_rows:
              ws.append(row)
      wb.save('.bioresearcher-tests/workspace/large_table.xlsx')
      print(f'Created table with {ws.max_row} rows')
  "
  ```
- Validators:
  - contains_string("Created table with")
- Expected: large_table.xlsx created with 150K+ rows

## Test: Large Table - Filter Rows Truncation
- Prerequisite: Test "Large Table - Generate Via Python" must pass first
- Tool: tableFilterRows
- Input:
  ```json
  {"file_path": ".bioresearcher-tests/workspace/large_table.xlsx", "column": "Age", "operator": ">", "value": 0, "max_results": 50}
  ```
- Validators:
  - has matched_rows
  - has total_matches_found
  - has returned_count
  - truncated === true
  - contains_string("Set force: true")
- Expected: Results truncated at row cap with guidance message

## Test: Large Table - Filter Rows With Force
- Prerequisite: Test "Large Table - Generate Via Python" must pass first
- Tool: tableFilterRows
- Input:
  ```json
  {"file_path": ".bioresearcher-tests/workspace/large_table.xlsx", "column": "Age", "operator": ">", "value": 0, "max_results": 50, "force": true}
  ```
- Validators:
  - has matched_rows
  - has total_matches_found
  - has returned_count
- Expected: All rows processed, no truncation field

## Test: Large Table - Summarize Truncation
- Prerequisite: Test "Large Table - Generate Via Python" must pass first
- Tool: tableSummarize
- Input:
  ```json
  {"file_path": ".bioresearcher-tests/workspace/large_table.xlsx", "columns": ["Age"]}
  ```
- Validators:
  - has summaries object
  - truncated === true
  - has processed_rows
  - contains_string("Set force: true")
- Expected: Summary computed on capped rows with truncation notice

## Test: Large Table - Search Truncation
- Prerequisite: Test "Large Table - Generate Via Python" must pass first
- Tool: tableSearch
- Input:
  ```json
  {"file_path": ".bioresearcher-tests/workspace/large_table.xlsx", "search_term": "Active", "max_results": 10}
  ```
- Validators:
  - has results array
  - has total_matches_found
  - has returned_count
  - truncated === true
  - has rows_scanned
- Expected: Search scanned up to 100K rows, counted all matches, returned limited results

## Test: Large Table - GroupBy Truncation
- Prerequisite: Test "Large Table - Generate Via Python" must pass first
- Tool: tableGroupBy
- Input:
  ```json
  {"file_path": ".bioresearcher-tests/workspace/large_table.xlsx", "group_column": "Category", "agg_column": "Score", "agg_type": "avg"}
  ```
- Validators:
  - has groups object
  - truncated === true
  - has processed_rows
- Expected: GroupBy truncated at row cap

## Test: Large Table - PivotSummary Truncation
- Prerequisite: Test "Large Table - Generate Via Python" must pass first
- Tool: tablePivotSummary
- Input:
  ```json
  {"file_path": ".bioresearcher-tests/workspace/large_table.xlsx", "row_field": "Category", "col_field": "Status", "value_field": "Score", "agg": "sum"}
  ```
- Validators:
  - has pivot object
  - truncated === true
  - has processed_rows
- Expected: Pivot truncated at row cap

## Test: Large Table - Cleanup
- Setup: Run the following Bash command to remove the large table:
  ```bash
  rm -f .bioresearcher-tests/workspace/large_table.xlsx .bioresearcher-tests/workspace/large_dummy.xlsx .bioresearcher-tests/workspace/pivot_avg_test.xlsx .bioresearcher-tests/workspace/pivot_neg_test.xlsx .bioresearcher-tests/workspace/invalid_data.xlsx .bioresearcher-tests/workspace/output_created.xlsx && echo "Cleanup done"
  ```
- Validators:
  - contains_string("Cleanup done")
- Expected: All generated test files removed
