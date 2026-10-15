{ ... }:
{
  flake-file.inputs.nvf = {
    inputs.nixpkgs.follows = "nixpkgs";
    url = "github:notashelf/nvf";
  };
}
