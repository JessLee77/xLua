#!/usr/bin/env python
"""Demo script to verify skill resource resolution."""

import os
import sys


def main():
    print("Demo Skill - Resource Resolution Test")
    print("=" * 40)
    print(f"Script location: {os.path.abspath(__file__)}")
    print(f"Python version: {sys.version.split()[0]}")
    print()
    print("Status: Resources resolved correctly!")
    print()
    print("This confirms:")
    print("  - Skill files bundled at build time")
    print("  - Resources discoverable via skill tool")
    print("  - Scripts executable from skill directory")


if __name__ == "__main__":
    main()
