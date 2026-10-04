{ self, ... }:

let
  host = "cargo";
in
{
  flake.nixosModules.${host} = {
    imports = with self.nixosModules;
      [
        # development
        zsh
      ]
      ++ [
        # system
        nix
      ];

    networking.hostName = host;
    security.sudo.wheelNeedsPassword = false;
    system.stateVersion = "26.05";

    users.users.nixos = {
      extraGroups = [ "wheel" ];
      initialPassword = "changeme";
      isNormalUser = true;
    };
  };
}
