{ lib, ... }:
{
  readme.sections = lib.mkOrder 100 [
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
