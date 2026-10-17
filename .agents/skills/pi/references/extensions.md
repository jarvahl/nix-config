<!-- DO-NOT-EDIT. This file was auto-generated using github:jarvahl/agent-files. Use nix run .#write-files to regenerate it. -->

# Pi extensions

## Workflow

1. Prefer the upstream Git repository over an npm tarball.
2. Inspect `package.json` to confirm the version and extension entry point.
3. Pin an immutable commit with `fetchFromGitHub` and record its hash.
4. Package only the extension files needed at runtime with a small derivation.
5. Add the resulting extension path to `programs.pi.coding-agent.extensions`.
6. Run `nix flake check --no-build` and build the affected derivation when possible.

Keep one shared packaging helper for multiple source-only extensions when their
derivations have the same shape, while keeping source paths explicit.
