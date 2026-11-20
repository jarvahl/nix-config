{
  flake-parts-lib,
  inputs,
  lib,
  ...
}:
let
  outputs = inputs.flakelight.lib.mkFlake ./. (
    { config, lib, ... }:
    {
      options.skills = lib.mkOption {
        default = { };
        type = lib.types.attrsOf lib.types.raw;
      };

      options.terranixModules = lib.mkOption {
        default = { };
        type = lib.types.attrsOf lib.types.path;
      };

      config = {
        nixDir = ./outputs;
        nixDirPathAttrs = [
          "skills"
          "terranixModules"
        ];
        outputs.skills = config.skills;
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

  options.perSystem = flake-parts-lib.mkPerSystemOption {
    options.skills = lib.mkOption {
      default = { };
      type = lib.types.attrsOf lib.types.path;
    };
  };

  config = {
    flake-file.inputs.flakelight = {
      inputs.nixpkgs.follows = "nixpkgs";
      url = "github:nix-community/flakelight";
    };

    flake.overlays.default = outputs.overlays.default;
    flakelight.outputs = outputs;

    transposition.skills = { };

    perSystem =
      { pkgs, ... }:
      {
        packages = outputs.packages.${pkgs.system};
        skills = outputs.skills;
      };
  };
}
