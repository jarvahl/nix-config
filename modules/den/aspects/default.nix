{ den, inputs, lib, ... }:
lib.mkMerge [
  {
    den.aspects.bat = {
      hjem = { lib, pkgs, ... }: {
        rum.programs.zsh.initConfig = ''
          alias cat='${lib.getExe pkgs.bat}'
        '';
        packages = [ pkgs.bat ];
      };
    };
  }

  {
    den.aspects.comma = {
      nixos =
        { ... }:
        {
          imports = [ inputs.nix-index-database.nixosModules.nix-index ];
          programs.nix-index-database.comma.enable = true;
        };
    };

    flake-file.inputs.nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  }

  {
    den.aspects.devbox.hjem =
      { pkgs, ... }:
      {
        packages = [ pkgs.devbox ];
      };
  }

  {
    den.aspects.direnv.hjem.rum.programs.direnv = {
      enable = true;
      integrations.zsh.enable = true;
    };
  }

  {
    den.aspects.eza = {
      hjem = { lib, pkgs, ... }: {
        rum.programs.zsh.initConfig =
          let
            flags = "--group-directories-first --icons=always";
          in
          ''
            alias ls="${lib.getExe pkgs.eza} ${flags}"
            alias ll="${lib.getExe pkgs.eza} -lh ${flags}"
            alias la="${lib.getExe pkgs.eza} -la ${flags}"
            alias tree="${lib.getExe pkgs.eza} --tree ${flags}"
          '';
        packages = [ pkgs.eza ];
      };
    };
  }

  {
    den.aspects.fonts.nixos =
      { pkgs, ... }:
      {
        fonts.packages = with pkgs.nerd-fonts; [
          fira-code
          jetbrains-mono
        ];
      };
  }

  {
    den.aspects.fzf.hjem = { pkgs, ... }: {
      packages = [ pkgs.fzf ];
    };
  }

  {
    den.aspects.gh = {
      hjem = { pkgs, ... }: {
        packages = [ pkgs.gh ];

        rum.programs.git.settings.credential = {
          "https://github.com".helper = [
            ""
            "!${pkgs.gh}/bin/gh auth git-credential"
          ];
          "https://gist.github.com".helper = [
            ""
            "!${pkgs.gh}/bin/gh auth git-credential"
          ];
        };
      };

      includes = [ den.aspects.gh ];
    };
  }

  {
    den.aspects.git.hjem = { ... }: {
      rum.programs.git = {
        enable = true;
        settings = {
          format.pretty = "oneline";
          log.decorate = "short";
        };
      };
    };
  }

  {
    den.aspects.lazygit = {
      hjem = { pkgs, ... }: {
        nvf.vim.terminal.toggleterm = {
          enable = true;
          lazygit.enable = true;
        };
        packages = with pkgs; [ lazygit ];
      };

      includes = [ den.aspects.git ];
    };
  }

  {
    den.aspects.nix.nixos = {
      nix.settings.experimental-features = [
        "nix-command"
        "flakes"
        "pipe-operators"
      ];

      nix.settings.trusted-users = [
        "root"
        "@wheel"
      ];
    };
  }

  {
    den.aspects.ripgrep.hjem = { pkgs, ... }: {
      packages = [ pkgs.ripgrep ];
    };
  }

  {
    den.aspects.ssh = {
      hjem = {
        files.".ssh/config".text = ''
          Include ~/.ssh/config.d/*
        '';
      };

      nixos.services.openssh = {
        enable = true;
        ports = [ 2222 ];
        settings = {
          PasswordAuthentication = true;
          KbdInteractiveAuthentication = true;
          PermitRootLogin = "no";
          X11Forwarding = false;
        };
      };
    };
  }

  {
    den.aspects.sudo.nixos.security.sudo = {
      enable = true;
      wheelNeedsPassword = false;
    };
  }

  {
    den.aspects.tailscale.nixos = {
      services.tailscale.enable = true;
      networking.firewall.trustedInterfaces = [ "tailscale0" ];
    };
  }

  {
    den.aspects.worktrunk = {
      hjem = { lib, pkgs, ... }: {
        rum.programs.zsh.initConfig =
          let
            shellIntegration = pkgs.runCommand "worktrunk-zsh-integration" { } ''
              plugin_dir=$out/share/zsh/plugins/worktrunk
              mkdir -p "$plugin_dir"
              ${lib.getExe pkgs.worktrunk} config shell init zsh > "$plugin_dir/worktrunk.plugin.zsh"
            '';
          in
          ''
            source "${shellIntegration}/share/zsh/plugins/worktrunk/worktrunk.plugin.zsh"
          '';
        packages = [ pkgs.worktrunk ];
      };
    };
  }

  {
    den.aspects.zoxide = {
      hjem = { lib, pkgs, ... }: {
        rum.programs.zsh.initConfig = ''
          eval "$(${lib.getExe pkgs.zoxide} init zsh)"
        '';
        packages = [ pkgs.zoxide ];
      };
    };
  }

  {
    den.aspects.zscaler.nixos =
      { pkgs, ... }:
      {
        security.pki.certificateFiles = [
          "${pkgs.zscaler-cacert}/etc/ssl/certs/zscaler-ca.crt"
        ];
      };
  }

  {
    den.aspects.console = {
      includes = with den.aspects; [ bat eza fzf zoxide tmux zsh ];
    };
  }

  {
    den.aspects.development = {
      includes = with den.aspects; [ console direnv gh lazygit ripgrep devbox nvim worktrunk ];
    };
  }
]
