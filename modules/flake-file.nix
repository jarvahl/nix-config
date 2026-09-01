{ lib, inputs, ... }:
{
  imports = [
    (inputs.flake-file.flakeModules.dendritic or { })
  ];

  flake-file.inputs = {
    flake-file.url = lib.mkForce "github:denful/flake-file";
    pi.url = "github:lukasl-dev/pi.nix";
  };
}
