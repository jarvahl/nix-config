---
name: "nix-package-init"
description: "Generates and reviews initial Nix package expressions from project URLs with nix-init. Use when packaging an external Rust, Go, Python, npm, crate, PyPI, GitHub, GitLab, Gitea, or generic source; do not treat the generated expression as final without validation."
---

# Initialize a Nix package with nix-init

Use this skill when a project URL needs an initial Nix package expression. `nix-init` is a code generator and source/hash discovery aid, not a substitute for reviewing the package.

## Workflow

1. Inspect the target repository or URL first. Identify the source revision, language, build system, expected executable or library, and likely Nix builder.
2. Choose an output path before invoking the command. Prefer a temporary working directory or a new package directory; do not overwrite an existing expression unless the user explicitly requests it.
3. Run `nix-init` through `nix run`, so it does not need to be installed in the current environment. The output path is positional; `nix-init` does not have an `--output` option:

   ```sh
   nix run nixpkgs#nix-init -- \
     --headless \
     --url "$URL" \
     --builder "$BUILDER" \
     "$OUTPUT"
   ```

4. Supply known inputs explicitly. In particular, use `--builder` when the project type is known, `--rev` for a requested tag or commit, and `--pname` when the generated name would be wrong. Use `--overwrite` only with explicit permission.
5. Read the generated Nix expression before using it. Check the source fetcher, revision, hash, pname/version, builder, native/build/runtime dependencies, phases, install output, metadata, and license.
6. Format and validate the result. Prefer the repository's configured formatter. Evaluate the expression, then build it when feasible. Inspect the resulting output and test the packaged command or library if possible.
7. Apply only the necessary corrections. Keep the generated expression as a starting point and show the resulting diff to the user.

## Builder selection

Use the builder matching the inspected project:

- `buildRustPackage` for Cargo projects.
- `buildGoModule` for Go modules.
- `buildPythonApplication` for an executable Python application.
- `buildPythonPackage` for a reusable Python package.
- `buildNpmPackage` for an npm project.
- `stdenv.mkDerivation` or `stdenvNoCC.mkDerivation` for projects without a more specific builder.

Use the exact `nix-init` enum spelling, such as `buildRustPackage` or `buildPythonApplication`.

## Validation checklist

For a generated file `$OUTPUT`, adapt the commands to its shape:

```sh
# Format if a formatter is available and appropriate.
nixfmt "$OUTPUT"

# Evaluate a standalone derivation.
nix eval --file "$OUTPUT" drvPath

# Build without creating a result symlink.
nix build --no-link --file "$OUTPUT"
```

If the file exports an attribute set rather than a derivation, evaluate or build the relevant attribute explicitly. Use the repository's flake checks and package conventions when integrating the result.

## Safety and limitations

- Never use `--commit` unless the user explicitly asks for a commit.
- Do not claim that a successful `nix-init` run proves the package is correct.
- Verify licenses, hashes, dependency completeness, install phases, and runtime behavior manually.
- Do not expose access tokens in command lines or generated files. Configure private-source credentials through the user's approved secret mechanism.
- Do not replace an existing package expression automatically.
- If `nix run nixpkgs#nix-init` cannot resolve or is unavailable for the pinned environment, report the error and use the repository's approved fallback rather than silently switching sources.
