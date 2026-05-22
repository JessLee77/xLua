# Skill Tests

## Test: Load demo-skill
- Tool: skill
- Input:
  ```json
  {"name": "demo-skill"}
  ```
- Validators:
  - contains_string("skill_content")
  - contains_string("demo-skill")
- Expected: Skill content loaded successfully

## Test: Load bioresearcher-core
- Tool: skill
- Input:
  ```json
  {"name": "bioresearcher-core"}
  ```
- Validators:
  - contains_string("skill_content")
  - contains_string("bioresearcher-core")
  - contains_string("allowed_tools")
- Expected: Skill content with allowedTools list

## Test: Execute demo-skill Script
- Tool: Bash
- Prerequisite: Load skill demo-skill first, extract skill_path
- Input:
  ```bash
  cd <skill_path>/../demo-skill && python demo_script.py
  ```
- Validators:
  - contains_string("Resources resolved")
- Expected: Demo script executes successfully

## Test: Skill Not Found
- Tool: skill
- Input:
  ```json
  {"name": "nonexistent-skill-xyz-12345"}
  ```
- Validators:
  - contains_string("not found")
- Expected: Error with available skills list

---

## Skipped: Skills with User Interaction

The following skills are NOT tested because they use the Question tool
and require user interaction during execution:

- `python-setup-uv` - Uses Question tool for installer choice and AGENTS.md update
- `long-table-summary` - Uses Question tool for table location, instructions, batch size
- `env-jsonc-setup` - Uses Question tool for configuration options
- `pubmed-weekly` - May use Question tool for download options

These skills are tested for metadata only (loading succeeds, content returned).
