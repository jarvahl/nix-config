{ ... }:
{
  den.aspects.zsh.hjem = { pkgs, ... }: {
    rum.programs.fzf.enable = true;

    rum.programs.zsh = {
      enable = true;

      plugins = {
        additional-completions.completions = [
          "${pkgs.nix-zsh-completions}/share/zsh/site-functions"
          "${pkgs.zsh-completions}/share/zsh/site-functions"
        ];

        autosuggestions.source = "${pkgs.zsh-autosuggestions}/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.plugin.zsh";

        compinit.config = ''
          autoload -Uz compinit
          compinit
        '';

        fzf-history-search.source = "${pkgs.zsh-fzf-history-search}/share/zsh-fzf-history-search/zsh-fzf-history-search.plugin.zsh";
        fzf-tab.source = "${pkgs.zsh-fzf-tab}/share/fzf-tab/fzf-tab.plugin.zsh";
        vi-mode.source = "${pkgs.zsh-vi-mode}/share/zsh-vi-mode/zsh-vi-mode.plugin.zsh";
        zsh-fast-syntax-highlighting.source = "${pkgs.zsh-fast-syntax-highlighting}/share/zsh/plugins/fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh";
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
      '';
    };
  };
}
