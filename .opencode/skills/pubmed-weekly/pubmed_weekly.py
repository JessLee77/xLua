#!/usr/bin/env python3
"""
PubMed Weekly Daily Updates Downloader

This script handles:
- Calculating the past week's date range (Monday-Sunday)
- Fetching FTP file list from NCBI
- Filtering files for the specific week
- Downloading files with retry logic
- Combining Excel files into combined.xlsx
"""

import os
import sys
import re
import time
import json
import glob
import urllib.request
import argparse
from datetime import datetime, timedelta
from typing import List, Dict, Any

MONTH_MAP = {
    "Jan": 1,
    "Feb": 2,
    "Mar": 3,
    "Apr": 4,
    "May": 5,
    "Jun": 6,
    "Jul": 7,
    "Aug": 8,
    "Sep": 9,
    "Oct": 10,
    "Nov": 11,
    "Dec": 12,
}


def calculate_week() -> str:
    """Calculate the past week's date range (Monday-Sunday).

    Returns:
        Week folder name in format 'YYYYMMDD-YYYYMMDD' for the PREVIOUS week
    """
    today = datetime.now()

    # Find the most recent Monday of the current week
    days_since_monday = today.weekday()  # Monday = 0, Sunday = 6
    current_monday = today - timedelta(days=days_since_monday)

    # Go back one week to get the previous week's Monday
    previous_week_monday = current_monday - timedelta(days=7)

    # Calculate the previous week's Sunday (6 days after Monday)
    previous_week_sunday = previous_week_monday + timedelta(days=6)

    week_start = previous_week_monday.strftime("%Y%m%d")
    week_end = previous_week_sunday.strftime("%Y%m%d")

    return f"{week_start}-{week_end}"


def infer_year(month: int, day: int, hour: int, minute: int) -> int:
    """Infer year for MMM DD HH:MM format.

    Uses current year if date is not in the future.
    Uses previous year if inferred date is in the future.

    Args:
        month: Month number (1-12)
        day: Day of month
        hour: Hour (0-23)
        minute: Minute (0-59)

    Returns:
        Inferred year as integer
    """
    now = datetime.now()
    date_this_year = datetime(now.year, month, day, hour, minute)

    if date_this_year > now:
        return now.year - 1
    return now.year


def parse_ftp_listing_to_dict(content: str) -> Dict[str, datetime]:
    """Parse FTP directory listing into {filename: datetime} dict.

    Supports multiple date formats with regex fallback chain:
    1. Unix ls format - MMM DD HH:MM (current year)
    2. Unix ls format - MMM DD  YYYY (older files)
    3. ISO 8601 format - YYYY-MM-DD HH:MM
    4. European format - DD-MMM-YYYY HH:MM

    Args:
        content: Raw FTP directory listing content

    Returns:
        Dictionary mapping filename to datetime object
    """
    file_dates = {}

    for line in content.split("\n"):
        line = line.strip()
        if not line or line.startswith("total"):
            continue

        filename = None
        file_date = None

        match = re.match(
            r"^\S+\s+\d+\s+\S+\s+\S+\s+\d+\s+(\w{3})\s+(\d{1,2})\s+(\d{2}:\d{2})\s+(.+)$",
            line,
        )
        if match:
            month_str, day_str, time_str, fn = match.groups()
            month = MONTH_MAP.get(month_str)
            if month:
                day = int(day_str)
                hour, minute = map(int, time_str.split(":"))
                year = infer_year(month, day, hour, minute)
                filename = fn
                file_date = datetime(year, month, day, hour, minute)

        if not file_date:
            match = re.match(
                r"^\S+\s+\d+\s+\S+\s+\S+\s+\d+\s+(\w{3})\s+(\d{1,2})\s+(\d{4})\s+(.+)$",
                line,
            )
            if match:
                month_str, day_str, year_str, fn = match.groups()
                month = MONTH_MAP.get(month_str)
                if month:
                    year = int(year_str)
                    day = int(day_str)
                    filename = fn
                    file_date = datetime(year, month, day)

        if not file_date:
            match = re.match(r"^(\d{4}-\d{2}-\d{2})\s+(\d{2}:\d{2})\s+(.+)$", line)
            if match:
                date_str, time_str, fn = match.groups()
                datetime_str = f"{date_str} {time_str}"
                try:
                    file_date = datetime.strptime(datetime_str, "%Y-%m-%d %H:%M")
                    filename = fn
                except ValueError:
                    pass

        if not file_date:
            match = re.match(
                r"^(\d{1,2})-(\w{3})-(\d{4})\s+(\d{2}:\d{2})\s+(.+)$", line
            )
            if match:
                day_str, month_str, year_str, time_str, fn = match.groups()
                month = MONTH_MAP.get(month_str)
                if month:
                    day = int(day_str)
                    year = int(year_str)
                    hour, minute = map(int, time_str.split(":"))
                    try:
                        file_date = datetime(year, month, day, hour, minute)
                        filename = fn
                    except ValueError:
                        pass

        if filename and file_date and filename not in file_dates:
            file_dates[filename] = file_date

    return file_dates


def parse_date_from_filename(filename: str) -> datetime | None:
    """Extract date from PubMed filename.

    PubMed filenames are in format: pubmed24nYYYYMMDD.xml.gz
    The date is embedded in the number following 'n'

    Args:
        filename: PubMed filename (e.g., pubmed24n1234.xml.gz)

    Returns:
        datetime object or None if date cannot be parsed
    """
    # Pattern to extract the numeric part after 'n'
    match = re.match(r"pubmed\d+n(\d+)\.xml\.gz", filename)
    if not match:
        return None

    number = match.group(1)

    # PubMed daily update files use a specific numbering scheme
    # The first 4 digits represent the year (e.g., 2024)
    # The next 4 digits represent a sequential number within the year
    # We need to convert this to a date

    # For daily updates, NCBI uses a sequential number that increments daily
    # We need to look up the actual date from the FTP directory listing
    # which includes modification time

    return None

    number = match.group(1)

    # PubMed daily update files use a specific numbering scheme
    # The first 4 digits represent the year (e.g., 2024)
    # The next 4 digits represent a sequential number within the year
    # We need to convert this to a date

    # For daily updates, NCBI uses a sequential number that increments daily
    # We need to look up the actual date from the FTP directory listing
    # which includes modification time

    return None


def fetch_ftp_file_list() -> List[str]:
    """Fetch list of xml.gz files from NCBI FTP server.

    Returns:
        List of xml.gz filenames from the FTP server
    """
    url = "ftp://ftp.ncbi.nlm.nih.gov/pubmed/updatefiles/"

    try:
        with urllib.request.urlopen(url) as response:
            html_content = response.read().decode("utf-8")

        # Parse HTML to extract filenames
        # FTP directory listing returns HTML with links
        filenames = []
        for line in html_content.split("\n"):
            match = re.search(r"pubmed\d+n\d+\.xml\.gz", line)
            if match:
                filename = match.group(0)
                if filename not in filenames:
                    filenames.append(filename)

        return sorted(filenames)

    except Exception as e:
        print(f"Error fetching FTP file list: {e}", file=sys.stderr)
        sys.exit(1)


def filter_files_by_date(week_name: str, file_list: List[str]) -> List[str]:
    """Filter files to include only those from the past week.

    Since PubMed files don't encode the date directly in the filename,
    we need to download the directory listing with timestamps and filter
    based on modification date.

    Args:
        week_name: Week folder name (YYYYMMDD-YYYYMMDD)
        file_list: List of all xml.gz filenames

    Returns:
        List of filenames that fall within the date range
    """
    # Parse week dates
    start_date_str, end_date_str = week_name.split("-")
    start_date = datetime.strptime(start_date_str, "%Y%m%d")
    end_date = datetime.strptime(end_date_str, "%Y%m%d").replace(
        hour=23, minute=59, second=59
    )

    # Fetch directory listing with timestamps
    url = "ftp://ftp.ncbi.nlm.nih.gov/pubmed/updatefiles/"

    try:
        with urllib.request.urlopen(url) as response:
            content = response.read().decode("utf-8", errors="ignore")

        file_dates = parse_ftp_listing_to_dict(content)

        # Filter files within date range AND in provided file_list
        filtered_files = [
            f
            for f in file_list
            if f in file_dates and start_date <= file_dates[f] <= end_date
        ]

        return sorted(filtered_files)

    except Exception as e:
        print(f"Error filtering files by date: {e}", file=sys.stderr)
        sys.exit(1)


def download_file(week_name: str, filename: str, max_retries: int = 3) -> int:
    """Download a single file from NCBI FTP server with retry logic.

    Args:
        week_name: Week folder name
        filename: XML.gz filename to download
        max_retries: Maximum number of retry attempts

    Returns:
        0 on success, 1 on failure (after all retries)
    """
    base_url = "ftp://ftp.ncbi.nlm.nih.gov/pubmed/updatefiles/"
    url = f"{base_url}{filename}"

    # Create download directory in current working directory
    base_dir = os.getcwd()
    download_dir = os.path.join(base_dir, ".download", "pubmed-daily", week_name)
    os.makedirs(download_dir, exist_ok=True)

    filepath = os.path.join(download_dir, filename)

    for attempt in range(max_retries):
        try:
            print(f"Downloading {filename} (attempt {attempt + 1}/{max_retries})...")

            urllib.request.urlretrieve(url, filepath)

            # Verify file was downloaded and has content
            if os.path.exists(filepath) and os.path.getsize(filepath) > 0:
                print(f"Successfully downloaded {filename}")
                return 0
            else:
                raise Exception("Downloaded file is empty or missing")

        except Exception as e:
            print(f"Error downloading {filename}: {e}", file=sys.stderr)

            if attempt < max_retries - 1:
                print(f"Retrying in 2 seconds...")
                time.sleep(2)
            else:
                print(f"Failed to download {filename} after {max_retries} attempts")
                return 1

    return 1


def combine_excel(week_name: str) -> Dict[str, Any]:
    """Combine all Excel files in week folder into combined.xlsx.

    Args:
        week_name: Week folder name (e.g., '20250217-20250223')

    Returns:
        Dict with success, total_rows, source_files, output_file
    """
    try:
        from openpyxl import load_workbook, Workbook
    except ImportError:
        print("Error: openpyxl package not installed.", file=sys.stderr)
        print("Please install with: uv add openpyxl", file=sys.stderr)
        return {
            "success": False,
            "error": "openpyxl not installed",
            "total_rows": 0,
            "source_files": [],
            "output_file": None,
        }

    # Use current working directory
    base_dir = os.getcwd()
    week_dir = os.path.join(base_dir, ".download", "pubmed-daily", week_name)

    if not os.path.exists(week_dir):
        return {
            "success": False,
            "error": f"Directory not found: {week_dir}",
            "total_rows": 0,
            "source_files": [],
            "output_file": None,
        }

    xlsx_pattern = os.path.join(week_dir, "*.xlsx")
    all_xlsx_files = glob.glob(xlsx_pattern)

    source_files = [
        os.path.basename(f) for f in all_xlsx_files if not f.endswith("combined.xlsx")
    ]
    source_files.sort()

    if not source_files:
        return {
            "success": False,
            "error": "No Excel files found to combine",
            "total_rows": 0,
            "source_files": [],
            "output_file": None,
        }

    combined_wb = Workbook()
    combined_ws = combined_wb.active
    if combined_ws is None:
        combined_ws = combined_wb.create_sheet("PubMed Articles")
    else:
        combined_ws.title = "PubMed Articles"

    header_written = False
    total_rows = 0
    processed_files = []

    for filename in source_files:
        filepath = os.path.join(week_dir, filename)

        try:
            wb = load_workbook(filepath, read_only=True, data_only=True)
            ws = wb.active
            if ws is None:
                print(f"Warning: {filename} has no active sheet, skipping")
                wb.close()
                continue

            rows = list(ws.rows)
            if not rows:
                print(f"Warning: {filename} is empty, skipping")
                wb.close()
                continue

            if not header_written:
                headers = [cell.value for cell in rows[0]]
                combined_ws.append(headers)
                header_written = True
                data_start = 1
            else:
                data_start = 0

            for row in rows[data_start:]:
                row_values = [cell.value for cell in row]
                if any(v is not None for v in row_values):
                    combined_ws.append(row_values)
                    total_rows += 1

            processed_files.append(filename)
            wb.close()
            print(f"Processed: {filename}")

        except Exception as e:
            print(f"Warning: Error processing {filename}: {e}", file=sys.stderr)
            continue

    output_path = os.path.join(week_dir, "combined.xlsx")
    combined_wb.save(output_path)

    print(f"\nCombined {total_rows} rows from {len(processed_files)} files")
    print(f"Output: {output_path}")

    return {
        "success": True,
        "total_rows": total_rows,
        "source_files": processed_files,
        "output_file": "combined.xlsx",
    }


def main():
    """Main entry point for command-line usage."""
    parser = argparse.ArgumentParser(
        description="PubMed Weekly Daily Updates Downloader"
    )
    parser.add_argument("command", type=str, help="Command to execute")
    parser.add_argument("args", nargs="*", help="Command arguments")

    parsed = parser.parse_args()

    command = parsed.command
    args = parsed.args

    if command == "calculate_week":
        week = calculate_week()
        print(week)

    elif command == "fetch_files":
        files = fetch_ftp_file_list()
        print(" ".join(files))

    elif command == "filter_files":
        if len(args) < 2:
            print("Usage: python pubmed_weekly.py filter_files <week_name> <file_list>")
            sys.exit(1)

        week_name = args[0]
        file_list = args[1].split()
        filtered = filter_files_by_date(week_name, file_list)
        print(" ".join(filtered))

    elif command == "download_file":
        if len(args) < 2:
            print("Usage: python pubmed_weekly.py download_file <week_name> <filename>")
            sys.exit(1)

        week_name = args[0]
        filename = args[1]
        sys.exit(download_file(week_name, filename))

    elif command == "combine_excel":
        if len(args) < 1:
            print("Usage: python pubmed_weekly.py combine_excel <week_name>")
            sys.exit(1)

        week_name = args[0]
        result = combine_excel(week_name)
        print(json.dumps(result, indent=2))

        if not result.get("success"):
            sys.exit(1)

    else:
        print(f"Unknown command: {command}")
        sys.exit(1)


if __name__ == "__main__":
    main()
