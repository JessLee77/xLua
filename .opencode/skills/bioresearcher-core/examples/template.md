# Batch Data Summarization Task

## Input File
- Full path: `{file_path}`
- Sheet name: `{sheet_name}`

## Row Range
- Batch number: {batch_number}
- Start row: {row_start}
- End row: {row_end}

## Summarization Instructions

Extract the following fields from each row:

{instructions_json}

## Output Format

Your output must be a valid JSON file with this structure:

```json
{
  "batch_number": {batch_number},
  "row_count": <number_of_rows_processed>,
  "summaries": [
    {
      "row_number": <row_number>,
      <field_1>: "<extracted_value>",
      <field_2>: "<extracted_value>"
    }
  ]
}
```

**Important:** The JSON keys for extracted values must match the field names specified in the Summarization Instructions.

## Instructions

1. Read the specified row range from the input file using the `tableGetRange` tool
2. For each row, extract the requested fields according to the instructions above
3. Map the extracted values to the JSON keys specified in the instructions
4. Generate concise summaries based on the extracted data
5. Save your output to: `{output_file}`

## Output File Path
Full path: `{output_file}`

**CRITICAL:** Write your final output as a markdown file (.md) containing ONLY the JSON object (no additional text or explanation).
