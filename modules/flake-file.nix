{ lib, inputs, ... }:
{
  imports = [
    (inputs.flake-file.flakeModules.dendritic or { })
  ];

  flake-file.inputs = {
    flake-file.url = lib.mkForce "github:denful/flake-file";
  };
}
