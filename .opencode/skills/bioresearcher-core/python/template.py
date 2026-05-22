#!/usr/bin/env python3
"""Template engine for generating files from templates with placeholder replacement.

This module provides functionality for:
- Filling templates with placeholder replacement
- Escaping text for markdown code blocks
- Batch generation from template + contexts

Usage:
    uv run python template.py fill --template template.md --context context.json --output output.md
    uv run python template.py generate-batches --template template.md --contexts contexts.json --output-dir ./outputs
"""

import argparse
import json
import os
import re
import sys
from pathlib import Path
from typing import Any, Dict, List, Optional


class TemplateEngine:
    """Template engine for placeholder replacement and batch generation."""

    PLACEHOLDER_PATTERN = re.compile(r"\{(\w+)\}")

    @staticmethod
    def escape_for_markdown(text: str) -> str:
        """Escape text for safe use in markdown code blocks.

        Args:
            text: Text to escape

        Returns:
            Escaped text safe for markdown code blocks
        """
        escaped = text.replace("\\", "\\\\")
        escaped = escaped.replace("`", "\\`")
        escaped = escaped.replace("$", "\\$")
        return escaped

    @staticmethod
    def fill_template(
        template: str, replacements: Dict[str, Any], escape_values: bool = False
    ) -> str:
        """Fill template by replacing {placeholder} patterns.

        Args:
            template: Template string with {placeholder} patterns
            replacements: Dictionary mapping placeholder names to values
            escape_values: If True, escape values for markdown code blocks

        Returns:
            Template with placeholders replaced
        """

        def replace_match(match: re.Match) -> str:
            key = match.group(1)
            if key not in replacements:
                return match.group(0)
            value = replacements[key]
            if value is None:
                return ""
            str_value = str(value)
            if escape_values:
                str_value = TemplateEngine.escape_for_markdown(str_value)
            return str_value

        return TemplateEngine.PLACEHOLDER_PATTERN.sub(replace_match, template)

    @staticmethod
    def generate_batch(
        template_path: str,
        context: Dict[str, Any],
        output_path: str,
        escape_values: bool = False,
    ) -> Dict[str, Any]:
        """Generate a single file from template and context.

        Args:
            template_path: Path to template file
            context: Dictionary with placeholder values
            output_path: Path for output file
            escape_values: If True, escape values for markdown

        Returns:
            Result dictionary with success status
        """
        if not os.path.exists(template_path):
            return {
                "success": False,
                "error": f"Template file not found: {template_path}",
            }

        try:
            with open(template_path, "r", encoding="utf-8") as f:
                template = f.read()
        except Exception as e:
            return {"success": False, "error": f"Failed to read template: {e}"}

        filled = TemplateEngine.fill_template(template, context, escape_values)

        try:
            output_dir = os.path.dirname(output_path)
            if output_dir:
                os.makedirs(output_dir, exist_ok=True)

            with open(output_path, "w", encoding="utf-8") as f:
                f.write(filled)
        except Exception as e:
            return {"success": False, "error": f"Failed to write output: {e}"}

        return {
            "success": True,
            "output_path": output_path,
            "template_path": template_path,
        }

    @staticmethod
    def generate_batches(
        template_path: str,
        contexts: List[Dict[str, Any]],
        output_dir: str,
        filename_pattern: str = "output_{index:03d}.md",
        escape_values: bool = False,
        dry_run: bool = False,
        verbose: bool = False,
    ) -> Dict[str, Any]:
        """Generate multiple files from template and list of contexts.

        Args:
            template_path: Path to template file
            contexts: List of context dictionaries
            output_dir: Directory for output files
            filename_pattern: Pattern for output filenames (use {index} placeholder)
            escape_values: If True, escape values for markdown
            dry_run: If True, don't write files
            verbose: If True, print progress

        Returns:
            Result dictionary with success status and generated files
        """
        if not os.path.exists(template_path):
            return {
                "success": False,
                "error": f"Template file not found: {template_path}",
            }

        if not contexts:
            return {"success": False, "error": "No contexts provided"}

        try:
            with open(template_path, "r", encoding="utf-8") as f:
                template = f.read()
        except Exception as e:
            return {"success": False, "error": f"Failed to read template: {e}"}

        if not dry_run:
            os.makedirs(output_dir, exist_ok=True)

        generated_files = []
        errors = []

        for index, context in enumerate(contexts):
            filename = filename_pattern.format(index=index + 1, **context)
            output_path = os.path.join(output_dir, filename)

            if dry_run:
                if verbose:
                    print(f"Would generate: {output_path}")
                generated_files.append(output_path)
                continue

            filled = TemplateEngine.fill_template(template, context, escape_values)

            try:
                with open(output_path, "w", encoding="utf-8") as f:
                    f.write(filled)

                if verbose:
                    print(f"Generated: {output_path}")
                generated_files.append(output_path)
            except Exception as e:
                error_msg = f"Failed to write {output_path}: {e}"
                if verbose:
                    print(f"Error: {error_msg}", file=sys.stderr)
                errors.append(error_msg)

        result = {
            "success": len(errors) == 0,
            "total_contexts": len(contexts),
            "generated_count": len(generated_files),
            "output_dir": output_dir,
            "generated_files": generated_files,
        }

        if errors:
            result["errors"] = errors
            result["error_count"] = len(errors)

        return result


def cmd_fill(args: argparse.Namespace) -> None:
    """Handle fill command."""
    try:
        with open(args.context, "r", encoding="utf-8") as f:
            context = json.load(f)
    except Exception as e:
        result = {"success": False, "error": f"Failed to read context file: {e}"}
        print(json.dumps(result, indent=2))
        sys.exit(1)

    result = TemplateEngine.generate_batch(
        template_path=args.template,
        context=context,
        output_path=args.output,
        escape_values=args.escape,
    )

    print(json.dumps(result, indent=2))

    if not result["success"]:
        sys.exit(1)


def cmd_generate_batches(args: argparse.Namespace) -> None:
    """Handle generate-batches command."""
    try:
        with open(args.contexts, "r", encoding="utf-8") as f:
            contexts = json.load(f)
    except Exception as e:
        result = {"success": False, "error": f"Failed to read contexts file: {e}"}
        print(json.dumps(result, indent=2))
        sys.exit(1)

    if not isinstance(contexts, list):
        result = {"success": False, "error": "Contexts must be a JSON array"}
        print(json.dumps(result, indent=2))
        sys.exit(1)

    result = TemplateEngine.generate_batches(
        template_path=args.template,
        contexts=contexts,
        output_dir=args.output_dir,
        filename_pattern=args.filename_pattern,
        escape_values=args.escape,
        dry_run=args.dry_run,
        verbose=args.verbose,
    )

    print(json.dumps(result, indent=2))

    if not result["success"]:
        sys.exit(1)


def cmd_escape(args: argparse.Namespace) -> None:
    """Handle escape command."""
    escaped = TemplateEngine.escape_for_markdown(args.text)
    result = {"success": True, "original": args.text, "escaped": escaped}
    print(json.dumps(result, indent=2))


def main() -> None:
    """Main entry point."""
    parser = argparse.ArgumentParser(
        description="Template engine for generating files from templates"
    )
    subparsers = parser.add_subparsers(dest="command", help="Available commands")

    fill_parser = subparsers.add_parser("fill", help="Fill single template")
    fill_parser.add_argument("--template", required=True, help="Path to template file")
    fill_parser.add_argument(
        "--context", required=True, help="Path to context JSON file"
    )
    fill_parser.add_argument("--output", required=True, help="Path for output file")
    fill_parser.add_argument(
        "--escape", action="store_true", help="Escape values for markdown"
    )

    batch_parser = subparsers.add_parser(
        "generate-batches", help="Generate multiple files"
    )
    batch_parser.add_argument("--template", required=True, help="Path to template file")
    batch_parser.add_argument(
        "--contexts", required=True, help="Path to contexts JSON file"
    )
    batch_parser.add_argument(
        "--output-dir", required=True, help="Directory for output files"
    )
    batch_parser.add_argument(
        "--filename-pattern",
        default="output_{index:03d}.md",
        help="Filename pattern (default: output_{index:03d}.md)",
    )
    batch_parser.add_argument(
        "--escape", action="store_true", help="Escape values for markdown"
    )
    batch_parser.add_argument(
        "--dry-run", action="store_true", help="Validate without writing"
    )
    batch_parser.add_argument("--verbose", action="store_true", help="Print progress")

    escape_parser = subparsers.add_parser("escape", help="Escape text for markdown")
    escape_parser.add_argument("--text", required=True, help="Text to escape")

    args = parser.parse_args()

    if args.command == "fill":
        cmd_fill(args)
    elif args.command == "generate-batches":
        cmd_generate_batches(args)
    elif args.command == "escape":
        cmd_escape(args)
    else:
        parser.print_help()
        sys.exit(1)


if __name__ == "__main__":
    main()
