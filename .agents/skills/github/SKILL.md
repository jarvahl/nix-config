# GitHub

!!! NEVER READ, PRINT, OR TRANSMIT PRIVATE KEYS OR TOKENS !!!
!!! PUBLIC SSH KEYS MAY BE READ AND UPLOADED !!!

Use this skill for GitHub account operations through `gh`.

## SSH keys

Use the idempotent helper:

```bash
bash .agents/skills/github/references/add-ssh-key.sh \
  "$HOME/.ssh/<username>@<host>.pub" \
  "<username>@<host>"
```

Helper behavior:

- checks active GitHub account;
- reads only the public key file;
- finds matching key or title;
- does nothing when key and title already match;
- updates an existing key when its public material or title changed;
- adds the key when no match exists.

Details: [references/ssh-keys.md](references/ssh-keys.md)
