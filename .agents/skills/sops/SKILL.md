# SOPS

!!! NEVER READ, PRINT, OR DECRYPT SECRET VALUES !!!
!!! NEVER READ OR PRINT PRIVATE KEY MATERIAL !!!
!!! NEVER PUT SECRETS IN ARGS, LOGS, CHAT, OR OUTPUT !!!

Use this skill to add, modify, or remove SOPS secrets directly with SOPS commands.

## Generate and add

Generate secret directly into a pipe. Never store it in a shell variable or print it:

```bash
openssl rand -hex 32 \
  | nix run nixpkgs#jq -- -Rs . \
  | sops set --value-stdin path/to/secrets.yaml \
      '["users"]["<username>"]["<service>"]["<secret>"]'
```

Other generators work the same way:

```bash
openssl rand -base64 32
age-keygen
```

Pipe output directly to the encoder and SOPS. For tools that require an output file, generate into a protected temporary file, pass it with the protected-file procedure below, then remove it securely.

## Add or modify

Read value only through a protected file or stdin. Encode multiline values as one JSON string, then stream them to SOPS:

```bash
nix run nixpkgs#jq -- -Rs . < "$PRIVATE_FILE" \
  | sops set --value-stdin path/to/secrets.yaml \
      '["users"]["<username>"]["<service>"]["<secret>"]'
```

`jq -Rs .` encodes plain or multiline input. `sops set --value-stdin` encrypts it in place. Keep secret out of args and output.

For a value already available on stdin:

```bash
sops set --value-stdin path/to/secrets.yaml \
  '["users"]["<username>"]["<service>"]["<secret>"]'
```

Never use command substitution:

```bash
sops set ... "$(cat private-file)"
```

## Remove

Remove one key or branch by its tree path:

```bash
sops unset path/to/secrets.yaml \
  '["users"]["<username>"]["<service>"]["<secret>"]'
```

Remove only the requested path. Do not decrypt file to confirm.

## Rules

- Preserve existing encrypted file and YAML structure.
- Use paths matching repository convention, e.g. `users/<username>/<service>/<secret>`.
- Never use `sops -d`.
- Trust command exit status; inspect no secret content.
- Never expose secret through terminal, process arguments, logs, temporary plaintext files, or chat.
