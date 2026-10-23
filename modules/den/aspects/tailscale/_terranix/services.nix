{ lib, tailscaleServicesByHost, ... }:
let
  services = lib.mergeAttrsList (builtins.attrValues tailscaleServicesByHost);
in
{
  resource.tailscale_service = lib.mapAttrs (
    name: service:
    {
      name = "svc:${name}";
      ports = [ "tcp:${toString service.servicePort}" ];
      tags = [ "tag:managed" ];
    }
    // lib.optionalAttrs (service.comment != null) { inherit (service) comment; }
  ) services;

  terraform.required_providers.tailscale = {
    source = "tailscale/tailscale";
  };
}
