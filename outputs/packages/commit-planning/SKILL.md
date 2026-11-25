---
name: commit-planning
description: Plan and safely create Git commits from pending work. Use when the user asks to commit, make commits, save changes, prepare a commit, or organize local changes into commits; inspect unpushed history first and propose the smallest coherent commit plan before changing Git state.
---

# Commit planning

Plan commits before modifying Git state. The goal is a small, coherent history without accidentally including unrelated work or creating redundant commits.

## Workflow

1. Check the current branch, configured upstream, and commits ahead of the upstream. Review recent commit style. If no reliable upstream or comparison base exists, report that and ask before assuming one.
2. Inspect `git status`, staged and unstaged diffs, and relevant untracked files. Compare pending work with unpushed commits to find changes already represented in local history.
3. Separate the user's requested work from unrelated pre-existing changes. Never include unrelated staged or unstaged changes merely because they are present.
4. Propose the fewest coherent commits. Combine changes that serve one logical purpose, separate independent changes, and avoid a new commit when the work belongs in an existing local-only commit. For amend, squash, or rebase, show exactly what would be rewritten and why.
5. Show the proposed file/hunk groups and commit messages. Stop and wait for explicit approval before staging, committing, amending, squashing, rebasing, or pushing. Approval to commit does not imply approval to push.
6. After approval, stage only the approved changes, inspect each staged diff, perform only the approved Git operations, and report the resulting history and remaining worktree changes.

## Safety boundaries

- Do not rewrite commits already present on the upstream.
- Do not push unless the user explicitly asks.
- Do not reset, stash, or overwrite unrelated work as a convenience.
- Prefer one commit per logical change, not one commit per file or edit.
- If isolating the requested changes risks altering unrelated work, explain the risk and ask before proceeding.

Use the repository's commit conventions when choosing messages. In this repository, commit messages are in English and use `<aspect>: <title>`.
