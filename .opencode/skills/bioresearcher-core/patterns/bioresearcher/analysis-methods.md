# Data Analysis Method Selection

Decision criteria for choosing between table tools, long-table-summary skill, and custom Python scripts.

## Overview

This pattern guides selection of the optimal analysis approach based on:
- Data size (row count)
- Operation complexity
- Parallelization needs
- Output format requirements
- Reusability considerations

---

## Decision Matrix

| Criteria | Table Tools | long-table-summary Skill | Custom Python |
|----------|-------------|-------------------------|---------------|
| **Data Size** | < 30 rows | 30-1000 rows, batch processing | > 1000 rows OR complex logic |
| **Operation Complexity** | Simple (filter, group, summarize) | Structured summarization with schema | Complex transformations, ML |
| **Parallelization** | No | Yes (waves of 3 subagents) | Optional |
| **Output Format** | Table/Excel | Structured JSON → Excel | Any format |
| **Reusability** | One-time | Reusable template | Reusable functions |
| **Setup Time** | Immediate | 5-10 minutes | 10-30 minutes |
| **Context Usage** | Low | Medium (subagent waves) | Low-Medium |

---

## Decision Flowchart

```
START: Data analysis needed
  │
  ├─ Can operation be done with table tools?
  │  │
  │  ├─ YES → Use table tools (fastest, simplest)
  │  │         → See Section 1: Table Tools Approach
  │  │
  │  └─ NO → Continue
  │
  ├─ Is data in table format (Excel/CSV)?
  │  │
  │  ├─ YES AND rows >= 30 AND need structured summarization
  │  │    → Load skill 'long-table-summary'
  │  │    → Follow 16-step workflow
  │  │    → See Section 2: long-table-summary Approach
  │  │
  │  └─ NO OR need custom logic
  │       → Write custom Python script
  │       → See Section 3: Custom Python Approach
```

---

## Section 1: Table Tools Approach

### When to Use
- Data size: < 30 rows
- Operations: Filter, group, summarize, pivot
- No complex transformations needed
- Quick analysis required

### Available Operations

#### Filtering
```typescript
// Filter by single condition
tableFilterRows(
  file_path,
  column="Status",
  operator="=",
  value="Active",
  max_results=100
)

// Supported operators: =, !=, >, <, >=, <=, contains
```

#### Grouping & Aggregation
```typescript
// Group by one column, aggregate another
tableGroupBy(
  file_path,
  group_column="Phase",
  agg_column="Patient_Count",
  agg_type="sum"  // sum, count, avg, min, max
)
```

#### Statistical Summary
```typescript
// Get statistics for numeric columns
tableSummarize(
  file_path,
  columns=["Age", "Dose_mg", "Response_Rate"]
)
// Returns: sum, avg, min, max, std_dev
```

#### Pivot Tables
```typescript
// Create cross-tabulation
tablePivotSummary(
  file_path,
  row_field="Phase",
  col_field="Status",
  value_field="Trial_Count",
  agg="count"
)
```

#### Search
```typescript
// Search across all cells
tableSearch(
  file_path,
  search_term="BRAF",
  max_results=50
)
```

### Example Workflow

```markdown
User: "Summarize the trial data by phase and count recruiting trials"

Agent actions:
1. tableGetSheetPreview(file_path) → Understand structure
2. tableFilterRows(
     file_path,
     column="Status",
     operator="=",
     value="Recruiting"
   )
3. tableGroupBy(
     file_path,
     group_column="Phase",
     agg_column="NCT_ID",
     agg_type="count"
   )
4. Present results with citations
```

---

## Section 2: long-table-summary Approach

### When to Use
- Data size: 30-1000+ rows
- Need structured summarization with specific output schema
- Batch processing with parallel subagents
- Complex field extraction/classification

### Skill Loading

```markdown
skill long-table-summary
```

### 16-Step Workflow Overview

1. Interview user for table location
2. Confirm table existence and list sheets
3. Interview for summarization instructions (JSON format)
4. Refine instructions iteratively
5. Generate output JSON schema
6. Autogenerate topic name
7. Ask user for batch size (default: 30 rows)
8. Calculate batch ranges
9. Create subagent prompt template
10. Create directory structure
11. Generate prompts using Python script
12. Launch subagents in waves of 3
13. Monitor progress (report every 3 completions)
14. Check for missing outputs and retry
15. Combine outputs using Python script
16. Generate final report

### Example Use Cases

#### Use Case 1: Species Classification
```json
{
  "species": "Species classification: Tier1 (human, monkey), Tier2 (other animals), or NA",
  "topic": "Research topic: Oncology, Immunology, General Biology, or Others"
}
```

#### Use Case 2: Gene Mutation Analysis
```json
{
  "gene_mutation": "Gene mutation pattern, e.g., V600E, R173, Wild Type",
  "clinical_significance": "Clinical relevance: High, Medium, Low, or Unknown",
  "therapeutic_target": "Is this a drug target? Yes, No, or Unknown"
}
```

#### Use Case 3: Trial Status Extraction
```json
{
  "trial_phase": "Extract trial phase: Phase 1, Phase 2, Phase 3, or Phase 4",
  "recruitment_status": "Recruitment status: Recruiting, Completed, Terminated",
  "primary_outcome": "Primary outcome measure description"
}
```

### Performance Considerations

```
Batch Size Recommendations:
  - Simple classification (2-3 fields): 50 rows per batch
  - Moderate complexity (4-6 fields): 30 rows per batch
  - Complex analysis (7+ fields): 20 rows per batch

Parallel Processing:
  - Waves of 3 subagents
  - Each wave processes 3 batches simultaneously
  - Progress reported every 3 completions

Expected Time:
  - Setup: 5-10 minutes
  - Processing: ~1 minute per batch
  - Total for 100 rows, 30/batch: ~40 minutes (4 batches × 10 min)
```

### When NOT to Use

```
❌ DON'T use long-table-summary when:
  - Less than 30 rows (use table tools instead)
  - Simple filtering/grouping only (use table tools)
  - Need real-time results (skill takes minutes)
  - Unstructured output acceptable (use Python)
  - No clear JSON schema possible (use Python)
```

---

## Section 3: Custom Python Approach

### When to Use
- Data size: > 1000 rows
- Complex transformations (ML, statistical models)
- Custom output formats
- Reusable analysis pipeline needed
- Operations beyond table tool capabilities

### Decision Sub-Flowchart

```
PYTHON SCRIPT DECISION:
  │
  ├─ Is this a one-time analysis?
  │  ├─ YES → Write single script in .scripts/py/
  │  │         → Include full documentation
  │  │         → Follow DRY principle
  │  │
  │  └─ NO → Create reusable module
  │           → Separate utilities into _utils.py
  │           → Document thoroughly
  │
  ├─ Can existing skills/patterns help?
  │  ├─ YES → Load skill 'bioresearcher-core'
  │  │         → Read relevant patterns:
  │  │           - retry.md (for network operations)
  │  │           - progress.md (for batch processing)
  │  │           - json-tools.md (for JSON validation)
  │  │           - table-tools.md (for combining outputs)
  │  │
  │  └─ NO → Implement from scratch
  │           → Follow python-standards.md pattern
  │           → Include comprehensive docstrings
```

### Python Script Categories

#### Category 1: Data Transformation
```python
# When to use: Complex data reshaping, format conversion
# Examples:
#   - Pivot/unpivot operations
#   - Multi-file joins
#   - Data cleaning and normalization
```

#### Category 2: Statistical Analysis
```python
# When to use: Beyond basic sum/avg/min/max
# Examples:
#   - Statistical tests (t-test, chi-square)
#   - Regression analysis
#   - Survival analysis
```

#### Category 3: Machine Learning
```python
# When to use: Predictive modeling, classification
# Examples:
#   - Clustering
#   - Classification
#   - Feature extraction
```

#### Category 4: Custom Aggregation
```python
# When to use: Complex business logic for aggregation
# Examples:
#   - Weighted averages
#   - Custom scoring algorithms
#   - Multi-step calculations
```

### Example: Statistical Analysis Script

```python
#!/usr/bin/env python3
"""Clinical trial outcome analysis with statistical testing.

This module provides functionality for:
- Comparing response rates across trial phases
- Statistical significance testing (chi-square)
- Generating publication-ready summary tables

Usage:
    uv run python trial_analysis.py analyze --input trials.xlsx --output results.json
    uv run python trial_analysis.py compare --phase1 phase2.xlsx --phase2 phase3.xlsx

Dependencies:
    - pandas >= 1.5.0
    - scipy >= 1.9.0
    - openpyxl >= 3.0.0

Author: BioResearcher AI Agent
Date: 2024-01-15
"""

import pandas as pd
from scipy import stats
from typing import Dict, List, Any

def load_trial_data(file_path: str) -> pd.DataFrame:
    """Load clinical trial data from Excel file.
    
    Args:
        file_path: Path to Excel file containing trial data
        
    Returns:
        DataFrame with trial records
        
    Raises:
        FileNotFoundError: If file_path does not exist
        ValueError: If required columns missing
    """
    df = pd.read_excel(file_path)
    
    required_columns = ["nct_id", "phase", "status", "response_rate"]
    missing = [col for col in required_columns if col not in df.columns]
    
    if missing:
        raise ValueError(f"Missing required columns: {missing}")
    
    return df

def compare_response_rates(
    df: pd.DataFrame,
    group_column: str = "phase"
) -> Dict[str, Any]:
    """Compare response rates across groups with statistical testing.
    
    Performs chi-square test for independence to determine if
    response rates differ significantly across trial phases.
    
    Args:
        df: DataFrame containing trial data
        group_column: Column to group by (default: "phase")
        
    Returns:
        Dictionary containing:
        - "group_stats": Statistics per group
        - "chi_square": Chi-square test results
        - "significant": Boolean indicating significance
        
    Example:
        >>> df = load_trial_data("trials.xlsx")
        >>> results = compare_response_rates(df, group_column="phase")
        >>> print(results["significant"])
        True
    """
    # Group statistics
    group_stats = df.groupby(group_column)["response_rate"].agg(
        ["mean", "std", "count"]
    ).to_dict()
    
    # Chi-square test
    contingency = pd.crosstab(df[group_column], df["response_rate"] > 50)
    chi2, p_value, dof, expected = stats.chi2_contingency(contingency)
    
    return {
        "group_stats": group_stats,
        "chi_square": {
            "statistic": chi2,
            "p_value": p_value,
            "degrees_of_freedom": dof
        },
        "significant": p_value < 0.05
    }

if __name__ == "__main__":
    import argparse
    
    parser = argparse.ArgumentParser(description="Clinical trial analysis")
    parser.add_argument("command", choices=["analyze", "compare"])
    parser.add_argument("--input", required=True, help="Input file path")
    parser.add_argument("--output", required=True, help="Output file path")
    
    args = parser.parse_args()
    
    # Analysis logic here
    df = load_trial_data(args.input)
    results = compare_response_rates(df)
    
    # Save results
    import json
    with open(args.output, 'w') as f:
        json.dump(results, f, indent=2)
```

### Python Best Practices

```
1. File Organization
   .scripts/py/
   ├── [topic]_analysis.py    # Main analysis script
   ├── [topic]_utils.py       # Reusable utilities
   └── requirements.txt       # Dependencies (if needed)

2. Documentation Requirements
   - Module-level docstring (purpose, usage, dependencies)
   - Function docstrings (Args, Returns, Raises, Examples)
   - Inline comments for complex logic
   - Type hints for all function signatures

3. DRY Principle
   - Single responsibility per function
   - No code duplication
   - Extract repeated logic to utility functions
   - Use configuration over hardcoding

4. Error Handling
   - Validate inputs early
   - Use try/except for external operations
   - Provide informative error messages
   - Log errors for debugging

5. Testing
   - Include example usage in docstrings
   - Test with sample data
   - Validate outputs
```

---

## Hybrid Approaches

### Approach 1: Table Tools → Python
```
Use table tools for initial filtering
→ Export subset
→ Use Python for complex analysis
```

### Approach 2: Python → Table Tools
```
Use Python for data cleaning
→ Export to Excel
→ Use table tools for interactive exploration
```

### Approach 3: long-table-summary → Python
```
Use skill for batch summarization
→ Combine outputs with Python
→ Further analysis with Python
```

---

## Performance Benchmarks

### Table Tools
- **Setup Time:** Immediate
- **Execution Time:** < 1 second for < 1000 rows
- **Context Usage:** Minimal
- **Best For:** Quick lookups, simple aggregations

### long-table-summary Skill
- **Setup Time:** 5-10 minutes
- **Execution Time:** ~1 minute per batch (30 rows)
- **Context Usage:** Medium (subagent overhead)
- **Best For:** Structured summarization, classification

### Custom Python
- **Setup Time:** 10-30 minutes
- **Execution Time:** Variable (depends on complexity)
- **Context Usage:** Low (script runs independently)
- **Best For:** Complex analysis, reusable pipelines

---

## Common Mistakes to Avoid

### Mistake 1: Using Python for Simple Operations
```
❌ BAD: Write Python script for simple filtering
✅ GOOD: Use tableFilterRows() for filtering
```

### Mistake 2: Using long-table-summary for Small Tables
```
❌ BAD: Load skill for 15-row table
✅ GOOD: Use table tools directly for < 30 rows
```

### Mistake 3: Not Using Skills When Appropriate
```
❌ BAD: Write custom Python for batch summarization
✅ GOOD: Load long-table-summary skill for structured summarization
```

### Mistake 4: Ignoring Upfront Filtering
```
❌ BAD: Load entire 10,000-row table then process
✅ GOOD: Apply filters first, then process subset
```

---

## Decision Checklist

Before choosing an approach, ask:

- [ ] How many rows in the dataset?
- [ ] What operations are needed? (filter, group, summarize, transform)
- [ ] Is output format specified? (JSON schema vs. flexible)
- [ ] Is parallel processing needed?
- [ ] Will this analysis be reused?
- [ ] What is the time constraint?
- [ ] Are there existing skills that can help?

**Based on answers, select approach using decision matrix above.**
