{ ... }:
{
  zsh.modules = [
    ({ lib, ... }: {
      options.vi.enable = lib.mkEnableOption "vi-mode";
    })

    ({ config, lib, pkgs, ... }: {
      config = lib.mkIf config.vi.enable {
        zsh.startPlugins.vi-mode = {
          package = pkgs.zsh-vi-mode;
          source = "share/zsh-vi-mode/zsh-vi-mode.plugin.zsh";
          before = [ "autosuggestions" ];
        };
      };
    })
  ];
}
