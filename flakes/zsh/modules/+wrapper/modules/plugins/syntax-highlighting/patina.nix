{ ... }:

{
  zsh.modules = [
    ({ lib, ... }: {
      options.syntaxHighlighting.integrations.patina.enable = lib.mkEnableOption "zsh-patina";
    })

    ({ config, lib, pkgs, ... }: {
      config = lib.mkIf config.syntaxHighlighting.integrations.patina.enable {
        zsh.startPlugins.syntax-highlighting = {
          package = lib.mkForce pkgs.zsh-patina;
          source = lib.mkForce null;
          init = lib.mkForce ''
            eval "$(${pkgs.zsh-patina}/bin/zsh-patina activate)"
          '';
          after = lib.mkForce [ "autosuggestions" ];
        };
      };
    })
  ];
}
