{ inputs, lib, ... }:
let
  flakelight = inputs.flakelight or null;

  flake =
    if flakelight == null then {
      overlays.default = _: _: { };
      hjemModules = { };
    }
    else
      flakelight.lib.mkFlake ../.
        ({ config, lib, ... }:
          {
            options.hjemModules = lib.mkOption {
              type = lib.types.attrsOf lib.types.path;
              default = { };
            };

            config = {
              inherit inputs;
              nixDir = ../.;
              nixDirPathAttrs = [ "hjemModules" ];
              outputs.hjemModules = config.hjemModules;
            };
          });
in
{
  den.default.nixos = {
    nixpkgs.overlays = [ flake.overlays.default ];
    hjem.extraModules = lib.attrValues flake.hjemModules;
  };

  flake-file.inputs.flakelight.url = "github:nix-community/flakelight";

  perSystem = { system, ... }: {
    _module.args.pkgs = import inputs.nixpkgs {
      inherit system;
      overlays = [ flake.overlays.default ];
    };
  };
}
