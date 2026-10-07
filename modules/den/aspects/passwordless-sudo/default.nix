{ ... }:
{
  den.aspects.passwordless-sudo = {
    nixos.security.sudo.wheelNeedsPassword = false;
    user.extraGroups = [ "wheel" ];
  };
}
