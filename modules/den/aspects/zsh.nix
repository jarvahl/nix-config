{ inputs, ... }:
{
  den.aspects.zsh.hjem = { ... }: {
    imports = [
      inputs.zsh-nix.homeManagerModules.default
      (
        { config, lib, ... }:
        let
          cfg = config.programs.zsh;
        in
        {
          options.programs.zsh = {
            enable = lib.mkEnableOption "zsh";
            initContent = lib.mkOption {
              default = "";
              type = lib.types.lines;
            };
          };

          config = lib.mkIf cfg.enable {
            rum.programs.zsh = {
              enable = true;
              initConfig = lib.concatStringsSep "\n" [
                cfg.bundle.initConfig
                cfg.initContent
              ];
              package = cfg.bundle.package;
            };
          };
        }
      )
    ];

    programs.zsh = {
      enable = true;

      bundle = {
        enable = true;
        autosuggestion.enable = true;
        syntaxHighlighting.integrations.patina.enable = true;
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

  flake-file.inputs.zsh-nix = {
    inputs = {
      flake-file.follows = "flake-file";
      flake-parts.follows = "flake-parts";
      git-hooks-nix.follows = "git-hooks-nix";
      home-manager.follows = "hjem-hm-modules/home-manager";
      import-tree.follows = "import-tree";
      nixpkgs.follows = "nixpkgs";
      treefmt-nix.follows = "treefmt-nix";
    };
    url = "github:jarvahl/zsh.nix";
  };
}
