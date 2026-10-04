{ self, ... }:

let
  host = "theia";
in
{
  flake.nixosModules.${host} = {
    users.users.jarvahl = {
      extraGroups = [ "wheel" ];
      initialPassword = "changeme";
      isNormalUser = true;
    };
  };
}
