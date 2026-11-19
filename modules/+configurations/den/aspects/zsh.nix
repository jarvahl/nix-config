{ den, ... }:
{
  den.aspects.zsh = {
    hjem =
      { lib, pkgs, ... }:
      let
        fzfTab = pkgs.fetchFromGitHub {
          hash = "sha256-WlmWLKHrLeptc5rqlHbKvthD73it9ij7IDT9QxN4jCc=";
          owner = "Aloxaf";
          repo = "fzf-tab";
          rev = "e394092c17277c84cb3d234917c4ac1073102ba6";
        };
      in
      {
        rum.programs.zsh = {
          enable = true;

          initConfig = ''
            ZSH_CACHE_DIR="''${XDG_CACHE_HOME:-$HOME/.cache}/oh-my-zsh"
            mkdir -p "$ZSH_CACHE_DIR/completions"
            chmod u+w "$ZSH_CACHE_DIR"/completions/*(.N) 2>/dev/null || true

            fpath=(
              "$ZSH_CACHE_DIR/completions"
              "${pkgs.nix-zsh-completions}/share/zsh/site-functions"
              "${pkgs.zsh-completions}/share/zsh/site-functions"
              $fpath
            )

            zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
            zstyle ':completion:*' menu select
            zstyle ':completion:*' list-colors "''${(s.:.)LS_COLORS}"

            HISTFILE="$HOME/.zsh_history"
            HISTSIZE=10000
            SAVEHIST=10000
            [[ -d "''${HISTFILE:h}" ]] || mkdir -p "''${HISTFILE:h}"

            autoload -Uz compinit
            compinit

            source "${pkgs.zsh-vi-mode}/share/zsh-vi-mode/zsh-vi-mode.plugin.zsh"
            source "${pkgs.zsh-autosuggestions}/share/zsh-autosuggestions/zsh-autosuggestions.zsh"

            source <(${lib.getExe pkgs.fzf} --zsh)
            source "${fzfTab}/fzf-tab.plugin.zsh"
            enable-fzf-tab
            source "${pkgs.zsh-fzf-history-search}/share/zsh-fzf-history-search/zsh-fzf-history-search.plugin.zsh"

            source "${pkgs.oh-my-zsh}/share/oh-my-zsh/lib/git.zsh"
            source "${pkgs.oh-my-zsh}/share/oh-my-zsh/plugins/git/git.plugin.zsh"

            eval "$(${pkgs.zsh-patina}/bin/zsh-patina activate)"

            PROMPT="%B%F{magenta}#%f%b "
          '';
        };
      };

    includes = with den.aspects; [ zsh-integration ];
  };

  den.aspects.zsh-integration = {
    nixos =
      {
        config,
        lib,
        user,
        ...
      }:
      let
        shell = "${config.hjem.users.${user.userName}.rum.programs.zsh.package}/bin/zsh";
      in
      {
        environment.shells = [ shell ];
        users.users.${user.userName}.shell = lib.mkForce shell;
      };
  };
}
