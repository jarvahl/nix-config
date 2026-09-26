{ inputs, lib, ... }:
let
  module = { config, lib, ... }: {
    options.hjemModules = lib.mkOption {
      type = lib.types.attrsOf lib.types.path;
      default = { };
    };

    config = {
      inherit inputs;
      nixDir = ./_;
      nixDirPathAttrs = [ "hjemModules" ];

      apps = pkgs:
        lib.mapAttrs (name: _: lib.getExe pkgs.${name}) (config.packages pkgs);

      outputs.hjemModules = config.hjemModules;
    };
  };

  generated = inputs.flakelight.lib.mkFlake ../.. module;
  overlay = generated.overlays.default;
in
{
  perSystem = { system, ... }: {
    _module.args.pkgs = import inputs.nixpkgs {
      inherit system;
      overlays = [ overlay ];
    };

    apps = generated.apps.${system};
    packages = generated.packages.${system};
  };

  den.default.nixos = {
    nixpkgs.overlays = [ overlay ];
    hjem.extraModules = lib.attrValues generated.hjemModules;
  };

  flake = {
    inherit (generated) overlays;
  };

  flake-file.inputs.flakelight.url = "github:nix-community/flakelight";
}
