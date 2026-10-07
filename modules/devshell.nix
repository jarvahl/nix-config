{ ... }:
{
  perSystem = { config, pkgs, ... }: {
    devShells.default = pkgs.mkShell {
      packages = with pkgs; [
        age
        just
        mdsh
        sops
      ];

      shellHook = ''
        ${config.pre-commit.shellHook}
      '';
    };
  };
}
