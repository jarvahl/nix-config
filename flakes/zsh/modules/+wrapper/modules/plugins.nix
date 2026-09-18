{ lib, ... }:

let
  pluginSubmodule = lib.types.submodule {
    options = {
      package = lib.mkOption {
        type = lib.types.package;
        description = "Package containing plugin scripts.";
      };
      source = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "Single plugin script path inside the package.";
      };
      sources = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        description = "Ordered list of plugin script paths inside the package.";
      };
      init = lib.mkOption {
        type = lib.types.lines;
        default = "";
        description = "Additional zsh commands run after sourcing plugin files.";
      };
      after = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        description = "Plugin names that must load before this plugin.";
      };
      before = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        description = "Plugin names that must load after this plugin.";
      };
    };
  };

  module =
    { lib, ... }:
    {
      options.zsh.startPlugins = lib.mkOption {
        type = lib.types.attrsOf pluginSubmodule;
        default = { };
        description = "Plugins rendered during shell startup.";
      };

      options.zsh.optPlugins = lib.mkOption {
        type = lib.types.attrsOf pluginSubmodule;
        default = { };
        description = "Plugins rendered through the idle loader.";
      };
    };

in
{
  zsh.modules = [ module ];
}
