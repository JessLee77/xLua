---
name: demo-skill
description: Demo skill showcasing the plugin skill integration system
allowedTools:
  - Bash
  - Read
---

# Demo Skill

This skill demonstrates the plugin skill integration system.

## Features Demonstrated

1. **Skill Discovery** - This skill is discovered from `plugin/skills/`
2. **allowedTools** - Listed above (documentation only)
3. **Bundled Resources** - Files in this directory are accessible

## Test Resource Resolution

Run the bundled script to verify resources are properly resolved:

```bash
python demo_script.py
```

Expected output:
```
Demo Skill - Resource Resolution Test
=====================================
Skill directory: <path to skill>
Status: Resources resolved correctly!
```

## How It Works

1. Plugin builds with `npm run build`
2. `skills/` directory copied to `dist/skills/`
3. Skill tool discovers all `SKILL.md` files
4. Agent calls `skill` tool with skill name
5. Skill content + file list returned to agent
