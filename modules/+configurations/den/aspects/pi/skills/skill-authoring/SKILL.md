---
name: "skill-authoring"
description: "Creates and maintains concise agent skills. Use when defining, reviewing, organizing, or testing skills; not for domain-specific task execution."
---

# Skill authoring

Create a skill only for a repeated workflow or reusable knowledge.

## Workflow

1. Identify the repeated failure or reusable pattern.
2. Decide which instructions apply to every use and which vary by target, environment, or workflow variant.
3. Write the smallest useful `SKILL.md` containing the universal workflow.
4. Make the description state WHAT the skill does, WHEN it applies, and NOT-WHEN it does not.
5. Put conditional procedures and detailed examples in `references/`, using one reference per meaningful variant.
6. Add a `References` table to `SKILL.md` with a short condition or target and a direct relative link to every reference.
7. Test the skill on representative tasks and refine it from observed behavior.

## Requirements

- `name` contains only lowercase letters, numbers, and hyphens.
- The description is third person, specific, and contains useful activation terms.
- Keep the entry point concise; assume the agent already knows general concepts.
- Use this layout for skills with variants:
  `SKILL.md` for shared rules and `references/<variant>.md` for conditional procedures.
- Keep a direct references table in `SKILL.md`; do not leave references orphaned or link through another reference.
- Create a reference only when it represents a real variant or reusable supporting procedure; add it later when that variant exists.
- Do not create a skill for a one-off detail.
- Prefer examples and checklists when the desired behavior is easy to misunderstand.
