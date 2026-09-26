---
name: pi-token-killer
description: Build small PATH-based wrappers for Pi bash output reduction.
---

# Pi Token Killer wrappers

A wrapper is an executable named after the command it shadows. Pi prepends these
layers to `PATH` for bash tool calls:

1. project `.pi/token-killer`
2. `$XDG_CONFIG_HOME/pi/token-killer`
3. package builtins
4. the inherited `PATH`

## Adding a wrapper

Create an executable named after the command, for example `.pi/token-killer/rg`.
Do not add a central dispatcher. The normal PATH lookup provides discovery and
chaining.

Every wrapper must remove its own directory from `PATH` before looking up and
running the real command:

```sh
self_dir=$(CDPATH= cd -P -- "${0%/*}" && pwd)
# Rebuild PATH without "$self_dir".
exec command-name "$@"
```

The next matching executable can then be another wrapper or the real command.
Always forward arguments and preserve the wrapped command's exit status with
`exec`.

## Reducing output safely

Start with exact, common noisy invocations such as plain `status`, `diff`, or
`log`. Pass options and unknown forms through unchanged until their semantics
are understood. Keep errors on stderr and avoid hiding failures.

Use small POSIX shell scripts where possible. Add a focused shell check for
PATH removal, chaining, output reduction, and non-zero exit codes when changing
a wrapper.
