{ inputs, ... }:
{
  flake-file.inputs.quadlet-nix.url = "github:SEIAROTg/quadlet-nix";

  den.default.nixos.imports = [
    inputs.quadlet-nix.nixosModules.quadlet
  ];
}
