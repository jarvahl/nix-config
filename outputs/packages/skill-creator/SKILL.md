---
name: skill-creator
description: Creates, reviews, and improves reusable agent skills. Use when asked to create a skill, turn a workflow into a skill, or revise or evaluate an existing skill.
license: Apache-2.0
---

<!-- Adapted from Anthropic's skill-creator (Apache-2.0): https://github.com/anthropics/skills/tree/main/skills/skill-creator. Modified for Pi and this repository; Claude-specific tooling and evaluation steps were removed. -->

# Skill creator

Create or improve skills that capture reusable workflows or knowledge. Keep the process proportional to the request; a useful skill does not require a formal spec, benchmark, or extra commits unless the user wants them.

## Workflow

1. **Understand the job.** Inspect the existing skill and relevant project guidance. Identify what the skill should help an agent do, when it should activate, its expected result, and any important boundaries. Use examples already in the conversation or files. Ask only about missing details that materially affect the result.
2. **Design the smallest useful contents.** Put core steps and decisions in `SKILL.md`. Add scripts for repeated deterministic work, references for substantial on-demand material, and assets only when the skill needs them. Do not add scaffolding or generic advice that the agent already knows.
3. **Write actionable instructions.** Use clear imperative language, include useful reasoning and error paths, and make confirmation boundaries explicit for consequential actions. Keep the description specific about both capability and activation cues.
4. **Validate proportionally.** Check frontmatter, links, referenced paths, and fit with the target agent's skill format. For a new or materially changed workflow, try a few realistic prompts, including a near-miss that should not activate it. Use assertions or a baseline comparison when outcomes are objectively testable; use focused human review for subjective work. Do not build a benchmark or run a large evaluation loop for a trivial edit.
5. **Improve from evidence.** Fix observed gaps without overfitting to one prompt. Keep successful behavior, remove instructions that add work without improving outcomes, and preserve the existing skill name unless renaming is requested.

## Design principles

- Treat a skill as an instruction interface, not a project proposal or user-facing manual.
- Explain non-obvious constraints and why they matter; avoid rigid `MUST`/`NEVER` rules when a decision rule is clearer.
- Prefer progressive disclosure: keep the entry point short and link directly to reference files only when needed.
- Keep the skill portable across supported agents. Do not assume Claude-only commands, tools, metadata, or evaluation infrastructure unless the user explicitly targets Claude.
- Never add hidden side effects, unsafe instructions, or behavior outside the skill's stated purpose.
- Follow the user's requested scope; do not create a design document, commit, or package unless that is part of the request.

## Pi and this repository

Pi uses the Agent Skills format: a skill directory contains `SKILL.md` with `name` and `description` frontmatter. Check the installed Pi documentation when uncertain about additional fields or loading behavior.

In this Nix repository, follow nearby skills under `outputs/skills/`: add a `default.nix` package when needed and register the skill in the Pi aspect. Stage newly created files before evaluating the flake so Git-tree evaluation can see them. Preserve the repository's existing packaging and naming conventions.
