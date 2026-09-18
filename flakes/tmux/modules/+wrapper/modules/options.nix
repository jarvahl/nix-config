{ ... }:
{
  tmux.modules = [
    ({ config, lib, ... }:
      {
        options = {
          initConfig = lib.mkOption {
            type = lib.types.lines;
            default = "";
            description = "Tmux configuration text.";
          };

          packages = lib.mkOption {
            type = lib.types.listOf lib.types.package;
            default = [ ];
            description = "Packages used by the tmux configuration.";
          };

          rc = lib.mkOption {
            type = lib.types.lines;
            internal = true;
          };
        };

        config.rc = lib.mkOrder 900 config.initConfig;
      })
  ];
}
