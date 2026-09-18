{ ... }:
{
  tmux.modules = [
    ({ config, lib, ... }:
      {
        options.mode = lib.mkOption {
          type = lib.types.enum [ "emacs" "vi" ];
          default = "vi";
          description = "Key mode used by tmux copy mode.";
        };

        config.rc = lib.mkBefore "set -g mode-keys ${config.mode}";
      })
  ];
}
