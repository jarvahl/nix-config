{ ... }:
{
  zsh.modules = [
    ({ config, lib, ... }:
      {
        options.setopt = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ ];
          example = [
            "AUTO_CD"
            "EXTENDED_GLOB"
          ];
          description = "List of zsh options to enable via `setopt`.";
        };

        options.unsetopt = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ ];
          example = [ "BEEP" ];
          description = "List of zsh options to disable via `unsetopt`.";
        };

        config.zsh.rc = lib.mkOrder 20 (
          lib.concatStringsSep "\n" (
            (map (o: "setopt ${o}") config.setopt) ++ (map (o: "unsetopt ${o}") config.unsetopt)
          )
        );
      })
  ];
}
