# Den aspects

This repo keeps reusable Den behavior under:

```text
modules/den/aspects/
```

`import-tree` merges files recursively. Do not manually import sibling aspect files.

## Conventions

Host includes should read declaratively:

```nix
includes = with den.aspects; [
  ssh
  (ssh.provisionHostKey { ... })

  (hyperland {
    includes = { autologin, ... }: [
      autologin
    ];
  })
];
```

Prefer names that say what happens:

```nix
sops.loadSecretsFrom
sops.decryptWithSshKey
ssh.provisionHostKey
```

Avoid vague helpers and compatibility aliases unless there is a real external caller.
