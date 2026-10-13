{ inputs, ... }:
{
  den.aspects.zsh.homeManager = { ... }: {
    imports = [ inputs.nzf.homeManagerModules.default ];

    programs.fzf.enable = true;

    programs.nzf = {
      enable = true;
      settings.zsh = {
        autosuggestion.enable = true;
        completion = {
          enable = true;
          integrations.fzf.enable = true;
        };
        history.integrations.fzf.enable = true;
        vi.enable = true;

        imports = [
          ({ lib, pkgs, ... }: {
            zsh.rc = lib.mkOrder 29 ''
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
            '';

            zsh.startPlugins.syntax-highlighting = {
              after = [ "autosuggestions" ];
              package = pkgs.zsh-fast-syntax-highlighting;
              source = "share/zsh/plugins/fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh";
            };
          })
        ];

        initConfig = ''
          PROMPT="%B%F{magenta}#%f%b "
        '';
      };
    };
  };

  flake-file.inputs.nzf = {
    inputs = {
      flake-file.follows = "flake-file";
      flake-parts.follows = "flake-parts";
      git-hooks-nix.follows = "git-hooks-nix";
      home-manager.follows = "home-manager";
      import-tree.follows = "import-tree";
      nixpkgs.follows = "nixpkgs";
      treefmt-nix.follows = "treefmt-nix";
    };
    url = "github:jarvahl/nzf";
  };
}
