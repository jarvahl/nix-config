{ ... }:
{
  den.aspects.tailscale.tags.__functor = _self: tags: {
    nixos.services.tailscale.tags = tags;
  };
}
