# Citations Pattern

Standardized citation format for biomedical research with automatic bibliography generation.

## Overview

Use this pattern to maintain consistent citations throughout research outputs. All findings must be backed by sources with proper citations.

## Citation Style

Use **numbered citations** for biomedical research:

- In-text: [1], [2], [3]
- Bibliography: Numbered list at end of document

## In-Text Citation Format

### Single Source
```
BRAF V600E mutations are found in approximately 50% of melanomas [1].
```

### Multiple Sources
```
Several studies have confirmed this association [1, 2, 3].
```

### Range of Sources
```
This has been extensively documented [1-5].
```

### Specific Claims
```
The drug was approved in 2011 [1] and has since become standard of care [2, 3].
```

## Bibliography Format

### PubMed Articles

```
[1] Author1 AB, Author2 CD, Author3 EF. Article Title. Journal Name. Year;Volume(Issue):Pages. PMID: XXXXXXXX.
```

**Example:**
```
[1] Chapman PB, Hauschild A, Robert C, et al. Improved survival with vemurafenib in melanoma with BRAF V600E mutation. N Engl J Med. 2011;364(26):2507-2516. PMID: 21639808.
```

### Clinical Trials

```
[N] NCT ID: Trial Title. Phase X. Sponsor: Company/Institution. Status: Recruiting/Completed. URL: https://clinicaltrials.gov/ct2/show/NCTXXXXXXX
```

**Example:**
```
[2] NCT04280705: A Study of Encorafenib Plus Cetuximab With or Without Nivolumab in Metastatic Colorectal Cancer. Phase 2. Sponsor: Pfizer. Status: Completed. https://clinicaltrials.gov/ct2/show/NCT04280705
```

### Web Sources

```
[N] Page Title. Website Name. Published/Updated Date. URL. Accessed: YYYY-MM-DD.
```

**Example:**
```
[3] BRAF Gene. National Cancer Institute. Updated 2024. https://www.cancer.gov/about-cancer/causes-prevention/genetics/brca-genes. Accessed: 2024-01-15.
```

### Drug/Chemical Information

```
[N] Drug Name. DrugBank ID: DBXXXXX. ChEMBL ID: CHEMBLXXXXX. Indication: Disease.
```

**Example:**
```
[4] Vemurafenib. DrugBank ID: DB08881. ChEMBL ID: CHEMBL1229511. Indication: Melanoma.
```

### Gene Information

```
[N] Gene Symbol: Gene Name. Entrez ID: XXXXXX. HGNC ID: HGNC:XXXX.
```

**Example:**
```
[5] BRAF: B-Raf proto-oncogene, serine/threonine kinase. Entrez ID: 673. HGNC ID: HGNC:1097.
```

## Source-Specific Citation Workflows

### From BioMCP Article Results

When using `biomcp_search` or `biomcp_article_searcher`:

```
1. Extract from result:
   - Authors (first author + "et al." if many)
   - Title
   - Journal
   - Year
   - PMID (from result.id or result.metadata)

2. Use biomcp_article_getter(pmid="XXXXXXXX") for full metadata if needed

3. Format citation
```

### From Clinical Trials

When using `biomcp_trial_searcher` or `biomcp_trial_getter`:

```
1. Extract from result:
   - NCT ID (result.id)
   - Official title
   - Phase
   - Sponsor
   - Status

2. Format citation with ClinicalTrials.gov URL
```

### From Gene/Drug/Variant Information

When using gene_getter, drug_getter, or variant_getter:

```
1. Extract identifiers:
   - Gene: Symbol, Entrez ID, HGNC ID
   - Drug: Name, DrugBank ID, ChEMBL ID
   - Variant: HGVS notation, rsID, ClinVar significance

2. Format as database citation
```

## Bibliography Section Format

Place bibliography at the end of your document:

```markdown
## References

[1] Chapman PB, Hauschild A, Robert C, et al. Improved survival with vemurafenib in melanoma with BRAF V600E mutation. N Engl J Med. 2011;364(26):2507-2516. PMID: 21639808.

[2] NCT04280705: A Study of Encorafenib Plus Cetuximab With or Without Nivolumab in Metastatic Colorectal Cancer. Phase 2. Sponsor: Pfizer. Status: Completed. https://clinicaltrials.gov/ct2/show/NCT04280705

[3] BRAF Gene. National Cancer Institute. Updated 2024. https://www.cancer.gov/about-cancer/causes-prevention/genetics/brca-genes. Accessed: 2024-01-15.
```

## Example: Research Report with Citations

```markdown
# BRAF Mutations in Melanoma

## Overview

BRAF V600E is the most common mutation in cutaneous melanoma, occurring in approximately 50% of cases [1]. This mutation leads to constitutive activation of the MAPK signaling pathway [2].

## Treatment Landscape

Targeted therapies against BRAF V600E have significantly improved outcomes:

- **Vemurafenib**: First FDA-approved BRAF inhibitor (2011) [3]
- **Dabrafenib**: Second-generation BRAF inhibitor [4]
- **Combination therapy**: BRAF + MEK inhibition improves survival [5]

## Clinical Trials

Several ongoing trials are exploring combination approaches:

- NCT04280705: Encorafenib + cetuximab ± nivolumab in colorectal cancer [6]
- NCT04511078: Adjuvant dabrafenib + trametinib in melanoma [7]

## References

[1] Davies H, Bignell GR, Cox C, et al. Mutations of the BRAF gene in human cancer. Nature. 2002;417(6892):949-954. PMID: 12068308.

[2] Wan PT, Garnett MJ, Roe SM, et al. Mechanism of activation of RAF-ERK signaling by oncogenic mutations of B-RAF. Cell. 2004;116(6):855-867. PMID: 15035987.

[3] Chapman PB, Hauschild A, Robert C, et al. Improved survival with vemurafenib in melanoma with BRAF V600E mutation. N Engl J Med. 2011;364(26):2507-2516. PMID: 21639808.

[4] Hauschild A, Grob JJ, Demidov LV, et al. Dabrafenib in BRAF-mutated metastatic melanoma: a multicentre, open-label, phase 3 randomised controlled trial. Lancet. 2012;380(9839):358-365. PMID: 22735384.

[5] Robert C, Karaszewska B, Schachter J, et al. Improved overall survival in melanoma with combined dabrafenib and trametinib. N Engl J Med. 2015;372(1):30-39. PMID: 25399551.

[6] NCT04280705: A Study of Encorafenib Plus Cetuximab With or Without Nivolumab in Metastatic Colorectal Cancer. Phase 2. Sponsor: Pfizer. Status: Completed. https://clinicaltrials.gov/ct2/show/NCT04280705

[7] NCT04511078: Adjuvant Dabrafenib Plus Trametinib in Resected BRAF V600-Mutant Melanoma. Phase 3. Sponsor: Novartis. Status: Recruiting. https://clinicaltrials.gov/ct2/show/NCT04511078
```

## Citation Quality Standards

### What to Cite

| Source Type | Citation Required |
|-------------|-------------------|
| Published research | Yes |
| Clinical trial data | Yes |
| Drug approval info | Yes |
| Gene/variant annotations | Yes |
| Statistical claims | Yes |
| Direct quotes | Yes |
| General knowledge | No (e.g., "DNA has 4 bases") |

### Citation Integrity

1. **Verify source exists**: Always confirm PMID, NCT ID, URL is valid
2. **Quote accurately**: Don't misrepresent findings
3. **Cite primary sources**: Prefer original papers over reviews
4. **Update outdated citations**: Use latest evidence when available

## Tools for Citation Generation

| Tool | Use Case |
|------|----------|
| `biomcp_article_getter` | Get full article metadata from PMID |
| `biomcp_trial_getter` | Get trial details from NCT ID |
| `biomcp_gene_getter` | Get gene identifiers |
| `biomcp_drug_getter` | Get drug identifiers |

## Best Practices

1. **Cite as you write**: Add citations immediately when making claims
2. **Number sequentially**: [1], [2], [3] in order of appearance
3. **Include access dates**: For web sources, always include when accessed
4. **Verify PMIDs**: Double-check PMID matches the article
5. **Keep bibliography alphabetical by number**: Not by author
6. **Format consistently**: Same style throughout document
