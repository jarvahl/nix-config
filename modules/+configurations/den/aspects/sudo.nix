{ ... }:
{
  den.aspects.sudo = {
    nixos.security.sudo.wheelNeedsPassword = false;
    user.extraGroups = [ "wheel" ];
  };
}
