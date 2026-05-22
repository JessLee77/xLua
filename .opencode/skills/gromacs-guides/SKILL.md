---
name: gromacs-guides
description: Reusable guides for GROMACS molecular dynamics workflows
allowedTools:
  - Read
  - Bash
---

# GROMACS Guides

This skill provides reusable guides for common GROMACS molecular dynamics workflows.

## Quick Start

### Step 1: Load This Skill
The skill is loaded automatically when agent calls `skill gromacs-guides`.

### Step 2: Extract Skill Path
From the `<skill_files>` section in the skill tool output, extract the `<skill_path>` value.

### Step 3: Read the Relevant Guide
```
Read <skill_path>/guides/inspect_tpr.md
Read <skill_path>/guides/create_index.md
```

## Available Guides

| Task | Guide |
|------|-------|
| TPR inspection | `guides/inspect_tpr.md` |
| Index file creation | `guides/create_index.md` |

## Guide Summaries

### inspect_tpr.md
Commands for extracting molecule information from TPR files:
- Quick summary and detailed dump commands
- Molecule type/counts extraction
- Cyclic molecule bond detection
- Molecule independence checking

### create_index.md
Workflow for creating GROMACS index files:
- Basic `make_ndx` usage
- `splitch` artefact identification and fixing
- Merge → verify → delete → rename workflow
- C-alpha group creation
