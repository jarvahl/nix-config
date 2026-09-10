# GitHub SSH keys

!!! NEVER READ OR PRINT PRIVATE SSH KEYS !!!

## Add or update

Use the helper:

```bash
bash .agents/skills/github/references/add-ssh-key.sh PUBLIC_KEY_FILE TITLE
```

Example:

```bash
bash .agents/skills/github/references/add-ssh-key.sh \
  "$HOME/.ssh/jarvahl@apex.pub" \
  "jarvahl@apex"
```

The helper uses the active `gh` account. It reads only the `.pub` file and GitHub's public key metadata.

Matching rules:

1. Same key and same title: no-op.
2. Same key, different title: update title.
3. Same title, different key: update key and title.
4. No match: add key.

Check the active identity before use:

```bash
gh api user --jq '.login'
```
