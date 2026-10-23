{ lib, tailscaleServicesByHost, ... }:
let
  services = lib.mergeAttrsList (builtins.attrValues tailscaleServicesByHost);
in
{
  resource.tailscale_service = lib.mapAttrs (name: service: {
    name = "svc:${name}";
    ports = [ "tcp:${toString service.port}" ];
    tags = [ "tag:managed" ];
  }) services;

  terraform.required_providers.tailscale = {
    source = "tailscale/tailscale";
  };
}
