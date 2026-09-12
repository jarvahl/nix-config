{ ... }:
{
  den.aspects.cargo.provides.nixos-user.hjem = { pkgs, ... }: {
    packages = [ pkgs.gh ];
  };
}
