{ ... }:
{
  den.aspects.gaia.provides.nixos-user = {
    hjem = { pkgs, ... }: {
      packages = [ pkgs.gh ];
    };

    nixos = { config, ... }: {
      sops.secrets = {
        "users/nixos/github/username" = { };
        "users/nixos/github/email" = { };
      };

      sops.templates."github-identity".content = ''
        [user]
            name = ${config.sops.placeholder."users/nixos/github/username"}
            email = ${config.sops.placeholder."users/nixos/github/email"}
      '';

      hjem.users.nixos.files.".config/git/github-identity".source =
        config.sops.templates."github-identity".path;
    };
  };
}
