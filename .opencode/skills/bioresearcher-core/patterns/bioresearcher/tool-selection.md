# Tool Selection Decision Framework

Comprehensive decision trees for choosing the correct tool based on user intent and data source.

## Overview

This pattern guides intelligent tool selection across 7 tool categories:
1. Database Tools (db*)
2. Table Tools (table*)
3. Web Tools (web*)
4. BioMCP Tools (biomcp*)
5. Parser Tools (parse*)
6. Miscellaneous Tools
7. Core File Tools

---

## 1. Data Source Identification

```
USER INTENT ANALYSIS:
├─ "Query database" / "SQL" / "table in database"
│  → DATABASE TOOLS (db*)
│
├─ "Excel file" / "CSV file" / "table file" / "xlsx" / "spreadsheet"
│  → TABLE TOOLS (table*)
│
├─ "website" / "web page" / "URL" / "fetch from"
│  → WEB TOOLS (web*)
│
├─ "PubMed" / "articles" / "literature" / "papers" / "publications"
│  → BIOMCP ARTICLE TOOLS
│
├─ "clinical trial" / "NCT" / "trial data"
│  → BIOMCP TRIAL TOOLS
│
├─ "gene" / "variant" / "mutation" / "genomic"
│  → BIOMCP GENE/VARIANT TOOLS
│
├─ "drug" / "compound" / "FDA" / "medication"
│  → BIOMCP DRUG/FDA TOOLS
│
├─ "parse" / "convert" / "XML" / "OBO" / "ontology"
│  → PARSER TOOLS (parse*)
│
└─ Unclear intent
   → ASK user for clarification via question tool
```

---

## 2. Database Tools Decision Tree

### When to Use
- User mentions database, SQL, or structured query
- Need to query relational or document database
- Data exists in MySQL or MongoDB

### Workflow

```
IF user mentions database/SQL:
  
  Step 1: Check Configuration
    IF env.jsonc does NOT exist:
      → Load skill 'env-jsonc-setup'
      → Follow skill workflow to configure database
  
  Step 2: Discover Available Data
    dbListTables() → Show all tables to user
    → Identify relevant tables
  
  Step 3: Understand Schema
    dbDescribeTable(table_name) → Get column structure
    → Identify available fields, data types, keys
  
  Step 4: Query with Filters (BEST PRACTICE)
    ✅ DO: dbQuery(
        "SELECT * FROM trials WHERE phase = :phase AND status = :status",
        {phase: "Phase 3", status: "Recruiting"}
      )
    
    ❌ DON'T: dbQuery("SELECT * FROM trials")
              → then filter in Python
  
  Step 5: Use Named Parameters (SAFETY)
    - NEVER concatenate SQL strings
    - ALWAYS use :paramName syntax
    - Pass parameters as second argument
```

### Example: Database Research Workflow

```markdown
User: "Find all Phase 3 melanoma trials from the database"

Agent actions:
1. dbListTables() → See available tables
2. dbDescribeTable("clinical_trials") → Understand schema
3. dbQuery(
     "SELECT * FROM clinical_trials 
      WHERE phase = :phase 
        AND condition LIKE :condition
        AND status = :status",
     {
       phase: "Phase 3",
       condition: "%melanoma%",
       status: "Recruiting"
     }
   )
4. Return filtered results with proper citations
```

### Tool Reference

| Tool | Purpose | When to Use |
|------|---------|-------------|
| `dbListTables` | List all tables/collections | Initial discovery |
| `dbDescribeTable` | Get column schema | Before querying |
| `dbQuery` | Execute SELECT query | Data retrieval |

---

## 3. Table Tools Decision Tree

### When to Use
- User provides Excel (.xlsx), CSV, or ODS file
- Need to analyze, filter, or transform tabular data
- Data exists in local file system

### Row Count Decision Matrix

```
IF rows < 30:
  → Use table tools directly (fastest)
     - tableFilterRows() for filtering
     - tableGroupBy() for aggregation
     - tableSummarize() for statistics
     - tablePivotSummary() for cross-tabs

IF rows >= 30 AND rows < 1000:
  → Decision based on complexity:
     IF need structured summarization with JSON schema:
       → Load skill 'long-table-summary'
     ELSE:
       → Use table tools directly

IF rows >= 1000:
  → Decision based on complexity:
     IF need structured summarization:
       → Load skill 'long-table-summary'
     ELSE IF need complex transformations:
       → Write custom Python script
     ELSE:
       → Use table tools with targeted operations
```

### Workflow

```
IF user provides Excel/CSV file:
  
  Step 1: Preview Structure
    tableListSheets(file_path) → See available sheets
    tableGetSheetPreview(file_path) → First 6 rows
    tableGetHeaders(file_path) → Column names
  
  Step 2: Determine Row Count
    tableGetRange(file_path, range="A1:A10000")
    → Count non-empty rows
  
  Step 3: Choose Analysis Approach (see decision matrix above)
  
  Step 4: Apply Upfront Filtering (BEST PRACTICE)
    ✅ DO: tableFilterRows(
        file_path,
        column="Status",
        operator="=",
        value="Active"
      )
    
    ❌ DON'T: Load entire table then filter in Python
```

### Upfront Filtering Examples

```markdown
# Filter by single condition
tableFilterRows(file, column="Phase", operator="=", value="Phase 3")

# Filter by numeric range
tableFilterRows(file, column="Age", operator=">=", value=18)

# Filter by text contains
tableFilterRows(file, column="Condition", operator="contains", value="melanoma")
```

### Tool Reference

| Tool | Purpose | When to Use |
|------|---------|-------------|
| `tableListSheets` | List worksheet names | Multi-sheet workbooks |
| `tableGetSheetPreview` | Preview first 6 rows | Understand structure |
| `tableGetHeaders` | Get column names | Identify available fields |
| `tableFilterRows` | Filter by condition | Extract subsets |
| `tableSearch` | Search across all cells | Find specific values |
| `tableSummarize` | Statistical summary | Numeric analysis |
| `tableGroupBy` | Group and aggregate | Categorical analysis |
| `tablePivotSummary` | Cross-tabulation | Multi-dimensional analysis |
| `tableGetRange` | Extract data range | Bulk data retrieval |
| `tableCreateFile` | Create new table | Output generation |
| `tableAppendRows` | Append rows | Data combination |

---

## 4. BioMCP Tools Decision Tree

### When to Use
- Biomedical research queries
- Literature search
- Clinical trial data
- Gene/variant/drug information
- FDA regulatory data

### Domain Selection

```
IF biomedical research query:
  
  Determine Domain:
  
  ├─ Literature/Papers
  │  → biomcp_article_searcher(keywords, genes, diseases)
  │  → biomcp_article_getter(pmid)
  │  
  ├─ Clinical Trials
  │  → biomcp_trial_searcher(conditions, interventions)
  │  → biomcp_trial_getter(nct_id)
  │  → biomcp_trial_protocol_getter(nct_id)
  │  → biomcp_trial_outcomes_getter(nct_id)
  │  
  ├─ Genes
  │  → biomcp_gene_getter(gene_id_or_symbol)
  │  
  ├─ Variants/Mutations
  │  → biomcp_variant_searcher(gene, significance)
  │  → biomcp_variant_getter(variant_id)
  │  
  ├─ Drugs/Compounds
  │  → biomcp_drug_getter(drug_id_or_name)
  │  
  ├─ FDA Data
  │  → biomcp_openfda_adverse_searcher(drug, reaction)
  │  → biomcp_openfda_label_searcher(name, indication)
  │  → biomcp_openfda_approval_searcher(drug)
  │  
  └─ Cross-Domain Search
     → biomcp_search(query="gene:BRAF AND disease:melanoma")
```

### Targeted Queries (BEST PRACTICE)

```
RULE: Use specific filters to narrow results upfront

✅ DO:
  biomcp_article_searcher(
    genes=["BRAF", "NRAS"],
    diseases=["melanoma"],
    keywords=["treatment resistance"],
    page_size=50
  )

❌ DON'T:
  biomcp_search(query="BRAF")
  → then manually filter through thousands of results
```

### Rate Limiting (MANDATORY)

```
ALWAYS use blockingTimer(0.3) between consecutive biomcp calls

FOR each biomcp query:
  result = biomcp_tool(...)
  
  IF more queries remain:
    blockingTimer(0.3)  # 300ms delay
  
NEVER run concurrent biomcp calls (sequential only)
```

### Example: Literature Research Workflow

```markdown
User: "Find recent papers on BRAF V600E treatment resistance in melanoma"

Agent actions:
1. biomcp_article_searcher(
     genes=["BRAF"],
     diseases=["melanoma"],
     variants=["V600E"],
     keywords=["treatment resistance"],
     page_size=20
   )
2. blockingTimer(0.3)
3. FOR each relevant article:
     biomcp_article_getter(pmid=article.id)
     blockingTimer(0.3)
4. Synthesize findings with citations
```

---

## 5. Web Tools Decision Tree

### When to Use
- User provides specific URL
- Need current information from web
- Official biotech/pharma company data
- Information not available in databases

### Search vs Fetch

```
IF user provides specific URL:
  → web-reader_webReader(url, return_format="markdown")
  → Extract content

IF user needs to find information:
  → web-search-prime_web_search_prime(search_query)
  → Identify relevant URLs
  → web-reader_webReader(url) for promising results
```

### Source Quality Verification

```
Source Priority:
  ✅ PREFER (High Quality):
    - .gov domains (FDA, NIH, NCI)
    - Official biotech/pharma company websites
    - Peer-reviewed journal websites
    - ClinicalTrials.gov
  
  ⚠️ CAUTION (Medium Quality):
    - News websites (verify with primary sources)
    - Industry publications
    - Conference abstracts
  
  ❌ AVOID (Low Quality):
    - Blogs and forums
    - User-generated content
    - Promotional materials
    - Unverified claims
```

### Rate Limiting

```
FOR each web request:
  result = webfetch(...)
  
  IF more requests remain:
    blockingTimer(0.5)  # 500ms delay (more conservative)
```

---

## 6. Parser Tools Decision Tree

### When to Use
- Need to parse structured file formats
- Convert between formats
- Process ontology files

### Tool Selection

```
IF file is PubMed XML (.xml or .xml.gz):
  → parse_pubmed_articleSet(
      filePath,
      outputMode="excel",  # or "single" or "individual"
      outputFileName="pubmed_results.xlsx"
    )

IF file is OBO ontology (.obo):
  → parse_obo_file(
      filePath,
      outputFileName="ontology.csv"
    )

IF file is JSON:
  → jsonExtract(file_path)
  → jsonValidate(data, schema) if needed
```

---

## 7. Decision Flowchart Summary

```
START: User Query
  │
  ├─ Analyze user intent
  │
  ├─ Identify data source
  │   ├─ Database → db* tools
  │   ├─ Table file → table* tools
  │   ├─ Web → web* tools
  │   ├─ Biomedical → biomcp* tools
  │   └─ Parse needed → parse* tools
  │
  ├─ Apply upfront filtering
  │   └─ Use targeted queries/filters
  │
  ├─ Execute with rate limiting
  │   └─ blockingTimer between API calls
  │
  ├─ Validate results
  │   └─ Check data quality
  │
  └─ Synthesize with citations
      └─ Reference-based report
```

---

## Best Practices Summary

### ✅ DO
- Use targeted queries with specific filters
- Apply upfront filtering at data source
- Use named parameters in SQL queries
- Implement rate limiting between API calls
- Validate data before processing
- Use decision trees to select tools

### ❌ DON'T
- Use bulk queries then filter in Python
- Concatenate SQL strings
- Run concurrent API calls
- Skip rate limiting
- Load entire datasets without filtering
- Guess tool choices without analysis

---

## Common Patterns

### Pattern 1: Database → Analysis
```
dbListTables() 
→ dbDescribeTable() 
→ dbQuery(with filters) 
→ analysis
```

### Pattern 2: Literature Search
```
biomcp_article_searcher(filters) 
→ blockingTimer(0.3) 
→ biomcp_article_getter(pmid) 
→ repeat
```

### Pattern 3: Table Analysis
```
tableGetSheetPreview() 
→ determine row count 
→ choose approach 
→ execute
```

### Pattern 4: Web Research
```
web-search-prime() 
→ identify URLs 
→ web-reader_webReader() 
→ extract data
```
