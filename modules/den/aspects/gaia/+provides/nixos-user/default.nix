{ den, lib, ... }:
lib.mkMerge [
  {
    den.aspects.gaia.provides.nixos-user = { ... }: {
      includes = [
        den.batteries.primary-user
        (den.batteries.user-shell "zsh")
        den.aspects.development
      ];
    };
  }

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

  {
    den.aspects.gaia.provides.nixos-user.hjem = { pkgs, ... }: {
      packages = [ pkgs.openshift ];
    };
  }

  {
    den.aspects.gaia.provides.nixos-user =
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
          sops.templates."git-proxy-${user.userName}" = {
            owner = user.userName;
            mode = "0400";
            content = ''
              [http]
                proxy = ${config.sops.placeholder."proxy/http"}
            '';
          };
        };
      };
  }

  {
    den.aspects.gaia.provides.nixos-user.hjem =
      { pkgs
      , sops
      , user
      , ...
      }:
      {
        files.".ssh/config".text = ''
          Include ~/.ssh/config.d/*
        '';
        files.".ssh/config.d/github".text = ''
          Host github.com
            HostName ssh.github.com
            Port 443
            User git
            IdentityFile ${sops.secrets."users/${user.userName}/github/ssh-key".path}
            IdentitiesOnly yes
            StrictHostKeyChecking accept-new
            UserKnownHostsFile ~/.ssh/known_hosts
            ProxyCommand sh -c '. ${
              sops.templates."proxy-environment".path
            }; proxy="''${http_proxy#*://}"; exec ${pkgs.netcat}/bin/nc -X connect -x "$proxy" "$1" "$2"' _ %h %p
        '';
      };
  }

  {
    den.aspects.gaia = {
      provides.nixos-user = { ... }: {
        hjem = { lib, sops, ... }: {
          rum.programs.zsh.initConfig = lib.mkBefore ''
            set -a
            if [ -r "${sops.templates.proxy-environment.path}" ]; then
              source "${sops.templates.proxy-environment.path}"
            fi
            if [ -r "${sops.templates.glab-environment.path}" ]; then
              source "${sops.templates.glab-environment.path}"
            fi
            set +a
          '';

          rum.programs.zsh.flake.imports = [
            (
              { pkgs, ... }:
              let
                ocCompletion = pkgs.runCommand "oc-zsh-completion" { } ''
                  plugin_dir=$out/share/zsh/plugins/oc
                  mkdir -p "$plugin_dir"
                  ${pkgs.openshift}/bin/oc completion zsh > "$plugin_dir/oc.plugin.zsh"
                '';
              in
              {
                zsh.optPlugins = {
                  oc = {
                    package = ocCompletion;
                    source = "share/zsh/plugins/oc/oc.plugin.zsh";
                  };
                  omz-npm = {
                    package = pkgs.oh-my-zsh;
                    source = "share/oh-my-zsh/plugins/npm/npm.plugin.zsh";
                  };
                  omz-nvm = {
                    package = pkgs.oh-my-zsh;
                    source = "share/oh-my-zsh/plugins/nvm/nvm.plugin.zsh";
                  };
                };
              }
            )
          ];
        };
      };
    };
  }
]
