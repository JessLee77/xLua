"""
BioResearcher Plugin Test Runner

Generates test structure and provides utilities for running tests.
Actual tests are executed by the agent using the skill.

Usage:
    uv run python test_runner.py --help
    uv run python test_runner.py --list
    uv run python test_runner.py --category parser
"""

import argparse
import json
import os
import re
import sys
from dataclasses import dataclass, field
from datetime import datetime
from pathlib import Path
from typing import Any


@dataclass
class TestCase:
    """Represents a single test case."""

    name: str
    tool: str
    input: dict
    validators: list[str]
    expected: str
    category: str


@dataclass
class TestResult:
    """Result of a single test execution."""

    test_name: str
    tool: str
    category: str
    passed: bool
    actual: Any
    expected: str
    validators: list[str]
    validator_results: list[dict] = field(default_factory=list)
    error: str | None = None


def parse_test_cases(md_content: str, category: str) -> list[TestCase]:
    """
    Parse test cases from markdown content.

    Format:
    ## Test: <name>
    - Tool: <tool>
    - Input:
      ```json
      {...}
      ```
    - Validators:
      - <validator>
    - Expected: <description>
    """
    tests = []

    test_blocks = re.split(r"\n## Test: ", md_content)

    for block in test_blocks[1:]:
        if not block.strip():
            continue

        try:
            name_match = re.match(r"(.+?)\n", block)
            if not name_match:
                continue
            name = name_match.group(1).strip()

            tool_match = re.search(r"- Tool:\s*(.+?)\n", block)
            if not tool_match:
                continue
            tool = tool_match.group(1).strip()

            input_match = re.search(r"- Input:\s*```json\n(.+?)```", block, re.DOTALL)
            if not input_match:
                continue
            input_json = json.loads(input_match.group(1).strip())

            validators_match = re.search(r"- Validators:\n((?:  - .+\n)+)", block)
            if validators_match:
                validators = [
                    v.strip()[2:]
                    for v in validators_match.group(1).strip().split("\n")
                    if v.strip().startswith("- ")
                ]
            else:
                validators = []

            expected_match = re.search(r"- Expected:\s*(.+?)(?:\n|$)", block)
            expected = expected_match.group(1).strip() if expected_match else ""

            tests.append(
                TestCase(
                    name=name,
                    tool=tool,
                    input=input_json,
                    validators=validators,
                    expected=expected,
                    category=category,
                )
            )
        except (json.JSONDecodeError, AttributeError) as e:
            continue

    return tests


def load_all_tests(test_cases_dir: str) -> dict[str, list[TestCase]]:
    """Load all test cases from test_cases directory."""
    categories = {
        "parser_tests.md": "parser",
        "table_tests.md": "table",
        "json_tests.md": "json",
        "misc_tests.md": "misc",
        "skill_tests.md": "skill",
    }

    all_tests = {}

    for filename, category in categories.items():
        filepath = os.path.join(test_cases_dir, filename)
        if os.path.exists(filepath):
            with open(filepath, "r", encoding="utf-8") as f:
                content = f.read()
            tests = parse_test_cases(content, category)
            all_tests[category] = tests

    return all_tests


def validate_result(result: Any, validators: list[str]) -> tuple[bool, list[dict]]:
    """
    Run validators against result.

    Returns:
        (all_passed, validator_results)
    """
    results = []
    all_passed = True

    result_str = json.dumps(result) if isinstance(result, (dict, list)) else str(result)
    result_obj = result if isinstance(result, dict) else {}

    for validator in validators:
        passed = False
        detail = ""

        if validator == "success_is_true":
            passed = result_obj.get("success") is True
            detail = f"success={result_obj.get('success')}"

        elif validator == "success_is_false":
            passed = result_obj.get("success") is False
            detail = f"success={result_obj.get('success')}"

        elif validator == "file_exists":
            path = result_obj.get("filePath") or result_obj.get("file_path")
            passed = path and os.path.exists(path)
            detail = f"path={path}, exists={passed}"

        elif validator == "json_valid":
            try:
                if isinstance(result, str):
                    json.loads(result)
                passed = True
            except:
                pass
            detail = "parsed as JSON"

        elif validator.startswith("stats.total"):
            match = re.match(r"stats\.total\s*===\s*(\d+)", validator)
            if match:
                expected = int(match.group(1))
                actual = result_obj.get("stats", {}).get("total", 0)
                passed = actual == expected
                detail = f"total={actual}, expected={expected}"

        elif validator.startswith("stats.successful"):
            match = re.match(r"stats\.successful\s*===\s*(\d+)", validator)
            if match:
                expected = int(match.group(1))
                actual = result_obj.get("stats", {}).get("successful", 0)
                passed = actual == expected
                detail = f"successful={actual}, expected={expected}"

        elif validator.startswith("stats.terms"):
            match = re.match(r"stats\.terms\s*>=\s*(\d+)", validator)
            if match:
                min_val = int(match.group(1))
                actual = result_obj.get("stats", {}).get("terms", 0)
                passed = actual >= min_val
                detail = f"terms={actual}, min={min_val}"

        elif validator.startswith("array_length"):
            match = re.match(r"array_length\s*>=?\s*(\d+)", validator)
            if match:
                min_len = int(match.group(1))
                arr = (
                    result_obj.get("sheets")
                    or result_obj.get("results")
                    or result_obj.get("matched_rows")
                    or result_obj.get("preview")
                    or result_obj.get("headers")
                    or []
                )
                passed = len(arr) >= min_len
                detail = f"length={len(arr)}, min={min_len}"

        elif validator.startswith("rows"):
            match = re.match(r"rows\s*===\s*(\d+)", validator)
            if match:
                expected = int(match.group(1))
                actual = result_obj.get("rows", 0)
                passed = actual == expected
                detail = f"rows={actual}, expected={expected}"

        elif validator.startswith("columns"):
            match = re.match(r"columns\s*===\s*(\d+)", validator)
            if match:
                expected = int(match.group(1))
                actual = result_obj.get("columns", 0)
                passed = actual == expected
                detail = f"columns={actual}, expected={expected}"

        elif validator.startswith("contains_string"):
            match = re.search(r'"(.+?)"', validator)
            if match:
                substr = match.group(1)
                passed = substr.lower() in result_str.lower()
                detail = f"contains '{substr}': {passed}"

        elif validator.startswith("error.code"):
            match = re.match(r'error\.code\s*===\s*"(.+?)"', validator)
            if match:
                expected = match.group(1)
                actual = result_obj.get("error", {}).get("code")
                passed = actual == expected
                detail = f"error.code={actual}, expected={expected}"

        elif validator.startswith("result"):
            match = re.match(r"result\s*===\s*(\d+\.?\d*)", validator)
            if match:
                expected = float(match.group(1))
                actual = result_obj.get("result")
                passed = actual is not None and abs(float(actual) - expected) < 0.001
                detail = f"result={actual}, expected={expected}"

        elif validator == "has result":
            passed = "result" in result_obj
            detail = f"has result: {passed}"

        elif validator == "has data object":
            passed = "data" in result_obj and isinstance(result_obj["data"], dict)
            detail = f"has data: {passed}"

        elif validator.startswith("data.name"):
            match = re.match(r'data\.(\w+)\s*===\s*"(.+)"', validator)
            if match:
                key, expected = match.group(1), match.group(2)
                actual = result_obj.get("data", {}).get(key)
                passed = actual == expected
                detail = f"data.{key}={actual}, expected={expected}"

        elif validator.startswith("data.value"):
            match = re.match(r"data\.(\w+)\s*===\s*(\d+)", validator)
            if match:
                key, expected = match.group(1), int(match.group(2))
                actual = result_obj.get("data", {}).get(key)
                passed = actual == expected
                detail = f"data.{key}={actual}, expected={expected}"

        elif validator.startswith("data.embedded"):
            match = re.match(r'data\.(\w+)\s*===\s*"(.+)"', validator)
            if match:
                key, expected = match.group(1), match.group(2)
                actual = str(result_obj.get("data", {}).get(key, ""))
                passed = actual == expected
                detail = f"data.{key}={actual}, expected={expected}"

        elif validator == "isArray(data)":
            passed = isinstance(result_obj.get("data"), list)
            detail = f"isArray: {passed}"

        elif validator == "has data.nested":
            data = result_obj.get("data", {})
            passed = "nested" in data if isinstance(data, dict) else False
            detail = f"has nested: {passed}"

        elif validator == "has count":
            passed = "count" in result_obj or "count" in result_obj.get("metadata", {})
            detail = f"has count: {passed}"

        elif validator.startswith("inferredType"):
            match = re.match(r'inferredType\s*===\s*"(.+?)"', validator)
            if match:
                expected = match.group(1)
                actual = result_obj.get("metadata", {}).get("inferredType")
                passed = actual == expected
                detail = f"inferredType={actual}, expected={expected}"

        elif validator.startswith("strictMode"):
            match = re.match(r'strictMode\s*===\s*"?(true|false)"?', validator)
            if match:
                expected = match.group(1) == "true"
                actual = result_obj.get("metadata", {}).get("strictMode")
                passed = actual == expected
                detail = f"strictMode={actual}, expected={expected}"

        elif validator.startswith("method"):
            match = re.match(r'method\s*===\s*"(.+?)"', validator)
            if match:
                expected = match.group(1)
                actual = result_obj.get("metadata", {}).get("method")
                passed = actual == expected
                detail = f"method={actual}, expected={expected}"

        elif validator == "has errors":
            passed = "errors" in result_obj and len(result_obj.get("errors", [])) > 0
            detail = f"has errors: {passed}"

        elif validator == "valid === true OR has data":
            passed = result_obj.get("valid") is True or "data" in result_obj
            detail = f"valid={result_obj.get('valid')}, has_data={'data' in result_obj}"

        elif validator.startswith("headers includes"):
            match = re.search(r'"(.+?)"', validator)
            if match:
                expected = match.group(1)
                headers = result_obj.get("headers", [])
                passed = expected in headers or expected.lower() in [
                    h.lower() for h in headers
                ]
                detail = f"headers={headers}"

        elif validator == "has preview array":
            passed = "preview" in result_obj and isinstance(result_obj["preview"], list)
            detail = f"has preview: {passed}"

        elif validator == "has total_rows":
            passed = "total_rows" in result_obj
            detail = f"has total_rows: {passed}"

        elif validator == "has headers array":
            passed = "headers" in result_obj and isinstance(result_obj["headers"], list)
            detail = f"has headers: {passed}"

        elif validator == "has sheets array":
            passed = "sheets" in result_obj and isinstance(result_obj["sheets"], list)
            detail = f"has sheets: {passed}"

        elif validator == "has value":
            passed = "value" in result_obj
            detail = f"has value: {passed}"

        elif validator == "has type":
            passed = "type" in result_obj
            detail = f"has type: {passed}"

        elif validator == "has data array":
            passed = "data" in result_obj and isinstance(result_obj["data"], list)
            detail = f"has data array: {passed}"

        elif validator == "has matched_rows":
            passed = "matched_rows" in result_obj
            detail = f"has matched_rows: {passed}"

        elif validator == "has total_matches":
            passed = "total_matches_found" in result_obj or "total_matches" in result_obj
            detail = f"has total_matches: {passed}"

        elif validator == "has total_matches_found":
            passed = "total_matches_found" in result_obj
            detail = f"has total_matches_found: {passed}"

        elif validator == "has returned_count":
            passed = "returned_count" in result_obj
            detail = f"has returned_count: {passed}"

        elif validator == "has results array":
            passed = "results" in result_obj and isinstance(result_obj["results"], list)
            detail = f"has results: {passed}"

        elif validator == "has total_found":
            passed = "total_found" in result_obj
            detail = f"has total_found: {passed}"

        elif validator == "has summaries object":
            passed = "summaries" in result_obj and isinstance(
                result_obj["summaries"], dict
            )
            detail = f"has summaries: {passed}"

        elif validator == "has groups object":
            passed = "groups" in result_obj and isinstance(result_obj["groups"], dict)
            detail = f"has groups: {passed}"

        elif validator == "has pivot object":
            passed = "pivot" in result_obj and isinstance(result_obj["pivot"], dict)
            detail = f"has pivot: {passed}"

        elif validator == "has columns array":
            passed = "columns" in result_obj and isinstance(result_obj["columns"], list)
            detail = f"has columns: {passed}"

        elif validator == "has truncated":
            passed = "truncated" in result_obj
            detail = f"has truncated: {passed}"

        elif validator == "has processed_rows":
            passed = "processed_rows" in result_obj
            detail = f"has processed_rows: {passed}"

        elif validator == "has rows_scanned":
            passed = "rows_scanned" in result_obj
            detail = f"has rows_scanned: {passed}"

        elif validator == "truncated === true":
            passed = result_obj.get("truncated") is True
            detail = f"truncated={result_obj.get('truncated')}"

        elif validator.startswith("not contains_string"):
            match = re.search(r'"(.+?)"', validator)
            if match:
                substr = match.group(1)
                passed = substr.lower() not in result_str.lower()
                detail = f"does NOT contain '{substr}': {passed}"

        elif validator == "rows_appended === 1":
            passed = result_obj.get("rows_appended") == 1
            detail = f"rows_appended={result_obj.get('rows_appended')}"

        elif validator == "rows_created === 1":
            passed = result_obj.get("rows_created") == 1
            detail = f"rows_created={result_obj.get('rows_created')}"

        elif validator == "rows_created === 2":
            passed = result_obj.get("rows_created") == 2
            detail = f"rows_created={result_obj.get('rows_created')}"

        elif validator == "directory exists":
            path = result_obj.get("filePath") or result_obj.get("file_path")
            passed = path and os.path.isdir(path)
            detail = f"path={path}, is_dir={passed}"

        elif validator.startswith("file ends with"):
            match = re.search(r"\.(.+)", validator)
            if match:
                ext = "." + match.group(1)
                path = result_obj.get("filePath") or result_obj.get("file_path") or ""
                passed = path.endswith(ext)
                detail = f"path={path}, ends_with={ext}"

        else:
            passed = False
            detail = f"validator not implemented: {validator}"

        if not passed:
            all_passed = False

        results.append({"validator": validator, "passed": passed, "detail": detail})

    return all_passed, results


def generate_report(results: list[TestResult], output_path: str) -> str:
    """Generate Markdown test report."""
    total = len(results)
    passed = sum(1 for r in results if r.passed)
    failed = total - passed

    categories = {}
    for r in results:
        if r.category not in categories:
            categories[r.category] = {"passed": 0, "failed": 0}
        if r.passed:
            categories[r.category]["passed"] += 1
        else:
            categories[r.category]["failed"] += 1

    lines = [
        "# BioResearcher Plugin Test Report",
        "",
        f"**Run Date:** {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}",
        f"**Total Tests:** {total}",
        f"**Passed:** {passed}",
        f"**Failed:** {failed}",
        "",
        "## Summary by Category",
        "",
        "| Category | Passed | Failed |",
        "|----------|--------|--------|",
    ]

    for cat, stats in sorted(categories.items()):
        total_cat = stats["passed"] + stats["failed"]
        lines.append(
            f"| {cat.title()} | {stats['passed']}/{total_cat} | {stats['failed']} |"
        )

    lines.extend(
        [
            "",
            "## Skipped Tests",
            "",
            "### Database Tools (Not Tested)",
            "- `dbQuery` - Requires live database connection",
            "- `dbListTables` - Requires live database connection",
            "- `dbDescribeTable` - Requires live database connection",
            "",
            "### Skills with User Interaction (Metadata Only)",
            "- `python-setup-uv` - Uses Question tool",
            "- `long-table-summary` - Uses Question tool",
            "- `env-jsonc-setup` - Uses Question tool",
            "- `pubmed-weekly` - Uses Question tool",
            "",
        ]
    )

    if failed > 0:
        lines.extend(
            [
                "## Failed Tests",
                "",
            ]
        )
        for r in results:
            if not r.passed:
                lines.append(f"### {r.category.title()}: {r.test_name}")
                lines.append(f"- **Tool:** `{r.tool}`")
                lines.append(f"- **Expected:** {r.expected}")
                if r.error:
                    lines.append(f"- **Error:** {r.error}")
                for vr in r.validator_results:
                    if not vr["passed"]:
                        lines.append(
                            f"  - Validator `{vr['validator']}`: {vr['detail']}"
                        )
                lines.append("")

    lines.extend(
        [
            "## Detailed Results",
            "",
            "| Test | Tool | Status |",
            "|------|------|--------|",
        ]
    )

    for r in results:
        status = "PASS" if r.passed else "FAIL"
        lines.append(f"| {r.test_name} | `{r.tool}` | {status} |")

    report = "\n".join(lines)

    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    with open(output_path, "w", encoding="utf-8") as f:
        f.write(report)

    return report


def list_tests(tests_by_category: dict[str, list[TestCase]]) -> None:
    """Print all test cases."""
    print("Available Test Cases")
    print("=" * 60)

    for category, tests in sorted(tests_by_category.items()):
        print(f"\n[{category.upper()}] ({len(tests)} tests)")
        for test in tests:
            print(f"  - {test.name} ({test.tool})")


def main():
    parser = argparse.ArgumentParser(
        description="BioResearcher Plugin Test Runner",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  uv run python test_runner.py --list
  uv run python test_runner.py --category parser
  uv run python test_runner.py --verbose
        """,
    )
    parser.add_argument("--list", "-l", action="store_true", help="List all test cases")
    parser.add_argument(
        "--category", "-c", help="Show tests for specific category only"
    )
    parser.add_argument("--verbose", "-v", action="store_true", help="Verbose output")
    parser.add_argument(
        "--output",
        "-o",
        default=".bioresearcher-tests/test_report.md",
        help="Output report path",
    )

    args = parser.parse_args()

    script_dir = os.path.dirname(os.path.abspath(__file__))
    test_cases_dir = os.path.join(script_dir, "test_cases")

    tests_by_category = load_all_tests(test_cases_dir)

    if args.list:
        if args.category:
            if args.category in tests_by_category:
                tests = {args.category: tests_by_category[args.category]}
                list_tests(tests)
            else:
                print(f"Unknown category: {args.category}")
                print(f"Available: {', '.join(tests_by_category.keys())}")
        else:
            list_tests(tests_by_category)
        return

    print("BioResearcher Plugin Test Runner")
    print("=" * 40)
    print()
    print("This script provides test structure utilities.")
    print()
    print("To run actual tests:")
    print("  1. Load skill: skill bioresearcher-tests")
    print("  2. Extract skill_path from output")
    print("  3. Follow workflow steps in SKILL.md")
    print()
    print(f"Total test cases: {sum(len(t) for t in tests_by_category.values())}")
    for cat, tests in sorted(tests_by_category.items()):
        print(f"  - {cat}: {len(tests)} tests")


if __name__ == "__main__":
    main()
