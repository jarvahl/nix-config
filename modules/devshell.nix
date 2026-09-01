{ ... }:
{
  perSystem = { config, pkgs, ... }: {
    devShells.default = pkgs.mkShell {
      packages = [
        pkgs.age-derived-key
        pkgs.age
        pkgs.gettext
        pkgs.gnumake
        pkgs.just
      ];

      shellHook = ''
        ${config.pre-commit.shellHook}
      '';
    };
  };
}
