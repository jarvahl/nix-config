{ ... }:
{
  den.aspects.tailscale.nixos = {
    networking.firewall.trustedInterfaces = [ "tailscale0" ];
    services.tailscale.enable = true;
  };
}
