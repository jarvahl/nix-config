{ ... }:
let
  service =
    {
      name,
      port,
    }:
    {
      nixos.services.tailscale.services.${name} = {
        inherit port;
      };
    };
in
{
  den.aspects.tailscale.service.__functor = _self: service;
}
