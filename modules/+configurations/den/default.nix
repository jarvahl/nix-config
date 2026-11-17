{
  config,
  inputs,
  lib,
  ...
}:
{
  den.default.nixos = with config.flakelight.outputs; {
    imports = lib.attrValues nixosModules;
    nixpkgs.overlays = [ overlays.default ];
  };

  flake-file.inputs.den.url = "github:denful/den";

  imports = [
    inputs.den.flakeModule
  ];
}
