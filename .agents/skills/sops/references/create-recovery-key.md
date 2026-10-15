<!-- DO-NOT-EDIT. This file was auto-generated using github:jarvahl/agent-files. Use nix run .#write-files to regenerate it. -->

# Create SOPS recovery key

Generate age identity:

```shell
age-keygen -o recovery.key
```

Encrypt it with a passphrase:

```shell
age -p -a -o recovery.key.age recovery.key
```

Show public recipient if you later want to add it to SOPS rules:

```shell
age-keygen -y recovery.key
```

Remove plaintext identity:

```shell
rm recovery.key
```

This creates `recovery.key.age`: a passphrase-encrypted age identity safe to keep in the repo.
