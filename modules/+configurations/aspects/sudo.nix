{ lib, ... }:
lib.mkMerge [
  {
    den.aspects.sudo.nixos.security.sudo.wheelNeedsPassword = false;
  }
  {
    den.aspects.sudo.user.extraGroups = [ "wheel" ];
  }
]
