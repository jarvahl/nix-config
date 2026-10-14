{ lib, ... }:
{
  readme.sections = lib.mkMerge [
    (lib.mkOrder 100 [
      {
        title = "Dev shell";
        text = ''
          ```sh
          nix develop
          ```

          Available tools:

          - `age` — create and inspect age keys
          - `just` — run repo tasks; see `just --list`
          - `mdsh` — run markdown runbooks from agent skill references
          - `sops` — edit and decrypt secrets
        '';
      }
    ])
    (lib.mkOrder 300 [
      {
        title = "Runbooks";
        text = ''
          Run executable runbooks with `mdsh`, for example:

          ```sh
          mdsh .agents/skills/sops/references/create-recovery-key.md
          ```
        '';
      }
    ])
  ];

  perSystem = { config, pkgs, ... }: {
    devShells.default = pkgs.mkShell {
      packages = with pkgs; [
        age
        just
        runme
        sops
      ];

      shellHook = ''
        ${config.pre-commit.shellHook}
      '';
    };
  };
}
