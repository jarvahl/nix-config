{ ... }:
{
  den.aspects.gaia.provides.nixos-user = {
    hjem = { pkgs, ... }: {
      packages = [ pkgs.glab ];
    };

    nixos = { config, ... }: {
      sops.secrets = {
        "users/nixos/gitlab/username" = { };
        "users/nixos/gitlab/email" = { };
      };

      sops.templates."gitlab-identity" = {
        content = ''
          [user]
              name = ${config.sops.placeholder."users/nixos/gitlab/username"}
              email = ${config.sops.placeholder."users/nixos/gitlab/email"}
        '';
        owner = "nixos";
        mode = "0400";
      };

      sops.templates."git-identity-includes" = {
        content = ''
          [includeIf "hasconfig:remote.*.url:https://github.com/"]
              path = ~/.config/git/github-identity

          [includeIf "hasconfig:remote.*.url:https://${config.sops.placeholder."gitlab/host"}/"]
              path = ~/.config/git/gitlab-identity
        '';
        owner = "nixos";
        mode = "0400";
      };

      hjem.users.nixos = {
        files = {
          ".config/git/gitlab-identity".source = config.sops.templates."gitlab-identity".path;
          ".config/git/git-identity-includes".source = config.sops.templates."git-identity-includes".path;
        };

        rum.programs.git.settings.include.path = "~/.config/git/git-identity-includes";
      };
    };
  };
}
