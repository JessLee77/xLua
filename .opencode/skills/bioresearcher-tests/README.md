# BioResearcher Tests Skill

Comprehensive test suite for the bioresearcher plugin.

## Quick Start

```
skill bioresearcher-tests
```

Then follow the workflow steps in SKILL.md.

## Test Coverage

### Parser Tools
- `parse_pubmed_articleSet` - PubMed XML parsing (single/excel/individual modes)
- `parse_obo_file` - OBO ontology parsing

### Table Tools (13 tools)
- `tableListSheets` - List worksheets
- `tableGetSheetPreview` - Preview first 6 rows
- `tableGetHeaders` - Get column headers
- `tableGetCell` - Get cell by address
- `tableGetRange` - Get range of cells
- `tableFilterRows` - Filter with conditions
- `tableSearch` - Search across cells
- `tableSummarize` - Statistical summary
- `tableGroupBy` - Group aggregation
- `tablePivotSummary` - Pivot tables
- `tableCreateFile` - Create new file
- `tableAppendRows` - Append rows
- `tableUpdateCell` - Update cell

### JSON Tools
- `jsonExtract` - Extract JSON from files
- `jsonValidate` - Validate against schema
- `jsonInfer` - Infer schema from data

### Misc Tools
- `blockingTimer` - Blocking delays
- `calculator` - Math expressions

### Skills
- `demo-skill` - Full execution
- `bioresearcher-core` - Full execution
- Other skills - Metadata only (use Question tool)

## Not Tested

### Database Tools
Require live database connection:
- `dbQuery`
- `dbListTables`
- `dbDescribeTable`

### Interactive Skills
Use Question tool (user interaction):
- `python-setup-uv`
- `long-table-summary`
- `env-jsonc-setup`
- `pubmed-weekly`

## Report Output

Tests generate `.bioresearcher-tests/test_report.md` containing:
- Pass/fail summary by category
- List of skipped tests with reasons
- Detailed failure diagnostics
- Validator results for each test

## File Structure

```
bioresearcher-tests/
├── SKILL.md              # Main skill with workflow
├── README.md             # This file
├── pyproject.toml        # Python project config
├── test_runner.py        # Test structure generator
├── resources/            # Gzipped test inputs
│   ├── pubmed_sample.xml.gz
│   ├── obo_sample.obo.gz
│   ├── table_sample.xlsx.gz
│   └── json_samples/*.gz
└── test_cases/           # Test definitions
    ├── parser_tests.md
    ├── table_tests.md
    ├── json_tests.md
    ├── misc_tests.md
    └── skill_tests.md
```
