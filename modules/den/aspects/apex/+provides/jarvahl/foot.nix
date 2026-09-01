{ ... }:
{
  den.aspects.apex = {
    provides.jarvahl = {
      hjem = { pkgs, ... }: {
        files.".config/foot/foot.ini".text = ''
          [main]
          pad=16x16
          font=FiraCode Nerd Font:size=9
        '';

        packages = [ pkgs.foot ];
      };
    };
  };
}
