{ ... }:
{
  den.aspects.cargo.provides.nixos-user = {
    hjem = { pkgs, ... }: {
      packages = [ pkgs.gh ];
    };

    nixos = { config, ... }: {
      sops.secrets = {
        "users/nixos/github/username" = { };
        "users/nixos/github/email" = { };
      };

      sops.templates."github-identity" = {
        content = ''
          [user]
              name = ${config.sops.placeholder."users/nixos/github/username"}
              email = ${config.sops.placeholder."users/nixos/github/email"}
        '';
        owner = "nixos";
        mode = "0400";
      };

      sops.templates."github-include" = {
        content = ''
          [includeIf "hasconfig:remote.*.url:https://github.com/"]
              path = ~/.config/git/github-identity
        '';
        owner = "nixos";
        mode = "0400";
      };

      hjem.users.nixos = {
        files = {
          ".config/git/github-identity".source = config.sops.templates."github-identity".path;
          ".config/git/github-include".source = config.sops.templates."github-include".path;
        };

        rum.programs.git.settings.include.path = "~/.config/git/github-include";
      };
    };
  };
}
