# Rate Limiting Pattern

Enforce delays between API calls to respect rate limits and avoid throttling.

## Overview

Use this pattern when making sequential API calls to services with rate limits. This is especially important for BioMCP tools that query external biomedical databases.

## Pattern Algorithm

```
1. Initialize: delay = D (based on service type)
2. For each API call:
   a. Make the API call
   b. If more calls remain:
      - Use blockingTimer(delay=D)
   c. Continue to next call
```

## Parameters

| Parameter | Default | Description |
|-----------|---------|-------------|
| `delay` | 0.3 | Wait time in seconds between calls |

## Tool: blockingTimer

```
blockingTimer(delay: number)
```

- Maximum delay: 300 seconds
- Returns: "Timer completed: waited X seconds (actual elapsed: Ys)"

## Recommended Delays by Service

| Service Type | Recommended Delay | Reason |
|--------------|-------------------|--------|
| BioMCP tools | 0.3 - 0.5 seconds | NCBI/API rate limits |
| External APIs | 1 - 2 seconds | General API etiquette |
| NCBI FTP | 2 - 3 seconds | FTP server limits |
| Web scraping | 3 - 5 seconds | Respect robots.txt |

## Example: BioMCP Sequential Calls

```
# Configuration
delay = 0.3  # 300ms between calls

# Sequential BioMCP calls with rate limiting
biomcp_search(query="gene:BRAF AND disease:melanoma")
blockingTimer(delay=0.3)

biomcp_fetch(id="NCT04280705")
blockingTimer(delay=0.3)

biomcp_article_getter(pmid="35271234")
blockingTimer(delay=0.3)

# Continue with more calls...
```

## Example: Batch Processing with Rate Limiting

```
# Configuration
delay = 0.5  # 500ms for safety
items = ["item1", "item2", "item3", "item4", "item5"]

# Process with rate limiting
for i, item in enumerate(items):
    result = biomcp_fetch(id=item)
    process(result)
    
    # Don't delay after the last item
    if i < len(items) - 1:
        blockingTimer(delay=delay)
```

## Example: Subagent Rate Limiting

For bioresearcherDR_worker subagents:

```
# Worker configuration
delay = 0.5  # Workers use slightly longer delay

# Sequential research calls
biomcp_search(query=gene_query)
blockingTimer(delay=0.5)

biomcp_article_searcher(genes=["BRAF"], diseases=["melanoma"])
blockingTimer(delay=0.5)

biomcp_trial_searcher(conditions=["melanoma"])
blockingTimer(delay=0.5)
```

## Why Rate Limiting Matters

1. **Avoid API bans**: Many services block IPs that exceed rate limits
2. **Ensure reliability**: Steady requests are less likely to timeout
3. **Respect resources**: Shared APIs serve many users
4. **Comply with ToS**: Most APIs require reasonable request rates

## Common Rate Limits

| Service | Rate Limit | Source |
|---------|------------|--------|
| NCBI E-utilities | 3 requests/second | NCBI Guidelines |
| PubMed API | 3 requests/second | NCBI Guidelines |
| ClinicalTrials.gov | Varies | Check API docs |
| MyGene.info | 10 requests/second | BioThings docs |
| MyVariant.info | 10 requests/second | BioThings docs |

## Integration with Retry Pattern

When combining rate limiting with retries:

```
# Retry configuration
max_attempts = 3
retry_delay = 2
rate_limit_delay = 0.3

for attempt in range(max_attempts):
    result = api_call()
    if result.success:
        break
    
    # Retry delay (longer)
    if attempt < max_attempts - 1:
        blockingTimer(delay=retry_delay)
        retry_delay *= 2  # Exponential backoff
    continue

# Rate limit before next call
blockingTimer(delay=rate_limit_delay)
```

## Best Practices

1. **Be conservative**: Use 0.5s when uncertain about limits
2. **Don't skip delays**: Even "quick" calls need spacing
3. **Adjust for errors**: Increase delay if getting 429 errors
4. **Document your delays**: Note why specific values were chosen
5. **Parallel with caution**: Parallel calls multiply effective rate

## Error Handling

If you receive rate limit errors (HTTP 429):

```
# Detect rate limit error
if response.status_code == 429:
    # Increase delay and retry
    blockingTimer(delay=5)  # Wait longer
    retry_request()
```

## Integration with Other Patterns

| Pattern | Integration |
|---------|-------------|
| `retry.md` | Rate limit delay + retry backoff |
| `progress.md` | Rate limiting during batch progress |
| `subagent-waves.md` | Each subagent applies its own rate limiting |
