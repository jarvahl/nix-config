---
name: "agent-files"
description: "Add and organize repository skills declaratively in this Nix configuration."
---

<!-- DO-NOT-EDIT. This file was auto-generated using github:jarvahl/agent-files. Use nix run .#write-files to regenerate it. -->

# Agent files

Declare skills with `agent-files.skills.<name>`.

A skill may be declared in any imported Nix module, preferably next to the functionality it documents.

Use:

- `description` for skill metadata;
- `instructions` for the generated `SKILL.md` content.

Generated skills are written to `.agents/skills/<name>/SKILL.md`.
Do not edit generated files directly. Regenerate them with `nix run .#write-files`.

Use references only when the skill needs larger supporting documentation.

