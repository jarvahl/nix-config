{ inputs, lib, ... }:

lib.mkMerge [
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
          5. Add the resulting extension path to `programs.pi.coding-agent.extensions`.
          6. Run `nix flake check --no-build` and build the affected derivation when possible.

          Keep one shared packaging helper for multiple source-only extensions when their
          derivations have the same shape, while keeping source paths explicit.
        '';
      };
    };

    flake-file.inputs.pi.url = "github:lukasl-dev/pi.nix";

    den.aspects.pi.hjem =
      { pkgs, ... }:
      {
        programs.pi.coding-agent = {
          enable = true;
          environment = {
            PI_SKIP_VERSION_CHECK.value = "1";
            PI_TELEMETRY.value = "0";
          };
          extensions = [
            "${pkgs.pi-core-skill-tool}/pi-core-skill-tool/index.ts"
            "${pkgs.pi-self-compact}/pi-self-compact/extensions/index.ts"
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

    den.default.nixos.nixpkgs.overlays = [
      inputs.pi.overlays.default
    ];
  }

  {
    den.default.nixos.nixpkgs.overlays = [
      (
        final: _prev:
        let
          mkPiExtension =
            {
              pname,
              sourcePath,
              src,
              version,
            }:
            final.stdenvNoCC.mkDerivation {
              inherit pname src version;

              dontBuild = true;

              installPhase = ''
                mkdir -p "$out/${pname}"
                cp -r ${sourcePath} "$out/${pname}/"
              '';
            };
        in
        {
          pi-core-skill-tool = mkPiExtension {
            pname = "pi-core-skill-tool";
            sourcePath = "packages/core/pi-core-skill-tool/src/index.ts";
            src = final.fetchFromGitHub {
              hash = "sha256-SCvTHU3aoSVuEovb6F5La7F/YPt63m8Bg1I/Y0fM2eM=";
              owner = "arhen";
              repo = "pi-extensions";
              rev = "267bbdb";
            };
            version = "1.0.12";
          };

          pi-self-compact = mkPiExtension {
            pname = "pi-self-compact";
            sourcePath = "extensions";
            src = final.fetchFromGitHub {
              hash = "sha256-bJgfMA1JGGGfItic9cTYN6BAG8LBbrFTqMg/igfAaoE=";
              owner = "saiday";
              repo = "pi-self-compact";
              rev = "de04f436207cf4fc45458739366cd7f7f61f11e7";
            };
            version = "0.2.0";
          };
        }
      )
    ];
  }
]
