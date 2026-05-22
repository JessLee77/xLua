# JSON Tool Tests

## Test: Extract - Simple Object
- Tool: jsonExtract
- Input:
  ```json
  {"file_path": ".bioresearcher-tests/workspace/json_samples/simple_object.json", "return_all": false}
  ```
- Validators:
  - success_is_true
  - has data object
  - data.name === "test"
  - data.value === 42
- Expected: Parsed JSON object with name="test", value=42

## Test: Extract - Array
- Tool: jsonExtract
- Input:
  ```json
  {"file_path": ".bioresearcher-tests/workspace/json_samples/simple_array.json", "return_all": false}
  ```
- Validators:
  - success_is_true
  - isArray(data)
  - array_length >= 3
- Expected: Parsed JSON array [1, 2, 3]

## Test: Extract - Nested Object
- Tool: jsonExtract
- Input:
  ```json
  {"file_path": ".bioresearcher-tests/workspace/json_samples/nested_object.json", "return_all": false}
  ```
- Validators:
  - success_is_true
  - has data.nested
- Expected: Nested object parsed with data.nested.deep

## Test: Extract - From Markdown
- Tool: jsonExtract
- Input:
  ```json
  {"file_path": ".bioresearcher-tests/workspace/json_samples/in_markdown.md", "return_all": false}
  ```
- Validators:
  - success_is_true
  - data.embedded === "true"
  - method === "json_code_block"
- Expected: JSON extracted from markdown code block

## Test: Extract - Return All
- Tool: jsonExtract
- Input:
  ```json
  {"file_path": ".bioresearcher-tests/workspace/json_samples/simple_array.json", "return_all": true}
  ```
- Validators:
  - success_is_true
  - has count
- Expected: Array with count metadata

## Test: Extract - File Not Found
- Tool: jsonExtract
- Input:
  ```json
  {"file_path": ".bioresearcher-tests/workspace/nonexistent.json", "return_all": false}
  ```
- Validators:
  - success_is_false
  - error.code === "FILE_NOT_FOUND"
- Expected: File not found error

## Test: Validate - Valid Data
- Tool: jsonValidate
- Input:
  ```json
  {"data": "{\"name\": \"test\", \"value\": 42}", "schema": "{\"type\": \"object\", \"properties\": {\"name\": {\"type\": \"string\"}, \"value\": {\"type\": \"number\"}}, \"required\": [\"name\"]}"}
  ```
- Validators:
  - success_is_true
  - valid === true OR has data
- Expected: Validation passes

## Test: Validate - Invalid Data
- Tool: jsonValidate
- Input:
  ```json
  {"data": "{\"name\": 123}", "schema": "{\"type\": \"object\", \"properties\": {\"name\": {\"type\": \"string\"}}, \"required\": [\"name\"]}"}
  ```
- Validators:
  - success_is_true
  - has errors
- Expected: Validation errors (name should be string)

## Test: Validate - From Schema File
- Tool: jsonValidate
- Input:
  ```json
  {"data": "{\"name\": \"test\", \"value\": 42}", "schema": ".bioresearcher-tests/workspace/json_samples/schema_draft7.json"}
  ```
- Validators:
  - success_is_true
- Expected: Schema loaded from file and validation passes

## Test: Infer - Object
- Tool: jsonInfer
- Input:
  ```json
  {"data": "{\"name\": \"test\", \"count\": 5, \"active\": true}", "strict": false}
  ```
- Validators:
  - success_is_true
  - has data object
  - inferredType === "object"
- Expected: JSON Schema inferred for object

## Test: Infer - Array
- Tool: jsonInfer
- Input:
  ```json
  {"data": "[1, 2, 3, 4, 5]", "strict": false}
  ```
- Validators:
  - success_is_true
  - inferredType === "array"
- Expected: Array schema inferred

## Test: Infer - Strict Mode
- Tool: jsonInfer
- Input:
  ```json
  {"data": "{\"name\": \"test\"}", "strict": true}
  ```
- Validators:
  - success_is_true
  - strictMode === "true"
- Expected: Schema with required fields
