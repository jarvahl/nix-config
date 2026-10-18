{ inputs, lib, ... }:

lib.mkMerge [
  {
    flake-file.inputs.pi.url = "github:jarvahl/pi.nix";

    den.aspects.pi.hjem =
      { pkgs, ... }:
      {
        programs.pi.coding-agent = {
          enable = true;
          environment = {
            PI_SKIP_VERSION_CHECK.value = "1";
            PI_TELEMETRY.value = "0";
          };
          extensions = with pkgs.pi; [
            "${pi-core-skill-tool}/pi-core-skill-tool/index.ts"
            "${pi-diff-review}/pi-diff-review/index.ts"
            "${pi-prompt-timer}/pi-prompt-timer/index.ts"
            "${pi-self-compact}/pi-self-compact/index.ts"
            "${ponytail}/pi-ponytail/index.js"
          ];
          extraArgs = [
            "--tui-mode"
            "fullscreen"
          ];
        };
      };

    den.default.nixos.hjem.extraModules = [
      inputs.pi.homeModules.default
    ];

  }

  {
    agent-files.skills.pi = {
      description = "Use when configuring Pi or adding Pi extensions; not for unrelated coding-agent configuration.";
      instructions =
        { references, ... }:
        ''
          # Pi

          Use this skill for Pi configuration and extensions.

          | Task | Read |
          | --- | --- |
          | Adding or updating an extension | `${references.extensions}` |
        '';
      references.extensions = {
        description = "Pi extensions";
        text = ''
          # Pi extensions

          ## Workflow

          1. Prefer the upstream Git repository over an npm tarball.
          2. Inspect `package.json` to confirm the version and extension entry point.
          3. Pin an immutable commit with `fetchFromGitHub` and record its hash.
          4. Package only the extension files needed at runtime with a small derivation.
             Install the entrypoint as `$out/<pname>/index.ts`; Pi uses this path to display the extension name.
          5. Add the resulting extension path to `programs.pi.coding-agent.extensions`.
          6. Run `nix flake check --no-build` and build the affected derivation when possible.

          Keep one shared packaging helper for multiple source-only extensions when their
          derivations have the same shape, while keeping source paths explicit.
        '';
      };
    };
  }
]
