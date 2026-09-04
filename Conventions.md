# Repository conventions

## Commit messages

Use the format:

```text
scope: short description
```

For host-specific module changes under `modules/config/+machines/<host>/`, use the host as the scope and include the module in the title:

```text
host: module -> short description
```

Examples:

```text
thinkbook: add audio support
thinkbook: niri -> extract config
```
