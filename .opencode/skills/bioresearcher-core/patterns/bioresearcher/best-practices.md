# Best Practices for Data Analysis

Critical best practices for data analysis including upfront filtering, validation, error handling, and performance optimization.

## Overview

This pattern defines mandatory best practices that MUST be followed for all data analysis tasks:
1. Upfront Filtering (CRITICAL)
2. Data Validation
3. Error Handling & Retry Logic
4. Rate Limiting
5. Performance Optimization
6. Context Window Management

---

## 1. Upfront Filtering (CRITICAL)

### Core Rule

**RULE: Always filter data at the SOURCE, not after retrieval**

**Why:**
- Reduces data transfer
- Improves performance
- Conserves context window
- Follows database best practices
- Minimizes memory usage

### Database Queries

```python
# ✅ GOOD: Filter at database level
dbQuery(
    "SELECT * FROM clinical_trials WHERE phase = :phase AND status = :status LIMIT 100",
    {phase: "Phase 3", status: "Recruiting"}
)

# ❌ BAD: Retrieve all data then filter
dbQuery("SELECT * FROM clinical_trials")
# Then filter in Python - inefficient!
```

**Best Practices:**
- Use WHERE clauses to filter rows
- Use LIMIT to cap result size
- Use indexed columns in WHERE clause
- Use named parameters (not string concatenation)
- Select only needed columns (avoid SELECT *)

### Table Operations

```python
# ✅ GOOD: Filter with table tools
tableFilterRows(
    file_path="data/trials.xlsx",
    column="Phase",
    operator="=",
    value="Phase 3",
    max_results=100
)

# ❌ BAD: Load entire table then filter
tableGetRange(file_path="data/trials.xlsx", range="A1:Z10000")
# Then filter in Python - wastes memory!
```

**Best Practices:**
- Use tableFilterRows for single-condition filters
- Use tableSearch to find specific values
- Use max_results to limit output
- Preview with tableGetSheetPreview before processing
- Check row count before deciding approach

### BioMCP Queries

```python
# ✅ GOOD: Targeted query with filters
biomcp_article_searcher(
    genes=["BRAF", "NRAS"],
    diseases=["melanoma"],
    keywords=["treatment resistance"],
    variants=["V600E"],
    page_size=50
)

# ❌ BAD: Broad query then manual filtering
biomcp_search(query="BRAF")
# Then manually filter through thousands of results!
```

**Best Practices:**
- Use specific domain filters (genes, diseases, variants)
- Combine multiple filters with AND logic
- Use page_size to limit results per page
- Use biomcp_search only for cross-domain queries
- Specify exact criteria upfront

### Web Searches

```python
# ✅ GOOD: Specific search query
web-search-prime_web_search_prime(
    search_query="BRAF V600E melanoma FDA approval 2024",
    search_recency_filter="oneYear"
)

# ❌ BAD: Broad search then filter results
web-search-prime_web_search_prime(search_query="BRAF")
# Then manually evaluate hundreds of results!
```

**Best Practices:**
- Use specific search terms
- Use recency filters when time-sensitive
- Use domain filters for trusted sources
- Limit results to manageable number
- Verify source quality before using

---

## 2. Data Validation

### Validation Pattern

```
VALIDATION WORKFLOW:
1. Check data existence (not empty/null)
2. Validate structure (required fields present)
3. Validate types (correct data types)
4. Validate values (within expected ranges)
5. Validate quality (no duplicates, no corruption)
```

### Example: Comprehensive Validation

```python
def validate_clinical_trials(trials: List[Dict]) -> List[Dict]:
    """Validate clinical trial data with comprehensive checks.
    
    Args:
        trials: List of trial dictionaries
        
    Returns:
        Validated trials
        
    Raises:
        ValueError: If validation fails
    """
    # 1. Check existence
    if not trials:
        raise ValueError("No trial data provided")
    
    # 2. Define required structure
    required_fields = {
        "nct_id": str,
        "phase": str,
        "status": str,
        "condition": str,
        "response_rate": (int, float),
        "patient_count": int
    }
    
    valid_trials = []
    errors = []
    
    for i, trial in enumerate(trials):
        try:
            # 3. Validate structure
            for field, expected_type in required_fields.items():
                if field not in trial:
                    raise ValueError(f"Missing field: {field}")
                
                # 4. Validate types
                if not isinstance(trial[field], expected_type):
                    raise ValueError(
                        f"Field {field} has wrong type: "
                        f"expected {expected_type}, got {type(trial[field])}"
                    )
            
            # 5. Validate values
            if not trial["nct_id"].startswith("NCT"):
                raise ValueError(f"Invalid NCT ID format: {trial['nct_id']}")
            
            if trial["phase"] not in ["Phase 1", "Phase 2", "Phase 3", "Phase 4"]:
                raise ValueError(f"Invalid phase: {trial['phase']}")
            
            if not 0 <= trial["response_rate"] <= 100:
                raise ValueError(f"Response rate out of range: {trial['response_rate']}")
            
            if trial["patient_count"] < 0:
                raise ValueError(f"Negative patient count: {trial['patient_count']}")
            
            valid_trials.append(trial)
            
        except ValueError as e:
            errors.append(f"Trial {i}: {e}")
    
    # 6. Report validation results
    if errors:
        print(f"Validation warnings: {len(errors)} trials had issues")
        for error in errors[:5]:  # Show first 5
            print(f"  - {error}")
        if len(errors) > 5:
            print(f"  ... and {len(errors) - 5} more")
    
    print(f"Validated {len(valid_trials)}/{len(trials)} trials")
    
    return valid_trials
```

### JSON Validation

```python
# Using jsonValidate for structured data
from json_tools import jsonExtract, jsonValidate

# Define expected schema
schema = {
    "type": "object",
    "required": ["nct_id", "phase", "status"],
    "properties": {
        "nct_id": {"type": "string", "pattern": "^NCT[0-9]{8}$"},
        "phase": {"type": "string"},
        "status": {"type": "string"},
        "response_rate": {"type": "number", "minimum": 0, "maximum": 100}
    }
}

# Extract and validate
result = jsonExtract(file_path="output.json")
if result.success:
    validation = jsonValidate(data=result.data, schema=schema)
    if not validation.valid:
        print(f"Validation failed: {validation.errors}")
    else:
        print("Data validated successfully")
```

---

## 3. Error Handling & Retry Logic

### Retry Pattern (from retry.md)

```python
def fetch_with_retry(
    operation,
    max_attempts: int = 3,
    initial_delay: float = 2.0,
    backoff_factor: float = 2.0
):
    """Execute operation with exponential backoff retry.
    
    Args:
        operation: Function to execute
        max_attempts: Maximum retry attempts
        initial_delay: Initial delay in seconds
        backoff_factor: Multiplier for delay after each failure
        
    Returns:
        Operation result
        
    Raises:
        Exception: If all attempts fail
    """
    delay = initial_delay
    
    for attempt in range(max_attempts):
        try:
            result = operation()
            return result
            
        except Exception as e:
            if attempt < max_attempts - 1:
                print(f"Attempt {attempt + 1} failed: {e}")
                print(f"Retrying in {delay} seconds...")
                blockingTimer(delay)
                delay = delay * backoff_factor  # Exponential backoff
            else:
                print(f"All {max_attempts} attempts failed")
                raise
```

### Apply Retry to External Operations

```python
# BioMCP queries
def fetch_articles_with_retry(genes, diseases):
    """Fetch articles with retry logic."""
    return fetch_with_retry(
        lambda: biomcp_article_searcher(
            genes=genes,
            diseases=diseases,
            page_size=50
        )
    )

# Database queries
def query_database_with_retry(sql, params):
    """Query database with retry logic."""
    return fetch_with_retry(
        lambda: dbQuery(sql, params)
    )

# Web requests
def fetch_web_with_retry(url):
    """Fetch web content with retry logic."""
    return fetch_with_retry(
        lambda: webfetch(url)
    )
```

### Error Handling Best Practices

```python
# ✅ GOOD: Comprehensive error handling
def process_trials(file_path: str) -> Dict:
    """Process trials with comprehensive error handling."""
    try:
        # Load data
        df = load_data(file_path)
        
        # Validate
        if df.empty:
            raise ValueError("File contains no data")
        
        # Process
        results = analyze_trials(df)
        
        return results
        
    except FileNotFoundError:
        raise FileNotFoundError(f"File not found: {file_path}")
    
    except pd.errors.EmptyDataError:
        raise ValueError(f"File is empty or corrupt: {file_path}")
    
    except Exception as e:
        raise RuntimeError(f"Processing failed: {e}")

# ❌ BAD: No error handling
def process_trials(file_path: str) -> Dict:
    """Process trials without error handling."""
    df = load_data(file_path)  # May fail silently
    results = analyze_trials(df)  # May fail silently
    return results
```

---

## 4. Rate Limiting

### BioMCP Rate Limiting (MANDATORY)

```python
# ✅ GOOD: Sequential calls with rate limiting
articles = biomcp_article_searcher(genes=["BRAF"], page_size=50)
blockingTimer(0.3)  # 300ms delay

for article in articles[:10]:
    details = biomcp_article_getter(pmid=article["pmid"])
    blockingTimer(0.3)  # 300ms between each call
    # Process details

# ❌ BAD: Concurrent calls without rate limiting
# This will cause API throttling!
results = []
for pmid in pmids:
    results.append(biomcp_article_getter(pmid))  # No delay!
```

### Web Rate Limiting

```python
# ✅ GOOD: Conservative rate limiting for web
for url in urls:
    content = webfetch(url)
    blockingTimer(0.5)  # 500ms delay for web requests
    # Process content

# ❌ BAD: No rate limiting
for url in urls:
    content = webfetch(url)  # May get blocked!
```

### Rate Limiting Guidelines

| Tool Category | Delay | Rationale |
|--------------|-------|-----------|
| BioMCP tools | 0.3s | API rate limits |
| Web tools | 0.5s | Server courtesy |
| Database | None | Local/network, no limit |
| File operations | None | Local filesystem, no limit |
| Parser tools | None | Local processing, no limit |

---

## 5. Performance Optimization

### Use Appropriate Tools for Data Size

```python
# Small datasets (< 30 rows): Use table tools
if row_count < 30:
    tableFilterRows(file_path, column="Status", operator="=", value="Active")
    tableGroupBy(file_path, group_column="Phase", agg_column="Count", agg_type="count")

# Medium datasets (30-1000 rows): Use long-table-summary skill
elif row_count < 1000:
    skill long-table-summary
    # Follow 16-step workflow

# Large datasets (> 1000 rows): Use Python
else:
    uv run python .scripts/py/large_analysis.py --input data.xlsx
```

### Batch Processing

```python
# ✅ GOOD: Process in batches
batch_size = 100
total_items = len(data)

for i in range(0, total_items, batch_size):
    batch = data[i:i+batch_size]
    results = process_batch(batch)
    
    # Report progress
    completed = min(i + batch_size, total_items)
    percent = (completed / total_items) * 100
    print(f"Progress: {completed}/{total_items} ({percent:.1f}%)")

# ❌ BAD: Process all at once (may overload memory)
results = process_all(data)  # Memory issue with large datasets!
```

### Caching Results

```python
# Cache expensive operations
import hashlib
import json

def get_cache_key(params: Dict) -> str:
    """Generate cache key from parameters."""
    return hashlib.md5(json.dumps(params, sort_keys=True).encode()).hexdigest()

def cached_query(sql: str, params: Dict, cache_dir: str = ".cache") -> Any:
    """Execute query with caching."""
    import os
    
    cache_key = get_cache_key({"sql": sql, "params": params})
    cache_file = f"{cache_dir}/{cache_key}.json"
    
    # Check cache
    if os.path.exists(cache_file):
        with open(cache_file, 'r') as f:
            return json.load(f)
    
    # Execute query
    result = dbQuery(sql, params)
    
    # Save to cache
    os.makedirs(cache_dir, exist_ok=True)
    with open(cache_file, 'w') as f:
        json.dump(result, f)
    
    return result
```

---

## 6. Context Window Management

### Minimize Data in Context

```python
# ✅ GOOD: Summarize large datasets
if len(results) > 100:
    summary = {
        "total": len(results),
        "sample": results[:5],  # First 5 items
        "statistics": calculate_stats(results)
    }
    # Return summary, not full dataset

# ❌ BAD: Load entire dataset into context
return results  # 1000+ items in context!
```

### Use File-Based Data Exchange

```python
# ✅ GOOD: Write to file, pass file path
output_file = ".work/results.json"
with open(output_file, 'w') as f:
    json.dump(results, f)

return f"Results saved to {output_file}"

# ❌ BAD: Return large data structure
return results  # Consumes context window!
```

### Pagination for Large Result Sets

```python
# ✅ GOOD: Paginated retrieval
page_size = 50
all_results = []

for page in range(1, max_pages + 1):
    results = biomcp_article_searcher(
        genes=["BRAF"],
        page=page,
        page_size=page_size
    )
    blockingTimer(0.3)
    
    all_results.extend(results)
    
    if len(results) < page_size:
        break  # No more results

# ❌ BAD: Try to get all at once
all_results = biomcp_article_searcher(genes=["BRAF"], page_size=10000)
# May hit API limits!
```

---

## 7. Common Anti-Patterns to Avoid

### Anti-Pattern 1: Premature Optimization

```python
# ❌ BAD: Optimize before measuring
def process_data(data):
    # Complex optimization for small dataset
    return optimized_result

# ✅ GOOD: Measure first, optimize if needed
def process_data(data):
    if len(data) < 100:
        # Simple approach is fine
        return simple_process(data)
    else:
        # Optimize for large dataset
        return optimized_process(data)
```

### Anti-Pattern 2: Over-Engineering

```python
# ❌ BAD: Complex solution for simple problem
class TrialProcessor:
    def __init__(self, config):
        self.config = config
        self.validator = Validator()
        self.analyzer = Analyzer()
        # ... many more components

processor = TrialProcessor(config)
result = processor.process(trial)

# ✅ GOOD: Simple solution for simple problem
result = analyze_trial(trial)
```

### Anti-Pattern 3: Not Using Existing Tools

```python
# ❌ BAD: Write custom Python when tools exist
df = pd.read_excel("data.xlsx")
filtered = df[df["Phase"] == "Phase 3"]
stats = filtered.groupby("Condition").size()

# ✅ GOOD: Use existing tools
tableFilterRows(file_path, column="Phase", operator="=", value="Phase 3")
tableGroupBy(file_path, group_column="Condition", agg_column="Count", agg_type="count")
```

---

## 8. Best Practices Checklist

Before completing any data analysis task, verify:

### Upfront Filtering
- [ ] Data filtered at source (database WHERE, table filters, API parameters)
- [ ] No bulk retrieval then filtering in Python
- [ ] Result size limited appropriately
- [ ] Only necessary columns/fields retrieved

### Validation
- [ ] Data existence checked (not empty)
- [ ] Structure validated (required fields present)
- [ ] Types validated (correct data types)
- [ ] Values validated (within expected ranges)
- [ ] Quality validated (no duplicates, no corruption)

### Error Handling
- [ ] Try-except for external operations
- [ ] Retry logic for network/API calls
- [ ] Informative error messages
- [ ] Graceful degradation when possible
- [ ] Error logging for debugging

### Rate Limiting
- [ ] BioMCP: 0.3s delay between calls
- [ ] Web: 0.5s delay between requests
- [ ] Sequential (not concurrent) API calls
- [ ] Respect API rate limits

### Performance
- [ ] Appropriate tool selected for data size
- [ ] Batch processing for large datasets
- [ ] Caching for expensive operations
- [ ] Progress reporting for long operations

### Context Management
- [ ] Large datasets summarized, not fully loaded
- [ ] File-based data exchange for subagents
- [ ] Pagination for large result sets
- [ ] Only necessary data in context

---

## Summary

**Critical Rules:**

1. **ALWAYS filter upfront** - Never retrieve then filter
2. **ALWAYS validate data** - Check structure, types, values
3. **ALWAYS handle errors** - Retry with backoff
4. **ALWAYS rate limit** - Respect API limits
5. **ALWAYS optimize for size** - Use appropriate tools
6. **ALWAYS manage context** - Minimize data in context

**Following these best practices ensures:**
- ✅ Efficient data processing
- ✅ Reliable operations
- ✅ Professional quality results
- ✅ Optimal resource usage
- ✅ Reproducible research
