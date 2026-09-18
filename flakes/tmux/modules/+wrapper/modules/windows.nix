{ ... }:
{
  tmux.modules = [
    ({ config, lib, ... }:
      {
        options.windows = {
          baseIndex = lib.mkOption {
            type = lib.types.ints.positive;
            default = 1;
            description = "First window index.";
          };

          paneBaseIndex = lib.mkOption {
            type = lib.types.ints.positive;
            default = 1;
            description = "First pane index.";
          };

          renumber = lib.mkOption {
            type = lib.types.bool;
            default = true;
            description = "Renumber windows after one is closed.";
          };
        };

        config.rc = lib.mkBefore ''
          set -g base-index ${toString config.windows.baseIndex}
          setw -g pane-base-index ${toString config.windows.paneBaseIndex}
          set -g renumber-windows ${if config.windows.renumber then "on" else "off"}
        '';
      })
  ];
}
