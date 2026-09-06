{ den, lib, ... }:
{
  den.aspects.zsh = {
    zsh = { pkgs, ... }: {
      enable = true;

      initConfig = ''
        setopt append_history
        setopt extended_history
        setopt hist_ignore_dups
        setopt hist_ignore_space
        setopt hist_reduce_blanks
        setopt share_history

        autoload -Uz compinit
        compinit

        HISTFILE="''${ZDOTDIR:-$HOME}/.zsh_history"
        HISTSIZE=100000
        SAVEHIST=100000
        [[ -d "''${HISTFILE:h}" ]] || mkdir -p "''${HISTFILE:h}"

        source "${pkgs.zsh-defer}/share/zsh-defer/zsh-defer.plugin.zsh"

        zsh-defer source "${pkgs.zsh-fzf-tab}/share/fzf-tab/fzf-tab.plugin.zsh"
        zsh-defer enable-fzf-tab
        zsh-defer source "${pkgs.zsh-fzf-history-search}/share/zsh-fzf-history-search/zsh-fzf-history-search.plugin.zsh"
        zsh-defer source "${pkgs.oh-my-zsh}/share/oh-my-zsh/lib/git.zsh"
        zsh-defer source "${pkgs.oh-my-zsh}/share/oh-my-zsh/plugins/git/git.plugin.zsh"
        zsh-defer source "${pkgs.oh-my-zsh}/share/oh-my-zsh/plugins/docker/docker.plugin.zsh"
        zsh-defer -c 'fpath+=("${pkgs.oh-my-zsh}/share/oh-my-zsh/plugins/docker/completions" $fpath)'
        zsh-defer source "${pkgs.oh-my-zsh}/share/oh-my-zsh/plugins/docker-compose/docker-compose.plugin.zsh"

        source "${pkgs.oh-my-zsh}/share/oh-my-zsh/plugins/dirhistory/dirhistory.plugin.zsh"
        source "${pkgs.oh-my-zsh}/share/oh-my-zsh/plugins/colored-man-pages/colored-man-pages.plugin.zsh"
        source "${pkgs.zsh-autoenv}/share/zsh-autoenv/autoenv.plugin.zsh"
        source "${pkgs.zsh-vi-mode}/share/zsh-vi-mode/zsh-vi-mode.plugin.zsh"
        source "${pkgs.zsh-autosuggestions}/share/zsh-autosuggestions/zsh-autosuggestions.zsh"
        bindkey -v
        eval "$(${pkgs.zsh-patina}/bin/zsh-patina activate)"

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

  den.schema.user.includes = [
    ({ user }:
      den.batteries.forward {
        each = lib.singleton user;
        fromClass = _: "zsh";
        intoClass = _: "hjem";
        intoPath = _: [ "rum" "programs" "zsh" ];
        fromAspect = u: u.aspect;
        adaptArgs = args: {
          inherit (args) pkgs lib;
        };
      })
  ];
}
