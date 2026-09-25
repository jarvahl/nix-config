{ ... }:
let
  host = "apex";
in
{
  den = {
    hosts.x86_64-linux.${host}.users.jarvahl = { };

    aspects.${host}.nixos.sops.defaultSopsFile = ./secrets.yml;
  };
}
