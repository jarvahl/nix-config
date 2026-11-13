{
  config,
  inputs,
  lib,
  ...
}:
{
  den.default.nixos.imports = lib.attrValues config.flakelight.outputs.nixosModules;

  flake-file.inputs.den.url = "github:denful/den";

  imports = [
    inputs.den.flakeModule
  ];
}
