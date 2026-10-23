{ lib, ... }:
let
  service =
    {
      comment ? null,
      name,
      port,
      servicePort ? 443,
    }:
    {
      nixos.services.tailscale.services.${name} = {
        inherit port servicePort;
      }
      // lib.optionalAttrs (comment != null) { inherit comment; };
    };
in
{
  den.aspects.tailscale.service.__functor = _self: service;
}
