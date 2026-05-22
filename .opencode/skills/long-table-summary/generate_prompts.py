#!/usr/bin/env python3
"""Generate subagent prompts from template for batched table processing."""

import argparse
import json
import os
import sys
from pathlib import Path


def generate_prompts(
    template_path,
    output_dir,
    num_batches,
    sheet_name,
    start_row,
    batch_size,
    file_path,
    instructions,
    schema_path,
    dry_run=False,
    verbose=False,
):
    """Generate individual prompt files from template.

    Args:
        template_path: Path to subagent_template.md
        output_dir: Directory for generated prompts
        num_batches: Total number of batches
        sheet_name: Sheet name from Excel file
        start_row: Starting data row (usually 2 to skip header)
        batch_size: Rows per batch
        file_path: Full path to input table file
        instructions: User-provided summarization instructions (JSON string)
        schema_path: Path to output JSON Schema file
        dry_run: Validate without creating files
        verbose: Enable verbose output
    """
    # Validate template exists
    if not os.path.exists(template_path):
        result = {
            "success": False,
            "error": f"Template file not found: {template_path}",
        }
        print(json.dumps(result, indent=2))
        sys.exit(1)

    # Validate input file exists
    if not os.path.exists(file_path):
        result = {"success": False, "error": f"Input file not found: {file_path}"}
        print(json.dumps(result, indent=2))
        sys.exit(1)

    # Read template
    with open(template_path, "r", encoding="utf-8") as f:
        template = f.read()

    # Create output directory
    output_path = Path(output_dir)
    output_path.mkdir(parents=True, exist_ok=True)

    # Absolute path to input file
    file_path_abs = os.path.abspath(file_path)

    # Escape instructions JSON for markdown code block
    # Replace backticks and dollar signs
    instructions_escaped = instructions.replace("`", "\\`").replace("$", "\\$")

    # Generate prompts for each batch
    for batch_num in range(1, num_batches + 1):
        # Calculate row range
        row_start = start_row + (batch_num - 1) * batch_size
        row_end = row_start + batch_size - 1

        # Output file path
        batch_str = f"{batch_num:03d}"
        topic = os.path.basename(os.path.dirname(template_path))
        output_file = f"./.long-table-summary/{topic}/outputs/batch{batch_str}.md"

        # Replace placeholders
        content = template.replace("{file_path}", file_path_abs)
        content = content.replace("{sheet_name}", sheet_name)
        content = content.replace("{batch_number}", str(batch_num))
        content = content.replace("{row_start}", str(row_start))
        content = content.replace("{row_end}", str(row_end))
        content = content.replace("{output_file}", output_file)
        content = content.replace("{instructions_json}", instructions_escaped)
        content = content.replace("{schema_path}", schema_path)

        # Dry run mode - skip actual file writes
        if dry_run:
            if verbose:
                print(f"Would write: {output_path}")
            continue

        # Write prompt file
        try:
            prompt_file = output_path / f"batch{batch_str}.md"
            with open(prompt_file, "w", encoding="utf-8") as f:
                f.write(content)

            if verbose:
                print(f"Created: {prompt_file}")

        except IOError as e:
            result = {
                "success": False,
                "error": f"Failed to write prompt file {batch_str}: {e}",
            }
            print(json.dumps(result, indent=2))
            sys.exit(1)

    return {
        "success": True,
        "num_prompts": num_batches,
        "output_dir": str(output_path),
        "batches": list(range(1, num_batches + 1)),
    }


def main():
    """Main entry point."""
    parser = argparse.ArgumentParser(
        description="Generate subagent prompts from template"
    )
    parser.add_argument(
        "--template", required=True, help="Path to subagent_template.md"
    )
    parser.add_argument(
        "--output-dir", default="./prompts", help="Directory for generated prompts"
    )
    parser.add_argument(
        "--num-batches", type=int, required=True, help="Total number of batches"
    )
    parser.add_argument(
        "--sheet-name", required=True, help="Sheet name from Excel file"
    )
    parser.add_argument(
        "--file-path", required=True, help="Full path to input table file"
    )
    parser.add_argument(
        "--start-row",
        type=int,
        default=2,
        help="Starting data row (default: 2 to skip header)",
    )
    parser.add_argument("--batch-size", type=int, required=True, help="Rows per batch")
    parser.add_argument(
        "--instructions",
        required=True,
        help="User-provided summarization instructions (JSON string)",
    )
    parser.add_argument(
        "--schema-path",
        required=True,
        help="Path to output JSON Schema file (relative or absolute)",
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Validate without creating files (testing only)",
    )
    parser.add_argument(
        "--verbose", action="store_true", help="Enable verbose output for debugging"
    )

    args = parser.parse_args()

    # Validate instructions is valid JSON
    try:
        json.loads(args.instructions)
    except json.JSONDecodeError as e:
        result = {"success": False, "error": f"Invalid JSON instructions: {e}"}
        print(json.dumps(result, indent=2))
        sys.exit(1)

    # Validate numeric arguments
    if args.num_batches <= 0:
        result = {
            "success": False,
            "error": f"num_batches must be positive (got: {args.num_batches})",
        }
        print(json.dumps(result, indent=2))
        sys.exit(1)

    if args.batch_size <= 0:
        result = {
            "success": False,
            "error": f"batch_size must be positive (got: {args.batch_size})",
        }
        print(json.dumps(result, indent=2))
        sys.exit(1)

    if args.start_row < 1:
        result = {
            "success": False,
            "error": f"start_row must be >= 1 (got: {args.start_row})",
        }
        print(json.dumps(result, indent=2))
        sys.exit(1)

    result = generate_prompts(
        template_path=args.template,
        output_dir=args.output_dir,
        num_batches=args.num_batches,
        sheet_name=args.sheet_name,
        start_row=args.start_row,
        batch_size=args.batch_size,
        file_path=args.file_path,
        instructions=args.instructions,
        schema_path=args.schema_path,
        dry_run=args.dry_run,
        verbose=args.verbose,
    )

    print(json.dumps(result, indent=2))


if __name__ == "__main__":
    main()
