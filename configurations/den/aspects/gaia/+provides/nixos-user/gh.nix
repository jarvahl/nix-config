{ ... }:
{
  den.aspects.gaia.provides.nixos-user.hjem = { pkgs, ... }: {
    packages = [ pkgs.gh ];
  };
}
