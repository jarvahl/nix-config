{ flakeConfig, lib, ... }:
let
  services = lib.mergeAttrsList (
    lib.mapAttrsToList (
      _host: nixos: nixos.config.services.tailscale.services or { }
    ) flakeConfig.nixosConfigurations
  );
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
