{ den, inputs, lib, ... }:
{
  den.aspects.zsh = {
    hjem = { ... }:
      {
        rum.programs.zsh = {
          enable = true;

          flake = {
            enable = true;

            vi.enable = true;
            autosuggestion.enable = true;
            syntaxHighlighting.integrations.patina.enable = true;

            completion = {
              enable = true;
              integrations.fzf.enable = true;
            };

            history = {
              size = 100000;
              save = 100000;
              integrations.fzf.enable = true;
            };

            setopt = [
              "APPEND_HISTORY"
              "EXTENDED_HISTORY"
              "HIST_IGNORE_DUPS"
              "HIST_IGNORE_SPACE"
              "HIST_REDUCE_BLANKS"
              "SHARE_HISTORY"
            ];

            initConfig = builtins.readFile "${inputs."zsh-flake"}/.zshrc";

            imports = [
              ({ pkgs, ... }: {
                zsh.startPlugins = {
                  autoenv = {
                    package = pkgs.zsh-autoenv;
                    source = "share/zsh-autoenv/autoenv.plugin.zsh";
                  };
                  dirhistory = {
                    package = pkgs.oh-my-zsh;
                    source = "share/oh-my-zsh/plugins/dirhistory/dirhistory.plugin.zsh";
                  };
                  colored-man-pages = {
                    package = pkgs.oh-my-zsh;
                    source = "share/oh-my-zsh/plugins/colored-man-pages/colored-man-pages.plugin.zsh";
                  };
                };
              })
            ];
          };
        };
      };

    includes = [
      (den.batteries.unfree [ "zsh-autoenv" ])
    ];
  };

  den.default.nixos.hjem.extraModules = lib.mkAfter [
    inputs."zsh-flake".hjemModules.default
  ];

  flake-file.inputs."zsh-flake" = {
    url = "github:jarvahl/zsh-flake";
  };
}
