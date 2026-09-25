{ den, lib, ... }:
lib.mkMerge [
  {
    den.aspects.cargo.provides.nixos-user.includes = [
      den.batteries.primary-user
      (den.batteries.user-shell "zsh")
      den.aspects.development
    ];
  }

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

  {
    den.aspects.cargo.provides.nixos-user =
      { user, ... }:
      let
        passwordSecret = "users/${user.userName}/hashedPassword";
      in
      {
        nixos = { config, ... }: {
          sops.secrets.${passwordSecret}.neededForUsers = true;
          sops.secrets."users/${user.userName}/github/ssh-key" = {
            owner = user.userName;
            mode = "0400";
          };
          users.users.${user.userName}.hashedPasswordFile = config.sops.secrets.${passwordSecret}.path;
        };
      };
  }

  {
    den.aspects.cargo.provides.nixos-user.hjem = { sops, user, ... }: {
      files.".ssh/config".text = ''
        Include ~/.ssh/config.d/*
      '';
      files.".ssh/config.d/github".text = ''
        Host github.com
          HostName github.com
          User git
          IdentityFile ${sops.secrets."users/${user.userName}/github/ssh-key".path}
          IdentitiesOnly yes
      '';
    };
  }
]
