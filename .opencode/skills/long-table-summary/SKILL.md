---
name: long-table-summary
description: Batch-process large tables using parallel subagents for summarization
allowedTools:
  - Bash
  - Read
  - Write
  - Question
  - Task
  - tableListSheets
  - tableGetSheetPreview
  - tableGetHeaders
  - tableGetRange
  - jsonValidate
  - jsonInfer
---

# Long Table Summary

This skill enables batched processing of large tables (xlsx, csv) using parallel subagents.

## Workflow Overview

1. **Table Discovery**: Interview user to locate table file and confirm existence
2. **Sheet Selection**: If multiple sheets, prompt user to choose one
3. **Summarization Instructions**: Interview user for summary requirements (JSON format)
4. **Instruction Refinement**: Iterate to refine summarization instructions
5. **Batch Size Prompting**: Use `question` tool to ask user for batch size
6. **Topic Generation**: Autogenerate topic name from filename + comprehension of JSON
7. **Template Creation**: Draft subagent prompt template with JSON output schema
8. **Template Writing**: Write finalized template
9. **Prompt Generation**: Use Python script to generate batch-specific prompts
10. **Parallel Processing**: Launch subagents in waves of 3
11. **Progress Monitoring**: Report every 3 completed subagents
12. **Retry Failed Batches**: Up to 3 retry attempts for failed batches
13. **Output Combination**: Automatically combine all JSON outputs into single table

## Steps

### Step 1: Interview User for Table Location

Use `question` tool to ask for table file path:

**Question:**
- "What is the full path to the table file you want to process?" (supports .xlsx, .csv, .ods)

### Step 2: Confirm Table Existence and List Sheets

Use `tableListSheets` tool to verify:

```bash
tableListSheets(file_path="<user_provided_path>")
```

If the file doesn't exist or is invalid, prompt user to verify the path.

### Step 3: Handle Multiple Sheets (if applicable)

**Important:** CSV files have only one sheet. Always skip this step for CSV files.

If the file is an Excel (.xlsx) or ODS (.ods) file AND there is more than one sheet, use `question` tool to ask user to choose one.

For CSV files: Use the first/only sheet name automatically (either filename returned by tableListSheets or "Sheet1" default) without asking user.

### Step 4: Get Table Metadata

Use `tableGetSheetPreview` and `tableGetHeaders` to get row count and column structure.

### Step 5: Interview User for Summarization Instructions

Use `question` tool to ask user to provide summarization instructions in JSON format.

**Question:**
- "Please provide your summarization requirements in JSON format. For each field you want extracted, specify as key the field name, and as value a brief description of what it represents."

**Show example:**
```json
{
  "species": "Species, one of Tier1/Tier2/NA. Tier1 includes human and monkey, Tier2 includes other animals. NA otherwise.",
  "topic": "Main topic, one of Oncology/Immunology/General Biology/Others."
}
```

**Additional example:**
```json
{
  "gene_mutation": "Gene mutation pattern, e.g., V600E, R173, Wild Type",
  "clinical_significance": "Clinical relevance, one of High/Medium/Low/Unknown",
  "therapeutic_target": "Is this a drug target? Answer Yes/No/Unknown"
}
```

**Instructions to user:**
- Provide any number of fields
- Each field should be a key (JSON property name) with a description as the value
- Use clear, specific descriptions that a subagent can interpret
- Include allowed values or examples if applicable

### Step 6: Summarization Instruction Refinement

After receiving user's JSON instructions, iteratively refine them.

**Question:**
- "Here's your summarization instruction template. Would you like to modify any field descriptions or add new fields?"

**Show the current JSON to user**

If user selects "No, it's correct", proceed to Step 7.

If user selects "Yes, I want to modify":
- Ask which field to modify or add
- Update the JSON accordingly
- Repeat the approval question

Continue until user explicitly confirms that the instruction JSON is correct.

### Step 6.5: Generate Output JSON Schema

Generate a JSON Schema that defines the exact output structure. All fields are required.

**Default value for unavailable data:** Use `"NA"` (string) for any field where data cannot be extracted.

**Construct example output:**

1. Start with the base structure:
```json
{
  "batch_number": 1,
  "row_count": 30,
  "summaries": [
    {
      "row_number": 2
    }
  ]
}
```

2. Add each user-specified field with an example value (use `"NA"` if the field might be empty):

For example, if user provided:
```json
{
  "species": "Species classification: Tier1/Tier2/NA",
  "topic": "Main topic: Oncology/Immunology/Other"
}
```

Construct the example output:
```json
{
  "batch_number": 1,
  "row_count": 30,
  "summaries": [
    {
      "row_number": 2,
      "species": "Tier1",
      "topic": "Oncology"
    }
  ]
}
```

**Generate schema with strict mode:**

```typescript
jsonInfer data='<example_output_json>' strict=true
```

**Save the returned schema to:**

```bash
Write file: .long-table-summary/{topic}/schema.json
Content: <schema_from_jsonInfer>
```

This schema file will be used by all subagents to validate their outputs before writing.

### Step 7: Autogenerate Topic Name

Generate the topic name by combining:
- Base filename (without extension)
- Summary words derived from manual comprehension of user's JSON

**Algorithm:**
1. Extract filename: `clinical_trials_2024_data.xlsx` → `clinical_trials_2024_data`
   - **Note:** The filename may have more than 6 words; keep the full name
2. Comprehend the overall content of user's JSON instructions:
   - Read the JSON manually to understand what it's about
   - Identify the main idea or subject matter
   - Generate summary words (maximum 6 words, lowercase, hyphenated)
   - Examples: `species-classification`, `gene-mutation`, `clinical-significance`
3. Combine with hyphens: `clinical_trials_2024_data-species-classification`
   - **Total words may exceed 6** (filename + summary words)
   - **Only the summary words part has a 6-word limit**

**Examples:**
- `clinical_trials_2024_data.xlsx` + topic about species → `clinical_trials_2024_data-species-classification`
- `literature_review_comprehensive.csv` + gene mutation analysis → `literature_review_comprehensive-gene-mutation`
- `long_descriptive_filename_multiple_words.xlsx` + immunology → `long_descriptive_filename_multiple_words-immunology`

### Step 8: Ask User for Batch Size

Use `question` tool to explicitly prompt user about batch size.

**Question:**
- "How many rows should each batch contain? Recommended default: 30 rows per batch."

User's value will be used. Calculate the number of batches needed: `ceil(total_rows / batch_size)`.

### Step 9: Calculate Batch Ranges

Example for 90 rows with 30 per batch:
- Batch 1: Rows 2-31
- Batch 2: Rows 32-61
- Batch 3: Rows 62-90

**Note:** Row 1 is the header, data starts at row 2.

### Step 10: Create Subagent Prompt Template

Create a template with `{placeholder}` format (single braces):

```markdown
# Batch Data Summarization Task

## Input File
- Path: `{file_path}`
- Sheet: `{sheet_name}`

## Row Range
- Batch: {batch_number}
- Rows: {row_start} to {row_end}

## Summarization Instructions

For each row, extract these fields:

{instructions_json}

**Default for unavailable data:** If a field cannot be extracted, use `"NA"` as the value.

## Output Structure

```json
{
  "batch_number": {batch_number},
  "row_count": <number_of_rows_in_this_batch>,
  "summaries": [
    {
      "row_number": <row_number>,
      "<field_1>": "<value_or_NA>",
      "<field_2>": "<value_or_NA>"
    }
  ]
}
```

## Output Schema

Your output must conform to this schema: `{schema_path}`

All fields are required. Use `"NA"` for unavailable values.

## Mandatory Workflow

**Step 1:** Read rows using `tableGetRange`:
```typescript
tableGetRange file_path="{file_path}" sheet_name="{sheet_name}" range="A{row_start}:Z{row_end}"
```

**Step 2:** Build JSON in memory with all required fields

**Step 3:** Validate BEFORE writing:
```typescript
jsonValidate data='<your_complete_json>' schema="{schema_path}"
```

**Step 4:** Check result:
- If `valid: true` → Go to Step 5
- If `valid: false` → Fix errors listed in `errors` array, return to Step 3

**Step 5:** Write validated JSON to `{output_file}`

Output file should contain ONLY the JSON object (no markdown, no extra text).

## Output Path
`{output_file}`
```
```

### Step 11: Create Directory Structure

```bash
mkdir -p .long-table-summary/{topic}/prompts
mkdir -p .long-table-summary/{topic}/outputs
```

### Step 12: Write Template

Write the finalized template to `.long-table-summary/{topic}/subagent_template.md`.

### Step 13: Generate Subagent Prompts

Use `generate_prompts.py`:

**Before Step 13 and Step 17:** Extract the full path to the skill directory from the `<skill_files>` section in the skill tool output. Use this path as `<skill_path>` in the commands below.

**Unix-like shells:**
```bash
uv run python <skill_path>/generate_prompts.py \
  --template .long-table-summary/{topic}/subagent_template.md \
  --output-dir .long-table-summary/{topic}/prompts \
  --num-batches {num_batches} \
  --sheet-name "{sheet_name}" \
  --file-path "{input_file}" \
  --start-row 2 \
  --batch-size {batch_size} \
  --instructions '{instructions_json}' \
  --schema-path ".long-table-summary/{topic}/schema.json"
```

**For Windows cmd.exe:**
```bash
uv.exe run python <skill_path>\generate_prompts.py ^
  --template .long-table-summary\{topic}\subagent_template.md ^
  --output-dir .long-table-summary\{topic}\prompts ^
  --num-batches {num_batches} ^
  --sheet-name "{sheet_name}" ^
  --file-path "{input_file}" ^
  --start-row 2 ^
  --batch-size {batch_size} ^
  --instructions "{instructions_json}" ^
  --schema-path ".long-table-summary\{topic}\schema.json"
```

**Note:** The `{instructions_json}` is the user-confirmed JSON from Step 6.

### Step 14: Launch Subagents in Waves of 3

Launch subagents in waves of 3, waiting for each wave to complete before starting the next.

**Wave 1:**
```typescript
task(subagent_type="general", description="Process batch 001", prompt="Read your prompt from .long-table-summary/{topic}/prompts/batch001.md and perform the task described there exactly as written.", run_in_background=true)
task(subagent_type="general", description="Process batch 002", prompt="Read your prompt from .long-table-summary/{topic}/prompts/batch002.md and perform the task described there exactly as written.", run_in_background=true)
task(subagent_type="general", description="Process batch 003", prompt="Read your prompt from .long-table-summary/{topic}/prompts/batch003.md and perform the task described there exactly as written.", run_in_background=true)
```

**Wait for Wave 1 to complete.**

**Wave 2 (if more batches):**
```typescript
task(subagent_type="general", description="Process batch 004", prompt="Read your prompt from .long-table-summary/{topic}/prompts/batch004.md and perform the task described there exactly as written.", run_in_background=true)
task(subagent_type="general", description="Process batch 005", prompt="Read your prompt from .long-table-summary/{topic}/prompts/batch005.md and perform the task described there exactly as written.", run_in_background=true)
task(subagent_type="general", description="Process batch 006", prompt="Read your prompt from .long-table-summary/{topic}/prompts/batch006.md and perform the task described there exactly as written.", run_in_background=true)
```

**Continue** launching waves of 3 until all batches are started.

**Important:** Do NOT pass the full generated prompts directly to subagents. Always direct subagents to read their respective prompt files.

### Step 15: Monitor Progress

Every time 3 subagents complete, report progress:

**Progress report format:**
- "Progress: X/Y batches completed (Z%)"

For example:
- "Progress: 3/10 batches completed (30%)"
- "Progress: 6/10 batches completed (60%)"
- "Progress: 9/10 batches completed (90%)"
- "Progress: 10/10 batches completed (100%)"

Do NOT inspect individual subagent outputs midway.

### Step 16: Check for Missing Outputs

After all batches are done, check for missing outputs:

```bash
ls .long-table-summary/{topic}/outputs/
```

Missing files indicate subagent failure. If any are missing:

1. Ask user using the `question` tool:
   - "{number} batches failed. Retry failed batches or proceed with available outputs?"

2. **Options:**
   - "Retry failed batches"
   - "Proceed with available outputs"

3. **If user selects "Retry":**
   - Re-launch subagent with same prompt file for each failed batch

4. **If user selects "Proceed":**
   - Continue to Step 17 with available outputs

Note: Since subagents validate their outputs before writing, existing files should contain valid JSON.


### Step 17: Combine All JSON Outputs

After all batches are complete (or user stops retrying), use `combine_outputs.py`:

**Before Step 13 and Step 17:** Extract the full path to the skill directory from the `<skill_files>` section in the skill tool output. Use this path as `<skill_path>` in the commands below.

**Unix-like shells:**
```bash
uv run python <skill_path>/combine_outputs.py \
  --input-dir .long-table-summary/{topic}/outputs \
  --output-file .long-table-summary/{topic}/combined_summary.xlsx
```

**For Windows cmd.exe:**
```bash
uv.exe run python <skill_path>\combine_outputs.py ^
  --input-dir .long-table-summary\{topic}\outputs ^
  --output-file .long-table-summary\{topic}\combined_summary.xlsx
```

**Expected output:**
- A single Excel file with all summaries combined
- Table format: row_number, <field_1>, <field_2>, ... (all user-requested fields)
- One row per input table row
- Sorted by row_number ascending

**Script behavior:**
- Reads all `batch*.md` files from the output directory
- Parses JSON from each file
- Dynamically determines all columns from the first batch's summaries (user's JSON keys)
- Merges all summaries into a structured table
- Writes the combined Excel file

### Step 18: Final Report

Provide user with:
1. Topic name used
2. Total batches processed
3. Number of retries (if any)
4. Combined output location
5. Row count in the combined file

## Python Scripts

### Script 1: `generate_prompts.py`

**Arguments:**
- `--template`: Path to subagent_template.md
- `--output-dir`: Directory for generated prompts
- `--num-batches`: Total number of batches
- `--sheet-name`: Sheet name
- `--file-path`: Full path to the input table file
- `--start-row`: Starting data row (default: 2)
- `--batch-size`: Rows per batch (default: 30)
- `--instructions`: User-confirmed JSON with summarization fields
- `--schema-path`: Path to output JSON Schema file (required)
- `--dry-run`: Validate without creating files (optional)
- `--verbose`: Enable verbose output for debugging (optional)

**Placeholders to replace:**
- `{file_path}` → Absolute input file path
- `{sheet_name}` → Sheet name
- `{batch_number}` → Batch number (001, 002, etc.)
- `{row_start}` → Start row
- `{row_end}` → End row
- `{output_file}` → Output file path
- `{instructions_json}` → User's JSON instruction (properly escaped for markdown code block)
- `{schema_path}` → Path to output JSON Schema file

### Script 2: `combine_outputs.py`

**Arguments:**
- `--input-dir`: Directory containing batch output JSON files
- `--output-file`: Path for the combined Excel output file
- `--dry-run`: Validate inputs without writing output file (optional)
- `--verbose`: Enable verbose output for debugging (optional)
- `--deduplicate`: Remove duplicate row numbers (keep first occurrence) (optional)
- `--column-order`: Column order - 'preserve' (from first batch) or 'alphabetical' (default) (optional)

**Behavior:**
1. Scan the input directory for `batch*.md` files
2. For each file, extract the JSON content
3. Dynamically determine all columns from the first batch's summaries (extract all JSON keys from the first summary, excluding `batch_number` and `row_count`)
4. Merge all summaries by row_number
5. Create an Excel file with columns: row_number, <all user fields>
6. Sort by row_number ascending
7. Write to the output path

**Error handling:**
- If no output files are found → Return error JSON
- If JSON parse fails → Log error and continue with other files
- If duplicate row numbers exist → The last write wins (or use --deduplicate flag to keep first)

## Notes

- The default batch size recommendation is 30 rows per batch
- Summarization instructions are provided as JSON with explicit field descriptions
- The topic name is autogenerated from the filename + manual comprehension of the user's JSON
  - The summary words part (derived from JSON) has a maximum of 6 words
  - The total topic name (filename + summary words) may exceed 6 words
- Subagent type is always `general`
- Subagents are launched in waves of 3 (not 5)
- Progress is reported every 3 completions
- Failed batches are retried up to 3 times
- Output is always combined automatically via the Python script
- The main agent does NOT manually read the JSON outputs
