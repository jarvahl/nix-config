{ ... }:
{
  zsh.modules = [
    ({ lib, ... }: {
      options.completion.integrations.fzf.enable = lib.mkEnableOption "fzf-tab";
    })

    ({ config, lib, pkgs, ... }: {
      config = {
        assertions = lib.mkIf config.completion.integrations.fzf.enable [
          {
            assertion = config.completion.enable;
            message = "completion.integrations.fzf.enable requires completion.enable.";
          }
        ];

        zsh.optPlugins.fzf-tab = lib.mkIf config.completion.integrations.fzf.enable {
          package = pkgs.fetchFromGitHub {
            owner = "Aloxaf";
            repo = "fzf-tab";
            rev = "e394092c17277c84cb3d234917c4ac1073102ba6";
            sha256 = "sha256-WlmWLKHrLeptc5rqlHbKvthD73it9ij7IDT9QxN4jCc=";
          };
          source = "fzf-tab.plugin.zsh";
          init = "enable-fzf-tab";
          before = [
            "fzf-history-search"
            "omz-git"
          ];
        };
      };
    })
  ];
}
