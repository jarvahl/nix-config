{ inputs, moduleWithSystem, ... }:

{
  flake.nixosModules.zsh = moduleWithSystem ({ self', ... }: {
    programs.zsh.enable = true;

    users.defaultUserShell = self'.packages.zsh;
  });

  perSystem = { lib, system, ... }:
    let
      pkgs = import inputs.nixpkgs {
        config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [
          "zsh-autoenv"
        ];
        inherit system;
      };
    in
    {
      packages.zsh = (inputs.zsh-flake.lib.zshConfiguration {
        inherit pkgs;
        modules = [
          {
            autosuggestion.enable = true;
            completion = {
              enable = true;
              integrations.fzf.enable = true;
            };
            history = {
              size = 100000;
              save = 100000;
              integrations.fzf.enable = true;
            };
            imports = [
              ({ pkgs, ... }: {
                zsh.startPlugins = {
                  autoenv = {
                    package = pkgs.zsh-autoenv;
                    source = "share/zsh-autoenv/autoenv.plugin.zsh";
                  };
                  colored-man-pages = {
                    package = pkgs.oh-my-zsh;
                    source = "share/oh-my-zsh/plugins/colored-man-pages/colored-man-pages.plugin.zsh";
                  };
                  dirhistory = {
                    package = pkgs.oh-my-zsh;
                    source = "share/oh-my-zsh/plugins/dirhistory/dirhistory.plugin.zsh";
                  };
                };
              })
            ];
            initConfig = builtins.readFile "${inputs.zsh-flake}/.zshrc";
            setopt = [
              "APPEND_HISTORY"
              "EXTENDED_HISTORY"
              "HIST_IGNORE_DUPS"
              "HIST_IGNORE_SPACE"
              "HIST_REDUCE_BLANKS"
              "SHARE_HISTORY"
            ];
            syntaxHighlighting.integrations.patina.enable = true;
            vi.enable = true;
          }
        ];
      }).overrideAttrs (old: {
        meta = (old.meta or { }) // {
          mainProgram = "zsh";
        };
        passthru = (old.passthru or { }) // {
          shellPath = "/bin/zsh";
        };
      });
    };
}
