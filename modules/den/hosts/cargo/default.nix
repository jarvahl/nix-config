{ ... }:
let
  host = "cargo";
in
{
  den = {
    hosts.x86_64-linux.${host}.users.nixos-user.userName = "nixos";

    aspects.${host}.nixos.sops.defaultSopsFile = ./secrets.yml;
  };
}
