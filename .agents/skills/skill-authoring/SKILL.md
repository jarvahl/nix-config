---
name: "skill-authoring"
description: "Use when defining, organizing, or regenerating repository skills; not for skill-specific domain guidance."
---

<!-- DO-NOT-EDIT. This file was auto-generated using github:jarvahl/agent-files. Use nix run .#write-files to regenerate it. -->

# Skill authoring

Declare skills with `agent-files.skills.<name>`.

A skill may be declared in any imported Nix module, preferably next to the functionality it documents.

Use:

- `description` for skill metadata;
- `instructions` for the generated `SKILL.md` content.

Write concise descriptions using WHAT, WHEN, and NOT-WHEN:
what the skill covers, when it should trigger, and when it should not be used.
Prefer one sentence of roughly 15–25 words.

Generated skills are written to `.agents/skills/<name>/SKILL.md`.
Do not edit generated files directly. Regenerate them with `nix run .#write-files`.

Use references only when the skill needs larger supporting documentation.

## Review and cleanup

- Check examples, helper names, and paths against the current code.
- Match each skill's description to its actual scope and contents.
- Route independent tasks to references; keep the entry point focused on when and what to read.
- Split only when it avoids loading unrelated instructions, not to meet a length limit.
- Remove duplication and obsolete guidance; check `AGENTS.md` rules for contradictions too.
- Keep sources near the functionality they document; do not add a new skill for a one-off cleanup.
- Edit source declarations, regenerate files, inspect the diff, and run `nix flake check --no-build`.

