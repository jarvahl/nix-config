{ ... }:
{
  den.aspects.apex.provides.jarvahl.hjem = { pkgs, ... }: {
    packages = with pkgs; [ wget curl ];
  };
}
