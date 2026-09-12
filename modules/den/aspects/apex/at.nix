{ ... }:
{
  den.aspects.apex.nixos = { pkgs, ... }: {
    services.atd.enable = true;
    environment.systemPackages = [ pkgs.at ];
  };
}
