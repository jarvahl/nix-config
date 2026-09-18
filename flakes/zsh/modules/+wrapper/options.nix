{ lib, ... }:
let
  assertionModule = { lib, ... }: {
    options.assertions = lib.mkOption {
      type = lib.types.listOf (lib.types.submodule {
        options = {
          assertion = lib.mkOption {
            type = lib.types.bool;
            description = "Whether the assertion passed.";
          };
          message = lib.mkOption {
            type = lib.types.str;
            description = "Message to show when the assertion fails.";
          };
        };
      });
      default = [ ];
      description = "Assertions checked after zsh module evaluation.";
    };
  };
in
{
  options.zsh.modules = lib.mkOption {
    type = lib.types.listOf lib.types.deferredModule;
    default = [ ];
    description = "NixOS modules collected by import-tree and passed to zshConfiguration.";
  };

  config.zsh.modules = [ assertionModule ];
}
