{ den, inputs, lib, ... }:
{
  den.aspects.zsh = {
    zsh = { pkgs, ... }: {
      enable = true;

      history = {
        file = "\${ZDOTDIR:-$HOME}/.zsh_history";
        size = 100000;
        save = 100000;
        integrations.fzf.enable = true;
      };

      setopt = [
        "append_history"
        "extended_history"
        "hist_ignore_dups"
        "hist_ignore_space"
        "hist_reduce_blanks"
        "share_history"
      ];

      completion = {
        enable = true;
        integrations.fzf.enable = true;
      };

      vi.enable = true;
      autosuggestion.enable = true;
      syntaxHighlighting.integrations.patina.enable = true;

      integrations = {
        git.enable = true;
        docker.enable = true;
      };

      zsh.startPlugins = {
        dirhistory = {
          package = pkgs.oh-my-zsh;
          source = "share/oh-my-zsh/plugins/dirhistory/dirhistory.plugin.zsh";
        };

        colored-man-pages = {
          package = pkgs.oh-my-zsh;
          source = "share/oh-my-zsh/plugins/colored-man-pages/colored-man-pages.plugin.zsh";
        };

        autoenv = {
          package = pkgs.zsh-autoenv;
          source = "share/zsh-autoenv/autoenv.plugin.zsh";
        };
      };

      initConfig = ''
        ZSH_CACHE_DIR="''${XDG_CACHE_HOME:-$HOME/.cache}/oh-my-zsh"
        mkdir -p "$ZSH_CACHE_DIR/completions"
        chmod u+w "$ZSH_CACHE_DIR"/completions/*(.N) 2>/dev/null || true

        fpath=("$ZSH_CACHE_DIR/completions" $fpath)

        zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
        zstyle ':completion:*' menu select
        zstyle ':completion:*' list-colors "''${(s.:.)LS_COLORS}"

        PROMPT="%B%F{magenta}#%f%b "

        set -a
        for f in /etc/environment.d/[0-9][0-9]-session-env-*.conf(N); do
          [[ -r "$f" ]] && source "$f";
        done
        set +a

      '';
    };

    includes = [
      (den.batteries.unfree [ "zsh-autoenv" ])
    ];
  };

  den.default.nixos.hjem.extraModules = lib.mkAfter [
    inputs.zsh-nix.hjemModules.default
  ];

  den.schema.user.includes = [
    ({ user }:
      den.batteries.forward {
        each = lib.singleton user;
        fromClass = _: "zsh";
        intoClass = _: "hjem";
        intoPath = _: [ "integrations" "zsh-nix" ];
        fromAspect = u: u.aspect;
        adaptArgs = args: { inherit (args) pkgs; inherit lib; };
      })
  ];
  flake-file.inputs.zsh-nix = {
    url = "github:jarvahl/zsh.nix";
    inputs.nixpkgs.follows = "nixpkgs";
  };
}
