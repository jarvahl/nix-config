{ ... }:
{
  zsh.modules = [
    ({ lib, ... }: {
      options.history.integrations.fzf.enable = lib.mkEnableOption "fzf-history-search";
    })

    ({ config, lib, pkgs, ... }: {
      config = lib.mkIf config.history.integrations.fzf.enable {
        zsh.optPlugins.fzf-history-search = {
          package = pkgs.zsh-fzf-history-search;
          source = "share/zsh-fzf-history-search/zsh-fzf-history-search.plugin.zsh";
          after = [ "fzf-tab" ];
          before = [ "omz-git" ];
        };
      };
    })
  ];
}
