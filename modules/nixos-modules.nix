{ inputs, ... }:
{
  den.default.nixos.imports = [
    (inputs.import-tree ../nixos-modules)
  ];
}
