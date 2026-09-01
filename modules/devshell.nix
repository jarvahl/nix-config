{ self, ... }:
{
  perSystem = { config, pkgs, ... }: {
    devShells.default = pkgs.mkShell {
      packages = self.lib.withSopsTools pkgs [
        pkgs.age-derived-key
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
