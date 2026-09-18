{ ... }:
{
  zsh.modules = [
    ({ lib, ... }: {
      options.autosuggestion.enable = lib.mkEnableOption "zsh-autosuggestions";
    })

    ({ config, lib, pkgs, ... }: {
      config = lib.mkIf config.autosuggestion.enable {
        zsh.startPlugins.autosuggestions = {
          package = pkgs.zsh-autosuggestions;
          source = "share/zsh-autosuggestions/zsh-autosuggestions.zsh";
          after = [ "vi-mode" ];
        };
      };
    })
  ];
}
