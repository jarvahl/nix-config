{ ... }:
{
  tmux.modules = [
    ({ config, lib, ... }:
      {
        options.mouse.enable = lib.mkEnableOption "tmux mouse support" // { default = true; };
        config.rc = lib.mkBefore ''
          set -g mouse ${if config.mouse.enable then "on" else "off"}
        '';
      })
  ];
}
