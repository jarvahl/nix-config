{ den, lib, inputs, ... }:
{
  imports = [
    inputs.den.flakeModules.dendritic
  ];

  den.default.includes = (with den.batteries; [
    mutual-provider
    hostname
    define-user
    inputs'
  ])
  ++ (with den.aspects; [
    ca
    clipboard
    comma
    nix
    sudo
  ]);

  den.default.nixos = {
    system.stateVersion = "25.11";
  };

  flake-file.inputs = {
    den.url = lib.mkDefault "github:denful/den";
  };
}
