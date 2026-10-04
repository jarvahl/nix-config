## Rules

- Keep attribute keys lexicographically sorted when editing Nix attrsets.
- Use `with` for module/package lists and `inherit` for explicit dependencies and argument forwarding.
- Use `inherit` to name deep attribute paths before reusing them.
- Use `writeShellApplication.runtimeInputs` for commands used inside shell scripts.
- Use `lib.getExe`/`lib.getExe'` instead of hard-coded `/bin` paths outside those scripts.
- Run `nix run .#write-flake` after changing `flake-file.inputs`.
