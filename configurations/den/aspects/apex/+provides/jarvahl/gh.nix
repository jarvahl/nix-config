{ ... }:
{
  den.aspects.apex.provides.jarvahl = {
    hjem = { pkgs, ... }: {
      packages = [ pkgs.gh ];
    };

    nixos = { config, ... }: {
      sops.secrets = {
        "users/jarvahl/github/username" = { };
        "users/jarvahl/github/email" = { };
      };

      sops.templates."github-identity".content = ''
        [user]
            name = ${config.sops.placeholder."users/jarvahl/github/username"}
            email = ${config.sops.placeholder."users/jarvahl/github/email"}
      '';

      sops.templates."github-include".content = ''
        [includeIf "hasconfig:remote.*.url:https://github.com/"]
            path = ~/.config/git/github-identity
      '';

      hjem.users.jarvahl = {
        files = {
          ".config/git/github-identity".source = config.sops.templates."github-identity".path;
          ".config/git/github-include".source = config.sops.templates."github-include".path;
        };

        rum.programs.git.settings.include.path = "~/.config/git/github-include";
      };
    };
  };
}
