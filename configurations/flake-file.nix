{ lib, inputs, ... }:
{
  imports = [
    (inputs.flake-file.flakeModules.dendritic or { })
  ];

  flake-file.inputs = {
    flake-file.url = lib.mkForce "github:denful/flake-file";
  };

  flake-file.outputs = ''
    inputs: inputs.flake-parts.lib.mkFlake { inherit inputs; } (inputs.import-tree ./configurations)
  '';
}
