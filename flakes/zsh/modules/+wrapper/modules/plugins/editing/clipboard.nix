{ ... }:
{
  zsh.modules = [
    ({ lib, ... }: {
      options.clipboard.enable = lib.mkEnableOption "clipboard support";
    })

    ({ config, lib, pkgs, ... }: {
      config = lib.mkIf config.clipboard.enable {
        zsh.optPlugins.omz-clipboard = {
          package = pkgs.oh-my-zsh;
          source = "share/oh-my-zsh/lib/clipboard.zsh";
        };
      };
    })
  ];
}
