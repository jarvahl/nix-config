{ ... }:
{
  tmux.modules = [
    ({ config, lib, ... }:
      {
        options.history.limit = lib.mkOption {
          type = lib.types.ints.positive;
          default = 50000;
          description = "Number of lines retained in scrollback.";
        };

        config.rc = lib.mkBefore "set -g history-limit ${toString config.history.limit}";
      })
  ];
}
