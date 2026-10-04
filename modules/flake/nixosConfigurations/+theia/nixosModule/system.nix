{ self, ... }:

let
  host = "theia";
in
{
  flake.nixosModules.${host} = {
    imports = with self.nixosModules;
      [
        # development
        nvim
      ]
      ++ [
        # system
        nix
      ];

    networking.hostName = host;
    security.sudo.wheelNeedsPassword = false;
    system.stateVersion = "26.05";
  };
}
