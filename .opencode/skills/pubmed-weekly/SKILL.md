---
name: pubmed-weekly
description: Download PubMed daily update xml.gz files from the past week from NCBI FTP server
allowedTools:
  - Bash
  - Read
  - Write
  - Question
  - parse_pubmed_articleSet
---

# PubMed Weekly Daily Updates Download

This skill downloads PubMed daily update xml.gz files from the past week (Monday-Sunday).

## Workflow Overview

1. **Python Environment Setup** (automatic): Checks for uv, installs via `python-setup-uv` skill if needed
2. **Date Calculation**: Calculates the past week's date range (Monday-Sunday)
3. **FTP Listing**: Fetches available xml.gz files from NCBI FTP server
4. **Filtering**: Filters files to include only those from the past week
5. **Download**: Downloads filtered files with retry logic (max 3 attempts per file)

## Prerequisites
- Internet connection
- Access to NCBI FTP server
- uv package manager (will be automatically installed if not present)

## Integration with python-setup-uv

This skill integrates with the `python-setup-uv` skill to ensure Python environment is properly configured.

### Prerequisite Check

Before starting the download process:

1. **Check if uv is installed:**
    ```bash
    if [ -f "uv" ] || [ -f "uv.exe" ]; then
      echo "uv already installed"
    else
      echo "uv not found, setting up..."
    fi
    ```

2. **If uv is not installed:**
   - Load the `python-setup-uv` skill using the skill tool
   - Follow all steps EXACTLY as specified in the python-setup-uv skill
   - Wait for uv installation to complete
   - Continue with this skill's Step 1 below

3. **After uv is installed:**
   - The bundled script `pubmed_weekly.py` will be executed using uv
   - Extract the full script path from the `<skill_files>` section in skill tool output

## Steps

Follow these steps EXACTLY as described.

### Step 1: Calculate Week Date Range

First, determine the date range for the past week (Monday through Sunday).

Extract the full path to `pubmed_weekly.py` from the `<skill_files>` section in the skill tool output.

**For Unix-like shells (Git Bash / macOS / Linux):**
```bash
uv run python <skill_path>/pubmed_weekly.py calculate_week
```

### Step 1: Calculate Week Date Range

First, determine the date range for the past week (Monday through Sunday).

Extract the full path to `pubmed_weekly.py` from the `<skill_files>` section in the skill tool output.

### Step 1: Calculate Week Date Range

First, determine the date range for the past week (Monday through Sunday).

**For Unix-like shells (Git Bash / macOS / Linux):**
```bash
uv run python <skill_path>/pubmed_weekly.py calculate_week
```

**For Windows cmd.exe:**
```bash
uv.exe run python <skill_path>\pubmed_weekly.py calculate_week
```

Replace `<skill_path>` with the full directory path extracted from `<skill_files>`.

This will output the week folder name in format `YYYYMMDD-YYYYMMDD`.

**Expected output format:**
```
20250217-20250223
```

### Step 2: Create Download Directory

The `download_file` command will automatically create the directory structure when needed. No manual directory creation is required.

### Step 3: Fetch FTP File List

Extract the full path to `pubmed_weekly.py` from the `<skill_files>` section and fetch the list of files from the NCBI FTP server.

**For Unix-like shells:**
```bash
uv run python <skill_path>/pubmed_weekly.py fetch_files
```

**For Windows cmd.exe:**
```bash
uv.exe run python <skill_path>\pubmed_weekly.py fetch_files
```

Replace `<skill_path>` with the full directory path extracted from `<skill_files>`.

This will list all daily update xml.gz files available on the FTP server.

**Expected output:**
```
pubmed24n1234.xml.gz pubmed24n1235.xml.gz pubmed24n1236.xml.gz
```

### Step 4: Filter Files for Past Week

Extract the full path to `pubmed_weekly.py` from the `<skill_files>` section and filter the file list for the past week's daily updates.

**For Unix-like shells:**
```bash
uv run python <skill_path>/pubmed_weekly.py filter_files "<WEEK>" "<FILE_LIST>"
```

**For Windows cmd.exe:**
```bash
uv.exe run python <skill_path>\pubmed_weekly.py filter_files "<WEEK>" "<FILE_LIST>"
```

Where:
- `<skill_path>` is the full directory path extracted from `<skill_files>`
- `<WEEK>` is the week folder name (e.g., `20250217-20250223`)
- `<FILE_LIST>` is the output from Step 3 (space-separated filenames, use quotes)

This will return a space-separated list of xml.gz files from the past week.

**Expected output:**
```
pubmed24n1234.xml.gz pubmed24n1235.xml.gz pubmed24n1236.xml.gz
```

### Step 5: Download Files with Retry

Extract the full path to `pubmed_weekly.py` from the `<skill_files>` section and for each file in the filtered list, download to the target directory with retry logic.

**For Unix-like shells:**
```bash
for file in <FILE_LIST>; do
  uv run python <skill_path>/pubmed_weekly.py download_file <WEEK> $file
done
```

**For Windows cmd.exe:**
```bash
for %f in (<FILE_LIST>) do uv.exe run python <skill_path>\pubmed_weekly.py download_file <WEEK> %f
```

Where:
- `<skill_path>` is the full directory path extracted from `<skill_files>`
- `<FILE_LIST>` is the space-separated list from Step 4
- `<WEEK>` is the week folder name

Replace `<FILE_LIST>` with the space-separated list from Step 4.

**Download behavior:**
- Downloads one file at a time
- Retries up to 3 times if download fails
- Waits 2 seconds between retry attempts
- After 3 failed attempts, asks user whether to abort

**If a download fails after 3 retries:**
Use the question tool to ask:
- "Abort remaining downloads?" (options: "Yes" / "No")

If user selects "Yes", stop the process and report summary.
If user selects "No", skip the failed file and continue with the next one.

### Step 6: Verify Downloads

After all downloads complete (or are aborted), verify the downloaded files:

```bash
ls -lh .download/pubmed-daily/<WEEK>/
```

Count the number of files downloaded and report the summary to the user.

### Step 7: Parse XML Files to Individual Excel Sheets

For each downloaded `.xml.gz` file in `.download/pubmed-daily/<WEEK>/`, use the `parse_pubmed_articleSet` tool to convert it to an Excel file.

**Tool invocation pattern:**

```
parse_pubmed_articleSet 
  filePath="<working_dir>/.download/pubmed-daily/<WEEK>/<filename>.xml.gz"
  outputMode="excel"
  outputFileName="<filename>.xlsx"
  outputDir="<working_dir>/.download/pubmed-daily/<WEEK>"
```

**Example:**
For file `pubmed24n1234.xml.gz` in week `20250217-20250223`:
- Input: `.download/pubmed-daily/20250217-20250223/pubmed24n1234.xml.gz`
- Output: `.download/pubmed-daily/20250217-20250223/pubmed24n1234.xlsx`

**Process:**
1. List all `.xml.gz` files in the week directory
2. For each file, call `parse_pubmed_articleSet` with `outputMode="excel"`
3. The output Excel file will be saved in the same directory as the input
4. Report parsing statistics (articles processed, any errors)

### Step 8: Combine Individual Excel Files

After all individual Excel files are created, combine them into a single `combined.xlsx` file using the Python script.

Extract the full path to `pubmed_weekly.py` from the `<skill_files>` section.

**For Unix-like shells (Git Bash / macOS / Linux):**
```bash
uv run python <skill_path>/pubmed_weekly.py combine_excel "<WEEK>"
```

**For Windows cmd.exe:**
```bash
uv.exe run python <skill_path>\pubmed_weekly.py combine_excel "<WEEK>"
```

Where:
- `<skill_path>` is the full directory path extracted from `<skill_files>`
- `<WEEK>` is the actual week folder name (e.g., `20250217-20250223`)

**Expected behavior:**
- Finds all `.xlsx` files in the week directory (excluding `combined.xlsx`)
- Reads each file and combines all rows
- Writes `combined.xlsx` with all articles from all files
- Returns summary: total rows, source files processed

**Output location:**
`.download/pubmed-daily/<WEEK>/combined.xlsx`

## Python Script Details

The skill includes a bundled Python script at `pubmed_weekly.py` with the following functions:

### 1. `calculate_week()` - Calculate week date range

Returns week folder name in format `YYYYMMDD-YYYYMMDD` for the past week (Monday-Sunday).

### 2. `fetch_files()` - Fetch FTP file list

Returns list of all xml.gz filenames from NCBI FTP server.

### 3. `filter_files(week_name, file_list)` - Filter files for the week

Parameters:
- `week_name`: Week folder name (e.g., `20250217-20250223`)
- `file_list`: List of filenames from FTP server

Returns: Space-separated list of xml.gz files that fall within the date range.

### 4. `download_file(week_name, filename)` - Download single file with retry

Parameters:
- `week_name`: Week folder name
- `filename`: XML.gz filename to download

Behavior:
- Downloads from `ftp://ftp.ncbi.nlm.nih.gov/pubmed/updatefiles/<filename>`
- Saves to `.download/pubmed-daily/<week_name>/<filename>` in current working directory
- Creates directory structure if needed
- Retries up to 3 times on failure
- Returns exit code 0 on success, 1 on failure (after all retries)

### 5. `combine_excel(week_name)` - Combine Excel files into combined.xlsx

Parameters:
- `week_name`: Week folder name (e.g., `20250217-20250223`)

Behavior:
- Searches for all `.xlsx` files in `.download/pubmed-daily/<week_name>/` in current working directory
- Excludes `combined.xlsx` from the list
- Reads each Excel file and combines all rows
- Creates `combined.xlsx` with all articles merged
- Returns JSON with: success, total_rows, source_files, output_file

## Output Summary

After completion, provide the user with:

1. Week date range processed
2. Number of files found for the week
3. Number of files successfully downloaded
4. Number of files failed to download (if any)
5. Download location: `.download/pubmed-daily/<WEEK>/`
6. Number of XML files parsed to Excel (Step 7)
7. Total articles in combined.xlsx (Step 8)
8. Combined file location: `.download/pubmed-daily/<WEEK>/combined.xlsx`

## Notes

- This skill automatically checks for and installs uv using the `python-setup-uv` skill if not present
- The Python script is bundled with this skill at `pubmed_weekly.py`
- All Python commands use the full script path extracted from `<skill_files>` section
- The script uses `os.getcwd()` to determine the working directory, which is naturally the opencode working directory
- All output files (downloads, Excel files) are created in the opencode working directory
- The FTP server path is: `ftp://ftp.ncbi.nlm.nih.gov/pubmed/updatefiles/`
- Only `.xml.gz` files are downloaded
- Downloads are sequential (one file at a time)
- Retry logic includes 2-second delays between attempts
- User has control to abort on persistent failures
- The script uses Python's built-in `urllib.request` for FTP operations
- The `combine_excel` command requires `openpyxl` package (auto-installed via uv)
- Skill directory path is extracted from `<skill_files>` section for script location
- Windows with Git Bash: Follow Unix-like shell instructions
- Windows cmd.exe: Use `uv.exe run python` syntax
- Step 7 uses the `parse_pubmed_articleSet` tool for XML to Excel conversion
- Step 8 combines all individual Excel files into a single `combined.xlsx`
