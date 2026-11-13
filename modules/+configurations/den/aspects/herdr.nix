{ inputs, ... }:
{
  den.aspects.herdr.hjem.programs.herdr = {
    enable = true;
  };

  den.default.nixos.hjem.extraModules = [
    (inputs.home-manager + "/modules/programs/herdr.nix")
  ];

}
