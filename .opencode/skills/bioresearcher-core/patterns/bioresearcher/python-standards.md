# Python Code Standards (DRY Principle)

Comprehensive documentation requirements and DRY (Don't Repeat Yourself) principle enforcement for all Python scripts.

## Overview

This pattern defines mandatory standards for Python code written by the bioresearcher agent:
- Complete documentation (module and function docstrings)
- DRY principle enforcement (no code duplication)
- Type hints and validation
- Error handling best practices
- Reusable component design

---

## 1. Module-Level Documentation

### Required Elements

**EVERY Python script MUST include:**

```python
#!/usr/bin/env python3
"""[Script Purpose - One Line Description]

This module provides functionality for:
- [Functionality 1 - brief description]
- [Functionality 2 - brief description]
- [Functionality 3 - brief description]

Usage:
    uv run python script_name.py [command] [options]
    
    Examples:
        uv run python script_name.py process --input data.xlsx --output results.json
        uv run python script_name.py validate --schema schema.json
        uv run python script_name.py analyze --config config.yaml

Dependencies:
    - pandas >= 1.5.0
    - openpyxl >= 3.0.0
    - [Other dependencies with version requirements]

Configuration:
    [Any configuration files or environment variables needed]

Output:
    [Description of output format and location]

Author: BioResearcher AI Agent
Date: YYYY-MM-DD
Version: 1.0.0
"""
```

### Example: Well-Documented Module

```python
#!/usr/bin/env python3
"""Clinical Trial Response Rate Analysis

This module provides functionality for:
- Loading and validating clinical trial data from Excel/CSV files
- Calculating response rates across trial phases and conditions
- Performing statistical comparisons (chi-square, t-test)
- Generating summary reports with visualizations

Usage:
    uv run python trial_analysis.py analyze --input trials.xlsx --output results/
    uv run python trial_analysis.py compare --phase1 "Phase 2" --phase2 "Phase 3"
    uv run python trial_analysis.py report --results results/ --output report.md

Dependencies:
    - pandas >= 1.5.0
    - scipy >= 1.9.0
    - openpyxl >= 3.0.0
    - matplotlib >= 3.6.0

Configuration:
    Requires env.jsonc with database connection (optional)

Output:
    - JSON files with statistical results
    - Excel files with aggregated data
    - Markdown report with findings

Author: BioResearcher AI Agent
Date: 2024-01-15
Version: 1.0.0
"""
```

---

## 2. Function Documentation

### Standard Docstring Format

**Required sections:**
1. Brief description (one line)
2. Extended description (if needed)
3. Args (with types and descriptions)
4. Returns (with type and description)
5. Raises (if applicable)
6. Example (recommended)

### Template

```python
def function_name(
    param1: Type1,
    param2: Type2,
    optional_param: Type3 = default_value
) -> ReturnType:
    """Brief one-line description of function.
    
    Extended description explaining what the function does,
    why it's needed, and any important behavior notes.
    
    Args:
        param1: Description of param1
        param2: Description of param2
            Can span multiple lines for complex parameters
        optional_param: Description of optional parameter
            Default: default_value
    
    Returns:
        Description of return value
        For complex returns, describe structure:
        {
            "key1": type - description,
            "key2": type - description
        }
    
    Raises:
        ExceptionType: When/why this exception is raised
        AnotherException: Description
    
    Example:
        >>> result = function_name(param1="value", param2=42)
        >>> print(result["key"])
        expected_output
    """
    # Implementation
    pass
```

### Example: Well-Documented Function

```python
def analyze_clinical_trials(
    trials_data: List[Dict[str, Any]],
    filter_criteria: Dict[str, str],
    output_format: str = "json"
) -> Dict[str, Any]:
    """Analyze clinical trial data with specified filters.
    
    Performs comprehensive analysis of clinical trial records including:
    - Filtering by phase, status, and condition
    - Statistical aggregation by sponsor and location
    - Response rate comparison across trial phases
    
    Args:
        trials_data: List of trial dictionaries from dbQuery or API
            Each dict must contain: nct_id, phase, status, condition,
            sponsor, response_rate, patient_count
        filter_criteria: Dictionary of filter conditions
            Example: {"phase": "Phase 3", "status": "Recruiting"}
            Supported keys: phase, status, condition, sponsor
        output_format: Output format for results
            Options: "json", "dataframe", "dict"
            Default: "json"
    
    Returns:
        Dictionary containing analysis results:
        {
            "filtered_count": int - Number of trials after filtering,
            "statistics": {
                "avg_response_rate": float,
                "total_patients": int,
                "by_phase": Dict[str, Dict]
            },
            "trials": List[Dict] - Filtered trial records
        }
    
    Raises:
        ValueError: If filter_criteria contains unsupported keys
        KeyError: If trials_data missing required fields
        TypeError: If trials_data is not a list
    
    Example:
        >>> trials = dbQuery("SELECT * FROM clinical_trials")
        >>> results = analyze_clinical_trials(
        ...     trials_data=trials,
        ...     filter_criteria={"phase": "Phase 3"},
        ...     output_format="json"
        ... )
        >>> print(results["filtered_count"])
        42
        >>> print(results["statistics"]["avg_response_rate"])
        0.65
    """
    # Validate inputs
    _validate_filter_criteria(filter_criteria)
    validated_data = _validate_trials(trials_data)
    
    # Apply filters (reusable function)
    filtered = _apply_filters(validated_data, filter_criteria)
    
    # Calculate statistics (reusable function)
    stats = _calculate_statistics(filtered)
    
    # Format output
    if output_format == "json":
        return {
            "filtered_count": len(filtered),
            "statistics": stats,
            "trials": filtered
        }
    elif output_format == "dataframe":
        import pandas as pd
        return {
            "filtered_count": len(filtered),
            "statistics": stats,
            "trials": pd.DataFrame(filtered)
        }
    else:
        return {
            "filtered_count": len(filtered),
            "statistics": stats,
            "trials": filtered
        }
```

---

## 3. DRY Principle Enforcement

### Core Principles

1. **Single Responsibility** - Each function does ONE thing
2. **No Code Duplication** - If code appears twice, extract to function
3. **Reusable Components** - Design functions for reuse across scripts
4. **Configuration Over Hardcoding** - Use parameters, not hardcoded values

### Violation Examples and Corrections

#### Violation 1: Code Duplication

```python
# ❌ BAD: Duplicated validation logic
def analyze_trials(trials):
    """Analyze trials with inline validation."""
    for trial in trials:
        if not trial.get("nct_id"):
            raise ValueError("Missing NCT ID")
        if not trial.get("phase"):
            raise ValueError("Missing phase")
        if not trial.get("status"):
            raise ValueError("Missing status")
    # ... analysis logic

def export_trials(trials):
    """Export trials with inline validation."""
    for trial in trials:
        if not trial.get("nct_id"):
            raise ValueError("Missing NCT ID")
        if not trial.get("phase"):
            raise ValueError("Missing phase")
        if not trial.get("status"):
            raise ValueError("Missing status")
    # ... export logic
```

```python
# ✅ GOOD: DRY principle - reusable validation function
def _validate_trial(trial: Dict[str, Any]) -> bool:
    """Validate single trial record.
    
    Checks for required fields and data types.
    Reusable across multiple functions.
    
    Args:
        trial: Trial dictionary to validate
        
    Returns:
        True if valid
        
    Raises:
        ValueError: If required fields missing or invalid
    """
    required_fields = {
        "nct_id": str,
        "phase": str,
        "status": str,
        "response_rate": (int, float),
        "patient_count": int
    }
    
    for field, expected_type in required_fields.items():
        if not trial.get(field):
            raise ValueError(f"Missing required field: {field}")
        if not isinstance(trial[field], expected_type):
            raise ValueError(
                f"Field {field} has wrong type: "
                f"expected {expected_type}, got {type(trial[field])}"
            )
    
    return True

def analyze_trials(trials: List[Dict]) -> Dict:
    """Analyze trials with reusable validation."""
    validated = [_validate_trial(t) for t in trials]
    # ... analysis logic

def export_trials(trials: List[Dict], output_path: str) -> None:
    """Export trials with reusable validation."""
    validated = [_validate_trial(t) for t in trials]
    # ... export logic
```

#### Violation 2: Hardcoded Values

```python
# ❌ BAD: Hardcoded configuration
def analyze_data(data):
    """Analyze with hardcoded thresholds."""
    if len(data) > 1000:
        print("Large dataset detected")
    
    for item in data:
        if item["value"] > 0.5:  # Magic number
            item["category"] = "High"
        else:
            item["category"] = "Low"
    
    return data
```

```python
# ✅ GOOD: Configuration via parameters
def analyze_data(
    data: List[Dict],
    large_dataset_threshold: int = 1000,
    category_threshold: float = 0.5
) -> List[Dict]:
    """Analyze with configurable thresholds.
    
    Args:
        data: List of data items
        large_dataset_threshold: Threshold for large dataset warning
            Default: 1000
        category_threshold: Threshold for High/Low categorization
            Default: 0.5
    
    Returns:
        Data with categories assigned
    """
    if len(data) > large_dataset_threshold:
        print(f"Large dataset detected: {len(data)} items")
    
    for item in data:
        if item["value"] > category_threshold:
            item["category"] = "High"
        else:
            item["category"] = "Low"
    
    return data
```

#### Violation 3: Multiple Responsibilities

```python
# ❌ BAD: Function does too many things
def process_trials(file_path):
    """Load, validate, filter, analyze, and export trials."""
    # Load data
    df = pd.read_excel(file_path)
    
    # Validate
    if df.empty:
        raise ValueError("Empty file")
    
    # Filter
    df = df[df["phase"] == "Phase 3"]
    
    # Analyze
    stats = df.groupby("condition")["response_rate"].mean()
    
    # Export
    stats.to_excel("output.xlsx")
    
    # Visualize
    stats.plot(kind="bar")
    plt.savefig("plot.png")
    
    return stats
```

```python
# ✅ GOOD: Single responsibility per function
def load_trials(file_path: str) -> pd.DataFrame:
    """Load trials from Excel file."""
    return pd.read_excel(file_path)

def validate_trials(df: pd.DataFrame) -> pd.DataFrame:
    """Validate trial data."""
    if df.empty:
        raise ValueError("Empty file")
    required_cols = ["nct_id", "phase", "response_rate"]
    missing = [col for col in required_cols if col not in df.columns]
    if missing:
        raise ValueError(f"Missing columns: {missing}")
    return df

def filter_trials(
    df: pd.DataFrame,
    phase: str = None,
    status: str = None
) -> pd.DataFrame:
    """Filter trials by criteria."""
    if phase:
        df = df[df["phase"] == phase]
    if status:
        df = df[df["status"] == status]
    return df

def analyze_trials(df: pd.DataFrame) -> pd.Series:
    """Calculate statistics by condition."""
    return df.groupby("condition")["response_rate"].mean()

def export_results(stats: pd.Series, output_path: str) -> None:
    """Export statistics to Excel."""
    stats.to_excel(output_path)

def create_visualization(stats: pd.Series, output_path: str) -> None:
    """Create bar chart visualization."""
    import matplotlib.pyplot as plt
    stats.plot(kind="bar")
    plt.savefig(output_path)

# Main workflow
def process_trials(file_path: str, output_dir: str) -> pd.Series:
    """Process trials using modular functions."""
    df = load_trials(file_path)
    df = validate_trials(df)
    df = filter_trials(df, phase="Phase 3")
    stats = analyze_trials(df)
    export_results(stats, f"{output_dir}/stats.xlsx")
    create_visualization(stats, f"{output_dir}/plot.png")
    return stats
```

---

## 4. Type Hints

### Why Type Hints Matter

- Improve code readability
- Enable IDE autocomplete and type checking
- Document expected types
- Catch errors early

### Standard Type Hint Patterns

```python
from typing import Dict, List, Any, Optional, Union, Tuple

# Basic types
def process_string(text: str) -> str:
    pass

# Collections
def process_list(items: List[str]) -> List[int]:
    pass

def process_dict(data: Dict[str, Any]) -> Dict[str, float]:
    pass

# Optional parameters
def search(
    query: str,
    limit: Optional[int] = None
) -> List[Dict]:
    pass

# Union types
def parse_value(value: Union[str, int, float]) -> float:
    pass

# Tuple returns
def get_stats(data: List[float]) -> Tuple[float, float, float]:
    """Returns (mean, std, median)."""
    pass

# Complex structures
def analyze_trials(
    trials: List[Dict[str, Union[str, int, float]]]
) -> Dict[str, Any]:
    pass
```

---

## 5. Error Handling

### Validation Pattern

```python
def analyze_data(data: List[Dict], threshold: float) -> Dict:
    """Analyze data with comprehensive validation.
    
    Args:
        data: List of data items
        threshold: Analysis threshold (0.0 to 1.0)
    
    Returns:
        Analysis results
    
    Raises:
        TypeError: If data is not a list
        ValueError: If threshold out of range or data empty
    """
    # Type validation
    if not isinstance(data, list):
        raise TypeError(f"data must be list, got {type(data)}")
    
    if not isinstance(threshold, (int, float)):
        raise TypeError(f"threshold must be numeric, got {type(threshold)}")
    
    # Value validation
    if not 0.0 <= threshold <= 1.0:
        raise ValueError(f"threshold must be 0.0-1.0, got {threshold}")
    
    if len(data) == 0:
        raise ValueError("data cannot be empty")
    
    # Field validation
    for i, item in enumerate(data):
        if "value" not in item:
            raise ValueError(f"Item {i} missing 'value' field")
    
    # Analysis logic
    results = [item for item in data if item["value"] > threshold]
    
    return {
        "count": len(results),
        "threshold": threshold,
        "items": results
    }
```

### Exception Handling Pattern

```python
def load_and_process(file_path: str) -> Dict:
    """Load and process file with error handling.
    
    Args:
        file_path: Path to input file
    
    Returns:
        Processed data
    
    Raises:
        FileNotFoundError: If file doesn't exist
        ValueError: If file format invalid
    """
    import json
    
    # Try-except for external operations
    try:
        with open(file_path, 'r') as f:
            data = json.load(f)
    except FileNotFoundError:
        raise FileNotFoundError(f"File not found: {file_path}")
    except json.JSONDecodeError as e:
        raise ValueError(f"Invalid JSON in {file_path}: {e}")
    
    # Validate structure
    if not isinstance(data, dict):
        raise ValueError(f"Expected dict, got {type(data)}")
    
    # Process with error handling
    try:
        processed = _process_data(data)
    except Exception as e:
        raise RuntimeError(f"Processing failed: {e}")
    
    return processed
```

---

## 6. File Organization

### Directory Structure

```
.scripts/py/
├── [topic]_analysis.py          # Main analysis script
├── [topic]_utils.py             # Reusable utilities
├── [topic]_config.py            # Configuration constants
└── requirements.txt             # Dependencies (if needed)
```

### Script Structure

```python
#!/usr/bin/env python3
"""Module docstring"""

# 1. Imports
import sys
from typing import Dict, List, Any
import pandas as pd

# 2. Constants/Configuration
DEFAULT_THRESHOLD = 0.5
SUPPORTED_FORMATS = ["json", "csv", "excel"]

# 3. Utility functions (private, prefix with _)
def _validate_input(data: Any) -> bool:
    """Private utility function."""
    pass

def _format_output(results: Dict) -> str:
    """Private utility function."""
    pass

# 4. Main functions (public)
def analyze_data(data: List[Dict]) -> Dict:
    """Public main function."""
    pass

def export_results(results: Dict, output_path: str) -> None:
    """Public utility function."""
    pass

# 5. CLI interface (if applicable)
def main():
    """Command-line interface."""
    import argparse
    
    parser = argparse.ArgumentParser(description="...")
    parser.add_argument("command", choices=["analyze", "export"])
    parser.add_argument("--input", required=True)
    parser.add_argument("--output", required=True)
    
    args = parser.parse_args()
    
    # CLI logic
    if args.command == "analyze":
        data = load_data(args.input)
        results = analyze_data(data)
        export_results(results, args.output)

# 6. Main execution block
if __name__ == "__main__":
    main()
```

---

## 7. Code Quality Checklist

Before finalizing any Python script, verify:

### Documentation
- [ ] Module docstring complete (purpose, usage, dependencies)
- [ ] All functions have docstrings
- [ ] Args section complete with types
- [ ] Returns section complete with types
- [ ] Raises section for functions that can fail
- [ ] Examples included for complex functions

### DRY Principle
- [ ] No duplicated code blocks
- [ ] Repeated logic extracted to functions
- [ ] Single responsibility per function
- [ ] Configuration via parameters, not hardcoded values
- [ ] Utility functions reusable across scripts

### Type Hints
- [ ] All function parameters have type hints
- [ ] All return types specified
- [ ] Complex types imported from typing module
- [ ] Optional parameters marked as Optional[Type]

### Error Handling
- [ ] Input validation at function start
- [ ] Type checking for critical parameters
- [ ] Try-except for external operations
- [ ] Informative error messages
- [ ] Proper exception types

### Code Style
- [ ] Consistent naming (snake_case for functions/variables)
- [ ] Functions are < 50 lines (if longer, split)
- [ ] Logical grouping of related functions
- [ ] Private functions prefixed with _
- [ ] No unused imports or variables

---

## 8. Example: Complete Well-Structured Script

```python
#!/usr/bin/env python3
"""Clinical Trial Statistical Analysis

This module provides functionality for:
- Loading trial data from multiple sources (Excel, CSV, database)
- Calculating response rates and survival statistics
- Performing statistical comparisons (chi-square, t-test, log-rank)
- Generating comprehensive reports with visualizations

Usage:
    uv run python trial_stats.py analyze --input trials.xlsx --output results/
    uv run python trial_stats.py compare --group1 Phase2 --group2 Phase3
    uv run python trial_stats.py report --results results/ --output report.md

Dependencies:
    - pandas >= 1.5.0
    - scipy >= 1.9.0
    - openpyxl >= 3.0.0
    - matplotlib >= 3.6.0
    - lifelines >= 0.27.0

Configuration:
    env.jsonc for database connection (optional)

Output:
    - JSON files with statistical results
    - Excel files with aggregated data
    - PNG files with visualizations
    - Markdown report with findings

Author: BioResearcher AI Agent
Date: 2024-01-15
Version: 1.0.0
"""

import sys
from typing import Dict, List, Any, Optional, Tuple
import pandas as pd
import numpy as np
from scipy import stats

# Constants
DEFAULT_ALPHA = 0.05
MIN_SAMPLE_SIZE = 10
SUPPORTED_FORMATS = ["json", "csv", "excel"]

# Private utility functions

def _validate_dataframe(df: pd.DataFrame, required_cols: List[str]) -> None:
    """Validate DataFrame has required columns.
    
    Args:
        df: DataFrame to validate
        required_cols: List of required column names
    
    Raises:
        ValueError: If required columns missing
    """
    missing = [col for col in required_cols if col not in df.columns]
    if missing:
        raise ValueError(f"Missing required columns: {missing}")

def _calculate_confidence_interval(
    data: np.ndarray,
    confidence: float = 0.95
) -> Tuple[float, float]:
    """Calculate confidence interval for data.
    
    Args:
        data: Array of values
        confidence: Confidence level (0.0 to 1.0)
    
    Returns:
        Tuple of (lower_bound, upper_bound)
    """
    mean = np.mean(data)
    sem = stats.sem(data)
    interval = sem * stats.t.ppf((1 + confidence) / 2, len(data) - 1)
    return (mean - interval, mean + interval)

# Main analysis functions

def load_trial_data(
    file_path: str,
    file_format: str = "excel"
) -> pd.DataFrame:
    """Load trial data from file.
    
    Args:
        file_path: Path to input file
        file_format: File format ("excel", "csv", "json")
    
    Returns:
        DataFrame with trial data
    
    Raises:
        FileNotFoundError: If file doesn't exist
        ValueError: If format unsupported or file invalid
    """
    if file_format not in SUPPORTED_FORMATS:
        raise ValueError(f"Unsupported format: {file_format}")
    
    try:
        if file_format == "excel":
            df = pd.read_excel(file_path)
        elif file_format == "csv":
            df = pd.read_csv(file_path)
        else:  # json
            df = pd.read_json(file_path)
    except FileNotFoundError:
        raise FileNotFoundError(f"File not found: {file_path}")
    except Exception as e:
        raise ValueError(f"Failed to load {file_path}: {e}")
    
    # Validate structure
    required = ["nct_id", "phase", "response_rate"]
    _validate_dataframe(df, required)
    
    return df

def compare_response_rates(
    df: pd.DataFrame,
    group_column: str = "phase",
    alpha: float = DEFAULT_ALPHA
) -> Dict[str, Any]:
    """Compare response rates across groups with statistical testing.
    
    Performs chi-square test for independence and calculates
    confidence intervals for each group.
    
    Args:
        df: DataFrame containing trial data
        group_column: Column to group by
        alpha: Significance level (0.0 to 1.0)
    
    Returns:
        Dictionary containing:
        {
            "group_stats": Statistics per group,
            "chi_square": Chi-square test results,
            "significant": Boolean for significance,
            "confidence_intervals": CI per group
        }
    
    Raises:
        ValueError: If insufficient data or invalid alpha
    """
    if not 0 < alpha < 1:
        raise ValueError(f"alpha must be 0-1, got {alpha}")
    
    if len(df) < MIN_SAMPLE_SIZE:
        raise ValueError(f"Insufficient data: {len(df)} < {MIN_SAMPLE_SIZE}")
    
    # Group statistics
    group_stats = df.groupby(group_column)["response_rate"].agg(
        ["mean", "std", "count", "median"]
    ).to_dict()
    
    # Chi-square test
    contingency = pd.crosstab(
        df[group_column],
        (df["response_rate"] > df["response_rate"].median()).astype(int)
    )
    chi2, p_value, dof, expected = stats.chi2_contingency(contingency)
    
    # Confidence intervals
    ci_results = {}
    for group in df[group_column].unique():
        group_data = df[df[group_column] == group]["response_rate"].values
        ci_low, ci_high = _calculate_confidence_interval(group_data)
        ci_results[group] = {"lower": ci_low, "upper": ci_high}
    
    return {
        "group_stats": group_stats,
        "chi_square": {
            "statistic": chi2,
            "p_value": p_value,
            "degrees_of_freedom": dof
        },
        "significant": p_value < alpha,
        "confidence_intervals": ci_results
    }

# CLI interface

def main():
    """Command-line interface for trial statistics."""
    import argparse
    
    parser = argparse.ArgumentParser(
        description="Clinical trial statistical analysis"
    )
    parser.add_argument("command", choices=["analyze", "compare"])
    parser.add_argument("--input", required=True, help="Input file path")
    parser.add_argument("--output", required=True, help="Output directory")
    parser.add_argument(
        "--format",
        choices=SUPPORTED_FORMATS,
        default="excel",
        help="Input file format"
    )
    
    args = parser.parse_args()
    
    # Load data
    df = load_trial_data(args.input, args.format)
    
    # Execute command
    if args.command == "compare":
        results = compare_response_rates(df)
        # Export results
        import json
        with open(f"{args.output}/comparison.json", 'w') as f:
            json.dump(results, f, indent=2)
        print(f"Results saved to {args.output}/comparison.json")

if __name__ == "__main__":
    main()
```

---

## Summary

**Every Python script must have:**
1. ✅ Complete module docstring
2. ✅ Function docstrings with Args/Returns/Raises/Example
3. ✅ No code duplication (DRY principle)
4. ✅ Type hints for all functions
5. ✅ Input validation and error handling
6. ✅ Single responsibility per function
7. ✅ Configuration via parameters
8. ✅ Proper file organization

**Follow this pattern for all Python code to ensure maintainability, reusability, and professional quality.**
