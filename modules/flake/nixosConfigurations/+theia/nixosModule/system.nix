{ self, ... }:

let
  host = "theia";
in
{
  flake.nixosModules.${host} = {
    imports = with self.nixosModules; [
      nix
    ];

    networking.hostName = host;
    system.stateVersion = "26.05";

    security.sudo.wheelNeedsPassword = false;
  };
}
