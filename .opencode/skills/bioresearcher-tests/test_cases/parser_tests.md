# Parser Tool Tests

## Test: PubMed XML - Single Mode
- Tool: parse_pubmed_articleSet
- Input:
  ```json
  {"filePath": ".bioresearcher-tests/workspace/pubmed_sample.xml", "outputMode": "single", "verbose": false}
  ```
- Validators:
  - success_is_true
  - file_exists
  - stats.total === 2
  - stats.successful === 2
- Expected: Single markdown file with 2 articles

## Test: PubMed XML - Excel Mode
- Tool: parse_pubmed_articleSet
- Input:
  ```json
  {"filePath": ".bioresearcher-tests/workspace/pubmed_sample.xml", "outputMode": "excel", "outputFileName": "pubmed_test.xlsx", "verbose": false}
  ```
- Validators:
  - success_is_true
  - file_exists
  - file ends with .xlsx
- Expected: Excel file with PMID, Title, Authors, Journal, DOI, Abstract, Keywords columns

## Test: PubMed XML - Individual Mode
- Tool: parse_pubmed_articleSet
- Input:
  ```json
  {"filePath": ".bioresearcher-tests/workspace/pubmed_sample.xml", "outputMode": "individual", "verbose": false}
  ```
- Validators:
  - success_is_true
  - directory exists
- Expected: Directory with individual .md files per article

## Test: OBO - Basic Parsing
- Tool: parse_obo_file
- Input:
  ```json
  {"filePath": ".bioresearcher-tests/workspace/obo_sample.obo", "outputFileName": "obo_test.csv", "verbose": false}
  ```
- Validators:
  - success_is_true
  - file_exists
  - stats.terms >= 3
- Expected: CSV file with term data

## Test: PubMed - Nonexistent File
- Tool: parse_pubmed_articleSet
- Input:
  ```json
  {"filePath": ".bioresearcher-tests/workspace/nonexistent.xml", "outputMode": "single"}
  ```
- Validators:
  - contains_string("error")
- Expected: Error response

## Test: PubMed - Compressed Input
- Tool: parse_pubmed_articleSet
- Input:
  ```json
  {"filePath": "<skill_path>/resources/pubmed_sample.xml.gz", "outputMode": "single", "verbose": false}
  ```
- Validators:
  - success_is_true
  - stats.total === 2
- Expected: Handles .xml.gz compressed files directly

## Test: OBO - Nonexistent File
- Tool: parse_obo_file
- Input:
  ```json
  {"filePath": ".bioresearcher-tests/workspace/nonexistent.obo", "outputFileName": "test.csv", "verbose": false}
  ```
- Validators:
  - contains_string("error")
- Expected: Error response for file not found
