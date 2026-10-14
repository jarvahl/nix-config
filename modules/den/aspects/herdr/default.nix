{ ... }:

{
  den.aspects.herdr.nixos = { pkgs, ... }: {
    environment.systemPackages = [ pkgs.herdr ];
  };
}
