{ inputs, ... }:
{
  den.default.nixos.hjem.extraModules = [
    inputs.hjem-rum.hjemModules.default
  ];

  flake-file.inputs = {
    hjem.url = "github:feel-co/hjem";
    hjem-rum.url = "github:snugnug/hjem-rum";
  };
}
