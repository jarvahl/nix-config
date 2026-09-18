{ ... }:
{
  tmux.modules = [
    ({ config, lib, ... }:
      {
        options.extendedKeys = {
          enable = lib.mkEnableOption "tmux extended key reporting" // { default = true; };

          format = lib.mkOption {
            type = lib.types.str;
            default = "csi-u";
            description = "Format used for extended keys.";
          };
        };

        config.rc = lib.mkBefore ''
          set -g extended-keys ${if config.extendedKeys.enable then "on" else "off"}
          set -g extended-keys-format ${config.extendedKeys.format}
        '';
      })
  ];
}
