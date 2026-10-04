## Rules

- Keep attribute keys lexicographically sorted when editing Nix attrsets.
- Use `with` for module/package lists and `inherit` for explicit dependencies and argument forwarding.
- Use `inherit` to name deep attribute paths before reusing them.
- Put `inherit` bindings before regular variable bindings in `let` blocks.
- Use `writeShellApplication.runtimeInputs` for commands used inside shell scripts.
- Use `lib.getExe`/`lib.getExe'` instead of hard-coded `/bin` paths outside those scripts.
- Put development modules before system modules when grouping NixOS module imports inline.
- Run `nix run .#write-flake` after changing `flake-file.inputs`.
