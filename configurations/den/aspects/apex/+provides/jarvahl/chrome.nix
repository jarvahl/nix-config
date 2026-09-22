{ den, ... }:
{
  den.aspects.apex.provides.jarvahl.hjem = { pkgs, ... }: {
    packages = [ pkgs.google-chrome ];
  };

  den.aspects.apex.provides.jarvahl.includes = [
    (den.batteries.unfree [ "google-chrome" ])
  ];
}
