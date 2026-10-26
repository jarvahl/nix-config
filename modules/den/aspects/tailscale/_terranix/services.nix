{ flakeConfig, lib, ... }:
let
  services = lib.mergeAttrsList (
    lib.mapAttrsToList (
      _host: nixos:
      if nixos.config.services.tailscale.enable then
        nixos.config.services.tailscale.services or { }
      else
        { }
    ) flakeConfig.nixosConfigurations
  );
in
{
  locals.tailscale_service_approvers = lib.mapAttrs' (
    name: _: lib.nameValuePair "svc:${name}" [ "tag:services" ]
  ) services;

  resource.tailscale_service = lib.mapAttrs (
    name: service:
    {
      depends_on = [ "tailscale_acl.tags" ];
      name = "svc:${name}";
      ports = [ "tcp:${toString service.servicePort}" ];
      tags = [ "tag:services" ];
    }
    // lib.optionalAttrs (service.comment != null) { inherit (service) comment; }
  ) services;

  terraform.required_providers.tailscale = {
    source = "tailscale/tailscale";
  };
}
