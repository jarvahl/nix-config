{ ... }:
{
  tmux.modules = [
    ({ config, lib, ... }:
      {
        options.prefix2 = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          default = "Home";
          description = "Secondary tmux prefix key, or null to leave it unchanged.";
        };

        config.rc = lib.mkBefore (
          lib.optionalString (config.prefix2 != null) "set -g prefix2 ${config.prefix2}"
        );
      })
  ];
}
