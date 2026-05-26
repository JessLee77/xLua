#!/usr/bin/env python3
"""Combine subagent JSON outputs into a single Excel table."""

import argparse
import json
import os
import sys
from pathlib import Path
from typing import List, Dict, Any, Tuple


def read_json_outputs(input_dir: str, verbose: bool = False) -> Dict[str, Any]:
    """Read all batch*.md files and extract JSON content.

    Args:
        input_dir: Directory containing batch output files
        verbose: Enable verbose output

    Returns:
        Dict with success status and parsed data
    """
    input_path = Path(input_dir)

    if not input_path.exists():
        return {"success": False, "error": f"Directory not found: {input_dir}"}

    # Find all batch files
    batch_files = sorted(input_path.glob("batch*.md"))

    if not batch_files:
        return {"success": False, "error": f"No batch files found in {input_dir}"}

    all_summaries = []

    for batch_file in batch_files:
        try:
            with open(batch_file, "r", encoding="utf-8") as f:
                content = f.read().strip()

            # Extract JSON using brace matching (string-aware, handles nested structures)
            extracted = extract_json_from_content(content)
            if extracted is None:
                if verbose:
                    print(f"Warning: No valid JSON found in {batch_file.name}")
                continue

            all_summaries.append(extracted)

            if verbose:
                data = extracted
                print(
                    f"Parsed: {batch_file.name} - {len(data.get('summaries', []))} summaries"
                )

        except json.JSONDecodeError as e:
            if verbose:
                print(f"Warning: Failed to parse {batch_file.name}: {e}")
            continue
        except Exception as e:
            if verbose:
                print(f"Warning: Error reading {batch_file.name}: {e}", file=sys.stderr)
            continue

    return {"success": True, "summaries": all_summaries}


def extract_json_from_content(content: str) -> dict | None:
    """Extract JSON from content using string-aware brace matching.

    Args:
        content: File content string

    Returns:
        Parsed JSON dict or None if not found
    """
    # Try direct parse first (file contains only JSON)
    try:
        return json.loads(content)
    except json.JSONDecodeError:
        pass

    # Find JSON object boundaries with brace matching
    start = content.find("{")
    if start == -1:
        return None

    depth = 0
    in_string = False
    escape = False

    for i in range(start, len(content)):
        char = content[i]
        if escape:
            escape = False
            continue
        if char == "\\":
            escape = True
            continue
        if char == '"':
            in_string = not in_string
            continue
        if not in_string:
            if char == "{":
                depth += 1
            elif char == "}":
                depth -= 1
                if depth == 0:
                    try:
                        return json.loads(content[start : i + 1])
                    except json.JSONDecodeError:
                        return None

    return None


def merge_summaries(
    summaries: List[Dict[str, Any]],
    deduplicate: bool = False,
    column_order: str = "preserve",
    verbose: bool = False,
) -> Tuple[List[Dict[str, Any]], List[str]]:
    """Merge all batch summaries into a unified table structure.

    Args:
        summaries: List of batch JSON objects
        deduplicate: Remove duplicate row numbers (keep first occurrence)
        column_order: Column order strategy ('preserve' or 'alphabetical')
        verbose: Enable verbose output

    Returns:
        Tuple of (flattened list of row summaries, sorted list of column names)
    """
    merged = []

    # Determine all column names from first batch's summaries
    all_columns = set()

    for batch in summaries:
        batch_summaries = batch.get("summaries", [])

        for row_summary in batch_summaries:
            # Add all keys except batch_number, row_count, and row_number
            for key in row_summary.keys():
                if key not in ["batch_number", "row_count", "row_number"]:
                    all_columns.add(key)

    # Sort columns based on strategy
    if column_order == "alphabetical":
        columns = sorted(all_columns)
        if verbose:
            print(f"Column order: alphabetical - {columns}")
    else:  # preserve
        # Get order from first batch
        for batch in summaries:
            batch_summaries = batch.get("summaries", [])
            if batch_summaries:
                # Extract column order from first row's keys (excluding batch_number, row_count, row_number)
                first_row_columns = [
                    k
                    for k in batch_summaries[0].keys()
                    if k not in ["batch_number", "row_count", "row_number"]
                ]
                if first_row_columns:
                    columns = first_row_columns
                    break
        if verbose:
            print(f"Column order: preserve - {columns}")

    # Track duplicates
    seen_rows = {}
    duplicates = []

    for batch in summaries:
        batch_summaries = batch.get("summaries", [])

        for row_summary in batch_summaries:
            row_num = row_summary.get("row_number")

            if row_num in seen_rows:
                duplicates.append(
                    {
                        "row_number": row_num,
                        "first_batch": seen_rows[row_num],
                        "duplicate_batch": batch.get("batch_number"),
                    }
                )
                if verbose:
                    print(
                        f"Duplicate row {row_num}: batch {seen_rows[row_num]} vs {batch.get('batch_number')}"
                    )

            seen_rows[row_num] = batch.get("batch_number")

    if duplicates:
        if verbose:
            print(f"Found {len(duplicates)} duplicate rows")
            for dup in duplicates[:5]:  # Show first 5
                print(
                    f"  Row {dup['row_number']}: batch {dup['first_batch']} vs {dup['duplicate_batch']}"
                )

    # Remove duplicates if requested
    if deduplicate:
        merged_dict = {}
        for batch in summaries:
            batch_summaries = batch.get("summaries", [])
            for row_summary in batch_summaries:
                row_num = row_summary.get("row_number")
                if row_num not in merged_dict:
                    merged_dict[row_num] = row_summary
        merged = list(merged_dict.values())
        if verbose:
            print(f"Deduplicated to {len(merged)} rows")
    else:
        # Keep all (including duplicates)
        for batch in summaries:
            batch_summaries = batch.get("summaries", [])
            for row_summary in batch_summaries:
                merged.append(row_summary)
        if verbose:
            print(f"Keeping all rows (including duplicates): {len(merged)}")

    # Sort by row_number
    merged.sort(key=lambda x: x.get("row_number", 0))

    return merged, columns


def write_combined_excel(
    merged: List[Dict[str, Any]],
    columns: List[str],
    output_file: str,
    verbose: bool = False,
) -> Dict[str, Any]:
    """Write merged summaries to Excel file.

    Args:
        merged: List of row summaries
        columns: List of column names to use
        output_file: Path for output Excel file
        verbose: Enable verbose output

    Returns:
        Success/error result
    """
    try:
        import openpyxl
    except ImportError:
        result = {
            "success": False,
            "error": "openpyxl package not installed. Install with: uv add openpyxl",
        }
        print(json.dumps(result, indent=2))
        sys.exit(1)

    output_path = Path(output_file)
    output_path.parent.mkdir(parents=True, exist_ok=True)

    # Create workbook
    wb = openpyxl.Workbook()
    ws = wb.active
    ws.title = "Combined Summary"

    # Write header
    header_row = ["row_number"] + columns
    ws.append(header_row)

    if verbose:
        print(f"Writing {len(merged)} rows with {len(columns)} columns")

    # Write data rows
    for row_data in merged:
        row_values = [row_data.get("row_number", "")]

        # Add values for each column in order
        for col in columns:
            row_values.append(row_data.get(col, ""))

        ws.append(row_values)

    # Save workbook with error handling
    try:
        wb.save(output_path)
        if verbose:
            print(f"Successfully saved to {output_path}")
    except Exception as e:
        result = {"success": False, "error": f"Failed to save Excel file: {e}"}
        print(json.dumps(result, indent=2))
        return result

    return {
        "success": True,
        "output_file": str(output_path),
        "total_rows": len(merged),
        "columns": columns,
    }


def main():
    """Main entry point."""
    parser = argparse.ArgumentParser(
        description="Combine subagent JSON outputs into Excel table"
    )
    parser.add_argument(
        "--input-dir",
        required=True,
        help="Directory containing batch output JSON files",
    )
    parser.add_argument(
        "--output-file", required=True, help="Path for combined Excel output file"
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Validate inputs without writing output file (testing only)",
    )
    parser.add_argument(
        "--verbose", action="store_true", help="Enable verbose output for debugging"
    )
    parser.add_argument(
        "--deduplicate",
        action="store_true",
        help="Remove duplicate row numbers (keep first occurrence)",
    )
    parser.add_argument(
        "--column-order",
        default="preserve",
        choices=["preserve", "alphabetical"],
        help="Column order: 'preserve' (from first batch) or 'alphabetical' (default)",
    )

    args = parser.parse_args()

    # Read all batch outputs
    result = read_json_outputs(args.input_dir, args.verbose)
    if not result.get("success"):
        print(json.dumps(result, indent=2))
        sys.exit(1)

    summaries = result["summaries"]

    # Check for empty results
    if not summaries:
        result = {
            "success": False,
            "error": "Found batch files but none contained valid JSON",
        }
        print(json.dumps(result, indent=2))
        sys.exit(1)

    # Merge into unified structure
    merged, columns = merge_summaries(
        summaries, args.deduplicate, args.column_order, args.verbose
    )

    # Check for empty merge
    if not merged:
        result = {"success": False, "error": "No valid summaries found in batch files"}
        print(json.dumps(result, indent=2))
        sys.exit(1)

    # Dry run mode - skip actual file writes
    if args.dry_run:
        result = {
            "success": True,
            "dry_run": True,
            "total_rows": len(merged),
            "columns": columns,
            "message": "Dry run completed - no files written",
        }
        print(json.dumps(result, indent=2))
        sys.exit(0)

    # Write to Excel
    result = write_combined_excel(merged, columns, args.output_file, args.verbose)

    if not result.get("success"):
        sys.exit(1)


if __name__ == "__main__":
    main()
