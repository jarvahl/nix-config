{ inputs, lib, ... }:
let
  outputs = inputs.flakelight.lib.mkFlake ./. (
    { config, lib, ... }:
    {
      options.terranixModules = lib.mkOption {
        default = { };
        type = lib.types.attrsOf lib.types.path;
      };

      config = {
        nixDir = ./outputs;
        nixDirPathAttrs = [ "terranixModules" ];
        outputs.terranixModules = config.terranixModules;
      };
    }
  );
in
{
  options.flakelight.outputs = lib.mkOption {
    readOnly = true;
    type = lib.types.lazyAttrsOf lib.types.raw;
  };

  config = {
    flake-file.inputs.flakelight = {
      inputs.nixpkgs.follows = "nixpkgs";
      url = "github:nix-community/flakelight";
    };

    flakelight.outputs = outputs;
  };
}
