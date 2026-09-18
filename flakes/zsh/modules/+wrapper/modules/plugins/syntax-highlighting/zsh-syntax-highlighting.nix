{ ... }:
{
  zsh.modules = [
    ({ lib, ... }: {
      options.zsh-syntax-highlighting.enable = lib.mkEnableOption "zsh-syntax-highlighting";
    })

    ({ config, lib, pkgs, ... }: {
      config = lib.mkIf config.zsh-syntax-highlighting.enable {
        zsh.startPlugins.syntax-highlighting = {
          package = pkgs.zsh-syntax-highlighting;
          source = "share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh";
          after = [ "autosuggestions" ];
        };
      };
    })
  ];
}
