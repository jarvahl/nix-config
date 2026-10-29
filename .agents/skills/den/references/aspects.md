<!-- DO-NOT-EDIT. This file was auto-generated using github:jarvahl/agent-files. Use nix run .#write-files to regenerate it. -->

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

  (hyperland hyperland.autologin)
];
```

Prefer names that say what happens:

```nix
sops.secret
sops.template
ssh
```

Avoid vague helpers and compatibility aliases unless there is a real external caller.
