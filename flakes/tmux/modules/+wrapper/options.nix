{ lib, ... }:
{
  options.tmux.modules = lib.mkOption {
    type = lib.types.listOf lib.types.deferredModule;
    default = [ ];
    description = "Nix modules used to build a tmux configuration.";
  };
}
